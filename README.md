# Clogger (Cron Logger)

**Version:** 0.0.2.1

## Overview
**Clogger** is a utility script designed to wrap around standard Linux commands—specifically those run via `cron`. Instead of output disappearing or being mailed to root, Clogger captures `stdout` and `stderr`, prefixes every line with a timestamp, and saves it to a daily log file.

It also handles "housekeeping" by deleting logs older than 30 days and fixing file permissions if run as root.

## Features
- **Timestamping:** Uses `awk` to inject a timestamp `[YYYY-MM-DD HH:MM:SS]` into every line of the command's output.
- **Daily Rotation:** Automatically creates a new log file for each day (e.g., `backup-2025-12-02.log`).
- **Retention Policy:** Automatically deletes log files older than 30 days.
- **Visuals:** Adds colored start/end markers to the log for better readability.
- **Permissions:** Can enforce specific User:Group ownership on the generated log file (useful when the cron job runs as root but you want to read logs as a normal user).

## Installation
Ensure the script is executable:

```bash
chmod +x cron_logger.sh
```

## Usage

```bash
./cron_logger.sh <LOG_PATH_PREFIX> "<COMMAND_TO_RUN>" [USER:GROUP]
```

### Arguments

1. **LOG_PATH_PREFIX**: The full path including the desired filename prefix.
   - Example: `/home/user/logs/myjob/backup` will create logs inside `/home/user/logs/myjob/` named `backup-YYYY-MM-DD.log`.
2. **COMMAND_TO_RUN**: The actual command you want to execute.
   - **Important:** Wrap this in double quotes `"`.
3. **USER:GROUP** *(Optional)*: The owner of the log file. Defaults to `root:root` if skipped.

## Examples

### 1. Simple Manual Test
Run a Docker pull command and log it to your logs directory:

```bash
./cron_logger.sh /home/user/logs/docker_updates "docker compose pull" user:user
```

### 2. Crontab Usage
To run a backup script every day at 3 AM and keep the logs tidy:

```bash
0 3 * * * /home/user/scripts/clogger/cron_logger.sh /home/user/logs/backups/daily_backup "/home/user/scripts/dtools/backup_script.sh" user:user
```

## Configuration
The log retention period is currently hardcoded in the script. To change it, edit the `RETENTION_DAYS` variable near the top of the file:

```bash
RETENTION_DAYS=30
```

## Requirements
- Bash
- Awk
