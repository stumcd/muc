#!/bin/bash
# -----------------------------------------------------
# Script Name: MacUpgradeChaperone.sh
# Description: This script will guide you to the best upgrade method for the host Mac
# Author: Stu McDonald
# Created: 14-09-24
# -----------------------------------------------------
# Version: 0.51
# Date: 05-12-24
# -----------------------------------------------------

#### Pre-Run Setup & Checks

## Check if the script is running as sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "Sorry, this script must be run as root. Sudo bang bang!" >&2
    exit 1
fi

## Set the target version
# Jamf Pro script parameters
targetOS=$4

# Hardcoded value for testing
# targetOS="macOS Sonoma"

# Get the current timestamp (format: YYYYMMDD_HHMMSS)
timestamp=$(date +"%Y%m%d_%H%M%S")
#echo "$timestamp" | tee -a "$log_file"

## Define the directory for the log file and error log
log_dir="/usr/local/muc"

## Create the directory if it doesn't exist
if [ ! -d "$log_dir" ]; then
  echo "The directory $log_dir does not exist. Creating it now..."
  sudo mkdir -p "$log_dir"
  sudo chown $(whoami) "$log_dir"  # Ensure the current user has ownership
fi

## Write to a new log file for each run, appended with timestamp
log_file="$log_dir/macupgradechaperone_${timestamp}.log"

## Write to a new error log file for each run, appended with timestamp
error_log="$log_dir/macupgradechaperone.error_${timestamp}.log"

#### Step 1 - let's check stuff

## Log start time
# echo "Target macOS Version is: $targetOS"
echo "========= 🖥️ 🤵 Mac Upgrade Chaperone 🤵 🖥️ =========" | tee -a "$log_file"
if [[ -n "$targetOS" ]]; then
	echo "== Jamf Pro Script parameter detected! macOS target version: $targetOS"
    echo "🎯 macOS Version: $targetOS (via Jamf Pro policy parameters 🎉)"    
else
    echo "== ⚠️  macOS target version has not specified, defaulting to latest major version"
    targetOS="macOS Sonoma"
    echo "🎯 macOS target version default: $targetOS"
fi
echo "-------------------------" | tee -a "$log_file"
echo "----- Guiding your journey to... ✨ $targetOS ✨" | tee -a "$log_file"


echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$log_file" 
echo "-------------------------" | tee -a "$log_file"
echo "⚙️  Checking MDM profile and Bootstrap Token..." | tee -a "$log_file"

#### MDM checks
# Check if there's an MDM profile installed

mdm_profile=$(profiles status -type enrollment 2>&1)
if [[ "$mdm_profile" == *"MDM enrollment: Yes"* ]]; then
  echo "--- ✅ MDM Profile: Installed"  | tee -a "$log_file"
  mdmUrl=$(profiles -e | grep "ConfigurationURL" | awk '{print $3}' | tr -d ';"' | sed 's|/cloudenroll$||')
else
  echo "--- ❌ MDM Profile not present. This device is NOT managed." | tee -a "$log_file" | tee -a "$error_log"
fi

# Check if MDM profile is removable 
mdm_profile_removeable=$(profiles -e | grep "IsMDMUnremovable" | awk '{print $3}' | tr -d ';')
if [[ ${mdm_profile_removeable} = '1' ]]; then
	echo "--- ✅ MDM profile is NOT removable." | tee -a "$log_file"
else
	if [[ ${mdm_profile_removeable} = '0' ]]; then
		echo "--- ⚠️  MDM Profile is removable." | tee -a "$log_file"
	fi
fi

### add:
### check expiry on MDM cert


### Check connection to JSS
echo "--- Checking connection to MDM Server..." | tee -a "$log_file" 

# this needs to fail gracefully if there's no connectivity
# using cURL is probably better than using the jamf binary w checkJSSConnection... 

mdmServerStatus=$(jamf checkJSSConnection)

# Check if the connection was successful
  if echo "$mdmServerStatus" | grep -q "The JSS is available"; then
    echo "--- ✅ Jamf Pro Server is reachable. URL: $mdmUrl"
  else
    echo "❌ Unable to connect to the Jamf Pro Server."
    echo "Details: $mdmServerStatus"
  fi

# Check if Bootstrap Token has been escrowed
if profiles status -type bootstraptoken | grep -q "Bootstrap Token escrowed to server: YES"; then
    echo "--- ✅ Bootstrap Token: Escrowed" | tee -a "$log_file"
