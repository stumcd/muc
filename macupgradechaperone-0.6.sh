#!/bin/bash

# -----------------------------------------------------
# Script Name: MacUpgradeChaperone.sh
# Description: This script will guide you to the best upgrade method for the host Mac
# Author: Stu McDonald
# Created: 14-09-24
# -----------------------------------------------------
# Version: 0.6
# Modified: 02-01-25
# -----------------------------------------------------


####################################
#               Config             #
####################################


## Check if script has been run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Sorry, this script must be run as root. Sudo bang bang!" >&2
    exit 1
fi

## Define the directory for the log file and error log
log_dir="/usr/local/muc"

## Create the directory if it doesn't exist
if [ ! -d "$log_dir" ]; then
  echo "The directory '$log_dir' does not exist. Creating it now..."
  sudo mkdir -p "$log_dir"
  sudo chown $(whoami) "$log_dir"  # Ensure the current user has ownership
fi

# Get the current timestamp (format: YYYYMMDD_HHMMSS)
timestamp=$(date +"%Y%m%d_%H%M%S")
#echo "$timestamp" | tee -a "$log_file"

## Write to a new log file for each run, appended with timestamp
log_file="$log_dir/macupgradechaperone_${timestamp}.log"

## Write to a new error log file for each run, appended with timestamp
error_log="$log_dir/macupgradechaperone.error_${timestamp}.log"




####################################
##         Step 1 - Checks        ##
####################################

echo "========= 🖥️ 🤵 Mac Upgrade Chaperone 🤵 🖥️ =========" | tee -a "$log_file"

## Use the target version specified by script parameters, will use default if not specified

#targetOS=$5
targetOS="macOS Sonoma"

echo "-- Target version: $targetOS" | tee -a "$log_file"

if [[ -n $targetOS ]]; then
    echo " --- No Jamf Pro script parameters were detected, so falling back to defaults." | tee -a "$log_file"
    targetOS="macOS Sonoma"
    echo "-- Target version set to: $targetOS" | tee -a "$log_file"
else
    echo "Target version set by Jamf Pro script parameters: $targetOS" | tee -a "$log_file"
fi

## Check if the Mac is connected to a network (Wi-Fi or Ethernet)
wifi_nic=$(networksetup -getnetworkserviceenabled "Wi-Fi" 2>/dev/null || echo "Disabled")
ethernet_nic=$(networksetup -getnetworkserviceenabled "Ethernet" 2>/dev/null || echo "Disabled")

wifi_connected=$(ifconfig en0 | grep "status: active" >/dev/null 2>&1 && echo "Yes" || echo "No")
ethernet_connected=$(ifconfig en1 | grep "status: active" >/dev/null 2>&1 && echo "Yes" || echo "No")

if [ "$wifi_connected" != "Yes" ] && [ "$ethernet_connected" != "Yes" ]; then
    echo "--- ❌ No active network connection found (Wi-Fi or Ethernet)." | tee -a "$log_file" | tee -a "$error_log"
    echo "-- Wi-Fi network status: $network_status" | tee -a "$log_file" | tee -a "$error_log"
    echo "-- Ethernet network status: $ethernet_status" | tee -a "$log_file" | tee -a "$error_log"
    echo "-- Wi-Fi connected: $wifi_connected" | tee -a "$log_file" | tee -a "$error_log"
    echo "-- Ethernet connected: $ethernet_connected" | tee -a "$log_file" | tee -a "$error_log"
    
while true; do
    response=$(osascript -e 'display dialog "Unfortunately, there is no network connection and many of our checks require connectivity. Please connect this Mac to a network (using Wi-Fi or Ethernet) and run this script again." buttons {"Quit", "Retry"} default button "Retry" with icon stop')

    if [[ "$response" == "button returned:Quit" ]]; then
        echo "Network connnection not detected." | tee -a "$log_file" 
        echo "User chose to quit." | tee -a "$log_file" 
        exit 1
    elif [[ "$response" == "button returned:Retry" ]]; then
        echo "Network connnection not detected." | tee -a "$log_file"         
        echo "User chose to retry. Restarting the script... " | tee -a "$log_file" 
    fi
done
    
else
    echo "--- ✅ Network connection available." | tee -a "$log_file"
    echo "-- Wi-Fi network status: $network_status" | tee -a "$log_file"
    echo "-- Ethernet network status: $ethernet_status" | tee -a "$log_file"
    echo "-- Wi-Fi connected: $wifi_connected" | tee -a "$log_file"
    echo "-- Ethernet connected: $ethernet_connected" | tee -a "$log_file"
