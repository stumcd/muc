#!/bin/bash

# -----------------------------------------------------
# Script Name: MacUpgradeChaperone.sh
# Description: This script will guide you to the best upgrade method for the host Mac
# Source: github.com/stumcd/muc  
# Author: Stu McDonald
# Created: 14-09-24
# -----------------------------------------------------
# Version: 0.62
# Modified: 24-03-25
# -----------------------------------------------------

# DISCLAIMER:
# This script is shared with no guarantees— it works for me, but your mileage (kilometerage?) may vary. 
# No guarantees are made about its suitability, reliability, or impact on your environment. 
# You are solely responsible for testing, validating, and using this script. 

# -----------------------------------------------------
# Future plans:
# - If macOS re-install needed, download installer from Apple using mist-cli 
# - If not already installed, install mist-cli from GitHub
# - Report on MDM profile installation date
# - One day: add some wild 90s ASCII art here, like you'd see on a .NFO
# -----------------------------------------------------

#  -----------------------------------------------------
#                Explainer                     
#  -----------------------------------------------------

# There are 5 potential outcomes when trying to upgrade a Mac:
#
# Group A = Not compatible. This Mac cannot upgrade to the target version. 
# Group B = Compatible, but you must erase and reinstall macOS (aka nuke & pave). 
# Group C = Upgrade possible, but not via MDM- must be upgraded manually. (or maybe nuke & pave?)
# Group D = Upgrade possible, but needs manual intervention first (e.g. not enough disk space)
# Group E = Upgrade possible, but maybe nuke & pave anyway? (e.g. MDM profile is removable)

############################################
#                  Variables               #
############################################

# Default values (can be overridden)
log_dir="/usr/local/muc"
targetOS="Sequoia"
silent_mode="off"
offline_mode=""

############################################
#        Parse CLI Arguments (if any)      #
############################################
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --log_dir)
            log_dir="$2"
            shift 2
            ;;
        --targetOS)
            targetOS="$2"
            shift 2
            ;;
        --silent_mode)
            silent_mode="$2"
            shift 2
            ;;
        --offline_mode)
            offline_mode="$2"
            shift 2
            ;;
        *)
            echo "❌ Unknown option: $1"
            exit 1
            ;;
    esac
done

############################################
#        Jamf Pro Script Parameters        #
############################################
# Only override *if* value is still empty

# $4 = log_dir
if [[ -z "$log_dir" && -n "$4" ]]; then
    log_dir="$4"
fi

# $5 = targetOS
if [[ -z "$targetOS" && -n "$5" ]]; then
    targetOS="$5"
fi

# $6 = silent_mode
if [[ -z "$silent_mode" && -n "$6" ]]; then
    silent_mode="$6"
fi

# $7 = offline_mode
if [[ -z "$offline_mode" && -n "$7" ]]; then
    offline_mode="$7"
fi

############################################
#                 Setup                    #
############################################

#### Quit if script hasn't been run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Sorry, this script must be run as root. Exiting..." >&2
    exit 1
fi

# Create the log directory if it doesn't exist & ensure the current user has ownership
if [ ! -d "$log_dir" ]; then
  echo "The log directory '$log_dir' does not exist. Creating it now..."
  sudo mkdir -p "$log_dir"
  sudo chown "${SUDO_USER:-$(whoami)}" "$log_dir"
fi

if [[ ! -w "$log_dir" ]]; then
    echo "Error: Log directory '$log_dir' is not writable."
    exit 1
fi

#### Get the current timestamp (format: YYYYMMDD_HHMMSS)
timestamp=$(date +"%Y%m%d_%H%M%S")

#### New log files (general, issue and conclusion) for each run, appended with timestamp
general_log="$log_dir/macupgradechaperone_${timestamp}.log"
issue_log="$log_dir/macupgradechaperone_${timestamp}.issue.log"
conclusion_log="$log_dir/macupgradechaperone_${timestamp}.conclusion.log"

