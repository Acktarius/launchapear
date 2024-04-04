#!/bin/bash
################################################################################
# this file is subject to Licence
#Copyright (c) 2024, Acktarius
################################################################################

#trip
trip() {
kill -INT $$
}
#Zenity templates
zenwarn() {
zenity --warning --timeout=12 --text="$@"
}
zeninfo() {
zenity --info --timeout=12 --text="$@"
}

#Check Zenity
if ! command -v zenity &> /dev/null; then
echo "zenity not install"
sleep 1
trip
fi

#Check Pear
if ! command -v pear &> /dev/null; then
zenwarn "Pear is not installed\n \
Please visit:\n \
https://docs.pears.com/guides/getting-started"
sleep 1
trip
fi 


set -e

#MAIN
pearLink=$(zenity --entry --title="launch a 🍐" --text="Enter pear link:" \
--width=520 \
--entry-text "pear://")


if [[ "${pearLink:0:7}" != "pear://" ]]; then
zenwarn "pear link should start with:\n \
pear://"
sleep 1
trip
fi 

if [[ ${#pearLink} -gt 59 ]]; then
zenwarn "pear link seems a bit too long"
sleep 1
trip
fi 

pear run $pearLink


