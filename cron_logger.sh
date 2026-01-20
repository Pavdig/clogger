#!/bin/bash
# ===================
# --- Cron Logger ---
# ===================

SCRIPT_VERSION=v0.0.5

SCRIPT_PATH=$(readlink -f "$0")
DEFAULT_LOG_BASE="${HOME}/logs"

# --- Initialize Terminal Cosmetics ---
if tput setaf 1 > /dev/null 2>&1; then
    C_RED=$(tput setaf 1)
    C_GREEN=$(tput setaf 2)
    C_YELLOW=$(tput setaf 3)
    C_CYAN=$(tput setaf 6)
    T_BOLD=$(tput bold)
    C_GRAY=$(tput bold)$(tput setaf 0)
    C_RESET=$(tput sgr0)
else
    C_RED="" ; C_GREEN="" ; C_YELLOW="" ; C_CYAN="" ; T_BOLD="" ; C_GRAY="" ; C_RESET=""
fi
TICKMARK="${C_GREEN}\xE2\x9C\x93${C_RESET}"

# --- ARGUMENT HANDLING & WRAPPER ---

if [ "$#" -gt 0 ]; then
    
    # Help Menu Check
    case "$1" in
        --help|-h)
            echo "=============================================="
            echo -e " ${C_GREEN}${T_BOLD}clogger ${SCRIPT_VERSION} - Help Menu${C_RESET}"
            echo "=============================================="
            echo -e " ${C_YELLOW}Description:${C_RESET}"
            echo -e "   A lightweight wrapper to log cron job output to files."
            echo
            echo -e " ${C_YELLOW}Usage:${C_RESET}"
            echo -e "   1. ${C_CYAN}Interactive Menu:${C_RESET} Run without arguments."
            echo -e "      ${C_GRAY}./cron_logger.sh${C_RESET}"
            echo
            echo -e "   2. ${C_CYAN}Wrapper Mode:${C_RESET}"
            echo -e "      ${C_GRAY}./cron_logger.sh <log_path> \"<command>\" <owner> [capture_output]${C_RESET}"
            echo "=============================================="
            exit 0
            ;;
    esac

    # 2. Wrapper Logic
    set -o pipefail

    if [ "$#" -ge 2 ]; then
        # Standard Mode: Path provided
        LOG_PATH_PREFIX="$1"
        COMMAND_TO_RUN="$2"
        LOG_OWNER="${3:-$(whoami):$(whoami)}"
        CAPTURE_OUTPUT="${4:-true}"
    else
        # Failsafe Mode: No path provided
        CURRENT_DIR=$(pwd)
        LOG_PATH_PREFIX="${CURRENT_DIR}/clogger-logs"
        COMMAND_TO_RUN="$1"
        LOG_OWNER="$(whoami):$(whoami)"
        CAPTURE_OUTPUT="true"
    fi

    RETENTION_DAYS=${RETENTION_DAYS:-30}

    LOG_DIR=$(dirname "$LOG_PATH_PREFIX")
    LOG_FILE_PREFIX=$(basename "$LOG_PATH_PREFIX")
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    CURRENT_DATE=$(date +'%Y-%m-%d')
    LOG_FILE="${LOG_DIR}/${LOG_FILE_PREFIX}-${CURRENT_DATE}.log"

    log_message() {
        echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    }

    log_message "--- Job Started: $COMMAND_TO_RUN ---"

    if [ "$CAPTURE_OUTPUT" == "false" ]; then
        # Execute silently (discard stdout/stderr)
        eval "$COMMAND_TO_RUN" >/dev/null 2>&1
        CMD_EXIT_CODE=$?
        
        if [ $CMD_EXIT_CODE -eq 0 ]; then
            log_message "--- Job Finished Successfully (Output Discarded) ---"
        else
            log_message "--- Job Failed with Exit Code: $CMD_EXIT_CODE (Output Discarded) ---"
        fi
    else
        # Execute and capture stdout/stderr with timestamps
        { eval "$COMMAND_TO_RUN"; } 2>&1 | awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> "$LOG_FILE"
        CMD_EXIT_CODE=${PIPESTATUS[0]}

        if [ $CMD_EXIT_CODE -eq 0 ]; then
            log_message "--- Job Finished Successfully ---"
        else
            log_message "--- Job Failed with Exit Code: $CMD_EXIT_CODE ---"
        fi
    fi

    # Cleanup Old Logs
    find "$LOG_DIR" -name "${LOG_FILE_PREFIX}-*.log" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null

    # Set Permissions (if running as root but for a user)
    if [ "$(id -u)" -eq 0 ]; then
        chown "$LOG_OWNER" "$LOG_FILE"
    fi

    exit $CMD_EXIT_CODE