# Normalise targetOS: prepend "macOS " if not already present
if [[ -n "$targetOS" ]]; then
    # Capitalise first letter (e.g. sierra → Sierra)
    targetOS="$(tr '[:upper:]' '[:lower:]' <<< "${targetOS:0:1}")${targetOS:1}"
    targetOS="$(tr '[:lower:]' '[:upper:]' <<< "${targetOS:0:1}")${targetOS:1}"

    # Prepend "macOS " if not already included (case-insensitive check)
    if [[ ! "$targetOS" =~ ^[Mm][Aa][Cc][Oo][Ss]\  ]]; then
        targetOS="macOS $targetOS"
    fi
fi

#### Target OS: if not set, default to latest major version
if [[ -z $targetOS ]]; then
    targetOS="Sequoia"
fi

echo "-----------------------------------------------------------" | tee -a "$general_log"
echo "ℹ️️  General log: $general_log" | tee -a "$general_log"
echo "ℹ️  Issue log: $issue_log" | tee -a "$general_log"
echo "🤵️  Conclusion log: $conclusion_log" | tee -a "$general_log"
echo "ℹ️  Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$general_log"


if [ "$silent_mode" = "on" ]; then
	echo "🤐  Silent mode enabled, logging only, no notifications"
fi

if [ "$offline_mode" = "on" ]; then
	echo "⚠️  Offline mode enabled, skipping checks that need connectivity"
fi

echo "==========================================================" | tee -a "$general_log"
echo "======== 🖥️ 🤵 Mac Upgrade Chaperone v0.61 🤵🖥️  ===========" | tee -a "$general_log"
echo "--------------- Guiding your journey to... ----------------" | tee -a "$general_log"
echo "------------------ ✨ $targetOS ✨ --------------------" | tee -a "$general_log"
echo "===========================================================" | tee -a "$general_log"


#### Insert here: if currentOS is already targetOS... prompt with 'are you sure? continue or quit'

#### Pre-req: network connectivity
## Check if the Mac is connected to a network (Wi-Fi or Ethernet)

if [ "$offline_mode" = "on" ]; then
    echo "⚠️  Offline mode: skipping connectivity checks" | tee -a "$general_log"
else

network_status() {

    get_active_interface() {
        for iface in $(ifconfig -l); do
            if [[ "$iface" =~ ^en[0-9]+$ ]]; then
                if ifconfig "$iface" 2>/dev/null | grep -q "status: active"; then
                    echo "$iface"
                    return
                fi
            fi
        done
    }

    local max_retries=5
    local retry_count=0

    while [[ $retry_count -lt $max_retries ]]; do
        active_interface=$(get_active_interface)

        if [[ -n "$active_interface" ]]; then
            # Actual internet test: ping or curl fallback
            if ping -q -c 1 -t 2 1.1.1.1 >/dev/null 2>&1; then
                internet_ok=true
            elif curl -s --max-time 3 https://apple.com | grep -qi "apple"; then
                internet_ok=true
            else
                internet_ok=false
            fi

            if [[ "$internet_ok" = true ]]; then
                echo "✅ Network connection detected. 🎉" | tee -a "$general_log"

                # Port test
                if nc -z -w 5 apple.com 443 >/dev/null 2>&1; then
                    return 0
                else
                    echo "❌ Unable to connect to apple.com on port 443. Port check failed." | tee -a "$general_log" | tee -a "$issue_log"
                    osascript <<EOF
display dialog "Unable to connect to apple.com on port 443, even though the Mac *is* connected to a network. There might be a misconfigured firewall rule blocking this, or maybe the Mac is not properly authenticated on the network." buttons {"Quit"} default button "Quit" with icon stop
EOF
                    exit 1
                fi
            fi
        fi

        # If we got here, something failed
        ((retry_count++))
        echo "❌ No active network connection found. (Attempt $retry_count of $max_retries)" | tee -a "$general_log" | tee -a "$issue_log"

        if [[ $retry_count -ge $max_retries ]]; then
            echo "❌ Maximum retry attempts reached. Exiting." | tee -a "$general_log" | tee -a "$issue_log"
            exit 1
        fi

        response=$(osascript <<EOF
display dialog "No network connection detected. Please connect to a network and try again." buttons {"Quit", "Retry"} default button "Retry" with icon stop
EOF
)

        if [[ "$response" == "button returned:Quit" ]]; then
            echo "User chose to quit." | tee -a "$general_log"
            exit 1
        elif [[ "$response" == "button returned:Retry" ]]; then
            echo "User chose to retry." | tee -a "$general_log"
            continue
        fi
    done
}

