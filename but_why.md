# Rationale (aka "but why?")


On the journey to upgrade a given Mac, there are (as I see it) 5 potential pathways: 

1. **End of the road:**
The Mac isn’t compatible with the specified version. 
 
2. **Nuke & Pave:** Due to $Reasons, you have to erase & re-install macOS. 
   
3. **'Be' the user:** Upgrade possible, but not via MDM. Must be done manually in GUI, or Nuke & Pave.

4. **Detour:** The Mac _is_ compatible but you can’t use MDM for the upgrade or there is small roadblock you can (probably) clear and run this script again

5. **Latest & greatest**
   Best case scenario! You can successfully upgrade this Mac via MDM. 🎉

------------ 
------------
### End of the road
_Sorry to be the bearer of bad news, but it's *not possible* for this Mac to run the target macOS version._
* The Mac isn't compatible
* The Mac isn't supported 
* This Mac cannot upgrade

macOS Sonoma is compatible with the following computers:
[Apple documentation](https://support.apple.com/en-au/105113)

-------------
### Nuke & Pave
_Erase and re-install macOS. Using EACS within the GUI if possible. Alternatively, AC2, or bootable USB_
* Weird array of volumes 
* MDM profile is removable (No, I don't think your management tooling should be removable. Automated Device Enrollment only is the best posture.)

Apple documentation: 
- [How to reinstall macOS](https://support.apple.com/en-au/102655)
- [Create a bootable installer for macOS](https://support.apple.com/en-au/101578)
- 

-------------
### Manual upgrade possible
_Maybe the MDM Server is no longer available. Maybe there never was an MDM server. But you can upgrade this Mac manually, provided you know the password of a local user._
* No MDM profile, Mac is not managed
* Can't reach the MDM server
* Bootstrap token is NOT escrowed 
* Push cert is expired

-------------
### Detour
* Not enough free space on disk 
* MDM
  - Software Update restriction in place
  - macOS Update Deferral 
* Software Update catalog custom URL






-------------

#### ‘Macintosh HD’ not found 
*There is no volume present named ‘Macintosh HD’*

This isn’t technically required, but consistency in file paths may be important in the future- e.g. ‘/Volumes/Mac HD/usr/local/blah’ is NOT ‘/Volumes/Macintosh HD/usr/local/blah’, so just in case this Mac’s system volume is named something special like ‘Backup23restoredv2’ let’s erase the disk and rename it to the default ‘Macintosh HD’

#### ‘Recovery’ not found 
*There is no volume present named ‘Recovery’.*
This isn’t technically required, but let’s avoid any weird situations where there’s an unusual array of volumes, thank you very much. 


#### Bootstrap Token is missing
*The MDM server can’t authorise the reboot without a Bootstrap Token*
Without a Bootstrap Token, the MDM Server managing this device cannot authorise an upgrade or update that requires a reboot. Without this, you can’t push the upgrade from the MDM server. 
Use secure token, bootstrap token and volume ownership in deployments 
[Apple Platform Deployment documentation](https://support.apple.com/en-au/guide/deployment/dep24dbdcf9e/web)


-------------

### Detour
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