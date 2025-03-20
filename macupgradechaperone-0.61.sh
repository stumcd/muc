#!/bin/bash

# -----------------------------------------------------
# Script Name: MacUpgradeChaperone.sh
# Description: This script will guide you to the best upgrade method for the host Mac
# Author: Stu McDonald
# Created: 14-09-24
# -----------------------------------------------------
# Version: 0.61
# Modified: 18-03-25

## Future plans:
## - If macOS re-install needed, download installer from Apple using mist-cli 
## - If not already installed, install mist-cli from GitHub
## - Report on MDM profile installation date
## - One day: add some wild 90s ASCII art here, like you'd see on a .NFO

## Notes: 
## Currently the checks for software update restrictions *are not valid*. 
## With a 90 day deferral in place, these commands do not respond as expected. 


#  -----------------------------------------------------
#                Explainer                     
#  -----------------------------------------------------

# There are 5 potential outcomes when trying to upgrade a Mac:
#
# Group A = Not compatible. End of the road. 
# Group B = Nuke & pave required
# Group C = Upgrade possible but can't be achived via MDM. Can be achieved manually, however
# Group D = Compatible, but can't upgrade until minor issue addressed (eg not enough disk space)
# Group E = Upgrade is possible, but there's something to be aware of


############################################
#                  Variables               #
############################################

### Description: Directory to create and write log files to 
### Jamf Pro parameter number: $4
### Jamf Pro parameter name: Log directory (e.g. '/usr/local/muc')
log_dir="/usr/local/muc"

targetOS=""
### Description: macOS version you want to upgrade to
### Jamf Pro parameter number: $4
### Jamf Pro parameter name: Target macOS Version (e.g. 'macOS Palm Springs')

silent_mode=""
### Description: To skip the on-screen notifications, enable silent mode
### Jamf Pro parameter number: $6
### Jamf Pro parameter name: Silent Mode (to enable, set to 'on')

offline_mode=""
### Description: To skip the connectivity checks, enable offline mode
### Jamf Pro parameter number: $7
### Jamf Pro parameter name: Offline mode (to enable, set to 'on')

############################################

# Parse CLI flags (still a WIP)
#while [[ "$#" -gt 0 ]]; do
#    case $1 in
#        --targetOS) targetOS="$2"; shift 2 ;;
#        --log_dir) log_dir="$2"; shift 2 ;;
#        --silent_mode) silent_mode="$2"; shift 2 ;;
#        *) echo "Unknown option: $1"; exit 1 ;;
#    esac
#done

# Assign values to positional variables
#set -- "$targetOS" "$log_dir" "$silent_mode" "$@"

# Ensure $4, $5, and $6 are assigned
#targetOS=$4
#log_dir=$5
#silent_mode=$6


############################################
#        Jamf Pro Script Parameters        #
############################################

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 5 AND, IF SO, ASSIGN TO "log_dir"
if [[ -n "$4" ]] && [[ -z "$log_dir" ]]; then
    log_dir="$4"
fi

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 6 AND, IF SO, SET TO "targetOS"
if [[ -n "$4" ]] && [[ -z "$targetOS" ]]; then
    targetOS="$5"
fi

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 6 AND, IF SO, SET TO "silent_mode"
if [[ -n "$6" ]] && [[ -z "$silent_mode" ]]; then
    silent_mode="$6"
fi

###################################################################


############################################
#                 Setup                    #
############################################

#### Make sure script has been run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Sorry, this script must be run as root. Exiting..." >&2
    exit 1
fi

#### Get the current timestamp (format: YYYYMMDD_HHMMSS)
timestamp=$(date +"%Y%m%d_%H%M%S")

# Create the directory if it doesn't exist & ensure the current user has ownership
if [ ! -d "$log_dir" ]; then
  echo "The log directory '$log_dir' does not exist. Creating it now..."
  sudo mkdir -p "$log_dir"
  sudo chown $(whoami) "$log_dir"  
fi

if [[ ! -w "$log_dir" ]]; then
    echo "Error: Log directory '$log_dir' is not writable."
    exit 1
fi