else
    echo "--- ❌ Bootstrap Token NOT Escrowed" | tee -a "$log_file" | tee -a "$error_log"
fi

#### Disk checks

echo "🧐 Checking for unusual disk volumes..." | tee -a "$log_file"

# Check for "Macintosh HD"
volume_check=$(diskutil list | grep "Macintosh HD")

if [ -n "$volume_check" ]; then
  echo "--- ✅ Found a volume named 'Macintosh HD'." | tee -a "$log_file"
else
  echo "--- ⚠️ There is no volume present named 'Macintosh HD'." | tee -a "$log_file" | tee -a "$error_log"
fi

# Check for Recovery volume
recovery_volume_check=$(diskutil list | grep "Recovery")
if [ -n "$recovery_volume_check" ]; then
  echo "--- ✅ Found a volume named 'Recovery'." | tee -a "$log_file"
else
  echo "--- ⚠️ Could not find a 'Recovery' volume. " | tee -a "$log_file" | tee -a "$error_log"
fi

echo "📏 Checking available space..." | tee -a "$log_file"

# Check available space
available_space=$(df / | tail -1 | awk '{print $4}')

# Convert available space from 1K blocks to GB (divide by 1,048,576)
available_space_gb=$((available_space / 1048576))

if [ "$available_space_gb" -ge 20 ]; then
  echo "--- ✅ There is enough free space (20 GB required, $available_space_gb GB available)." | tee -a "$log_file"
else
  echo "--- ❌ There is not enough free space on disk ($available_space_gb GB available, 20 GB required)." | tee -a "$log_file" | tee -a "$error_log"
fi

#### Retrieve and display hardware info

echo "🖥  Mac hardware:" | tee -a "$log_file"

hardware_name=$(system_profiler SPHardwareDataType | awk -F ": " '/Model Name/ {print $2}')
hardware_modelidentifier=$(system_profiler SPHardwareDataType | awk '/Model Identifier/ {print $3}')
hardware_chip=$(system_profiler SPHardwareDataType | awk -F ": " '/Chip/ {print $2}')
hardware_serial=$(system_profiler SPHardwareDataType | awk -F ": " '/Serial Number/ {print $2}')

# Display hardware info
echo "- Model: $hardware_name" | tee -a "$log_file"
echo "- Model Identifier: $hardware_modelidentifier" | tee -a "$log_file"
echo "- Chip: $hardware_chip" | tee -a "$log_file"
echo "- Serial: $hardware_serial" | tee -a "$log_file"

#### Check compatibility

# Define an array of compatible models
compatible_models=(
  "MacBookAir8,1"  # MacBook Air (2018)
  "MacBookAir9,1"  # MacBook Air (2019)
  "MacBookAir10,1" # MacBook Air (M1, 2020)
  "MacBookAir14,2" # MacBook Air (M2, 2022)
  "MacBookAir14,15" # MacBook Air (M2, 2022, 15-inch)

  "MacBookPro15,1" # MacBook Pro (2018, 13-inch)
  "MacBookPro15,2" # MacBook Pro (2018, 15-inch)
  "MacBookPro15,3" # MacBook Pro (2019, 13-inch)
  "MacBookPro15,4" # MacBook Pro (2019, 15-inch)
  "MacBookPro16,1" # MacBook Pro (2020, 13-inch)
  "MacBookPro16,2" # MacBook Pro (2020, 13-inch)
  "MacBookPro16,3" # MacBook Pro (2020, 16-inch)
  "MacBookPro17,1" # MacBook Pro (M1, 2020, 13-inch)
  "MacBookPro18,1" # MacBook Pro (M1 Pro, 2021, 14-inch)
  "MacBookPro18,2" # MacBook Pro (M1 Pro, 2021, 16-inch)
  "MacBookPro18,3" # MacBook Pro (M1 Max, 2021, 14-inch)
  "MacBookPro18,4" # MacBook Pro (M1 Max, 2021, 16-inch)
  "MacBookPro15,6" # MacBook Pro (2019, 16-inch)

  "Macmini8,1"     # Mac mini (2018)
  "Macmini9,1"     # Mac mini (M1, 2020)

  "Mac14,3"        # Mac Studio (M1 Max, 2022)
  "Mac14,12"       # Mac Studio (M1 Ultra, 2022)

  "iMac19,1"       # iMac (2019, 21.5-inch)
  "iMac19,2"       # iMac (2019, 27-inch)
  "iMac20,1"       # iMac (2020, 21.5-inch)
  "iMac20,2"       # iMac (2020, 27-inch)
  "iMac21,1"       # iMac (M1, 2021, 24-inch)
  "iMac21,2"       # iMac (M1, 2021, 24-inch)

  "iMacPro1,1"     # iMac Pro (2017)

  "MacPro7,1"      # Mac Pro (2019)
  "Mac14,8"        # Mac Pro (2022)

  "MacStudio1,1"   # Mac Studio (2022)
  "MacStudio1,2"   # Mac Studio (2022)
  "Mac13,1"        # Mac Studio (M1 Max, 2022)
  "Mac13,2"        # Mac Studio (M1 Ultra, 2022)
  "Mac14,13"       # Mac Studio (M2 Max, 2023)
  "Mac14,14"       # Mac Studio (M2 Ultra, 2023)
  "Mac14,7"        # Mac Studio (M2, 2023)
  "Mac14,9"        # Mac Studio (M2, 2023)
  
  "Mac14,5"        # MacBook Air (M2, 2022)
  "Mac14,10"       # MacBook Pro (M2, 2023)
  "Mac14,6"        # MacBook Pro (M2 Pro, 2023)
  "Mac15,3"        # MacBook Pro (M2 Pro, 2023, 14-inch)
  "Mac15,6"        # MacBook Pro (M2 Pro, 2023, 16-inch)
  "Mac15,10"       # MacBook Pro (M2 Max, 2023, 14-inch)
  "Mac15,8"        # MacBook Pro (M2 Max, 2023, 16-inch)
  "Mac15,7"        # MacBook Pro (M2, 2023)
  "Mac15,11"       # MacBook Pro (M2, 2023)
  "Mac15,9"        # MacBook Pro (M2, 2023)
)