if network_status; then
    echo "✅ Network connectivity checks passed." | tee -a "$general_log"
fi

fi

############################################
#             Step 1: Checks               #
############################################

#### Check: MDM Profile and enrollment info
echo "-----------------------------------------------------------" | tee -a "$general_log"
echo "🔎  Checking MDM profile..." | tee -a "$general_log"
echo "-----------------------------------------------------------" | tee -a "$general_log"

mdm_profile=$(profiles status -type enrollment)

if [[ "$mdm_profile" == *"MDM enrollment: Yes"* ]]; then
  echo "✅ MDM Profile: Installed." | tee -a "$general_log"
  
  mdmUrl=$(system_profiler SPConfigurationProfileDataType | awk -F'[/:?]' '/CheckInURL/ {print $4}')
  echo "ℹ️  MDM Server URL: $mdmUrl" | tee -a "$general_log"
fi
 
if [[ "$mdm_profile" == *"MDM enrollment: No"* ]]; then
  echo "❌ MDM Profile not present. This Mac is NOT managed." | tee -a "$general_log" | tee -a "$issue_log"
fi


#if [[ -z "$mdm_profile_install_date" ]]; then
#    echo "--- ❌ Profiles binary couldn't find an MDM Profile... That's... odd." | tee -a "$general_log" | tee -a "$issue_log"
#else

# Compare installation date with the current date
#    current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
#    mdm_profile_ts=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$mdm_profile_install_date" +%s)
#    current_ts=$(date -u +%s)

#    Calculate timestamp for 5 years (5 * 365 * 24 * 60 * 60)
#    five_years_ago_ts=$((current_ts - 157680000))

#    if [[ "$mdm_profile_ts" -lt "$five_years_ago_ts" ]]; then
#        echo "--- ❌ The MDM Profile installation date ($mdm_profile_install_date) is over 5 years earlier than the current date ($current_date)." | tee -a "$general_log" | tee -a "$issue_log"
#    else
#        echo "--- ✅ The MDM Profile has a valid install date within 5 years." | tee -a "$general_log"
#        echo "--- MDM Profile installation date: $mdm_profile_install_date" | tee -a "$general_log"
#    fi
#fi

if [[ "$offline_mode" = "on" ]]; then
    echo "⚠️  Offline mode: skipping check for Device Enrollment Configuration" | tee -a "$general_log"
else
    # Check if MDM profile is removable
    mdm_profile_removeable=$(profiles -e | grep "IsMDMUnremovable" | awk '{print $3}' | tr -d ';')
    
    if [[ ${mdm_profile_removeable} = '1' ]]; then
        echo "✅ MDM Profile is NOT removable" | tee -a "$general_log"
    elif [[ ${mdm_profile_removeable} = '0' ]]; then
        echo "⚠️  MDM Profile is removable." | tee -a "$general_log" | tee -a "$issue_log"
    else
        echo "❓ Unable to determine MDM Profile removability." | tee -a "$general_log" | tee -a "$issue_log"
    fi
fi
	
# Check: push certificate expiry
apns_expiry_date=$(security find-certificate -a -p /Library/Keychains/System.keychain | \
openssl x509 -noout -enddate | \
grep "notAfter" | head -n 1 | cut -d= -f2)

if [[ -z "$apns_expiry_date" ]]; then
    echo "❌ No APNS certificate found in the system keychain." | tee -a "$general_log" | tee -a "$issue_log"
    exit 1
fi

# Convert dates to Unix timestamps for comparison
apns_expiry_ts=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$apns_expiry_date" +"%s")
current_ts=$(date -u +"%s")

if [[ "$apns_expiry_ts" -lt "$current_ts" ]]; then
    echo "❌ Push certificate has expired. Expiry date: $apns_expiry_date" | tee -a "$general_log" | tee -a "$issue_log"