fi

# --- INTERACTIVE MENU ---

print_header() {
    clear
    # Context Indicator Logic
    local context_msg
    if [ "$(id -u)" -eq 0 ]; then
        context_msg="${C_RED}${T_BOLD}ROOT (System)\n${C_GRAY}Run script without sudo to edit USER jobs${C_RESET}"
    else
        context_msg="${C_GREEN}${T_BOLD}USER ($(whoami))\n${C_GRAY}Run script with sudo to edit ROOT jobs${C_RESET}"
    fi

    echo "=============================="
    echo -e " ${C_GREEN}${T_BOLD}clogger ${SCRIPT_VERSION} - Job Manager${C_RESET}"
    echo "=============================="
    echo -e " Editing Crontab of: ${context_msg}"
    echo -e "------------------------------\n"
}

get_current_crontab() {
    crontab -l 2>/dev/null || true
}

list_clogger_jobs() {
    print_header
    echo -e "${C_YELLOW}Current Cron ${C_CYAN}Jobs ${C_YELLOW}managed by ${C_GREEN}clogger${C_RESET}:\n"

    local jobs
    jobs=$(get_current_crontab | grep "$SCRIPT_PATH")

    if [ -z "$jobs" ]; then
        echo -e "${C_CYAN}No jobs found pointing to this script.${C_RESET}"
    else
        local count=1
        echo "$jobs" | while read -r line; do
            local sched="${line%%$SCRIPT_PATH*}"
            sched="${sched%"${sched##*[![:space:]]}"}" # Trim trailing space

            # Schedule Naming (Human Readable)
            local sched_name="Custom"
            case "$sched" in
                "* * * * *")   sched_name="Every Minute" ;;
                "*/5 * * * *") sched_name="Every 5 Mins" ;;
                "*/10 * * * *") sched_name="Every 10 Mins" ;;
                "*/15 * * * *") sched_name="Every 15 Mins" ;;
                "*/30 * * * *") sched_name="Every 30 Mins" ;;
                "0 * * * *")   sched_name="Hourly" ;;
                "0 */6 * * *") sched_name="Every 6 Hours" ;;
                "0 */12 * * *") sched_name="Every 12 Hours" ;;
                "0 0 * * *")   sched_name="Daily (Midnight)" ;;
                "0 0 * * 0")   sched_name="Weekly (Sunday)" ;;
                "@daily")      sched_name="Daily" ;;
                "@hourly")     sched_name="Hourly" ;;
                "@reboot")     sched_name="On Reboot" ;;
            esac

            local remainder=${line#*$SCRIPT_PATH }
            local raw_log_arg=$(echo "$remainder" | awk '{print $1}')
            local log_dir=$(dirname "$raw_log_arg")
            local log_prefix=$(basename "$raw_log_arg")
            local log_display="${log_dir}/${C_YELLOW}${log_prefix}-YYYY-MM-DD.log"
            local cmd_part=$(echo "$line" | awk -F '"' '{print $2}')
            local last_arg=$(echo "$line" | awk '{print $NF}')
            local log_info=""
            if [[ "$last_arg" == "false" ]]; then
                log_info="[Log Output: ${C_RED}OFF${C_RESET}]"
            fi

            # Display
            echo -e "${C_CYAN}${count}) ${C_GREEN}[${sched}]${C_RESET} ${C_GRAY}(${sched_name})${C_RESET} ${log_info}"
            echo -e "   Command: ${C_YELLOW}${cmd_part}${C_RESET}"
            echo -e "   Log To:  ${C_GRAY}${log_display}${C_RESET}"
            echo ""
            ((count++))
        done
    fi
    echo -e "${C_RESET}------------------------------"
}

