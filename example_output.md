## Example output

By default, logs are written to: `/usr/local/muc/`

### Error log

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

### General log
```
============================================================
======= 🖥️ 🤵 Mac Upgrade Chaperone v0.61 🤵🖥️  ===========
--------------- Guiding your journey to... ----------------
------------------ ✨ macOS Sequoia ✨ --------------------
============================================================
ℹ️️  General log: /usr/local/muc/macupgradechaperone_20250320_120354.log
ℹ️  Error log: /usr/local/muc/macupgradechaperone_20250320_120354.error.log
-----------------------------------------------------------
✅ Successfully connected to apple.com on port 443. Port check passed.
-----------------------------------------------------------
🔎  Checking MDM profile...
-----------------------------------------------------------
✅ MDM Profile: Installed.
ℹ️  MDM Server URL: jamf.jamfcloud.com
⚠️  MDM Profile is removable.
✅ APNS certificate is valid. Expiry date: Feb  6 05:22:29 2042 GMT
✅ This Mac was enrolled via Automated Device Enrollment
-----------------------------------------------------------
🔎 Checking MDM Server...
-----------------------------------------------------------
✅ MDM Server is reachable. HTTP response code: 301
ℹ️  URL: blah.jamfcloud.com
❌ Bootstrap Token has NOT been escrowed
-----
✅ No macOS restrictions found in com.apple.applicationaccess.
✅ No deferral policy for macOS updates detected.
✅ The system is using Apple's default software update catalog
-----------------------------------------------------------
🔎 Checking APFS volumes...
-----------------------------------------------------------
✅ 'Macintosh HD' Volume is present.
✅ 'Data' Volume is present.
✅ 'Preboot' Volume is present.
✅ 'Recovery' Volume is present.
✅ 'VM' Volume is present.
✅ All required volumes are present.
✅ There is enough free space on disk to install macOS Sequoia (20 GB required, 89 GB available).
-----------------------------------------------------------
🔎 Checking hardware...
-----------------------------------------------------------
✅ Battery cycle count is acceptable. Battery cycles: 241
✅ Battery condition: Normal
-- Architecture: Apple silicon
-- Serial: QW1CY3V9XY
-- Model: MacBook Pro
-- Model Identifier: MacBookPro18,3
-- Processor Info: Apple M1 Pro
✅ This device (MacBookPro18,3) is compatible with macOS Sequoia
-----------------------------------------------------------
🔎  Checking existing macOS installation
-----------------------------------------------------------
✅ 15.3.2 can upgrade to macOS Sequoia
ℹ️  Current version: 15.3.2
⚠️  macOS Sequoia installer was not found in /Applications
-----------------------------------------------------------
🔎 Checking existing user accounts...
-----------------------------------------------------------
User: joanna.smith
      Admin
      Secure Token enabled
      Home Directory: /Users/joanna.smith
      UID: 502
-----------------------------------------------------------
🧮 Calculating the best upgrade path...
🌲 Reticulating splines...
-----------------------------------------------------------
==================== Conclusion =====================
 
Bad news...

⚠️  MDM Profile is removable.

You will need to erase and re-install macOS, using either Internet Recovery or Apple Configurator 2. (aka time to nuke and pave).
 
-----------------------------------------------------------
Best of luck on your upgrade journey! Bon voyage! 👋
-----------------------------------------------------------

```

