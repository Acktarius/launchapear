#!/bin/bash
################################################################################
# this file is subject to Licence
#Copyright (c) 2024, Acktarius
################################################################################

#variables
user=$(whoami)
path=$(pwd)
#Delete shortcut and folder
uninstall() {
rm -f /home/${user}/.local/share/applications/launchapear.desktop
rm -rf $path
}
set -e

if (zenity --warning --timeout=12 --text="Confirm Uninstall launchApear folder and shortcut ?"); then
uninstall
fi