schedule_picker() {
    local -n result_var=$1
    local current_val="${2:-}"

    echo -e "${C_YELLOW}--- Frequency ---${C_RESET}"
    if [ -n "$current_val" ]; then
        echo -e "   0) ${C_CYAN}Keep Current${C_RESET} [${current_val}]"
    fi
    echo "   1) Hourly (0 * * * *)"
    echo "   2) Every 6 hours (0 */6 * * *)"
    echo "   3) Daily at Midnight (0 0 * * *)"
    echo "   4) Daily at 3 AM (0 3 * * *)"
    echo "   5) Weekly (Sunday) (0 0 * * 0)"
    echo "   6) Custom Expression"
    echo ""
    read -p "${C_YELLOW}Select schedule: ${C_RESET}" choice

    case "$choice" in
        0) 
            if [ -n "$current_val" ]; then result_var="$current_val"; else result_var=""; fi ;;
        1) result_var="0 * * * *" ;;
        2) result_var="0 */6 * * *" ;;
        3) result_var="0 0 * * *" ;;
        4) result_var="0 3 * * *" ;;
        5) result_var="0 0 * * 0" ;;
        6) 
            read -p "${C_CYAN}Enter cron expression ${C_GRAY}(e.g. '@daily')${C_RESET}: " custom
            result_var="$custom" 
            ;;
        *) result_var="" ;;
    esac
}

sanitize_command_input() {
    local input="$1"
    if [[ "$input" == *"\"\""* ]]; then
        echo -e "${C_YELLOW}Warning: Double quotes (\"\") detected in command.${C_RESET}"
        echo -e "${C_CYAN}-> Auto-fixing to single quotes (...\"...)...${C_RESET}"
        input="${input//\"\"/\"}"
    fi
    echo "$input"
}

add_job() {
    print_header
    echo -e "${C_GREEN}--- Add New Job ---${C_RESET}"

    # Get Command
    echo -e "\n${C_YELLOW}Enter a path to script or command to run:${C_RESET}"
    echo -e "${C_GRAY}(e.g., /home/user/scripts/backup.sh)${C_RESET}"
    echo -e "${C_GRAY}(      /usr/sbin/fstrim -av        )${C_RESET}"
    read -e -p "> " cmd_input
    if [ -z "$cmd_input" ]; then echo -e "${C_RED}Aborted.${C_RESET}"; sleep 1; return; fi
    cmd_input=$(sanitize_command_input "$cmd_input")

    # Get Log Location
    echo -e "\n${C_YELLOW}Enter the directory to save logs:${C_RESET}"
    read -e -i "$DEFAULT_LOG_BASE" -p "> " target_log_dir
    target_log_dir=${target_log_dir%/}

    echo -e "\n${C_YELLOW}Enter filename prefix for this log:${C_RESET}"
    read -e -p "> " log_name
    if [ -z "$log_name" ]; then echo -e "${C_RED}Aborted.${C_RESET}"; sleep 1; return; fi
    log_name=$(echo "$log_name" | tr -dc 'a-zA-Z0-9_-')
    local full_log_path="${target_log_dir}/${log_name}"

    # Get Owner (Root only)
    local job_owner
    job_owner=$(whoami)
    if [ "$(id -u)" -eq 0 ]; then
        local detected_user="${SUDO_USER:-root}"
        echo -e "\n${C_YELLOW}Enter the username who should own the log files:${C_RESET}"
        read -e -i "$detected_user" -p "> " job_owner
    fi

    # Get Capture Preference
    echo -e "\n${C_YELLOW}Capture command output (stdout/stderr) in logs?${C_RESET}"
    echo -e "${C_GRAY}(Y = Verbose / N = Only start/finish timestamps)${C_RESET}"
    read -p " (Y/N) > " cap_choice
    local cap_flag="true"
    if [[ "$cap_choice" =~ ^[Nn] ]]; then cap_flag="false"; fi

    # Get Schedule
    echo ""
    local schedule_str
    schedule_picker schedule_str
    if [ -z "$schedule_str" ]; then echo -e "${C_RED}Invalid schedule.${C_RESET}"; sleep 1; return; fi

    # Construct Cron Line
    # Format: SCHEDULE SCRIPT LOG "CMD" OWNER CAPTURE_FLAG
    local cron_line="${schedule_str} ${SCRIPT_PATH} ${full_log_path} \"${cmd_input}\" ${job_owner} ${cap_flag}"

    echo -e "\n${C_CYAN}Adding the following job:${C_RESET}"
    echo -e " ${cron_line}\n"
    read -p "${C_YELLOW}Confirm? ${C_RESET}(${C_GREEN}y${C_RESET}/${C_RED}N${C_RESET}): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        (get_current_crontab; echo "$cron_line") | crontab -
        echo -e "\n${TICKMARK} ${C_GREEN}Job added successfully.${C_RESET}"
    else
        echo -e "\n${C_RED}Cancelled.${C_RESET}"
    fi
    sleep 2
}

