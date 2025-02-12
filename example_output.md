## Example output

Default location: `/usr/local/muc/`

#### Error log
`/usr/local/muc/macupgradechaperone_20250117_170138.error.log`
```
⚠️  This Mac was not enrolled via Automated Device Enrollment
⚠️  This Mac is MDM enrolled (User Approved)
❌ Bootstrap Token has NOT been escrowed
❌ 'Macintosh HD' Volume is missing.
❌ 'Macintosh HD - Data' Volume is missing.
❌ Some required volumes are missing.
⚠️ Architecture: Intel
❌ Macmini6,1 is not compatible with macOS Sequoia.
❌ macOS Big Sur (and earlier versions) cannot upgrade to macOS Sequoia.
ℹ️  Current version: 10.15.7
⚠️  macOS Sequoia installer was not found in /Applications
```

#### Log
`/usr/local/muc/macupgradechaperone_20250117_170138.log`
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

