#!/bin/bash
################################################################################
# this file is subject to Licence
#Copyright (c) 2024-2025, Acktarius
################################################################################

#working directory
path=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Configuration
# First check for AppImage location, then fall back to current directory
APPIMAGE_WHITELIST="/usr/share/launchapear/ressources/.whitelistgpg"
CURRENT_DIR_WHITELIST="${path}/.whitelistgpg"

# Set the whitelist file location
if [[ -f "${APPIMAGE_WHITELIST}" ]]; then
    WHITELIST_FILE="${APPIMAGE_WHITELIST}"
    # Make sure the directory exists for writing
    mkdir -p "$(dirname "${APPIMAGE_WHITELIST}")" 2>/dev/null
else
    WHITELIST_FILE="${CURRENT_DIR_WHITELIST}"
fi

MAX_LINK_LENGTH=120

#trip
trip() {
    sleep 1
kill -INT $$
}

#Check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Sub-function to check if a command exists
    check_cmd() {
        if ! command -v "$1" &> /dev/null; then
            missing_deps+=("$1")
        fi
    }
    
    # Check for required dependencies
    check_cmd "zenity"
    check_cmd "pear"
    check_cmd "gpg"
    
    # If any dependencies are missing, show error and exit
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error_msg="Missing required dependencies:\n"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "zenity")
                    error_msg+="- zenity (needed for GUI dialogs)\n"
                    ;;
                "pear")
                    error_msg+="- pear (please visit: https://docs.pears.com/guides/getting-started)\n"
                    ;;
                "gpg")
                    error_msg+="- gpg (needed for secure whitelist storage)\n"
                    ;;
            esac
        done
        
        # Check if zenity is the first missing dependency
        if [[ "${missing_deps[0]}" == "zenity" ]]; then
            # Zenity not available, use console output
            echo -e "${error_msg}"
        else
            # Zenity is available, use GUI dialog
            zenity --error --text="${error_msg}" --width=400
        fi
        exit 1
    fi
}

#Zenity templates
zenwarn() {
    zenity --warning --timeout=12 --text="$@" --width=400
}

zeninfo() {
    zenity --info --timeout=12 --text="$@" --width=400
}

zenerror() {
    zenity --error --text="$@" --width=400
}

if [[ ! -f ${WHITELIST_FILE} ]]; then
    # Create directory for whitelist if it doesn't exist (especially for AppImage)
    mkdir -p "$(dirname "${WHITELIST_FILE}")" 2>/dev/null
    
    if (zenity --question --text="No whitelist, one will be created"); then
    echo "pear://keet pear://runtime" | gpg -c > ${WHITELIST_FILE}
    else
    trip
    fi
fi

#functions
launchPear() {
    local link="$1"
    local tmp_output_file="/tmp/pear_output_$$.txt"
    local app_pid
    local trust_issue
    local line_count
    
    echo "Starting Pear app..."
    
    # Run the app in background and capture its PID
    pear run "${link}" --no-ask-trust > "$tmp_output_file" 2>&1 &
    app_pid=$!
    
    # Wait for a moment to collect output and check status
    sleep 2
    
    # Check for trust issues by looking for the word "TRUST" in the output
    if grep -q "TRUST" "$tmp_output_file"; then
        # Trust is required - found the word TRUST in output
        trust_issue=1
    else
        # Trust is not required
        trust_issue=0
    fi
    
    # Count lines of output
    line_count=$(wc -l < "$tmp_output_file")
    
    # Display debug info
    echo "PID: $app_pid, Trust issue: $trust_issue, Lines: $line_count"
    
    # Check if trust is required based on trust_issue flag
    if [[ $trust_issue -eq 1 ]]; then
        # Trust is required - first kill the background process that needs trust
        echo "Trust issue detected, terminating current process..."
        kill $app_pid 2>/dev/null
        
        # Ask user if they want to proceed with trust process
        if zenity --warning --text="Link requires going through the TRUST process.\n\nContinue?"; then
            echo "Launching terminal for TRUST interaction..."
            # Launch in terminal where user can interact with the TRUST process
            gnome-terminal --title='TRUST Required' --active --geometry=80x20 -- bash -c "pear run \"$link\""
        else
            echo "User declined TRUST process."
            zeninfo "Pear link won't be launched.\nYou're never too cautious.\n\nBye now!"
            rm -f "$tmp_output_file"
            return 1
        fi
        
        # Clean up and exit main script
        rm -f "$tmp_output_file"
        echo "Exiting launcher after trust handling..."
        exit 0
    fi
    
    # If we got here, the app is trusted and running
    # Check if it's a terminal app based on line count
    if [[ $line_count -gt 4 ]]; then
        echo "Detected terminal app, relaunching in terminal window..."
        # Kill the background process
        kill $app_pid 2>/dev/null
        
        # Launch terminal with the app and let it run independently
        gnome-terminal --title="Pear: $link" --geometry=100x30 -- bash -c "pear run \"$link\""
    else
        echo "Detected desktop app, already running as child process (PID: $app_pid)..."
        # For desktop apps, do nothing - it's already running in background
    fi
    
    # Clean up
    rm -f "$tmp_output_file"
    
    # Exit main script, allowing the subprocess to continue running
    echo "Exiting launcher, app will continue running..."
    exit 0
}

listIt() {
local newLink="$1"
declare -a whiteListArray
read -a whiteListArray <<< "$(gpg -qd ${WHITELIST_FILE})"
if [[ "${whiteListArray[@]}" =~ "${newLink}" ]]; then
    zeninfo "pear link is already in your white list"
    trip
fi
whiteListArray+=("${newLink}")
echo ${whiteListArray[@]} | gpg -c > ${WHITELIST_FILE}
}

notListed() {
local link="$1"
info_temp=$(pear info "${link}")
notValid=$(echo "${info_temp}" | grep -c "is not valid")
set -e
    if [[ "${notValid}" -gt "0" ]]; then
    zenwarn "pear link is not valid"
    else
    echo "${info_temp}" > info_temp.md
        if (zenity --text-info \
            --title="NOT IN YOUR WHITE LIST - Pear link info" \
            --width=480 \
            --height=640 \
            --filename=${path}/info_temp.md \
            --checkbox="I want to add it to the white list"); then
        rm -f ${path}/info_temp.md  
        listIt "${link}"
            case $? in
                0)
                sleep 1
                launchPear "${link}"  
                ;;
                *)
                trip
                ;;
            esac
        else
        zeninfo "pear link won't be added,\nyou're never too cautious\n\n\tBye now"
        fi
    rm -f ${path}/info_temp.md     
    fi  
}

#MAIN
main() {
check_dependencies

pearLink=$(zenity --entry --title="launch a 🍐" --text="Enter pear link:" \
--width=520 \
--entry-text "$1")
}
main "pear://"

if [[ "${pearLink:0:7}" != "pear://" ]]; then
zenwarn "pear link should start with:\n \
pear://"
sleep 1
exit 1
fi 

if [[ ${#pearLink} -gt "${MAX_LINK_LENGTH}" ]]; then
zenwarn "pear link seems a bit too long"
sleep 1
exit 1
fi 

inWhiteList() {
local inWhiteList=1    
declare -a whiteListArray
read -a whiteListArray <<< "$(gpg -qd ${WHITELIST_FILE})"
for entry in ${whiteListArray[@]}; do
    if [[ "${entry}" == "${pearLink}" ]]; then
    launchPear "${pearLink}"
    inWhiteList=0
    break
    fi
done
unset whiteListArray
if [[ "${inWhiteList}" -eq 1 ]]; then
notListed "${pearLink}"
fi
}
inWhiteList


