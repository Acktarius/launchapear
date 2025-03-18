# Launch a Pear

A secure launcher for Pear apps with whitelisting capabilities.

## Features

- Launch Pear applications securely
- Maintain a whitelist of trusted Pear links
- Automatic detection of terminal/desktop apps
- GPG encryption for the whitelist

## Dependencies

- zenity
- pear
- gpg

## License

This project is licensed under the terms of the included LICENSE file.

## DISCLAIMER
Only launch link you trust !
this script is delivered "as is" and the author deny any and all liability for any damages arising out of using it! 


## AppImage

The application is available as an AppImage, which provides these benefits:
- No installation required
- Portable across Linux distributions
- Desktop integration
- Automatic dependency checks

### Using the AppImage

1. Download the latest AppImage from the [Releases](https://github.com/Acktarius/launchapear/releases) page
2. Make it executable:
   ```bash
   chmod +x LaunchAPear-*.AppImage
   ```
3. Run it:
   ```bash
   ./LaunchAPear-*.AppImage
   ```

When running as an AppImage, the application will automatically detect the AppImage environment and store the whitelist in `/usr/share/launchapear/ressources/` directory within the AppImage filesystem. When running directly as a script, it will use the whitelist in the current directory.

### Verifying Integrity

Each release includes an MD5 checksum file to verify the integrity of your download:

1. Download both the AppImage and the MD5 checksum file
2. Verify the integrity by running:
   ```bash
   md5sum -c LaunchAPear-md5sums.txt
   ```
3. You should see "OK" if the checksum matches

Alternatively, you can generate and compare the checksums manually:
```bash
md5sum LaunchAPear-*.AppImage
cat LaunchAPear-md5sums.txt
```

## Manual Install

### check
make sure *launchapear.sh* and *shortcut_installer.sh* are executable,  
if not :  
`chmod 755 launchapear.sh`  
`chmod 755 shortcut_installer.sh`  

### Install
Download this repository in folder of your choice:
in terminal, (Ctrl + Alt +T)
`git clone https://github.com/Acktarius/launchapear.git`  
`cd launchapear`  
`source shortcut_installer.sh`  

new icon should appear on your desktop, if not logout and log back in.

---  
comments, questions, suggestions:  

https://discord.gg/643caU8a