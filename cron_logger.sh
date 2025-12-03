#!/bin/bash
# ====================
# Cron Logger v0.0.2.2
# ====================

set -e
set -o pipefail

LOG_DIR=$(dirname "$1")
LOG_FILE_PREFIX=$(basename "$1")
COMMAND_TO_RUN="$2"
LOG_OWNER="${3:-root:root}"
RETENTION_DAYS=30

mkdir -p "$LOG_DIR"

LOG_FILE="${LOG_DIR}/${LOG_FILE_PREFIX}-$(date +'%Y-%m-%d').log"

log_message() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_message "--- Job Started: $COMMAND_TO_RUN ---"

eval "$COMMAND_TO_RUN" 2>&1 | awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> "$LOG_FILE"

log_message "--- Job Finished ---"

find "$LOG_DIR" -name "${LOG_FILE_PREFIX}-*.log" -type f -mtime +$RETENTION_DAYS -delete

if [ "$(id -u)" -eq 0 ]; then
    chown "$LOG_OWNER" "$LOG_FILE"
fi