#### Write to a new log file for each run, appended with timestamp
log_file="$log_dir/macupgradechaperone_${timestamp}.log"

#### Write to a new error log file for each run, appended with timestamp
error_log="$log_dir/macupgradechaperone_${timestamp}.error.log"

echo "==========================================================" | tee -a "$log_file"
echo "======== 🖥️ 🤵 Mac Upgrade Chaperone v0.61 🤵🖥️  ===========" | tee -a "$log_file"

#echo "Start: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$log_file"


#### Target OS: if not set, default to latest major version
if [[ -z $targetOS ]]; then
    targetOS="macOS Sequoia"
#    echo "--- 🎯 Target OS not set, using default: $targetOS ---" | tee -a "$log_file"
fi

echo "--------------- Guiding your journey to... ----------------" | tee -a "$log_file"
echo "------------------ ✨ $targetOS ✨ --------------------" | tee -a "$log_file"

echo "===========================================================" | tee -a "$log_file"
echo "ℹ️️  General log: $log_file" | tee -a "$log_file"
echo "ℹ️  Error log: $error_log" | tee -a "$log_file"
echo "-----------------------------------------------------------" | tee -a "$log_file"

if [ "$silent_mode" = "on" ]; then
	echo "⚠️  Silent mode: enabled 🤐"
fi

if [ "$offline_mode" = "on" ]; then
	echo "⚠️ Offline mode: enabled"
fi

#### Pre-req: network connectivity
## Check if the Mac is connected to a network (Wi-Fi or Ethernet)

network_status() {
    while true; do
        # Check if any network interface is active
        active_interface=$(ifconfig -l | tr ' ' '\n' | grep -E 'en[0-9]' | while read -r iface; do
            if ifconfig "$iface" 2>/dev/null | grep -q "status: active"; then
                echo "$iface"
                break
            fi
        done)

        # Check if a default gateway exists (indicating an internet connection)
        gateway_check=$(route -n get default 2>/dev/null | grep -q "gateway" && echo "Connected" || echo "Not connected")

        # Determine network status
        if [[ -n "$active_interface" && "$gateway_check" == "Connected" ]]; then
            echo "✅ Network connection detected. 🎉" | tee -a "$log_file"
            return 0  # Network is connected
        else
            echo "❌ No active network connection found." | tee -a "$log_file" | tee -a "$error_log"
            response=$(osascript -e 'display dialog "No network connection detected. Please connect to a network and try again." buttons {"Quit", "Retry"} default button "Retry" with icon stop')

            if [[ "$response" == "button returned:Quit" ]]; then
                echo "User chose to quit." | tee -a "$log_file"
                exit 1
            elif [[ "$response" == "button returned:Retry" ]]; then
                echo "User chose to retry." | tee -a "$log_file"
                continue  # Retry checking network
            fi
        fi
    done
}

if [ "$offline_mode" == "enabled" ]; then
    echo "⚠️  Offline mode: skipping connectivity checks" | tee -a "$log_file"
else
    nc -z -w 5 apple.com 443 >/dev/null 2>&1
    nc_apple=$?

    if [ "$nc_apple" -ne 0 ]; then
        echo "❌ Unable to connect to apple.com on port 443. Port check failed." | tee -a "$log_file" | tee -a "$error_log"
        osascript -e 'display dialog "Unable to connect to apple.com on port 443, even though the Mac *is* connected to a network. There might be a misconfigured firewall rule blocking this, or maybe the Mac is not properly authenticated on the network." buttons {"Quit"} default button "Quit" with icon stop'
        exit 1
    else
        echo "✅ Successfully connected to apple.com on port 443. Port check passed." | tee -a "$log_file"
    fi
fi

############################################
#             Step 1: Checks               #
############################################


#### Check: MDM Profile and enrollment info
echo "-----------------------------------------------------------" | tee -a "$log_file"
echo "🔎  Checking MDM profile..." | tee -a "$log_file"
echo "-----------------------------------------------------------" | tee -a "$log_file"

mdm_profile=$(profiles status -type enrollment)