fi

# Last network check - can we Netcat apple.com:443
nc -z -w 5 apple.com 443 >/dev/null 2>&1
nc_apple=$?

if [ "$nc_apple" -ne 0 ]; then
    echo "--- ❌ Unable to connect to apple.com on port 443. Port check failed." | tee -a "$log_file" | tee -a "$error_log"
    osascript -e 'display dialog "Unable to connect to apple.com on port 443, even though the Mac *is* connected to a network. There might be a misconfigured firewall rule blocking this, or maybe the Mac is not properly authenticated on the network." buttons {"Quit"} default button "Quit" with icon stop'
    exit 1
else
    echo "--- ✅ Successfully connected to apple.com on port 443. Port check passed." | tee -a "$log_file"
fi


echo "-------------------------" | tee -a "$log_file"
echo "----- Guiding your journey to... ✨ $targetOS ✨" | tee -a "$log_file"
echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$log_file" 
echo "-------------------------" | tee -a "$log_file"

### Check if Mac is managed 

# Check if there's an MDM profile installed 
echo "⚙️  Checking MDM enrollment..." | tee -a "$log_file"

mdm_profile=$(profiles status -type enrollment)

if [[ "$mdm_profile" == *"MDM enrollment: Yes"* ]]; then
  echo "--- ✅ MDM Profile: Installed." | tee -a "$log_file"
  mdmUrl=$(system_profiler SPConfigurationProfileDataType | awk -F'[/:?]' '/CheckInURL/ {print $4}')
  echo "------ MDM Server: $mdmUrl" | tee -a "$log_file"
fi
 
if [[ "$mdm_profile" == *"MDM enrollment: No"* ]]; then
  echo "--- ❌ MDM Profile not present. This Mac is NOT managed." | tee -a "$log_file" | tee -a "$error_log"
fi

# Check the MDM profile installation date
mdm_profile_install_date=$(profiles show -output stdout-xml | plutil -extract ProfileDetails xml1 -o - - | grep -A 1 "InstallationDate" | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}Z')

if [[ -z "$mdm_profile_install_date" ]]; then
    echo "--- ❌ Profiles binary couldn't find an MDM Profile... That's... odd." | tee -a "$log_file" | tee -a "$error_log"
else

    # Compare installation date with the current date
    current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    mdm_profile_ts=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$mdm_profile_install_date" +%s)
    current_ts=$(date -u +%s)

    # Calculate timestamp for 5 years (5 * 365 * 24 * 60 * 60)
    five_years_ago_ts=$((current_ts - 157680000))

    if [[ "$mdm_profile_ts" -lt "$five_years_ago_ts" ]]; then
        echo "--- ❌ The MDM Profile installation date ($mdm_profile_install_date) is over 5 years earlier than the current date ($current_date)." | tee -a "$log_file" | tee -a "$error_log"
    else
        echo "--- ✅ The MDM Profile has a valid install date within 5 years." | tee -a "$log_file"
        echo "--- MDM Profile installation date: $mdm_profile_install_date" | tee -a "$log_file"
    fi
fi
# Check if MDM profile is removable
mdm_profile_removeable=$(profiles -e | grep "IsMDMUnremovable" | awk '{print $3}' | tr -d ';')

if [[ ${mdm_profile_removeable} = '1' ]]; then
	echo "--- ✅ MDM Profile is NOT removable." | tee -a "$log_file"
	
else
  if [[ ${mdm_profile_removeable} = '0' ]]; then
    echo "--- ❌  MDM Profile is removable." | tee -a "$log_file" | tee -a "$error_log"
  fi
fi

# Check if the push certificate has expired
apns_expiry_date=$(security find-certificate -a -p /Library/Keychains/System.keychain | \
openssl x509 -noout -enddate | \
grep "notAfter" | head -n 1 | cut -d= -f2)

if [[ -z "$apns_expiry_date" ]]; then
    echo "❌ No APNs push certificate found in the system keychain." | tee -a "$log_file" | tee -a "$error_log"
    exit 1
fi

# Convert dates to Unix timestamps for comparison
apns_expiry_ts=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$apns_expiry_date" +"%s")
current_ts=$(date -u +"%s")

if [[ "$apns_expiry_ts" -lt "$current_ts" ]]; then
    echo "❌ Push certificate has expired. Expiry date: $apns_expiry_date" | tee -a "$log_file" | tee -a "$error_log"
