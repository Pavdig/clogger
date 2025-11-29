#!/bin/bash
# ======================================================================================
# Cron Logger v0.0.1
# ======================================================================================

# A generic script to run a command and log its output with timestamps.
# Usage: ./cron_logger.sh LOG_FILE_PREFIX "COMMAND_TO_RUN"

# Exit if any command fails
set -e

LOG_DIR=$(dirname "$1")
LOG_FILE_PREFIX=$(basename "$1")
COMMAND_TO_RUN=$2
LOG_OWNER="pavdig:pavdig"

# Ensure the log directory exists
mkdir -p "$LOG_DIR"

# Define the final log file with today's date
LOG_FILE="${LOG_DIR}/${LOG_FILE_PREFIX}-$(date +'%Y-%m-%d').log"

# Run the command, pipe its output to be timestamped, and append to the log file
eval "$COMMAND_TO_RUN" 2>&1 | while IFS= read -r line; do
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $line"
done >> "$LOG_FILE"

# Set correct ownership on the log file
chown "$LOG_OWNER" "$LOG_FILE"