else
    echo "✅ APNS certificate is valid. Expiry date: $apns_expiry_date" | tee -a "$general_log"
fi

# Check if enrolled via Automated Device Enrolment
ade_enrolled=$(profiles status -type enrollment)

if echo "$ade_enrolled" | grep -q "Enrolled via DEP: Yes"; then
    echo "✅ This Mac was enrolled via Automated Device Enrollment" | tee -a "$general_log"
else
    echo "⚠️  This Mac was not enrolled via Automated Device Enrollment" | tee -a "$general_log" | tee -a "$issue_log"
fi

# Check: MDM server
echo "-----------------------------------------------------------" | tee -a "$general_log"
echo "🔎 Checking MDM Server..." | tee -a "$general_log" 
echo "-----------------------------------------------------------" | tee -a "$general_log"

mdmServerStatus=$(curl -s -o /dev/null -w "%{http_code}" "$mdmUrl/healthCheck.html")

if [ "$mdmServerStatus" -eq 200 ] || [ "$mdmServerStatus" -eq 301 ]; then
    echo "✅ MDM Server is reachable. HTTP response code: $mdmServerStatus" | tee -a "$general_log"
    echo "ℹ️  URL: $mdmUrl" | tee -a "$general_log"

else
    echo "❌ Failed to reach $mdmUrl." | tee -a "$general_log" | tee -a "$issue_log"
    echo "-- URL: $mdmUrl" | tee -a "$general_log"
    echo "-- HTTP response: $mdmServerStatus" | tee -a "$general_log"    
fi

# Check if Bootstrap Token has been escrowed
if profiles status -type bootstraptoken | grep -q "Bootstrap Token escrowed to server: YES"; then
    echo "✅ Bootstrap Token has been escrowed" | tee -a "$general_log"
else
    echo "❌ Bootstrap Token has NOT been escrowed" | tee -a "$general_log" | tee -a "$issue_log"
fi

echo "-----" | tee -a "$general_log"

#### Check: upgrade restrictions

echo "-----------------------------------------------------------" | tee -a "$general_log"
echo "🔎 Checking for any deferrals/restrictions..." | tee -a "$general_log"
echo "-----------------------------------------------------------" | tee -a "$general_log"

# Check com.apple.applicationaccess (MCX-style or Jamf config profile)
if [ -f "/Library/Managed Preferences/com.apple.applicationaccess.plist" ]; then
    restrict=$(/usr/bin/defaults read /Library/Managed\ Preferences/com.apple.applicationaccess restrict-software-update 2>/dev/null || echo "Not found")
    max_os=$(/usr/bin/defaults read /Library/Managed\ Preferences/com.apple.applicationaccess max-os-version 2>/dev/null || echo "Not found")
    defer_general=$(/usr/bin/defaults read /Library/Managed\ Preferences/com.apple.applicationaccess enforcedSoftwareUpdateDelay 2>/dev/null || echo "Not found")
    defer_major=$(/usr/bin/defaults read /Library/Managed\ Preferences/com.apple.applicationaccess enforcedSoftwareUpdateMajorOSDeferredInstallDelay 2>/dev/null || echo "Not found")
    defer_minor=$(/usr/bin/defaults read /Library/Managed\ Preferences/com.apple.applicationaccess enforcedSoftwareUpdateMinorOSDeferredInstallDelay 2>/dev/null || echo "Not found")
    defer_nonos=$(/usr/bin/defaults read /Library/Managed\ Preferences/com.apple.applicationaccess enforcedSoftwareUpdateNonOSDeferredInstallDelay 2>/dev/null || echo "Not found")

    if [ "$restrict" = "1" ]; then
        echo "❌ Software updates are restricted by MDM (restrict-software-update = 1)." | tee -a "$general_log" | tee -a "$issue_log"
    elif [ "$max_os" != "Not found" ]; then
        echo "❌ Maximum allowed macOS version: $max_os" | tee -a "$general_log" | tee -a "$issue_log"
    elif [ "$defer_general" != "Not found" ] || [ "$defer_major" != "Not found" ] || [ "$defer_minor" != "Not found" ] || [ "$defer_nonos" != "Not found" ]; then
        echo "❌ Update deferral policy detected in com.apple.applicationaccess:" | tee -a "$general_log" | tee -a "$issue_log"
        [ "$defer_general" != "Not found" ] && echo "   • General update delay: ${defer_general} days" | tee -a "$general_log"
        [ "$defer_major" != "Not found" ] && echo "   • Major OS update delay: ${defer_major} days" | tee -a "$general_log"
        [ "$defer_minor" != "Not found" ] && echo "   • Minor OS update delay: ${defer_minor} days" | tee -a "$general_log"
        [ "$defer_nonos" != "Not found" ] && echo "   • Non-OS update delay: ${defer_nonos} days" | tee -a "$general_log"
    else
        echo "✅ No macOS restrictions found in com.apple.applicationaccess." | tee -a "$general_log"
    fi