else
    echo "✅ Push certificate is valid. Expiry date: $apns_expiry_date" | tee -a "$log_file"
fi

# Check if enrolled via Automated Device Enrolment
ade_enrolled=$(profiles status -type enrollment)
user_approved_enrol=$(profiles status -type enrollment)

if echo "$ade_enrolled" | grep -q "Enrolled via DEP: Yes"; then
    echo "--- ✅ This Mac was enrolled using Automated Device Enrollment." | tee -a "$log_file"
else
    echo "--- ❌ This Mac was not enrolled via Automated Device Enrollment." | tee -a "$log_file" | tee -a "$error_log"
fi

if echo "$user_approved_enrol" | grep -q "Yes (User Approved)"; then
    echo "--- ⚠️ This Mac *is* enrolled in MDM (User Approved), not via Automated Device Enrollment.." | tee -a "$log_file"
else
    echo "--- ❌ Not MDM enrolled, not User Approved" | tee -a "$log_file"
fi


# Check if we can reach MDM server
echo "--- Checking connection to MDM Server..." | tee -a "$log_file" 

mdmServerStatus=$(curl -s -o /dev/null -w "%{http_code}" "$mdmUrl/enrol")

if [ "$mdmServerStatus" -eq 200 ]; then
    echo "--- ✅ MDM Server is reachable. URL: $mdmUrl. HTTP status code: $mdmServerStatus"
else
    echo "--- ❌ Failed to connect to "$mdmUrl". HTTP status code: $mdmServerStatus" | tee -a "$log_file" | tee -a "$error_log"
fi

# Check if Bootstrap Token has been escrowed
if profiles status -type bootstraptoken | grep -q "Bootstrap Token escrowed to server: YES"; then
    echo "--- ✅ Bootstrap Token: Escrowed" | tee -a "$log_file"
else
    echo "--- ❌ Bootstrap Token NOT Escrowed" | tee -a "$log_file" | tee -a "$error_log"
fi

# Check if there are any MDM restrictions in place that would prevent upgrading 
echo "Checking for any macOS upgrade restrictions..." | tee -a "$log_file"

# Check macOS upgrade restrictions in com.apple.applicationaccess
if sudo defaults read /Library/Managed\ Preferences/com.apple.applicationaccess &>/dev/null; then
    restrict=$(sudo defaults read /Library/Managed\ Preferences/com.apple.applicationaccess restrict-software-update 2>/dev/null)
    max_os=$(sudo defaults read /Library/Managed\ Preferences/com.apple.applicationaccess max-os-version 2>/dev/null)
    
    if [ "$restrict" == "1" ]; then
        echo "--- ❌ Software updates are restricted by MDM." | tee -a "$log_file" | tee -a "$error_log"
    elif [ -n "$max_os" ]; then
        echo "------ Maximum allowed macOS version: $max_os" | tee -a "$log_file" | tee -a "$error_log"
    else
        echo "--- ✅ No macOS restrictions found in com.apple.applicationaccess." | tee -a "$log_file"
    fi
else
    echo "No com.apple.applicationaccess MDM profile found." | tee -a "$log_file"
fi

# Check for deferred updates
deferred_days=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate SoftwareUpdateMajorOSDeferredInstallDelay 2>/dev/null)

if [ -n "$deferred_days" ] && [ "$deferred_days" -gt 0 ]; then
    echo "--- ❌ Major macOS updates are deferred by $deferred_days days." | tee -a "$log_file" | tee -a "$error_log" 
else
    echo "--- ✅ No deferral policy for macOS updates detected." | tee -a "$log_file"
fi

# Check MDM software update commands
#mdm_logs=$(log show --predicate 'eventMessage contains "MDM"' --info | grep "SoftwareUpdate" 2>/dev/null)

#if [ -n "$mdm_logs" ]; then
#    echo "--- ❌ MDM commands related to SoftwareUpdate detected:" | tee -a "$log_file" | tee -a #"$error_log"
#    echo "------ $mdm_logs" | tee -a "$log_file" | tee -a "$error_log"
#else
#    echo "--- ✅ No MDM SoftwareUpdate commands detected in the logs." | tee -a "$log_file"
#fi

# Check for custom Software Update Catalog URL
catalog_url=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL 2>/dev/null)

if [ -z "$catalog_url" ]; then
    echo "--- ✅ The system is using Apple's default software update catalog." | tee -a "$log_file"
else
    echo "--- ❌ Custom software update catalog URL detected: $catalog_url" | tee -a "$log_file" | tee -a "$error_log"
fi