if [[ "$mdm_profile" == *"MDM enrollment: Yes"* ]]; then
  echo "✅ MDM Profile: Installed." | tee -a "$log_file"
  
  mdmUrl=$(system_profiler SPConfigurationProfileDataType | awk -F'[/:?]' '/CheckInURL/ {print $4}')
  echo "ℹ️  MDM Server URL: $mdmUrl" | tee -a "$log_file"
fi
 
if [[ "$mdm_profile" == *"MDM enrollment: No"* ]]; then
  echo "❌ MDM Profile not present. This Mac is NOT managed." | tee -a "$log_file" | tee -a "$error_log"
fi


#if [[ -z "$mdm_profile_install_date" ]]; then
#    echo "--- ❌ Profiles binary couldn't find an MDM Profile... That's... odd." | tee -a "$log_file" | tee -a "$error_log"
#else

# Compare installation date with the current date
#    current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
#    mdm_profile_ts=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$mdm_profile_install_date" +%s)
#    current_ts=$(date -u +%s)

#    Calculate timestamp for 5 years (5 * 365 * 24 * 60 * 60)
#    five_years_ago_ts=$((current_ts - 157680000))

#    if [[ "$mdm_profile_ts" -lt "$five_years_ago_ts" ]]; then
#        echo "--- ❌ The MDM Profile installation date ($mdm_profile_install_date) is over 5 years earlier than the current date ($current_date)." | tee -a "$log_file" | tee -a "$error_log"
#    else
#        echo "--- ✅ The MDM Profile has a valid install date within 5 years." | tee -a "$log_file"
#        echo "--- MDM Profile installation date: $mdm_profile_install_date" | tee -a "$log_file"
#    fi
#fi

if [[ "$offline_mode" != "disabled" ]]; then

# Check if MDM profile is removable
	mdm_profile_removeable=$(profiles -e | grep "IsMDMUnremovable" | awk '{print $3}' | tr -d ';')
	
	if [[ ${mdm_profile_removeable} = '1' ]]; then
		echo "✅ MDM Profile is NOT removable" | tee -a "$log_file"
		
	else
	  if [[ ${mdm_profile_removeable} = '0' ]]; then
		echo "⚠️  MDM Profile is removable." | tee -a "$log_file" | tee -a "$error_log"
	  fi
	fi
else 
	echo "⚠️  Running in offline mode: unable to check Device Enrollment Configuration" | tee -a "$log_file"
fi
	
# Check: push certificate expiry
apns_expiry_date=$(security find-certificate -a -p /Library/Keychains/System.keychain | \
openssl x509 -noout -enddate | \
grep "notAfter" | head -n 1 | cut -d= -f2)

if [[ -z "$apns_expiry_date" ]]; then
    echo "❌ No APNS certificate found in the system keychain." | tee -a "$log_file" | tee -a "$error_log"
    exit 1
fi

# Convert dates to Unix timestamps for comparison
apns_expiry_ts=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$apns_expiry_date" +"%s")
current_ts=$(date -u +"%s")

if [[ "$apns_expiry_ts" -lt "$current_ts" ]]; then
    echo "❌ Push certificate has expired. Expiry date: $apns_expiry_date" | tee -a "$log_file" | tee -a "$error_log"
else
    echo "✅ APNS certificate is valid. Expiry date: $apns_expiry_date" | tee -a "$log_file"
fi

# Check if enrolled via Automated Device Enrolment
ade_enrolled=$(profiles status -type enrollment)

if echo "$ade_enrolled" | grep -q "Enrolled via DEP: Yes"; then
    echo "✅ This Mac was enrolled via Automated Device Enrollment" | tee -a "$log_file"
else
    echo "⚠️  This Mac was not enrolled via Automated Device Enrollment" | tee -a "$log_file" | tee -a "$error_log"
fi

# Check: MDM server
echo "-----------------------------------------------------------" | tee -a "$log_file"
echo "🔎 Checking MDM Server..." | tee -a "$log_file" 
echo "-----------------------------------------------------------" | tee -a "$log_file"