else
    echo "ℹ️ com.apple.applicationaccess.plist not found — checking configuration profiles..." | tee -a "$general_log"
fi

# Check for update deferrals from Configuration Profiles (e.g., via Jamf Pro)
profile_deferrals=$(sudo /usr/bin/profiles show -type configuration | grep -i 'enforcedSoftwareUpdate' || true)

if [ -n "$profile_deferrals" ]; then
    echo "❌ Software Update deferrals found in configuration profiles:" | tee -a "$general_log" | tee -a "$issue_log"
    echo "$profile_deferrals" | tee -a "$general_log"
else
    echo "✅ No Software Update deferrals found in active configuration profiles." | tee -a "$general_log"
fi

# Optional legacy check: com.apple.SoftwareUpdate.plist
if [ -f "/Library/Preferences/com.apple.SoftwareUpdate.plist" ]; then
    deferred_days=$(/usr/bin/defaults read /Library/Preferences/com.apple.SoftwareUpdate SoftwareUpdateMajorOSDeferredInstallDelay 2>/dev/null || echo "Not found")

    if [ "$deferred_days" != "Not found" ] && [ "$deferred_days" -gt 0 ]; then
        echo "❌ Major macOS updates are deferred by $deferred_days days (legacy preference)." | tee -a "$general_log" | tee -a "$issue_log"
    else
        echo "✅ No legacy deferral policy for macOS updates detected." | tee -a "$general_log"
    fi
else
    echo "No legacy deferral policy found in com.apple.SoftwareUpdate." | tee -a "$general_log"
fi

#### Check: Software Update Catalog URL
catalog_url=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL 2>/dev/null)

if [ -z "$catalog_url" ]; then
    echo "✅ The system is using Apple's default software update catalog" | tee -a "$general_log"
else
    echo "❌ Custom software update catalog URL detected: $catalog_url" | tee -a "$general_log" | tee -a "$issue_log"
fi

#### Check: Disk volume naming
echo "-----------------------------------------------------------" | tee -a "$general_log"
echo "🔎 Checking APFS volumes..." | tee -a "$general_log"
echo "-----------------------------------------------------------" | tee -a "$general_log"

# List of volumes to check
volumes=("Macintosh HD" "Data" "Preboot" "Recovery" "VM")

# Flag to track volumes
all_volumes_present=true

# Loop through and check for each volume
for volume in "${volumes[@]}"; do
  if diskutil list | grep -q "$volume"; then
    echo "✅ '$volume' Volume is present." | tee -a "$general_log"
  else
    echo "❌ '$volume' Volume is missing." | tee -a "$general_log" | tee -a "$issue_log"
    all_volumes_present=false
  fi
done

# Final check for all volumes
if [ "$all_volumes_present" = true ]; then
  echo "✅ All required volumes are present." | tee -a "$general_log"
else
  echo "❌ Some required volumes are missing." | tee -a "$general_log" | tee -a "$issue_log"
fi

#### Check: Available space
available_space=$(df / | tail -1 | awk '{print $4}')

# Convert available space to GB
available_space_gb=$((available_space / 1048576))

