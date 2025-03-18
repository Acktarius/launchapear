# Launch a Pear

A secure launcher for Pear apps with whitelisting capabilities.

## Features

- Launch Pear applications securely
- Maintain a whitelist of trusted Pear links
- Automatic detection of terminal/desktop apps
- GPG encryption for the whitelist

## AppImage

The application is available as an AppImage, which provides these benefits:
- No installation required
- Portable across Linux distributions
- Desktop integration
- Automatic dependency checks

### Using the AppImage

1. Download the latest AppImage from the [Releases](https://github.com/yourusername/launchapear/releases) page
2. Make it executable:
   ```bash
   chmod +x LaunchAPear-*.AppImage
   ```
3. Run it:
   ```bash
   ./LaunchAPear-*.AppImage
   ```

### Building the AppImage Manually

If you want to build the AppImage yourself:

1. Clone this repository
2. Make sure you have `linuxdeploy` installed
3. Run the build script:
   ```bash
   # Extract version from git tag or set manually
   VERSION=$(git describe --tags --always | sed 's/^v//')
   
   # Create AppDir structure
   mkdir -p AppDir/usr/bin
   mkdir -p AppDir/usr/share/applications
   mkdir -p AppDir/usr/share/icons/hicolor/128x128/apps
   
   # Copy files
   cp launchapear.sh AppDir/usr/bin/launchapear
   cp icon/pearrocket.png AppDir/usr/share/icons/hicolor/128x128/apps/launchapear.png
   cp icon/pearrocket.png AppDir/launchapear.png
   cp AppRun AppDir/AppRun
   
   # Make scripts executable
   chmod +x AppDir/usr/bin/launchapear AppDir/AppRun
   
   # Create desktop file
   cat > AppDir/usr/share/applications/launchapear.desktop << EOF
   [Desktop Entry]
   Type=Application
   Name=Launch a Pear
   Comment=Launch Pear applications securely
   Exec=launchapear
   Icon=launchapear
   Categories=Office;Utility;Network;
   Terminal=false
   EOF
   
   # Build the AppImage
   ./linuxdeploy-x86_64.AppImage --appdir=AppDir --output=appimage
   ```

## Dependencies

- zenity
- pear
- gpg

## License

This project is licensed under the terms of the included LICENSE file.

## DISCLAIMER
Only launch link you trust !
this script is delivered "as is" and the author deny any and all liability for any damages arising out of using it! 

## check
make sure *launchapear.sh* and *shortcut_installer.sh* are executable,  
if not :  
`chmod 755 launchapear.sh`  
`chmod 755 shortcut_installer.sh`  

## Install
Download this repository in folder of your choice:
in terminal, (Ctrl + Alt +T)
`git clone https://github.com/Acktarius/launchapear.git`  
`cd launchapear`  
`source shortcut_installer.sh`  

new icon should appear on your desktop, if not logout and log back in.

---  

#TODO: 

- [ ] Sandbox
- [x] Personal encrypted whitelist

---  
comments, questions, suggestions:  

https://discord.gg/643caU8a