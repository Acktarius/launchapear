#!/bin/bash
################################################################################
# this file is subject to Licence
#Copyright (c) 2024-2025, Acktarius
################################################################################

#working directory
path=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Configuration
# Define whitelist locations
# Use XDG_DATA_HOME if defined, otherwise default to ~/.local/share
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APPIMAGE_WHITELIST="${XDG_DATA_HOME}/launchapear/.whitelistgpg"
CURRENT_DIR_WHITELIST="${path}/.whitelistgpg"

# Better AppImage detection using environment variable set in AppRun
if [[ -n "$LAUNCHAPEAR_APPIMAGE" ]]; then
    WHITELIST_FILE="${APPIMAGE_WHITELIST}"
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
    # Always ensure the directory exists before trying to create the whitelist
    if ! mkdir -p "$(dirname "${WHITELIST_FILE}")" 2>/dev/null; then
        # If directory creation fails
        zenerror "Failed to create directory for whitelist.\nPlease check permissions."
        exit 1
    fi
    
    if (zenity --question --text="No whitelist, one will be created.\n\nYou'll need to set a password for your whitelist.\nRemember this password - you'll need it every time!"); then
        if ! echo "pear://keet pear://runtime" | gpg --no-symkey-cache -c > "${WHITELIST_FILE}" 2>/dev/null; then
            # If writing to whitelist fails
            zenerror "Failed to create whitelist file.\nPlease check permissions."
            exit 1
        fi
        
        # Show a message emphasizing password importance
        zenity --info --title="Password Important!" \
            --text="Whitelist created successfully.\n\nIMPORTANT: Remember your password!\nYou will need the EXACT SAME PASSWORD\nwhenever you use this application." \
            --width=400
    else
        trip
    fi
fi

#functions
launchPear() {
    local link="$1"
    local tmp_output_file="/tmp/launchapear_output_$$.txt"
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
        if ps -p $app_pid > /dev/null 2>&1; then
            kill $app_pid 2>/dev/null || true
            echo "Killed background process with PID: $app_pid"
        else
            echo "Process with PID: $app_pid no longer running"
        fi
        
        # Ask user if they want to proceed with trust process
        if zenity --warning --text="Link requires going through the TRUST process.\n\nContinue?"; then
            echo "Launching terminal for TRUST interaction..."
            # Launch in terminal where user can interact with the TRUST process
            gnome-terminal --title='TRUST Required' --active --geometry=80x20 -- bash -c "pear run \"$link\""
            # Clean up and return from function
            rm -f "$tmp_output_file"
            echo "Launched trust process in terminal, returning from launcher..."
            return 0
        else
            echo "User declined TRUST process."
            zeninfo "Pear link won't be launched.\nYou're never too cautious.\n\nBye now!"
            rm -f "$tmp_output_file"
            return 1
        fi
    fi
    
    # If we got here, the app is trusted and running
    # Check if it's a terminal app based on line count
    if [[ $line_count -gt 4 ]]; then
        echo "Detected terminal app, relaunching in terminal window..."
        # Kill the background process more safely
        if ps -p $app_pid > /dev/null 2>&1; then
            kill $app_pid 2>/dev/null || true
            echo "Killed background process with PID: $app_pid"
        else
            echo "Process with PID: $app_pid no longer running"
        fi
        
        # Add debug output before launching terminal
        echo "Debug: About to launch gnome-terminal with command: pear run \"$link\""
        # Launch terminal with the app and let it run independently
        gnome-terminal --title="Pear: $link" --geometry=100x30 -- bash -c "pear run \"$link\""
        echo "Debug: After gnome-terminal command"
        
        # Clean up
        rm -f "$tmp_output_file"
        
        # Return from function instead of exiting script
        echo "Terminal app launched in separate window, returning from launcher..."
        return 0
    else
        echo "Detected desktop app, already running as child process (PID: $app_pid)..."
        # For desktop apps, do nothing - it's already running in background
        
        # Clean up
        rm -f "$tmp_output_file"
        
        # Return from function instead of exiting script
        echo "Desktop app running in background, returning from launcher..."
        return 0
    fi
}

listIt() {
local newLink="$1"
declare -a whiteListArray
local gpg_output
gpg_output=$(gpg --no-symkey-cache -qd ${WHITELIST_FILE} 2>&1)

# Check if decryption failed
if [[ "$gpg_output" == *"decryption failed"* ]]; then
    zenwarn "Wrong password, please try again"
    trip
    return 1
fi

# Only process the whitelist if decryption succeeded
read -a whiteListArray <<< "$gpg_output"

if [[ "${whiteListArray[@]}" =~ "${newLink}" ]]; then
    zeninfo "Pear link is already in your whitelist"
    trip
    return 0
fi

# Add the new link
whiteListArray+=("${newLink}")

# Display clear message about using the same password
zenity --info --title="Password Required" --text="Please use the SAME PASSWORD you just entered.\nDo not change it or the whitelist will be corrupted." --width=350

# Re-encrypt with hopefully the same password
echo ${whiteListArray[@]} | gpg --no-symkey-cache -c > ${WHITELIST_FILE}

# Add debug output and return success
echo "Debug: Link successfully added to whitelist, returning from listIt"
zeninfo "Link successfully added to whitelist"
return 0
}

notListed() {
local link="$1"
info_temp=$(pear info "${link}")
notValid=$(echo "${info_temp}" | grep -c "is not valid")
    if [[ "${notValid}" -gt "0" ]]; then
        zenwarn "pear link is not valid"
    else
        # Use /tmp for temporary files to avoid read-only filesystem issues
        local info_temp_file="/tmp/launchapear_info_$$.md"
        echo "${info_temp}" > "$info_temp_file"
        if (zenity --text-info \
            --title="NOT IN YOUR WHITE LIST - Pear link info" \
            --width=480 \
            --height=640 \
            --filename="$info_temp_file" \
            --checkbox="I want to add it to the white list"); then
            rm -f "$info_temp_file"  
            listIt "${link}"
            # Add debug output to help trace the flow
            echo "Debug: After listIt, now launching with launchPear"
            # Directly launch the app without checking return value
            launchPear "${link}"
            # Return to prevent further processing
            return
        else
            zeninfo "pear link won't be added,\nyou're never too cautious\n\n\tBye now"
        fi
        rm -f "$info_temp_file"     
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
local gpg_output
gpg_output=$(gpg --no-symkey-cache -qd ${WHITELIST_FILE} 2>&1)

# First check if decryption failed before trying to process output
if [[ "$gpg_output" == *"decryption failed"* ]]; then
    zenwarn "wrong password, please try again"
    trip
fi

# Only process the whitelist if decryption succeeded
read -a whiteListArray <<< "$gpg_output"

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