mdmServerStatus=$(curl -s -o /dev/null -w "%{http_code}" "$mdmUrl/healthCheck.html")

if [ "$mdmServerStatus" -eq 200 ] || [ "$mdmServerStatus" -eq 301 ]; then
    echo "✅ MDM Server is reachable. HTTP response code: $mdmServerStatus" | tee -a "$log_file"
    echo "ℹ️  URL: $mdmUrl" | tee -a "$log_file"

else
    echo "❌ Failed to reach $mdmUrl." | tee -a "$log_file" | tee -a "$error_log"
    echo "-- URL: $mdmUrl" | tee -a "$log_file"
    echo "-- HTTP response: $mdmServerStatus" | tee -a "$log_file"    
fi

# Check if Bootstrap Token has been escrowed
if profiles status -type bootstraptoken | grep -q "Bootstrap Token escrowed to server: YES"; then
    echo "✅ Bootstrap Token has been escrowed" | tee -a "$log_file"
else
    echo "❌ Bootstrap Token has NOT been escrowed" | tee -a "$log_file" | tee -a "$error_log"
fi

echo "-----" | tee -a "$log_file"

#### Check: upgrade restrictions

#echo "Checking for any managed configuration preventing macOS upgrades..." | tee -a "$log_file"

# Check: com.apple.applicationaccess exists
if [ -f "/Library/Managed Preferences/com.apple.applicationaccess.plist" ]; then
    restrict=$(/usr/bin/defaults read /Library/Managed\ Preferences/com.apple.applicationaccess restrict-software-update 2>/dev/null || echo "Not found")
    max_os=$(/usr/bin/defaults read /Library/Managed\ Preferences/com.apple.applicationaccess max-os-version 2>/dev/null || echo "Not found")
    
    if [ "$restrict" = "1" ]; then
        echo "❌ Software updates are restricted by MDM (restrict-software-update = 1)." | tee -a "$log_file" | tee -a "$error_log"
    elif [ "$max_os" != "Not found" ]; then
        echo "❌ Maximum allowed macOS version: $max_os" | tee -a "$log_file" | tee -a "$error_log"
    else
        echo "✅ No macOS restrictions found in com.apple.applicationaccess." | tee -a "$log_file"
    fi
else
    echo "No MDM restrictions found in com.apple.applicationaccess." | tee -a "$log_file"
fi

#### Check: deferred updates in com.apple.SoftwareUpdate
if [ -f "/Library/Preferences/com.apple.SoftwareUpdate.plist" ]; then
    deferred_days=$(/usr/bin/defaults read /Library/Preferences/com.apple.SoftwareUpdate SoftwareUpdateMajorOSDeferredInstallDelay 2>/dev/null || echo "Not found")

    if [ "$deferred_days" != "Not found" ] && [ "$deferred_days" -gt 0 ]; then
        echo "❌ Major macOS updates are deferred by $deferred_days days (via MDM)." | tee -a "$log_file" | tee -a "$error_log"
    else
        echo "✅ No deferral policy for macOS updates detected." | tee -a "$log_file"
    fi
else
    echo "No deferral policy found in com.apple.SoftwareUpdate." | tee -a "$log_file"
fi


#### Check: Software Update Catalog URL
catalog_url=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL 2>/dev/null)

if [ -z "$catalog_url" ]; then
    echo "✅ The system is using Apple's default software update catalog" | tee -a "$log_file"
else
    echo "❌ Custom software update catalog URL detected: $catalog_url" | tee -a "$log_file" | tee -a "$error_log"
fi

#### Check: Disk volume naming
echo "-----------------------------------------------------------" | tee -a "$log_file"
echo "🔎 Checking APFS volumes..." | tee -a "$log_file"
echo "-----------------------------------------------------------" | tee -a "$log_file"

# List of volumes to check
volumes=("Macintosh HD" "Data" "Preboot" "Recovery" "VM")

# Flag to track volumes
all_volumes_present=true

# Loop through and check for each volume
for volume in "${volumes[@]}"; do
  if diskutil list | grep -q "$volume"; then
    echo "✅ '$volume' Volume is present." | tee -a "$log_file"
  else
    echo "❌ '$volume' Volume is missing." | tee -a "$log_file" | tee -a "$error_log"
    all_volumes_present=false
  fi
