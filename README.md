## Mac Upgrade Chaperone

At times, it can be difficult to determine what your options are for upgrading a given Mac.
So, it’d be great to have someone who knows all the minutia and can guide you on the best path to take... a guide or sherpa. Or a chaperone!

Meet 'Mac Upgrade Chaperone' 🖥️🤵‍♂️ 
This script will guide you to the best (available) macOS upgrade method for a given Mac. 
Broadly, the upgrade methods range from 'best case scenario' (send an MDM command), through 'not so bad' (manual intervention needed e.g. not enough free space), to 'erase and re-install' (nuke & pave via EACS, MDM command, Recovery, depending on options), and the true dead-end scenario: this Mac *cannot* run the specified macOS version (e.g. incompatible). 

### Features: 
* Target a macOS version to check and report on which requirements are not met  
* Determine the best method available, explain why, provide links to relevant Apple documentation
* MUC conclusion is displayed on-screen using AppleScript, plus two log files are written to disk (general log + error log)
	* Alternative: MUC now has a 'silent mode' that doesn't display any notifications on-screen and *only* logs the results (Thanks to [Daniel MacLaughlin](https://github.com/daniel-maclaughlin) for the idea!) 
* Jamf Pro extension attribute for reporting the MUC conclusion into Jamf Pro inventory, then create Smart Groups e.g. '✅ Upgrade Ready', '⚠️ Needs Attention' and '❌ Can't Upgrade' (Thanks to [Ant Darlow](https://github.com/cantscript) for the idea of scoping upgrade policies to these groups!)

You can view [example output of both logs here](https://github.com/stumcd/muc/blob/0466ddd52df513c698b14c5d8f7baf7c797e4d4e/example_output.md)

### Mac Upgrade Chaperone checks and reports on: 
#### Connectivity
* ✅ Is the Mac connected to a Wi-Fi network?  
* ✅ Is the Mac connected to a wired network?  
* ✅ Is apple.com:443 reachable and open?  

#### Management 
* ✅ Is there an MDM profile?  
* ✅ Is the MDM profile valid (ie not expired)?  
* ✅ Is the MDM profile non-removable?  
		* Has the associated push cert expired? (not reliable currently)  
* ✅ Was the device enrolled via Automated Device Enrollment (aka DEP)?  
* ✅ Was the device enrolled using User-Approved?  
* ✅ Can we connect to the MDM server?  
		* ✅ Has a Bootstrap Token been escrowed to the MDM server?  
MDM Restrictions (still a work in progress)
* ~~Are there any MDM-managed upgrade restrictions in-place?~~ 
* ~~Is there a deferral in place for macOS upgrades? If so, how many days?~~  
* ✅ Is the Software Update Catalog URL set to Apple's default?  
 
#### Disk volumes
* ✅ Are the expected volume names found? (Macintosh HD, Macintosh HD - Data, Preboot, Recovery, VM) 
* ✅ Is there enough available space?
 
#### Compatibility
* ✅ Is the Mac hardware compatible with $targetOS?
* ✅ Can we upgrade directly from the current installed macOS version?
 
#### macOS Installers
✅ * Is there an Installer on disk already? "/Applications/Install $targetOS.app"
✅ * Is the startosinstall binary available the installer too? 

## FAQ:
1. Will this script download and install macOS? **No.**  
------- Instead, check out s.u.p.e.r, nudge or mist  
Will this script *determine what's possible and let you know?* **Yes.**  
------- This script provides advice only. 
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