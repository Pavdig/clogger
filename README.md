# Clogger (Cron Logger)

## Overview
**Clogger** is a small utility script designed to manage and log `cron` jobs. It acts as a wrapper around standard Linux commands, capturing `stdout` and `stderr` into timestamped daily log files.

## 🚀 Features

- **Interactive Menu:** Manage jobs via a visual menu (List, Add, Edit, Remove).
- **Dual Mode:** Works as both an interactive manager and a command-line wrapper.
- **Output Control:** Choose to capture full command output (`stdout`/`stderr`) or run silently (logging only start/finish status).
- **Timestamping:** Injects `[YYYY-MM-DD HH:MM:SS]` into every line of output.
- **Daily Rotation & Retention:** Automatically rotates daily logs and deletes files older than 30 days.
- **Root Awareness:** When run as root, allows specifying a different owner for the generated log files (e.g., `user:group`), defaulting to the `SUDO_USER`.

## 🛠️ Installation

1. **Clone the repo:**
   ```bash
   git clone https://github.com/Pavdig/clogger.git
   cd clogger
2. **Make executable:**
   ```bash
   chmod +x cron_logger.sh
   ```
3. **Run:**
   ```bash
   ./cron_logger.sh
   ```

## 📖 Usage

### 1. Interactive Mode (Recommended)
Run the script without arguments to open the menu. This allows you to manage schedules visually.

```bash
./cron_logger.sh
```
*   **List:** View all cron jobs managed by Clogger.
*   **Add:** Step-by-step wizard to create a new job, including options for log capturing.
*   **Edit:** Modify existing jobs (preserves current values for easy editing).
*   **Remove:** Safely delete jobs from crontab.

### 2. Wrapper Mode (Standard)
Used internally by cron, but can be run manually.

```bash
./cron_logger.sh <LOG_PATH_PREFIX> "<COMMAND>" [USER:GROUP] [CAPTURE_OUTPUT]
```
*   **Arguments:**
    *   `LOG_PATH_PREFIX`: Path to log directory + filename prefix.
    *   `COMMAND`: The actual command to run.
    *   `USER:GROUP`: (Optional) Ownership of the log file.
    *   `CAPTURE_OUTPUT`: (Optional) `true` (default) or `false`.

*   **Example (Verbose):**
    ```bash
    ./cron_logger.sh /home/user/logs/backup "tar -czf..." user:user true
    ```
*   **Example (Silent - only log start/finish):**
    ```bash
    ./cron_logger.sh /home/user/logs/backup "tar -czf..." user:user false
    ```

### 3. Failsafe Mode (Quick)
If you only provide a command, Clogger saves logs to a default folder in the current directory.

```bash
./cron_logger.sh "<COMMAND>"
```

## 🛟 Help
To see a quick usage guide:

```bash
./cron_logger.sh --help
```

## 📂 Configuration
The log retention period is defined in the script header:
```bash
RETENTION_DAYS=30
```

## Requirements
- Bash
- Awk
- Crontab