# Check if the hardware model is in the list of compatible models
if [[ " ${compatible_models[@]} " =~ " $hardware_modelidentifier " ]]; then
    echo "--- ✅ Compatible with $targetOS" | tee -a "$log_file"
else
    echo "NOT compatible with $targetOS. ❌" | tee -a "$log_file" | tee -a "$error_log"
fi

if [ "$(uname -m)" = "arm64" ]; then
  echo "--- ✅ Architecture: Apple silicon" | tee -a "$log_file"
else
  echo "--- ⚠️ A️rchitecture: Intel️" | tee -a "$log_file"
fi

echo "🖥  Checking existing macOS installation" | tee -a "$log_file"

macos_version=$(sw_vers -productVersion)
major_version=$(echo "$macos_version" | cut -d '.' -f 1)

echo "--- Installed macOS version: $macos_version." | tee -a "$log_file"

if [ "$major_version" -ge 11 ]; then
  echo "--- ✅ $macos_version can upgrade to $targetOS" | tee -a "$log_file"
else
  echo "--- ❌ Installed macOS version ($macos_version) can't upgrade to $targetOS'." | tee -a "$log_file" | tee -a "$error_log"
fi

#### Step 2 - let's determine the best pathway forward
#### Check the error log and based on what we found, display a dialog recommending an upgrade method 

echo "System checks complete." | tee -a "$log_file"
echo "-------------------------" | tee -a "$log_file"
echo "Calculating the best upgrade path & reticulating splines.." | tee -a "$log_file"

# Check if the error_log file is non-empty
if [ -s "$error_log" ]; then

# Read the contents of the error_log file
	error_messages=$(cat "$error_log" | sed 's/"/\\"/g')  # Escape double quotes
 
# Display dialog: bad news - Nuke and Pave
	nukeandpave="Unfortunately, the best option for this Mac is to erase and reinstall macOS, using either Internet Recovery, Bootable USB, or Apple Configurator 2. "
	echo "$nukeandpave" | tee -a "$log_file"
    osascript -e "tell application \"System Events\" to display dialog \"$nukeandpave\n\nIssues detected:\n$error_messages\" buttons {\"OK\"} default button \"OK\" with title \"Time to nuke and pave 🎉\""
else

# Display dialog: Best case scenario - MDM
    success_message="Congratulations, you can upgrade this Mac using an MDM command."
    echo "$success_message" | tee -a "$log_file"
    osascript -e "tell application \"System Events\" to display dialog \"${success_message}\" buttons {\"OK\"} default button \"OK\" with title \"No issues detected 🎉\""
fi


#### End
echo "Good luck on your upgrade journey! Bon voyage! 👋" | tee -a "$log_file"
echo "Finished: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$log_file"
echo "=========================================" | tee -a "$log_file"
exit 0