######## Checking disk volumes
echo "-------------------------" | tee -a "$log_file"
echo "🧐 Checking the volumes on disk..." | tee -a "$log_file"

# List of volumes to check
volumes=("Macintosh HD" "Macintosh HD - Data" "Preboot" "Recovery" "VM")

# Flag to track volumes
all_volumes_present=true

# Loop through and check for each volume
for volume in "${VOLUMES[@]}"; do
  if diskutil list | grep -q "$volume"; then
    echo "✅ '$volume' Volume is present."
  else
    echo "❌ '$volume' Volume is missing."
    all_volumes_present=false
  fi
done

# Final check for all volumes
if [ "$all_volumes_present" = true ]; then
  echo "✅ All required volumes are present."
else
  echo "❌ Some required volumes are missing."
fi

######## Check available space
echo "-------------------------" | tee -a "$log_file"
echo "📏 Checking available space..." | tee -a "$log_file"

available_space=$(df / | tail -1 | awk '{print $4}')

# Convert available space to GB
available_space_gb=$((available_space / 1048576))

if [ "$available_space_gb" -ge 20 ]; then
echo "--- ✅ There is enough free space (20 GB required, $available_space_gb GB available)." | tee -a "$log_file"
else

echo "--- ❌ There is not enough free space ($available_space_gb GB available, 20 GB required)." | tee -a "$log_file" | tee -a "$error_log"
fi

######## Checking Mac hardware
hardware_serial=$(system_profiler SPHardwareDataType | awk -F ": " '/Serial Number/ {print $2}')
hardware_name=$(system_profiler SPHardwareDataType | awk -F ": " '/Model Name/ {print $2}')
hardware_modelidentifier=$(system_profiler SPHardwareDataType | awk '/Model Identifier/ {print $3}')
hardware_chip=$(system_profiler SPHardwareDataType | awk -F ": " '/Processor Name/ {print $2}')
processor_name=$(system_profiler SPHardwareDataType | awk -F ": " '/Chip/ {print $2}')

# Display system info
echo "-------------------------" | tee -a "$log_file"
echo "🖥  Mac hardware:" | tee -a "$log_file"
echo "- Serial: $hardware_serial" | tee -a "$log_file"
echo "- Model: $hardware_name" | tee -a "$log_file"
echo "- Model Identifier: $hardware_modelidentifier" | tee -a "$log_file"
echo "- Chip: $hardware_chip" | tee -a "$log_file"
echo "- Processor Name: $processor_name" | tee -a "$log_file"

#### Check compatibility
echo "-------------------------" | tee -a "$log_file"

compatible_models=(
  "MacBookAir8,1"  # MacBook Air (Retina, 13-inch, 2018)
  "MacBookAir9,1"  # MacBook Air (Retina, 13-inch, 2019)
  "MacBookAir10,1" # MacBook Air (M1, 2020)
  "MacBookAir14,2" # MacBook Air (13-inch, M2, 2022)
  "MacBookAir14,15" # MacBook Air (15-inch, M2, 2023)

  "MacBookPro15,1" # MacBook Pro (15-inch, 2018)
  "MacBookPro15,2" # MacBook Pro (13-inch, 2018)
  "MacBookPro15,3" # MacBook Pro (15-inch, 2019)
  "MacBookPro15,4" # MacBook Pro (13-inch, 2019)
  "MacBookPro16,1" # MacBook Pro (16-inch, 2019)
  "MacBookPro16,2" # MacBook Pro (13-inch, 2020)
  "MacBookPro16,4" # MacBook Pro (16-inch, 2020)
  "MacBookPro17,1" # MacBook Pro (13-inch, M1, 2020)
  "MacBookPro18,1" # MacBook Pro (16-inch, M1 Pro/Max, 2021)
  "MacBookPro18,3" # MacBook Pro (14-inch, M1 Pro/Max, 2021)
  "MacBookPro15,13" # MacBook Pro (14-inch, M3, Nov 2023)
  "MacBookPro15,14" # MacBook Pro (16-inch, M3, Nov 2023)
  "MacBookPro16,7" # MacBook Pro (16-inch, M2, 2023)
  "MacBookPro15,6" # MacBook Pro (14-inch, M2 Pro, 2023)
  "MacBookPro15,7" # MacBook Pro (16-inch, M2 Pro, 2023)
  "MacBookPro15,8" # MacBook Pro (14-inch, M2 Max, 2023)
  "MacBookPro15,10" # MacBook Pro (16-inch, M2 Max, 2023)
  "MacBookPro15,11" # MacBook Pro (14-inch, M3, 2024)
  "MacBookPro15,9"  # MacBook Pro (16-inch, M3, 2024)
  "MacBookPro16,1" # MacBook Pro (13-inch, M2, 2024)
  "MacBookPro16,5" # MacBook Pro (14-inch, M2, 2024)
  "MacBookPro16,6" # MacBook Pro (16-inch, M2, 2024)
  "MacBookPro16,8" # MacBook Pro (M3, 2024)

  "Macmini8,1"     # Mac mini (2018)
  "Macmini9,1"     # Mac mini (M1, 2020)
  "Macmini10,1"    # Mac mini (M2, 2023)

  "iMac19,1"       # iMac (Retina 5K, 27-inch, 2019)
  "iMac19,2"       # iMac (Retina 4K, 21.5-inch, 2019)
  "iMac20,1"       # iMac (Retina 5K, 27-inch, 2020)
  "iMac21,1"       # iMac (24-inch, M1, 2021)

  "iMacPro1,1"     # iMac Pro (2017)

  "MacPro7,1"      # Mac Pro (2019)
  "MacPro8,1"      # Mac Pro (M2 Ultra, 2023)

  "Mac14,3"        # Mac Studio (M1 Max, 2022)
  "Mac14,12"       # Mac Studio (M1 Ultra, 2022)
  "Mac14,13"       # Mac Studio (M2 Max, 2023)
  "Mac14,14"       # Mac Studio (M2 Ultra, 2023)

)