if [ "$available_space_gb" -ge 20 ]; then
  echo "✅ There is enough free space on disk to install $targetOS (20 GB required, $available_space_gb GB available)." | tee -a "$general_log"
else
  echo "❌ There is not enough free space on disk ($available_space_gb GB available, 20 GB required)." | tee -a "$general_log" | tee -a "$issue_log"
fi

#### Check: Hardware

echo "-----------------------------------------------------------" | tee -a "$general_log"
echo "🔎 Checking hardware..." | tee -a "$general_log"
echo "-----------------------------------------------------------" | tee -a "$general_log"


# Define hardware compatibility for each supported version (Sequoia, Sonoma)

sonoma_compatible_models=(
  "MacBookAir8,1"  # MacBook Air (Retina, 13-inch, 2018)
  "MacBookAir9,1"  # MacBook Air (Retina, 13-inch, 2020)
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
  "Mac15,3"        # MacBook Pro (14-inch, M3, 2023)
  "Mac15,6"        # MacBook Pro (16-inch, M3, 2023)  
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
  "MacBookAir9,1"   # MacBook Air (Retina, 13-inch, 2020)
  "MacBookAir10,1"  # MacBook Air (M1, 2020)
  "MacBookAir14,2"  # MacBook Air (13-inch, M2, 2022)
  "MacBookAir14,15" # MacBook Air (15-inch, M2, 2023)
  "MacBookAir15,1"  # MacBook Air (13-inch, M3, 2024)
  "MacBookAir15,2"  # MacBook Air (15-inch, M3, 2024)
  "MacBookPro17,1"  # MacBook Pro (13-inch, M1, 2020)
  "MacBookPro18,1"  # MacBook Pro (16-inch, M1 Pro/Max, 2021)
  "MacBookPro18,3"  # MacBook Pro (14-inch, M1 Pro/Max, 2021)
  "Mac15,3"   # MacBook Pro (14-inch, M3, 2023)
  "Mac15,6"   # MacBook Pro (16-inch, M3, 2023)
  "Mac15,11"  # MacBook Pro (14-inch, M3 Pro, 2024)
  "Mac15,9"   # MacBook Pro (16-inch, M3 Pro, 2024)  
  "MacBookPro15,6"  # MacBook Pro (14-inch, M2 Pro, 2023)
  "MacBookPro15,7"  # MacBook Pro (16-inch, M2 Pro, 2023)
  "MacBookPro15,8"  # MacBook Pro (14-inch, M2 Max, 2023)
  "MacBookPro15,10" # MacBook Pro (16-inch, M2 Max, 2023)
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

#### Retrieve hardware info
architecture=$(uname -m)
hardware_serial=$(system_profiler SPHardwareDataType | awk -F ": " '/Serial Number/ {print $2}')
hardware_name=$(system_profiler SPHardwareDataType | awk -F ": " '/Model Name/ {print $2}')
hardware_modelidentifier=$(system_profiler SPHardwareDataType | awk -F ": " '/Model Identifier/ {print $2}')
processor_info=$(system_profiler SPHardwareDataType | awk -F ": " '/Processor Name|Chip/ {print $2}')

if [ "$architecture" = "arm64" ]; then
  echo "-- Architecture: Apple silicon" | tee -a "$general_log"
else
  echo "⚠️ Architecture: Intel" | tee -a "$general_log" | tee -a "$issue_log"
fi
echo "-- Serial: ${hardware_serial:-Unknown}" | tee -a "$general_log"
echo "-- Model: ${hardware_name:-Unknown}" | tee -a "$general_log"
echo "-- Model Identifier: ${hardware_modelidentifier:-Unknown}" | tee -a "$general_log"
echo "-- Processor Info: ${processor_info:-Unknown}" | tee -a "$general_log"

if [[ "$targetOS" == "macOS Sonoma" ]]; then
    compatible_models=("${sonoma_compatible_models[@]}")
elif [[ "$targetOS" == "macOS Sequoia" ]]; then
    compatible_models=("${sequoia_compatible_models[@]}")
else
    echo "🙃 Sorry, currently MUC doesn't support macOS version: $targetOS" | tee -a "$general_log" | tee -a "$issue_log"
    exit 1
fi

#### Check: Battery health

echo "-----------------------------------------------------------" | tee -a "$general_log"
echo "⚡️ Checking battery..." | tee -a "$general_log"
echo "-----------------------------------------------------------" | tee -a "$general_log"

battery_info=$(system_profiler SPPowerDataType)
battery_cycle_count=$(system_profiler SPPowerDataType | awk '/Cycle Count:/ {print $3}')
battery_condition=$(echo "$battery_info" | awk -F ': ' '/Condition/ {print $2}')

if [ "$battery_cycle_count" -lt 1000 ]; then
    echo "✅ Battery cycle count is acceptable. Battery cycles: $battery_cycle_count" | tee -a "$general_log"
else
    echo "❌ Battery cycle count is too high: $battery_cycle_count" | tee -a "$general_log" "$issue_log"
fi

# Check: Battery condition
if [[ -n "$battery_condition" ]]; then
  echo "✅ Battery condition: $battery_condition" | tee -a "$general_log"
  if [[ "$battery_condition" != "Normal" ]]; then
    echo "⚠️ Battery condition is not optimal: $battery_condition. Consider servicing or replacing this Mac." | tee -a "$general_log" | tee -a "$issue_log"
  fi
else
  echo "❌ Failed to retrieve battery condition." | tee -a "$general_log" | tee -a "$issue_log"
fi

# Check if the hardware model is in the list of compatible models
if [[ " ${compatible_models[@]} " =~ " $hardware_modelidentifier " ]]; then
    echo "✅ This Mac (${hardware_modelidentifier:-Unknown}) is compatible with $targetOS" | tee -a "$general_log"
else
    echo "❌ ${hardware_modelidentifier:-Unknown} is not compatible with $targetOS." | tee -a "$general_log" | tee -a "$issue_log"
fi

#### Check: Currently installed macOS version
echo "-----------------------------------------------------------" | tee -a "$general_log"
echo "🔎  Checking existing macOS installation" | tee -a "$general_log"
echo "-----------------------------------------------------------" | tee -a "$general_log"

macos_version=$(sw_vers -productVersion)
major_version=$(echo "$macos_version" | cut -d '.' -f 1)

if [ "$major_version" -ge 11 ]; then
  echo "ℹ️  Current version: $macos_version" | tee -a "$general_log"
else
  echo "❌ macOS Big Sur (and earlier versions) cannot upgrade to $targetOS. Current version: $macos_version" | tee -a "$general_log" | tee -a "$issue_log"
fi

#### Check: macOS installer is already on disk

installer_path="/Applications/Install $targetOS.app"

echo "- Checking for $targetOS installer on disk: '$installer_path'." | tee -a "$general_log"

startosinstall_path="$installer_path/Contents/Resources/startosinstall"

if [ -d "$installer_path" ]; then
  echo "✅ $targetOS installer found at '$installer_path'." | tee -a "$general_log"

# Check: startosinstall binary
  if [ -f "$startosinstall_path" ]; then
    echo "✅ startosinstall binary detected, too." | tee -a "$general_log"
  else
    echo "⚠️  startosinstall binary not found." | tee -a "$general_log" | tee -a "$issue_log"
    echo "---  'startosinstall' expected at: $startosinstall_path." | tee -a "$general_log"
  fi
else
  echo "⚠️  $targetOS installer not found in /Applications" | tee -a "$general_log"
fi

#### Check: Existing user accounts for admin role + Secure Token
echo "-----------------------------------------------------------" | tee -a "$general_log"
echo "🔎 Checking user accounts..." | tee -a "$general_log"
echo "-----------------------------------------------------------" | tee -a "$general_log"

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
                } | tee -a "$general_log"
            fi
        fi
    fi
