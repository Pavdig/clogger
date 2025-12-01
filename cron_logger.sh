#!/bin/bash
# ====================
# Cron Logger v0.0.2
# ====================

set -e
set -o pipefail

# --- Cosmetics ---
C_RED=$'\e[0;31m'
C_LIGHT_RED=$'\e[1;31m'
C_GREEN=$'\e[0;32m'
C_YELLOW=$'\e[1;33m'
C_CYAN=$'\e[0;36m'
C_GRAY=$'\e[90m'
C_RESET=$'\e[0m'

LOG_DIR=$(dirname "$1")
LOG_FILE_PREFIX=$(basename "$1")
COMMAND_TO_RUN="$2"
LOG_OWNER="${3:-pavdig:pavdig}"
RETENTION_DAYS=30

mkdir -p "$LOG_DIR"

LOG_FILE="${LOG_DIR}/${LOG_FILE_PREFIX}-$(date +'%Y-%m-%d').log"

log_message() {
    echo -e "${C_CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] ${C_RESET}$1" >> "$LOG_FILE"
}

log_message "${C_YELLOW}--- ${C_CYAN}Job Started:${C_RESET} $COMMAND_TO_RUN ${C_YELLOW}---${C_RESET}"

eval "$COMMAND_TO_RUN" 2>&1 | awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> "$LOG_FILE"

log_message "${C_YELLOW}--- ${C_GREEN}Job Finished ${C_YELLOW}---${C_RESET}"

find "$LOG_DIR" -name "${LOG_FILE_PREFIX}-*.log" -type f -mtime +$RETENTION_DAYS -delete

if [ "$(id -u)" -eq 0 ]; then
    chown "$LOG_OWNER" "$LOG_FILE"
fi
