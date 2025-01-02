#!/bin/bash

# -----------------------------------------------------
# Name: muc_EA.sh
# Description: Jamf Pro Extension Attribute to display results from MacUpgradeChaperone in your device inventory
# Author: Stu McDonald
# Created: 14-09-24
# -----------------------------------------------------
# Version: 0.6
# Modified: 02-01-25
# -----------------------------------------------------


# Define the directory where the log files are located
LOG_DIR="/usr/local/muc"

# Find the most recent log file that matches the pattern
ERROR_LOG=$(ls -1t "${LOG_DIR}/macupgradechaperone.error_"*.log 2>/dev/null | head -n 1)

# Check if a file was found
if [[ -f "$ERROR_LOG" ]]; then
  # Output the contents of the file wrapped in <result> tags
  echo "<result>$(cat "$ERROR_LOG")</result>"
else
  # If no file was found, return an error message
  echo "<result>No issues detected. 🎉</result>"
fi