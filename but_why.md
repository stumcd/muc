# Rationale (aka "but why?")

## Potential issues + upgrade workflow impact

When you are trying to upgrade a Mac, there are five types of issues, in order from worst- to best-case scenario:

- The Mac isn’t compatible with the specified version. 
 
- Due to $Reasons, you should erase & re-install macOS.
   
- The Mac _is_ compatible but you can’t use MDM for the upgrade. 
- The Mac is compatible but there is small roadblock you can (probably) clear and run this script again

- You can successfully upgrade this Mac via your MDM solution. 🎉

### Mac isn’t compatible
*This Mac can’t run macOS Sonoma...*

Sorry to be the bearer of bad news, but this Mac is too old. :(
macOS Sonoma is compatible with the following computers:
[Apple documentation](https://support.apple.com/en-au/105113)

### Erase and re-install macOS 

#### ‘Macintosh HD’ not found 
*There is no volume present named ‘Macintosh HD’*

This isn’t technically required, but consistency in file paths may be important in the future- e.g. ‘/Volumes/Mac HD/usr/local/blah’ is NOT ‘/Volumes/Macintosh HD/usr/local/blah’, so just in case this Mac’s system volume is named something special like ‘Backup23restoredv2’ let’s erase the disk and rename it to the default ‘Macintosh HD’

#### ‘Recovery’ not found 
*There is no volume present named ‘Recovery’.*
This isn’t technically required, but let’s avoid any weird situations where there’s an unusual array of volumes, thank you very much. 

### Can’t upgrade via MDM, but upgrading via the GUI is possible

#### No management detected
*Mac is not managed*
This Mac isn’t managed, so you can’t upgrade via MDM. However, you (or the end-user) can upgrade via System Preferences/Settings. 

#### Bootstrap Token is missing
*The MDM server can’t authorise the reboot without a Bootstrap Token*
Without a Bootstrap Token, the MDM Server managing this device cannot authorise an upgrade or update that requires a reboot. Without this, you can’t push the upgrade from the MDM server. 
Use secure token, bootstrap token and volume ownership in deployments 
[Apple Platform Deployment documentation](https://support.apple.com/en-au/guide/deployment/dep24dbdcf9e/web)

### Mac is compatible, but there’s a small obstacle you can probably overcome

#### Not enough free space
*There isn’t enough free space on this Mac*
macOS Sonoma requires 23 GB of free space. 
Krypted: [Free Space Required for Modern macOS Upgrades](https://krypted.com/mac-os-x/free-space-required-for-modern-macos-upgrades/)








================ 

## But I don’t *want* to erase & re-install!!
You might be wondering why some issues we’re checking for are considered reasons to nuke & pave. You might be thinking: 

“There’s nothing wrong with having a system volume named ‘Mac HD’ or ‘Untitled’, I want to upgrade as-is.”

Or “I don’t think it matters the MDM profile is removable, I want to upgrade anyway.” 

Or “But I don’t want to erase and re-install, it will take too long”. 

Do ‘Future You’ a favour and accept these conventions: 

* Volume naming: Stick to standard naming
* Removable MDM profile: Allowing end-users to remove an MDM profile is a terrible user experience (e.g. managed Wi-Fi profiles are dropped, so the device is now offline) and an even worse security posture. 
* Don’t have time or decent download speeds: Setup a Mac to provide Content Caching for all Apple devices on the network, or create a bootable drive (ideally with both USB-A and USB-C)