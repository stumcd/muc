#!/bin/bash

# -----------------------------------------------------
# Name: muc_EA_issue.sh
# Description: Jamf Pro Extension Attribute to report issues discovered by MacUpgradeChaperone into device inventory
# Author: Stu McDonald
# Created: 14-09-24
# -----------------------------------------------------
# Version: 0.6
# Modified: 25-03-24
# -----------------------------------------------------

# Directory containing the log files
log_dir="/usr/local/muc"

# Find the most recent log file that matches the pattern
issue_log=$(ls -1t "${log_dir}/macupgradechaperone_"*.issue.log 2>/dev/null | head -n 1)

# Check if a file was found
if [[ -f "$issue_log" ]]; then
  # Output the contents of the file wrapped in <result> tags
  echo "<result>$(cat "$issue_log")</result>"
else
  # If no file was found, return an error message
  echo "<result>No issue log found within directory '$log_dir'</result>"
fi