# Check if the hardware model is in the list of compatible models
echo "-------------------------" | tee -a "$log_file"

if [[ " ${compatible_models[@]} " =~ " $hardware_modelidentifier " ]]; then
    echo "--- ✅ Compatible with $targetOS" | tee -a "$log_file"
else
    echo "--- ❌ This Mac is not compatible with $targetOS." | tee -a "$log_file" | tee -a "$error_log"
fi

if [ "$(uname -m)" = "arm64" ]; then
  echo "--- ✅ Architecture: Apple silicon" | tee -a "$log_file"
else
  echo "--- ⚠️ A️rchitecture: Intel️" | tee -a "$log_file" | tee -a "$error_log"
fi

# Check what version of macOS is currently installed
echo "-------------------------" | tee -a "$log_file"
echo "🖥  Checking existing macOS installation" | tee -a "$log_file"

macos_version=$(sw_vers -productVersion)
major_version=$(echo "$macos_version" | cut -d '.' -f 1)

echo "--- Installed macOS version: $macos_version." | tee -a "$log_file"

if [ "$major_version" -ge 11 ]; then
  echo "--- ✅ $macos_version can upgrade to $targetOS" | tee -a "$log_file"
else
  echo "--- ❌ macOS Big Sur and earlier versions cannot upgrade straight to $targetOS. (Installed version: $macos_version" | tee -a "$log_file" | tee -a "$error_log"
fi

#### Check if macOS installer is already on disk 
## Future plans:
## - If macOS re-install needed, download installer from Apple using mist-cli 
## - If not already installed, install mist-cli from GitHub


# macOS installer path
INSTALLER_PATH="/Applications/Install $targetOS.app"

# startosinstall path
BINARY_PATH="$INSTALLER_PATH/Contents/Resources/startosinstall"

# Check if the installer exists
if [ -d "$INSTALLER_PATH" ]; then
  echo "✅ $targetOS installer found at '$INSTALLER_PATH'." | tee -a "$log_file"

  # Check if the startosinstall binary exists
  if [ -f "$BINARY_PATH" ]; then
    echo "✅ The 'startosinstall' binary is available." | tee -a "$log_file"
  else
    echo "❌ The 'startosinstall' binary is missing." | tee -a "$log_file" | tee -a "$error_log"
  fi
else
  echo "❌ $targetOS installer is not found at '$INSTALLER_PATH'." | tee -a "$log_file" | tee -a "$error_log"
fi


echo "-------------------------" | tee -a "$log_file"
echo "Evaluation complete." | tee -a "$log_file"
echo "-------------------------" | tee -a "$log_file"
echo "🧮 Calculating the best upgrade path..." | tee -a "$log_file"
echo "🌲 Reticulating splines..." | tee -a "$log_file"
echo "-------------------------" | tee -a "$log_file"


####################################
#      Step 2 - Calculation        #
####################################

#### Check the error log and based on what we found, recommend an upgrade method with an AppleScript dialog
# There are 5 groups of errors:

