# MUC - Mac Upgrade Chaperone

It can be a challenge to determine the best way to upgrade a given Mac. 
So, it’d be great if we had a guide or sherpa for the journey. Or a chaperone!

Meet 'MacUpgradeChaperone' 🖥️🤵‍♂️ 
This script aims to guide you to the 'best' macOS upgrade method, ranging from 'good' (send an MDM command) to 'bad' (nuke & pave via EACS, MDM command, Recovery, depending on options)

Note:
1. Will this script download and install macOS? **No.**
2. Will this script *determine what's possible and let you know?* **Yes.**
3. Is this still a work-in-progress? *Yes!*


## How to use
### Jamf Pro
1. Upload script
2. Create policy
3. Scope
4. Upload extension attribute (optional) 
5. Test

### Manually
1. Download script
2. Execute `sudo sh /path/to/macupgradechaperone-0.6.sh`

[Direct link to script](https://github.com/stumcd/muc/blob/92c9c35fbac19e1376353805e50b8404f70e0932/macupgradechaperone-0.6.sh)




## Checks include: 

### Connectivity
* Is the Mac connected to a wifi network? ✅
* Is the Mac connected to an wired network? ✅
* Can we netcat apple.com:443? ✅

### Management 
* Is there an MDM profile? ✅
  * Is the MDM profile valid (ie not expired)?
  * Is the MDM profile non-removable?
  * Has the associated push cert expired? 
* Was the device enrolled via Automated Device Enrollment (aka DEP)? ✅
* Was the device enrolled using User-Approved?
* Can we connect to the MDM server? ✅
  * Has a Bootstrap Token been escrowed to the MDM server? 
* Are there any MDM-managed upgrade restrictions in-place? 
* Is there a deferral in place for macOS updates?
  * If so, how many days?
* Is the Software Update Catalog URL set to Apple's default? ✅
 
### Disk volumes
* Are the expected volume names found? (Macintosh HD, Macintosh HD - Data, Preboot, Recovery, VM) ✅
* Is there enough available space? ✅
 
### Compatibility
* Is the Mac hardware compatible with $targetOS? ✅
* Can we upgrade directly from the current installed macOS version? ✅
 
### macOS Installation
* Is there an Installer on disk already? "/Applications/Install $targetOS.app" ✅
* Is the startosinstall binary available the installer too? ✅
 
## Example output: 
```
Log: /usr/local/muc/macupgradechaperone_20250114_095823.log
Error log: /usr/local/muc/macupgradechaperone_20250114_095823.error.log
========= 🖥️ 🤵 Mac Upgrade Chaperone v0.6🤵 🖥️ =========
-------------------------
- Jamf Pro script parameters were not detected, so falling back to default.
🎯 Target version set: macOS Sonoma
-------------------------
🌐 Checking network connection...
✅ Network connection detected. 🎉
✅ Successfully connected to apple.com on port 443. Port check passed.
-------------------------
----- Guiding your journey to... ✨ macOS Sonoma ✨ -----
-------------------------
Start time: 2025-01-14 09:58:23
Checking local user accounts for admin/standard roles and Secure Token status...
User: john.smith
Role: Admin
Secure Token: ENABLED
---
User account check completed.
------------------------------
⚙️  Checking MDM enrollment...
------------------------------
✅ MDM Profile: Installed.
--- MDM Server: blah.jamfcloud.com
❌  MDM Profile is removable.
✅ Push certificate is valid. Expiry date: Feb  6 05:22:29 2042 GMT
✅ This Mac was enrolled using Automated Device Enrollment
⚠️ This Mac _is_ enrolled in MDM (User Approved), but not via Automated Device Enrollment..
------------------------------
⚙️  Checking MDM Server...
------------------------------
✅ MDM Server is reachable. URL: blah.jamfcloud.com. HTTP status code: 301
✅ Bootstrap Token has been escrowed
Checking for any macOS upgrade restrictions...
✅ No macOS restrictions found in com.apple.applicationaccess.
✅ No deferral policy for macOS updates detected.
✅ The system is using Apple's default software update catalog.
------------------------------
🧐 Checking the volumes on disk...
------------------------------
✅ 'Macintosh HD' Volume is present.
❌ 'Macintosh HD - Data' Volume is missing.
✅ 'Preboot' Volume is present.
✅ 'Recovery' Volume is present.
✅ 'VM' Volume is present.
❌ Some required volumes are missing.
------------------------------
📏 Checking available space...
------------------------------
--- ✅ There is enough free space (20 GB required, 104 GB available).
✅ Architecture: Apple silicon
------------------------------
🖥  Mac hardware:
Serial: XWXYZ0V123
Model: MacBook Pro
Model Identifier: MacBookPro18,3
Processor Info: Apple M1 Pro
✅ Architecture: Apple silicon
-------------------------
✅ Compatible with macOS Sonoma
-------------------------
🖥  Checking existing macOS installation
✅ 15.2 can upgrade to macOS Sonoma
❌ macOS Sonoma installer was not found in /Applications
-------------------------
Evaluation complete.
-------------------------
🧮 Calculating the best upgrade path...
🌲 Reticulating splines...
-------------------------
======= MacUpgradeChaperone Conclusion ======
Bad news...

❌  MDM Profile is removable.
❌ Some required volumes are missing.

You will need to erase and re-install macOS, using either Internet Recovery or Apple Configurator 2. (aka time to nuke and pave).
-------------------------
Best of luck on your upgrade journey! Bon voyage! 👋
Completed time: 2025-01-14 09:58:28
```