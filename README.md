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
 
### Example screenshots
Log:
![muc - log](https://raw.githubusercontent.com/stumcd/muc/main/README_Resources/example.png)

Error log:
![muc - error_log](https://github.com/user-attachments/assets/204996b2-727e-409f-9b06-d6700618d9bd)


