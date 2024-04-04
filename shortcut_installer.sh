#!/bin/bash
#shorcut installer for launchapear Ubuntu users
# this file is subject to Licence
#Copyright (c) 2024, Acktarius
#
# make sure ./shortcut_installer.sh is an executable file
# otherwise, run: sudo chmod 755 shortcut_installer.sh
# run with command: ./shortcut_installer.sh
#
#
#variables
user=$(whoami)
path=$(pwd)
#Functions
shortcutCreator() {
cat << EOF > /home/${user}/.local/share/applications/launchapear.desktop
[Desktop Entry]
Encoding=UTF-8
Name=Launch a Pear
Exec=${path}/launchapear.sh
Terminal=false
Type=Application
Icon=${path}/icon/pearrocket.png
Hidden=false
NoDisplay=false
Terminal=false
Categories=Office
X-GNOME-Autostart-enabled=true
Comment=launch a pear link
EOF
echo "shortcut created, you may have to log out and log back in"
}
already() {
read -p  "shortcut already in place, do you want to replace it (y/N)" ans
	case $ans in
		y | Y | yes)
		rm -f /home/${user}/.local/share/applications/launchapear.desktop
		shortcutCreator
		;;
		*)
		echo "nothing done"
		;;
	esac
}
#check and install
##not already install
if [[ ! -f /home/${user}/.local/share/applications/launchapear.desktop ]]; then 
shortcutCreator
else
already
fi