done

# Final check for all volumes
if [ "$all_volumes_present" = true ]; then
  echo "✅ All required volumes are present." | tee -a "$log_file"
else
  echo "❌ Some required volumes are missing." | tee -a "$log_file" | tee -a "$error_log"
fi

#### Check: Available space
available_space=$(df / | tail -1 | awk '{print $4}')

# Convert available space to GB
available_space_gb=$((available_space / 1048576))

if [ "$available_space_gb" -ge 20 ]; then
  echo "✅ There is enough free space on disk to install $targetOS (20 GB required, $available_space_gb GB available)." | tee -a "$log_file"
else
  echo "❌ There is not enough free space on disk ($available_space_gb GB available, 20 GB required)." | tee -a "$log_file" | tee -a "$error_log"
fi

#### Check: Hardware

echo "-----------------------------------------------------------" | tee -a "$log_file"
echo "🔎 Checking hardware..." | tee -a "$log_file"
echo "-----------------------------------------------------------" | tee -a "$log_file"

#### Check: Battery health
battery_info=$(system_profiler SPPowerDataType)
battery_cycle_count=$(system_profiler SPPowerDataType | awk '/Cycle Count:/ {print $3}')
battery_condition=$(echo "$battery_info" | awk -F ': ' '/Condition/ {print $2}')

if [ "$battery_cycle_count" -lt 1000 ]; then
    echo "✅ Battery cycle count is acceptable. Battery cycles: $battery_cycle_count" | tee -a "$log_file"
else
    echo "❌ Battery cycle count is too high: $battery_cycle_count" | tee -a "$log_file" "$error_log"
fi

# Check: Battery condition
if [[ -n "$battery_condition" ]]; then
  echo "✅ Battery condition: $battery_condition" | tee -a "$log_file"
  if [[ "$battery_condition" != "Normal" ]]; then
    echo "⚠️ Battery condition is not optimal: $battery_condition. Consider servicing or replacing this Mac." | tee -a "$log_file" | tee -a "$error_log"
  fi
else
  echo "❌ Failed to retrieve battery condition." | tee -a "$log_file" | tee -a "$error_log"
fi

# Define macOS compatibility