edit_job() {
    list_clogger_jobs
    local jobs
    jobs=$(get_current_crontab | grep "$SCRIPT_PATH")
    
    if [ -z "$jobs" ]; then
        read -p "Press Enter to return..."
        return
    fi

    echo -e "${C_YELLOW}Enter the ${C_CYAN}number ${C_YELLOW}of the job to ${C_CYAN}EDIT ${C_GRAY}(or 'q' to cancel)${C_YELLOW}:${C_RESET}"
    read -p "> " choice

    if [[ "$choice" == "q" ]]; then return; fi

    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        local line_to_edit
        line_to_edit=$(echo "$jobs" | sed -n "${choice}p")
        
        if [ -z "$line_to_edit" ]; then
            echo -e "\n${C_RED}Invalid number.${C_RESET}"; sleep 1; return
        fi
        
        # Parsing Existing Line
        local current_sched=${line_to_edit%%$SCRIPT_PATH*}
        current_sched=$(echo "$current_sched" | sed 's/ *$//')
        local remainder=${line_to_edit#*$SCRIPT_PATH } 
        local current_log_path=${remainder%% \"*} 
        current_log_path=$(echo "$current_log_path" | sed 's/ *$//')
        local current_cmd=$(echo "$line_to_edit" | awk -F '"' '{print $2}')
        # Extract Args after command: Owner and Capture Flag
        local after_cmd=$(echo "$line_to_edit" | awk -F '"' '{print $3}')
        local current_owner=$(echo "$after_cmd" | awk '{print $1}')
        local current_cap=$(echo "$after_cmd" | awk '{print $2}')

        [ -z "$current_owner" ] && current_owner=$(whoami)
        [ -z "$current_cap" ] && current_cap="true" # Default for old version jobs

        echo -e "\n${C_CYAN}--- Editing Job ---${C_RESET}"

        #  Edit Command
        echo -e "${C_YELLOW}Command:${C_RESET}"
        read -e -i "$current_cmd" -p "> " new_cmd
        new_cmd=$(sanitize_command_input "$new_cmd")

        # Edit Log Path
        echo -e "${C_YELLOW}Log Directory:${C_RESET}"
        local current_log_dir=$(dirname "$current_log_path")
        local current_log_name=$(basename "$current_log_path")
        read -e -i "$current_log_dir" -p "> " new_log_dir
        new_log_dir=${new_log_dir%/}
        
        echo -e "${C_YELLOW}Log Name Prefix:${C_RESET}"
        read -e -i "$current_log_name" -p "> " new_log_name
        new_log_name=$(echo "$new_log_name" | tr -dc 'a-zA-Z0-9_-')
        local new_full_log_path="${new_log_dir}/${new_log_name}"

        # Edit Owner
        local new_owner="$current_owner"
        if [ "$(id -u)" -eq 0 ]; then
            echo -e "${C_YELLOW}Log Owner:${C_RESET}"
            read -e -i "$current_owner" -p "> " new_owner
        fi
        
        # Edit Capture Flag
        echo -e "${C_YELLOW}Capture Output ${C_GRAY}(Current: ${current_cap}):${C_RESET}"
        read -p " ${C_RESET}(${C_GREEN}y${C_RESET}/${C_RED}N${C_RESET}/${C_CYAN}Enter ${C_GRAY}to keep current) ${C_RESET}> " cap_input
        local new_cap="$current_cap"
        if [[ "$cap_input" =~ ^[Nn] ]]; then new_cap="false"; fi
        if [[ "$cap_input" =~ ^[Yy] ]]; then new_cap="true"; fi

        # 5. Edit Schedule
        echo ""
        local new_sched
        schedule_picker new_sched "$current_sched"
        if [ -z "$new_sched" ]; then echo -e "${C_RED}Invalid schedule.${C_RESET}"; sleep 1; return; fi
        
        # --- Construct New Line ---
        local new_cron_line="${new_sched} ${SCRIPT_PATH} ${new_full_log_path} \"${new_cmd}\" ${new_owner} ${new_cap}"
        
        if [ "$line_to_edit" == "$new_cron_line" ]; then
             echo -e "\n${C_GRAY}No changes made.${C_RESET}"; sleep 1; return
        fi
        
        echo -e "\n${C_CYAN}Updating job to:${C_RESET}\n"
        echo -e " ${new_cron_line}\n"
        read -p "${C_YELLOW}Confirm update? ${C_RESET}(${C_GREEN}y${C_RESET}/${C_RED}N${C_RESET}): " confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            get_current_crontab | grep -F -v "$line_to_edit" | (cat; echo "$new_cron_line") | crontab -
            echo -e "\n${TICKMARK} ${C_GREEN}Job updated successfully.${C_RESET}"
        else
            echo -e "\n${C_RED}Cancelled.${C_RESET}"
        fi
        sleep 2
    else
        echo -e "\n${C_RED}Invalid input.${C_RESET}"
        sleep 1
    fi
}

remove_job() {
    list_clogger_jobs
    local jobs
    jobs=$(get_current_crontab | grep "$SCRIPT_PATH")
    
    if [ -z "$jobs" ]; then
        read -p "Press Enter to return..."
        return
    fi

    echo -e "${C_YELLOW}Enter the number of the job to DELETE ${C_GRAY}(or 'q' to cancel)${C_YELLOW}:${C_RESET}"
    read -p "> " choice

    if [[ "$choice" == "q" ]]; then return; fi

    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        local line_to_remove
        line_to_remove=$(echo "$jobs" | sed -n "${choice}p")
        
        if [ -n "$line_to_remove" ]; then
            get_current_crontab | grep -F -v "$line_to_remove" | crontab -
            echo -e "\n${TICKMARK} ${C_GREEN}Job removed.${C_RESET}"
        else
            echo -e "\n${C_RED}Invalid number.${C_RESET}"
        fi
    else
        echo -e "\n${C_RED}Invalid input.${C_RESET}"
    fi
    sleep 2
}

# --- Main Loop ---

while true; do
    print_header
    echo -e " Options:"
    echo -e " 1) ${C_YELLOW}List active jobs${C_RESET}"
    echo -e " 2) ${C_GREEN}Add new job${C_RESET}"
    echo -e " 3) ${C_CYAN}Edit job${C_RESET}"
    echo -e " 4) ${C_RED}Remove job${C_RESET}"
    echo -e "------------------------------"
    echo -e " ${C_RED}(Q)uit${C_RESET}"
    echo ""
    read -p "Select option: " opt

    case "$opt" in
        1) list_clogger_jobs; echo; read -p "Press Enter to continue..." ;;
        2) add_job ;;
        3) edit_job ;;
        4) remove_job ;;
        [qQ]) clear; exit 0 ;;
        *) echo -e "${C_RED}Invalid option${C_RESET}"; sleep 1 ;;
    esac
done
