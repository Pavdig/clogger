#!/bin/bash
# ===================
# --- Cron Logger ---
# ===================

#SCRIPT_VERSION=v0.0.2.3

set -o pipefail

# --- Input Validation ---
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <log_path_prefix> <command> [owner]"
    exit 1
fi

LOG_DIR=$(dirname "$1")
LOG_FILE_PREFIX=$(basename "$1")
COMMAND_TO_RUN="$2"
LOG_OWNER="${3:-root:root}"
RETENTION_DAYS=${RETENTION_DAYS:-30} # Allow env var override, default to 30

mkdir -p "$LOG_DIR"

LOG_FILE="${LOG_DIR}/${LOG_FILE_PREFIX}-$(date +'%Y-%m-%d').log"

log_message() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_message "--- Job Started: $COMMAND_TO_RUN ---"

# --- Execute Command ---
{ eval "$COMMAND_TO_RUN"; } 2>&1 | awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> "$LOG_FILE"
CMD_EXIT_CODE=${PIPESTATUS[0]}

if [ $CMD_EXIT_CODE -eq 0 ]; then
    log_message "--- Job Finished Successfully ---"
else
    log_message "--- Job Failed with Exit Code: $CMD_EXIT_CODE ---"
fi

# --- Cleanup / Rotation ---
# Redirecting stderr to /dev/null for find to keep cron emails clean if dir is empty
find "$LOG_DIR" -name "${LOG_FILE_PREFIX}-*.log" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null

# --- Permissions ---
if [ "$(id -u)" -eq 0 ]; then
    chown "$LOG_OWNER" "$LOG_FILE"
fi

# --- Exit with the actual command status ---
exit $CMD_EXIT_CODE