sierra_compatible_models=(
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

sequoia_compatible_models=(
  "MacBookAir10,1"  # MacBook Air (M1, 2020)
  "MacBookAir14,2"  # MacBook Air (13-inch, M2, 2022)
  "MacBookAir14,15" # MacBook Air (15-inch, M2, 2023)
  "MacBookAir15,1"  # MacBook Air (13-inch, M3, 2024)
  "MacBookAir15,2"  # MacBook Air (15-inch, M3, 2024)
  "MacBookPro17,1"  # MacBook Pro (13-inch, M1, 2020)
  "MacBookPro18,1"  # MacBook Pro (16-inch, M1 Pro/Max, 2021)
  "MacBookPro18,3"  # MacBook Pro (14-inch, M1 Pro/Max, 2021)
  "MacBookPro15,13" # MacBook Pro (14-inch, M3, Nov 2023)
  "MacBookPro15,14" # MacBook Pro (16-inch, M3, Nov 2023)
  "MacBookPro15,6"  # MacBook Pro (14-inch, M2 Pro, 2023)
  "MacBookPro15,7"  # MacBook Pro (16-inch, M2 Pro, 2023)
  "MacBookPro15,8"  # MacBook Pro (14-inch, M2 Max, 2023)
  "MacBookPro15,10" # MacBook Pro (16-inch, M2 Max, 2023)
  "MacBookPro15,11" # MacBook Pro (14-inch, M3, 2024)
  "MacBookPro15,9"  # MacBook Pro (16-inch, M3, 2024)
  "Macmini9,1"      # Mac mini (M1, 2020)
  "Macmini10,1"     # Mac mini (M2, 2023)
  "Macmini10,2"     # Mac mini (M3, 2024)
  "iMac21,1"        # iMac (24-inch, M1, 2021)
  "iMac21,2"        # iMac (24-inch, M3, 2024)
  "MacPro8,1"       # Mac Pro (M2 Ultra, 2023)
  "Mac14,13"        # Mac Studio (M2 Max, 2023)
  "Mac14,14"        # Mac Studio (M2 Ultra, 2023)
  "Mac14,15"        # Mac Studio (M3 Max, 2024)
  "Mac14,16"        # Mac Studio (M3 Ultra, 2024)
)

#### Hardware info - collect
architecture=$(uname -m)
hardware_serial=$(system_profiler SPHardwareDataType | awk -F ": " '/Serial Number/ {print $2}')
hardware_name=$(system_profiler SPHardwareDataType | awk -F ": " '/Model Name/ {print $2}')
hardware_modelidentifier=$(system_profiler SPHardwareDataType | awk -F ": " '/Model Identifier/ {print $2}')
processor_info=$(system_profiler SPHardwareDataType | awk -F ": " '/Processor Name|Chip/ {print $2}')

if [ "$architecture" = "arm64" ]; then
  echo "-- Architecture: Apple silicon" | tee -a "$log_file"
else
  echo "⚠️ Architecture: Intel" | tee -a "$log_file" | tee -a "$error_log"
fi
echo "-- Serial: ${hardware_serial:-Unknown}" | tee -a "$log_file"
echo "-- Model: ${hardware_name:-Unknown}" | tee -a "$log_file"
echo "-- Model Identifier: ${hardware_modelidentifier:-Unknown}" | tee -a "$log_file"
echo "-- Processor Info: ${processor_info:-Unknown}" | tee -a "$log_file"

if [[ "$targetOS" == "macOS Sonoma" ]]; then
    compatible_models=("${sonoma_compatible_models[@]}")
elif [[ "$targetOS" == "macOS Sequoia" ]]; then
    compatible_models=("${sequoia_compatible_models[@]}")
else
    echo "❌ Unknown macOS version: $targetOS" | tee -a "$log_file" | tee -a "$error_log"
    exit 1
fi

# Check if the hardware model is in the list of compatible models
if [[ " ${compatible_models[@]} " =~ " $hardware_modelidentifier " ]]; then
    echo "✅ This device (${hardware_modelidentifier:-Unknown}) is compatible with $targetOS" | tee -a "$log_file"
else
    echo "❌ ${hardware_modelidentifier:-Unknown} is not compatible with $targetOS." | tee -a "$log_file" | tee -a "$error_log"
fi

#### Check: Currently installed macOS version
echo "-----------------------------------------------------------" | tee -a "$log_file"
echo "🔎  Checking existing macOS installation" | tee -a "$log_file"
echo "-----------------------------------------------------------" | tee -a "$log_file"


macos_version=$(sw_vers -productVersion)
major_version=$(echo "$macos_version" | cut -d '.' -f 1)

if [ "$major_version" -ge 11 ]; then
  echo "✅ $macos_version can upgrade to $targetOS" | tee -a "$log_file"
  echo "ℹ️  Current version: $macos_version" | tee -a "$log_file" | tee -a "$error_log"
else
  echo "❌ macOS Big Sur (and earlier versions) cannot upgrade to $targetOS." | tee -a "$log_file" | tee -a "$error_log"
  echo "ℹ️  Current version: $macos_version" | tee -a "$log_file" | tee -a "$error_log"
fi

#### Check: macOS installer is already on disk 
installer_path="/Applications/Install $targetOS.app"

# startosinstall path
startosinstall_path="$installer_path/Contents/Resources/startosinstall"

# Check: macOS installer
if [ -d "$installer_path" ]; then
  echo "✅ $targetOS installer found at '$installer_path'." | tee -a "$log_file"

# Check: startosinstall binary
  if [ -f "$startosinstall_path" ]; then
    echo "✅ The 'startosinstall' binary is available." | tee -a "$log_file"
  else
    echo "⚠️  The 'startosinstall' binary is missing." | tee -a "$log_file" | tee -a "$error_log"
    echo "---  'startosinstall' should be found at: $startosinstall_path." | tee -a "$log_file" | tee -a "$error_log"
  fi
else
  echo "⚠️  $targetOS installer was not found in /Applications" | tee -a "$log_file" | tee -a "$error_log"
fi

#### Check: Existing user accounts for admin role + Secure Token
echo "-----------------------------------------------------------" | tee -a "$log_file"
echo "🔎 Checking existing user accounts..." | tee -a "$log_file"
echo "-----------------------------------------------------------" | tee -a "$log_file"

# Function to check if a user has a Secure Token
check_secure_token() {
    local user="$1"
    sysadminctl -secureTokenStatus "$user" 2>&1 | grep -q "ENABLED"
    if [ $? -eq 0 ]; then
        echo "Secure Token: ENABLED"
    else
        echo "Secure Token: DISABLED"
    fi
}

# Get a list of local user accounts (excluding system accounts)
user_list=$(dscl . list /Users | awk '($1 !~ /^_|daemon|nobody|root|com.apple/)')

# Loop through each user
while IFS= read -r user; do
    # Ensure the user exists
    if id "$user" >/dev/null 2>&1; then
        # Check if the user is an admin
        if dscl . read /Groups/admin GroupMembership 2>/dev/null | grep -qw "$user"; then
            # Check Secure Token status
            secure_token_status=$(sysadminctl -secureTokenStatus "$user" 2>&1)
            if echo "$secure_token_status" | grep -q "ENABLED"; then
                # Retrieve home directory and UID
                home_directory=$(dscl . -read "/Users/$user" NFSHomeDirectory | awk '{print $2}')
                user_uid=$(id -u "$user")
                
                # Log the results for admin users with Secure Token enabled
                {
                    echo "User: $user"
                    echo "      Admin"
                    echo "      Secure Token enabled"
                    echo "      Home Directory: $home_directory"
                    echo "      UID: $user_uid"
                } | tee -a "$log_file"
            fi
        fi
    fi
done <<< "$user_list"

############################################
#           Step 2: Evaluation             #
############################################
#### Check the error log and based on what we found, recommend an upgrade method with an AppleScript dialog

echo "-----------------------------------------------------------" | tee -a "$log_file"
echo "🧮 Calculating the best upgrade path..." | tee -a "$log_file"
echo "🌲 Reticulating splines..." | tee -a "$log_file"
echo "-----------------------------------------------------------" | tee -a "$log_file"


GROUP_A_ERRORS=$(grep -E "Not compatible|not supported|cannot upgrade" "$error_log")

GROUP_B_ERRORS=$(grep -E "volumes are missing|cannot upgrade straight to $targetOS|MDM Profile is removable|not enrolled via DEP" "$error_log")

GROUP_C_ERRORS=$(grep -E "Mac is NOT managed|Bootstrap Token NOT Escrowed|expired" "$error_log")

GROUP_D_ERRORS=$(grep -E "not enough free space on disk|Software updates are restricted|Custom software update catalog URL|macOS updates are deferred" "$error_log")

GROUP_E_ERRORS=$(grep -E "Intel" "$error_log")

############################################
#         Step 3: Notification             #
############################################

# If silent_mode is NOT enabled, then present notifications
if [[ "$silent_mode" != "on" ]]; then

# Set the message and buttons based on error group and display notification using osascript with timeout
# Timeout for dialogs, in case there is no button clicked. We want the script to complete anyway

TIMEOUT_SECONDS=30

    if [ -n "$GROUP_A_ERRORS" ]; then
        MESSAGE="Bad news…\n\nThis Mac is not compatible with the target version of macOS ($targetOS).\n\n$GROUP_A_ERRORS"
        DEFAULT_ACTION="Quit"
        osascript <<EOF &
        on run
            try
                display dialog "$MESSAGE" buttons {"Compatibility Info…", "Quit"} default button "$DEFAULT_ACTION" with icon caution giving up after $TIMEOUT_SECONDS
                set userChoice to button returned of result
                if userChoice is "Compatibility Info…" then
                    do shell script "open https://support.apple.com/en-au/105113"
                end if
            on error
                display dialog "No response was received. Defaulting to \"$DEFAULT_ACTION\"." buttons {"OK"} default button "OK"
            end try
        end run
EOF

    elif [ -n "$GROUP_B_ERRORS" ]; then
        MESSAGE="Bad news...\n\n$GROUP_B_ERRORS\n\nYou will need to erase and re-install macOS, using either Internet Recovery or Apple Configurator 2. (aka time to nuke and pave)."
        DEFAULT_ACTION="Quit"
        osascript <<EOF &
        on run
            try
                display dialog "$MESSAGE" buttons {"How to…", "Quit"} default button "$DEFAULT_ACTION" with icon caution giving up after $TIMEOUT_SECONDS
                set userChoice to button returned of result
                if userChoice is "How to…" then
                    do shell script "open https://support.apple.com/en-au/guide/mac-help/mchl7676b710/15.0/mac/15.0"
                end if
            on error
                display dialog "No response was received. Defaulting to \"$DEFAULT_ACTION\"." buttons {"OK"} default button "OK"
            end try
        end run
EOF

    elif [ -n "$GROUP_C_ERRORS" ]; then
        MESSAGE="Not-so-great news...\n\n$GROUP_C_ERRORS\n\nThis Mac can be upgraded to $targetOS, but you won't be able to use MDM commands to achieve this. Recommendation: upgrade macOS via System Preferences."
        DEFAULT_ACTION="Quit"
        osascript <<EOF &
        on run
            try
                display dialog "$MESSAGE" buttons {"Open System Settings…", "Quit"} default button "$DEFAULT_ACTION" with icon note giving up after $TIMEOUT_SECONDS
                set userChoice to button returned of result
                if userChoice is "Open System Settings…" then
                    do shell script "open -a 'System Settings'"
                end if
            on error
                display dialog "Input timeout. No one clicked on a button... Defaulting to \"$DEFAULT_ACTION\"." buttons {"OK"} default button "OK"
            end try
        end run
EOF

    elif [ -n "$GROUP_D_ERRORS" ]; then
        MESSAGE="Rats.\n\n$GROUP_D_ERRORS\n\nHave a look at the above issues. Rectify these and try again. Or, just nuke and pave."
        DEFAULT_ACTION="Quit"
        osascript <<EOF &
        on run
            try
                display dialog "$MESSAGE" buttons {"Show error log", "Quit"} default button "$DEFAULT_ACTION" with icon stop giving up after $TIMEOUT_SECONDS
                set userChoice to button returned of result
                if userChoice is "Show error log" then
                    do shell script "open /path/to/error/log"
                end if
            on error
                display dialog "Input timeout. No one clicked on a button... Defaulting to \"$DEFAULT_ACTION\"." buttons {"OK"} default button "OK"
            end try
        end run
EOF

    else
        MESSAGE="Great news! All checks passed successfully. 🎉 You can upgrade this Mac via MDM. Log into your MDM server ($mdmUrl) and go from there."
        DEFAULT_ACTION="OK"
        osascript <<EOF &
        on run
            try
                display dialog "$MESSAGE" buttons {"OK"} default button "$DEFAULT_ACTION" with icon note giving up after $TIMEOUT_SECONDS
            on error
                display dialog "Input timeout. No one clicked on a button... Defaulting to \"$DEFAULT_ACTION\"." buttons {"OK"} default button "OK"
            end try
        end run
EOF
    fi
else
    echo "Silent mode is enabled. No dialogs will be displayed."
fi

############################################
#           Step 4: Conclusion             #
############################################

echo "==================== Conclusion =====================" | tee -a "$log_file"

echo " " | tee -a "$log_file"
echo "$MESSAGE" | tee -a "$log_file"
echo " " | tee -a "$log_file"


echo "-----------------------------------------------------------" | tee -a "$log_file"
echo "Best of luck on your upgrade journey! Bon voyage! 👋" | tee -a "$log_file"
#echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$log_file"
echo "-----------------------------------------------------------" | tee -a "$log_file"

exit 0