done <<< "$user_list"

############################################
#           Step 2: Evaluation             #
############################################

echo "-----------------------------------------------------------" | tee -a "$general_log"
echo "🧮 Calculating the best upgrade path..." | tee -a "$general_log"
echo "🌲 Reticulating splines..." | tee -a "$general_log"
echo "-----------------------------------------------------------" | tee -a "$general_log"

#### Check the issue log and based on what we found, recommend an upgrade method with an AppleScript dialog

GROUP_A_ISSUES=$(grep -E "Not compatible|not supported|cannot upgrade" "$issue_log")

GROUP_B_ISSUES=$(grep -E "volumes are missing|cannot upgrade straight to $targetOS|not enrolled via DEP" "$issue_log")

GROUP_C_ISSUES=$(grep -E "Mac is NOT managed|Bootstrap Token NOT Escrowed|expired" "$issue_log")

GROUP_D_ISSUES=$(grep -E "not enough free space on disk|Software updates are restricted|Custom software update catalog URL|macOS updates are deferred" "$issue_log")

GROUP_E_ISSUES=$(grep -E "Intel|MDM Profile is removable" "$issue_log")

############################################
#         Step 3: Notification             #
############################################

# If silent_mode is NOT enabled, then present notifications
if [[ "$silent_mode" != "on" ]]; then

