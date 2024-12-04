# Rationale (aka "but why?")

### Potential issues + upgrade workflow impact

#### Bootstrap Token is missing
*The MDM server can't authorise the reboot without a Bootstrap Token*
Without a Bootstrap Token, the MDM Server managing this device cannot authorise an upgrade or update that requires a reboot. Without this, you can't push the upgrade from the MDM server. 
Use secure token, bootstrap token and volume ownership in deployments 
[Apple Platform Deployment documentation](https://support.apple.com/en-au/guide/deployment/dep24dbdcf9e/web)

#### Hardware not compatible with macOS Sonoma
*This Mac can't run macOS Sonoma...*
macOS Sonoma is compatible with the following computers:
[Apple documentation](https://support.apple.com/en-au/105113)

### *Issues preventing macOS upgrade, regardless of method*

#### Not enough free space
*There isn't enough free space on this Mac*
macOS Sonoma requires 23 GB of free space. 
Krypted: [Free Space Required for Modern macOS Upgrades](https://krypted.com/mac-os-x/free-space-required-for-modern-macos-upgrades/)

#### 'Macintosh HD' not found 
*There is no volume present named 'Macintosh HD'*
This isn't technically required, but consistency in file paths may be important in the future- e.g. '/Volumes/Mac HD/usr/local/blah' is NOT '/Volumes/Macintosh HD/usr/local/blah', so just in case this Mac's system volume is named something special like 'Backup23restoredv2' let's erase the disk and rename it to the default 'Macintosh HD'

#### 'Recovery' not found 
*There is no volume present named 'Recovery'.*
This isn't technically required, but let's avoid any weird situations where there's an unusual array of volumes, thank you very much. 