#!/bin/bash

# Define the directory where the log files are located
LOG_DIR="/usr/local/muc"

# Find the most recent log file that matches the pattern
LOG_FILE=$(ls -1t "${LOG_DIR}/macupgradechaperone.error_"*.log 2>/dev/null | head -n 1)

# Check if a file was found
if [[ -f "$LOG_FILE" ]]; then
  # Output the contents of the file wrapped in <result> tags
  echo "<result>$(cat "$LOG_FILE")</result>"
else
  # If no file was found, return an error message
  echo "<result>No log file found</result>"
fi