#!/bin/bash

# -----------------------------------------------------
# Name: muc_EA_conclusion.sh
# Description: Jamf Pro Extension Attribute to report errors discovered by MacUpgradeChaperone into device inventory
# Author: Stu McDonald
# Created: 14-09-24
# -----------------------------------------------------
# Version: 0.6
# Modified: 24-03-25
# -----------------------------------------------------


# Directory containing the log files
log_dir="/usr/local/muc"

# Find the most recent log file that matches the pattern
conclusion_log=$(ls -1t "${LOG_DIR}/macupgradechaperone.conclusion_"*.log 2>/dev/null | head -n 1)

# Check if a file was found
if [[ -f "$conclusion_log" ]]; then
  # Output the contents of the file wrapped in <result> tags
  echo "<result>$(cat "$conclusion_log")</result>"
else
  # If no file was found, return an error message
  echo "<result>No conclusion log found within directory '$log_dir'</result>"
fi