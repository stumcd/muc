# MUC - Mac Upgrade Chaperone

It can be difficult to determine the best way to upgrade a given Mac. e.g. what is a Secure Token & is it needed to upgrade? Can this Mac even upgrade to 'macOS Palm Springs'? Would it just be easier to erase and reinstall? 
Your scenario may range from 'I have 15 Macs here I need to return to service ASAP on the latest version' to 'I need to get this Mac onto the latest version ASAP, but can I upgrade in place so I don't need to backup and restore user data after the install?' 

So, it’d be great to have someone who knows all the minutia and can guide you on the best path to take... a guide or sherpa. Or a chaperone!

Meet 'Mac Upgrade Chaperone' 🖥️🤵‍♂️ 
This script will guide you to the best (available) macOS upgrade method for a given Mac. 
Broadly, the upgrade methods range from 'best case scenario' (send an MDM command), through 'not so bad' (manual intervention needed e.g. not enough free space), to 'erase and re-install' (nuke & pave via EACS, MDM command, Recovery, depending on options), and the true dead-end scenario: this Mac *cannot* run the specified macOS version (e.g. incompatible). 


## To determine the 'best' upgrade method, Mac Upgrade Chaperone will check: 

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
  * Has a Bootstrap Token been escrowed to the MDM server? ✅
* Are there any MDM-managed upgrade restrictions in-place? (not accurate atm)
* Is there a deferral in place for macOS updates? (not accurate atm)
  * If so, how many days? (not accurate atm)
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
==========================================================
========= 🖥️ 🤵 Mac Upgrade Chaperone v0.6🤵 🖥️ ========
==========================================================
🎯 Target version: macOS Sequoia
-------------------------
Log: /usr/local/muc/macupgradechaperone_20250117_170138.log
Error log: /usr/local/muc/macupgradechaperone_20250117_170138.error.log
-------------------------
🌐 Checking network connection...
✅ Network connection detected. �
✅ Successfully connected to apple.com on port 443. Port check passed.
-------------------------
----- Guiding your journey to... ✨ macOS Sequoia ✨ -----
-------------------------
Start: 2025-01-17 17:01:38
=========================================
⚙️  Checking MDM profile...
------------------------------
✅ MDM Profile: Installed.
ℹ️  MDM Server: blah.jamfcloud.com
✅ Push certificate is valid. Expiry date: Aug 23 05:18:30 2040 GMT
⚠️  This Mac was not enrolled via Automated Device Enrollment
⚠️  This Mac is MDM enrolled (User Approved)
------------------------------
⚙️  Checking MDM Server...
------------------------------
✅ MDM Server is reachable.
ℹ️  URL: blah.jamfcloud.com
ℹ️  HTTP response: 301
❌ Bootstrap Token has NOT been escrowed
-----
Checking for any managed configuration preventing macOS upgrades...
✅ No macOS restrictions found in com.apple.applicationaccess.
✅ No deferral policy for macOS updates detected.
✅ The system is using Apple's default software update catalog.
------------------------------
🧐 Checking APFS volumes...
------------------------------
❌ 'Macintosh HD' Volume is missing.
❌ 'Macintosh HD - Data' Volume is missing.
✅ 'Preboot' Volume is present.
✅ 'Recovery' Volume is present.
✅ 'VM' Volume is present.
❌ Some required volumes are missing.
✅ There is enough free space on disk to install macOS Sequoia (20 GB required, 641 GB available).
------------------------------
🖥 Checking Mac hardware:
⚠️ Architecture: Intel
-- Serial: C04JK5111YZL
-- Model: Mac mini
-- Model Identifier: Macmini6,1
-- Processor Info: Dual-Core Intel Core i5
❌ Macmini6,1 is not compatible with macOS Sequoia.
-------------------------
🖥  Checking existing macOS installation
❌ macOS Big Sur (and earlier versions) cannot upgrade to macOS Sequoia.
ℹ️  Current version: 10.15.7
⚠️  macOS Sequoia installer was not found in /Applications
-------------------------
🙋 Checking which users have admin role + are Secure Token enabled...
-------------------------
User: localadmin
      Admin
      Secure Token enabled
      Home Directory: /Users/localadmin
      UID: 502
User: oscar
      Admin
      Secure Token enabled
      Home Directory: /Users/oscar
      UID: 503
-------------------------
Evaluation complete.
-------------------------
🧮 Calculating the best upgrade path...
🌲 Reticulating splines...
-------------------------
========= 🖥️ 🤵 Mac Upgrade Chaperone 🖥️ =========
==================== Conclusion =====================
Bad news…\n\nThis Mac is not compatible with the target version of macOS (macOS Sequoia).\n\n❌ macOS Big Sur (and earlier versions) cannot upgrade to macOS Sequoia.
-------------------------
```

## FAQ:
1. Will this script download and install macOS? **No.**
------- Instead, check out s.u.p.e.r, nudge or mist
2. Will this script *determine what's possible and let you know?* **Yes.**
------- This script provides advice only. It doesn't actually *do* anything besides write results to log files. 
3. Is this still a work-in-progress? *Yes!*
------- If you have a suggestion on checks that should be included or false positives you notice, please let me know- submit a issue!




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