# Set the message and buttons based on error group and display notification using osascript with timeout
# Timeout for dialogs, in case there is no button clicked. We want the script to complete anyway

TIMEOUT_SECONDS=30

    if [ -n "$GROUP_A_ISSUES" ]; then
        MESSAGE="Unfortunately…\n\nThis Mac is not compatible with the target version of macOS ($targetOS).\n\n$GROUP_A_ISSUES"
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

    elif [ -n "$GROUP_B_ISSUES" ]; then
        MESSAGE="Bad news...\n\n$GROUP_B_ISSUES\n\nYou will need to erase and re-install macOS, using either Internet Recovery or Apple Configurator 2. (aka time to nuke and pave)."
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

    elif [ -n "$GROUP_C_ISSUES" ]; then
        MESSAGE="Not-so-great news...\n\n$GROUP_C_ISSUES\n\nThis Mac can be upgraded to $targetOS, but you won't be able to use MDM commands to achieve this. Recommendation: upgrade macOS via System Preferences."
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

    elif [ -n "$GROUP_D_ISSUES" ]; then
        MESSAGE="Rats.\n\n$GROUP_D_ISSUES\n\nHave a look at the above issues. Rectify these and try again. Or, just nuke and pave."
        DEFAULT_ACTION="Quit"
        osascript <<EOF &
        on run
            try
                display dialog "$MESSAGE" buttons {"Show error log", "Quit"} default button "$DEFAULT_ACTION" with icon stop giving up after $TIMEOUT_SECONDS
                set userChoice to button returned of result
                if userChoice is "Show error log" then
                    do shell script "open $issue_log"
                end if
            on error
                display dialog "Input timeout. No one clicked on a button... Defaulting to \"$DEFAULT_ACTION\"." buttons {"OK"} default button "OK"
            end try
        end run
EOF

	    elif [ -n "$GROUP_E_ISSUES" ]; then
        MESSAGE="Good news! 🎉 This Mac can be upgraded to $targetOS.\n\nHowever, consider erasing and re-installing because:\n\n$GROUP_E_ISSUES"
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

    else
        MESSAGE="Great news! All checks passed successfully. 🎉 You can upgrade this Mac with the latest and greatest methods."
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
    echo "🤐  Silent mode enabled. Logging only."
fi

############################################
#           Step 4: Conclusion             #
############################################

echo "====== 🖥️ 🤵 Mac Upgrade Chaperone v0.61 🤵🖥️  ==========" | tee -a "$general_log" | tee -a "$conclusion_log"
echo " " | tee -a "$general_log" | tee -a "$conclusion_log"

echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$general_log"
echo "$MESSAGE" | tee -a "$general_log" | tee -a "$conclusion_log"
echo " " | tee -a "$general_log" | tee -a "$conclusion_log"

echo "-----------------------------------------------------------" | tee -a "$general_log"
echo "Best of luck on your upgrade journey! Bon voyage! 👋" | tee -a "$general_log"
echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$general_log"
echo "-----------------------------------------------------------" | tee -a "$general_log"

exit 0