# Group A = Not compatible. End of the road. 
GROUP_A_ERRORS=$(grep -E "Not compatible|not supported|cannot upgrade" "$error_log")
######### DEBUG NOTE: - below line INCLUDES Oscar, above is TECHNICALLY CORRECT
# GROUP_A_ERRORS=$(grep -E "Not compatible|not supported|cannot upgrade" "$error_log") 

# Group B = Nuke & pave needed
GROUP_B_ERRORS=$(grep -E "volumes are missing|cannot upgrade straight to $targetOS|MDM Profile is removable|not enrolled via DEP" "$error_log")

# Group C = Upgrade possible, but can't be achived with MDM commands- must be done manually 
GROUP_C_ERRORS=$(grep -E "Mac is NOT managed|Bootstrap Token NOT Escrowed|expired" "$error_log")

# Group D = Compatible but can't upgrade _at the moment_
GROUP_D_ERRORS=$(grep -E "not enough free space on disk|Software updates are restricted|Custom software update catalog URL|macOS updates are deferred" "$error_log")

# Group E = Notable, but won't prevent upgrading
GROUP_E_ERRORS=$(grep -E "Intel" "$error_log")

# Set the message and buttons based on error group
if [ -n "$GROUP_A_ERRORS" ]; then
    MESSAGE="Bad news:\n\n$GROUP_A_ERRORS\n\nThis Mac is not compatible with the target version of macOS ($targetOS)."
    osascript -e "display dialog \"$MESSAGE\" buttons {\"Compatibility Info…\", \"Quit\"} default button \"Quit\" with icon caution" \
        -e "if button returned of result = \"Compatibility Info…\" then open location \"https://support.apple.com/en-au/105113\""

elif [ -n "$GROUP_B_ERRORS" ]; then
    MESSAGE="Bad news:\n\n$GROUP_B_ERRORS\n\nYou will need to erase and re-install macOS, using either Internet Recovery or Apple Configurator 2. (aka time to nuke and pave)."
    osascript -e "display dialog \"$MESSAGE\" buttons {\"How to…\", \"Quit\"} default button \"Quit\" with icon caution" \
        -e "if button returned of result = \"How to…\" then open location \"https://support.apple.com/en-au/guide/mac-help/mchl7676b710/15.0/mac/15.0\""

elif [ -n "$GROUP_C_ERRORS" ]; then
    MESSAGE="Not-so-great news:\n\n$GROUP_C_ERRORS\n\nThis Mac can be upgraded to $targetOS, but you won't be able to use MDM commands to achieve this. Recommendation: upgrade macOS via System Preferences."
    osascript -e "display dialog \"$MESSAGE\" buttons {\"Open System Settings…\", \"Quit\"} default button \"Quit\" with icon note" \
        -e "if button returned of result = \"Open System Settings…\" then do shell script \"open -a 'System Settings'\""

elif [ -n "$GROUP_D_ERRORS" ]; then
    MESSAGE="Uh oh:\n\n$GROUP_D_ERRORS\n\nHave a look at the above issues. Rectify these and try again. Or, just nuke and pave."
    osascript -e "display dialog \"$MESSAGE\" buttons {\"Show error log\", \"Quit\"} default button \"Quit\" with icon stop" \
        -e "if button returned of result = \"Show error log\" then do shell script \"open /path/to/error/log\""

else
    MESSAGE="Great news! All checks passed successfully. 🎉 You can upgrade this Mac via MDM. Log into your MDM server ($mdmUrl) and go from there."
    osascript -e "display dialog \"$MESSAGE\" buttons {\"OK\"} default button \"OK\" with icon note"
fi

echo "======= MacUpgradeChaperone Guidance: $MESSAGE ======" | tee -a "$log_file"

# Display AppleScript dialog

if [ "$BUTTON" != "OK" ]; then
    osascript <<EOF
tell application "System Events"
    set userResponse to display dialog "$MESSAGE" buttons {"$BUTTON"} default button "$BUTTON"
    if button returned of userResponse is "$BUTTON" then
        do shell script "open \"$URL\""
    end if
end tell
EOF

else
    osascript <<EOF
tell application "System Events"
    display dialog "$MESSAGE" buttons {"$BUTTON"} default button "$BUTTON"
end tell
EOF
fi

####################################
#       Wrap Up & Farewell         #
####################################

echo "Best of luck on your upgrade journey! Bon voyage! 👋" | tee -a "$log_file"
echo "MacUpgradeChaperone finished at: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$log_file"
echo "=========================================" | tee -a "$log_file"
exit 0