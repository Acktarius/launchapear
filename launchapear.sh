#!/bin/bash
################################################################################
# this file is subject to Licence
#Copyright (c) 2024, Acktarius
################################################################################

#working directory
path=$(pwd)

#trip
trip() {
kill -INT $$
}


#Check Zenity
if ! command -v zenity &> /dev/null; then
echo "zenity not install"
sleep 1
trip
fi

#Zenity templates
zenwarn() {
zenity --warning --timeout=12 --text="$@"
}
zeninfo() {
zenity --info --timeout=12 --text="$@"
}

#Check Pear
if ! command -v pear &> /dev/null; then
zenwarn "Pear is not installed\n \
Please visit:\n \
https://docs.pears.com/guides/getting-started"
sleep 1
trip
fi 

if [[ ! -f ${path}/.whitelistgpg ]]; then
    if (zenity --question --text="No whitelist, one will be created"); then
    echo "pear://keet pear://runtime" | gpg -c > ${path}/.whitelistgpg
    else
    trip
    fi
fi

#functions
launchPear() {
    pear run $1 --no-ask-trust
    if [[ "$?" -eq "1" ]]; then
        if (zenity --warning \
        --text="link is in your white list\nbut you still need to go through TRUST process,\n\n\tcontinue ?"); then
        gnome-terminal --title='TRUST ?' --active --geometry=80x20 -- bash -c 'pear run "$1"' sh "$1"
        else
zeninfo "pear link won't be launched,\nyou're never too cautious\n\n\tBye now"
        fi
    fi
}

#MAIN
main() {
pearLink=$(zenity --entry --title="launch a 🍐" --text="Enter pear link:" \
--width=520 \
--entry-text "$1")
}
main "pear://"

if [[ "${pearLink:0:7}" != "pear://" ]]; then
zenwarn "pear link should start with:\n \
pear://"
sleep 1
trip
fi 

if [[ ${#pearLink} -gt 120 ]]; then
zenwarn "pear link seems a bit too long"
sleep 1
trip
fi 

inWhiteList() {
declare -a whiteListArray
read -a whiteListArray <<< "$(gpg -qd ${path}/.whitelistgpg)"
#echo ${whiteListArray[@]} ---------------------------------------------<
notFoundInit=${#whiteListArray[@]}
for i in ${whiteListArray[@]}; do
    if [[ "$i" == "${pearLink}" ]]; then
    #pear run $pearLink
    launchPear $pearLink
    break
    else
    notFoundInit=$(( $notFoundInit - 1 ))
    fi
done
unset whiteListArray
}
inWhiteList

listIt() {
declare -a whiteListArray
read -a whiteListArray <<< "$(gpg -qd ${path}/.whitelistgpg)"
whiteListArray+=("${1}")
echo ${whiteListArray[@]} | gpg -c > ${path}/.whitelistgpg
}


notListed() {
info_temp=$(pear info $1)
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
listIt $1
case $? in
    0)
    sleep 1
    main "$1"
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


if [[ $notFoundInit -eq 0 ]]; then
notListed $pearLink
fi
