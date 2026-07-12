#!/bin/bash
# ==========================================
# S.M.A.R.T - System Monitoring And Resource Toolkit
# CSE 324 - Final Version
# Team: Urmi, Mahim, Nayeem, Jisan, Iftee
# ==========================================

# Color codes
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RESET="\e[0m"

# Global arrays for process data
declare -a bt at prio

# Global screen dimensions
SCREEN_WIDTH=""
SCREEN_HEIGHT=""
DIALOG_WIDTH=""
DIALOG_HEIGHT=""
TEXT_WIDTH=""
TEXT_HEIGHT=""

# ==========================================
# GET SCREEN DIMENSIONS FOR FULLSCREEN
# ==========================================
get_screen_size() {
    # Try to get screen dimensions using xrandr or xdpyinfo
    if command -v xrandr &> /dev/null; then
        SCREEN_WIDTH=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d'x' -f1 | head -1)
        SCREEN_HEIGHT=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d'x' -f2 | head -1)
    elif command -v xdpyinfo &> /dev/null; then
        SCREEN_WIDTH=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d'x' -f1)
        SCREEN_HEIGHT=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d'x' -f2)
    else
        # Fallback values
        SCREEN_WIDTH=1920
        SCREEN_HEIGHT=1080
    fi
    
    # Use 90% of screen for dialogs (leaving some margin)
    DIALOG_WIDTH=$((SCREEN_WIDTH - 100))
    DIALOG_HEIGHT=$((SCREEN_HEIGHT - 100))
    
    # For text-info dialogs, use full screen
    TEXT_WIDTH=$((SCREEN_WIDTH - 50))
    TEXT_HEIGHT=$((SCREEN_HEIGHT - 100))
}

# ==========================================
# ZENITY FULLSCREEN WRAPPER
# ==========================================
zenity_full() {
    get_screen_size
    
    local type=$1
    shift
    
    case $type in
        info)
            zenity --info --width=$DIALOG_WIDTH --height=$DIALOG_HEIGHT "$@"
            ;;
        error)
            zenity --error --width=$DIALOG_WIDTH --height=$DIALOG_HEIGHT "$@"
            ;;
        question)
            zenity --question --width=$DIALOG_WIDTH --height=$DIALOG_HEIGHT "$@"
            ;;
        warning)
            zenity --warning --width=$DIALOG_WIDTH --height=$DIALOG_HEIGHT "$@"
            ;;
        list)
            zenity --list --width=$DIALOG_WIDTH --height=$DIALOG_HEIGHT "$@"
            ;;
        forms)
            zenity --forms --width=$DIALOG_WIDTH --height=$DIALOG_HEIGHT "$@"
            ;;
        text-info)
            zenity --text-info --width=$TEXT_WIDTH --height=$TEXT_HEIGHT "$@"
            ;;
        password)
            # FIXED: --password ignores --width/--height; --entry --hide-text respects them
            zenity --entry --hide-text --width=$DIALOG_WIDTH --height=$DIALOG_HEIGHT "$@"
            ;;
        scale)
            zenity --scale --width=$DIALOG_WIDTH --height=$DIALOG_HEIGHT "$@"
            ;;
        progress)
            zenity --progress --width=$DIALOG_WIDTH --height=$DIALOG_HEIGHT "$@"
            ;;
        *)
            zenity "$@"
            ;;
    esac
}

# ==========================================
# ZENITY PAUSE FUNCTION
# ==========================================
pause() {
    zenity_full info \
        --title="S.M.A.R.T" \
        --text="Press OK to continue..." \
        --ok-label="Continue"
}

# ==========================================
# ZENITY BOOT ANIMATION (Fullscreen)
# ==========================================
boot_animation() {
    get_screen_size
    
    (
        echo "10" ; sleep 0.2
        echo "25" ; sleep 0.2
        echo "40" ; sleep 0.2
        echo "55" ; sleep 0.2
        echo "70" ; sleep 0.2
        echo "85" ; sleep 0.2
        echo "100" ; sleep 0.3
    ) | zenity_full progress \
        --title="S.M.A.R.T - Booting" \
        --text="Initializing System Components...\n\n[ OK ] Loading Kernel Modules\n[ OK ] Checking System Resources\n[ OK ] Starting User Interface" \
        --percentage=0 \
        --auto-close \
        --no-cancel
}

# ==========================================
# ZENITY EXIT ANIMATION (Fullscreen)
# ==========================================
exit_animation() {
    get_screen_size
    
    (
        echo "20" ; sleep 0.2
        echo "40" ; sleep 0.2
        echo "60" ; sleep 0.2
        echo "80" ; sleep 0.2
        echo "100" ; sleep 0.3
    ) | zenity_full progress \
        --title="S.M.A.R.T - Shutting Down" \
        --text="Stopping Services...\n\n[ OK ] Stopping Background Services\n[ OK ] Saving Session State\n[ OK ] Releasing Memory" \
        --percentage=0 \
        --auto-close \
        --no-cancel
}

# ==========================================
# ZENITY LOGIN SYSTEM (Fullscreen)
# ==========================================
login_system() {
    get_screen_size
    PASS_FILE="$HOME/password.txt"
    MAX_TRY=3

    # First Time Password Setup (if no password file exists)
    if [ ! -f "$PASS_FILE" ]; then
        # UPDATED: Improved welcome dialog with markup
        zenity_full info \
            --title="🔐 S.M.A.R.T - First Time Setup" \
            --text="<big><b>👋 Welcome to S.M.A.R.T!</b></big>

This is your <b>first time</b> running S.M.A.R.T.

Please create a password to <b>secure your access</b>.
<span foreground='gray'>You will use this password every time you log in.</span>" \
            --ok-label="▶  Continue"
        
        # Check if user clicked cancel
        [ $? -ne 0 ] && return 1

        # Password setup dialog
        while true; do
            # UPDATED: Improved password setup form with markup
            PASSWORD_DATA=$(zenity_full forms \
                --title="🔐 Create Your Password" \
                --text="Set Up Your S.M.A.R.T Password

Choose a strong password.
Both fields must match to continue." \
                --add-password="🔒  New Password" \
                --add-password="🔒  Confirm Password" \
                --ok-label="✔  Create Password" \
                --cancel-label="✘  Exit")
            
            # Check if user cancelled
            if [ $? -ne 0 ]; then
                zenity_full question \
                    --title="Exit S.M.A.R.T" \
                    --text="Do you want to exit S.M.A.R.T?" \
                    --ok-label="Yes" \
                    --cancel-label="No"
                if [ $? -eq 0 ]; then
                    exit_animation
                    exit 0
                else
                    continue
                fi
            fi

            # Split the form data (format: "password|confirm_password")
            NEW_PASS=$(echo "$PASSWORD_DATA" | cut -d'|' -f1)
            CONFIRM_PASS=$(echo "$PASSWORD_DATA" | cut -d'|' -f2)

            # Check if passwords are empty
            if [ -z "$NEW_PASS" ] || [ -z "$CONFIRM_PASS" ]; then
                zenity_full error \
                    --title="Error" \
                    --text="Password cannot be empty!\nPlease enter a password."
                continue
            fi

            # Check if passwords match
            if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
                zenity_full error \
                    --title="Error" \
                    --text="Passwords do not match!\nPlease try again."
                continue
            fi

            # Save password
            echo "$NEW_PASS" > "$PASS_FILE"
            
            # Success message
            zenity_full info \
                --title="Success" \
                --text="Password saved successfully!\n\nYou can now login with your password." \
                --timeout=2
            break
        done
    fi

    # =================
    # Login Attempts
    # =================
    TRY=1
    while [ $TRY -le $MAX_TRY ]; do
        # UPDATED: Improved login dialog with markup formatting and cleaner look
        INPUT_PASS=$(zenity_full password \
            --title="🔐 S.M.A.R.T — Secure Login" \
            --text="S.M.A.R.T Login Portal

Please enter your password to continue.
Attempt $TRY of $MAX_TRY  |  Remaining: $((MAX_TRY - TRY + 1))")
        
        # Check if user clicked Cancel
        if [ $? -ne 0 ]; then
            zenity_full question \
                --title="Exit S.M.A.R.T" \
                --text="Do you want to exit S.M.A.R.T?" \
                --ok-label="Yes" \
                --cancel-label="No"
            if [ $? -eq 0 ]; then
                exit_animation
                exit 0
            else
                continue
            fi
        fi

        # Read stored password
        STORED_PASS=$(cat "$PASS_FILE")

        # Check password
        if [ "$INPUT_PASS" = "$STORED_PASS" ]; then
            # Success animation with progress bar
            (
                echo "10"; sleep 0.1
                echo "25"; sleep 0.1
                echo "50"; sleep 0.1
                echo "75"; sleep 0.1
                echo "100"; sleep 0.2
            ) | zenity_full progress \
                --title="Logging In" \
                --text="Verifying credentials..." \
                --percentage=0 \
                --auto-close \
                --no-cancel
            
            zenity_full info \
                --title="Welcome" \
                --text="Login successful!\n\nWelcome to S.M.A.R.T - System Monitoring And Resource Toolkit" \
                --timeout=2
            
            # Call main menu
            main_menu
            return 0
        else
            # Wrong password
            TRY=$((TRY + 1))
            REMAINING=$((MAX_TRY - TRY + 1))
            
            if [ $TRY -le $MAX_TRY ]; then
                zenity_full error \
                    --title="Login Failed" \
                    --text="Wrong password!\n\nAttempts remaining: $REMAINING"
            fi
        fi
    done

    # Too many failed attempts
    zenity_full error \
        --title="Access Denied" \
        --text="Too many wrong attempts!\n\nAccess to S.M.A.R.T has been blocked."
    
    sleep 2
    exit_animation
    exit 1
}

# ==========================================
# ZENITY RESET PASSWORD (Fullscreen)
# ==========================================
reset_password() {
    get_screen_size
    clear
    PASS_FILE="$HOME/password.txt"
    
    # Check if password file exists
    if [ ! -f "$PASS_FILE" ]; then
        zenity_full error \
            --title="Error" \
            --text="No password file found!\nPlease setup password first."
        pause
        return
    fi

    # UPDATED: Improved reset password dialog with markup
    CUR_PASS=$(zenity_full password \
        --title="🔐 S.M.A.R.T — Reset Password" \
        --text="Reset Your Password

Enter your CURRENT password to verify identity.
You will be asked for a new password next.")
    
    # Check if cancelled
    [ $? -ne 0 ] && return

    STORED_PASS=$(cat "$PASS_FILE")

    # Verify current password
    if [ "$CUR_PASS" != "$STORED_PASS" ]; then
        zenity_full error \
            --title="Error" \
            --text="Incorrect current password!"
        sleep 1
        return
    fi

    # Get new password (with confirmation)
    while true; do
        PASSWORD_DATA=$(zenity_full forms \
            --title="Reset Password" \
            --text="Enter your NEW password" \
            --add-password="New Password" \
            --add-password="Confirm New Password")
        
        # Check if cancelled
        [ $? -ne 0 ] && return

        # Split the form data
        NEW_PASS=$(echo "$PASSWORD_DATA" | cut -d'|' -f1)
        CONFIRM_PASS=$(echo "$PASSWORD_DATA" | cut -d'|' -f2)

        # Check if passwords are empty
        if [ -z "$NEW_PASS" ] || [ -z "$CONFIRM_PASS" ]; then
            zenity_full error \
                --title="Error" \
                --text="Password cannot be empty!"
            continue
        fi

        # Check if passwords match
        if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
            zenity_full error \
                --title="Error" \
                --text="Passwords do not match!\nPlease try again."
            continue
        fi

        # Save new password
        echo "$NEW_PASS" > "$PASS_FILE"
        
        # Success message
        zenity_full info \
            --title="Success" \
            --text="Password successfully changed!"
        break
    done
    
    pause
}

# ==========================================
# ZENITY PROCESS MANAGER (Fullscreen)
# ==========================================
process_manager() {
    get_screen_size
    
    while true; do
        ACTION=$(zenity_full list \
            --title="📊 Process Manager" \
            --text="<big><b>Process Management Options</big></b>\n\nSelect an action:" \
            --column="Action" \
            --column="Description" \
            --ok-label="Select" \
            --cancel-label="Back" \
            "1" "🔥 Top CPU Processes - View highest CPU consuming processes" \
            "2" "💾 Top Memory Processes - View highest memory consuming processes" \
            "3" "🔪 Kill Process - Terminate a running process by PID" \
            "4" "📋 List All Processes - View complete process list" \
            "5" "🔍 Search Process - Find process by name" \
            "6" "📊 Process Tree - View processes in hierarchy" \
            "7" "🔙 Return to Main Menu")
        
        if [ $? -ne 0 ] || [ -z "$ACTION" ]; then
            return
        fi
        
        case "$ACTION" in
            "1"|"🔥 Top CPU Processes - View highest CPU consuming processes")
                top_cpu_processes
                ;;
            "2"|"💾 Top Memory Processes - View highest memory consuming processes")
                top_memory_processes
                ;;
            "3"|"🔪 Kill Process - Terminate a running process by PID")
                kill_process_gui
                ;;
            "4"|"📋 List All Processes - View complete process list")
                list_all_processes
                ;;
            "5"|"🔍 Search Process - Find process by name")
                search_process
                ;;
            "6"|"📊 Process Tree - View processes in hierarchy")
                process_tree
                ;;
            "7"|"🔙 Return to Main Menu")
                return
                ;;
        esac
    done
}

# ==========================================
# Top CPU Processes (Fullscreen)
# ==========================================
top_cpu_processes() {
    get_screen_size
    
    COUNT=$(zenity_full scale \
        --title="Top CPU Processes" \
        --text="How many top CPU processes to display?" \
        --min-value=5 \
        --max-value=50 \
        --value=10 \
        --step=5)
    
    if [ $? -eq 0 ] && [ -n "$COUNT" ]; then
        {
            echo "PID\tCPU%\tCommand"
            echo "------------------------"
            ps -eo pid,comm,%cpu --sort=-%cpu | awk 'NR>1 {printf "%d\t%.1f\t%s\n", $1, $3, $2}' | head -n $COUNT
        } > /tmp/top_cpu.txt
        
        zenity_full text-info \
            --title="Top $COUNT CPU Processes" \
            --filename=/tmp/top_cpu.txt \
            --font="Monospace 12" \
            --ok-label="Refresh" \
            --cancel-label="Back"
        
        if [ $? -eq 0 ]; then
            top_cpu_processes
        fi
    fi
}

# ==========================================
# Top Memory Processes (Fullscreen)
# ==========================================
top_memory_processes() {
    get_screen_size
    
    COUNT=$(zenity_full scale \
        --title="Top Memory Processes" \
        --text="How many top memory processes to display?" \
        --min-value=5 \
        --max-value=50 \
        --value=10 \
        --step=5)
    
    if [ $? -eq 0 ] && [ -n "$COUNT" ]; then
        {
            echo "PID\tMEM%\tCommand"
            echo "------------------------"
            ps -eo pid,comm,%mem --sort=-%mem | awk 'NR>1 {printf "%d\t%.1f\t%s\n", $1, $3, $2}' | head -n $COUNT
        } > /tmp/top_mem.txt
        
        zenity_full text-info \
            --title="Top $COUNT Memory Processes" \
            --filename=/tmp/top_mem.txt \
            --font="Monospace 12" \
            --ok-label="Refresh" \
            --cancel-label="Back"
        
        if [ $? -eq 0 ]; then
            top_memory_processes
        fi
    fi
}

# ==========================================
# Kill Process with GUI (Fullscreen)
# ==========================================
kill_process_gui() {
    get_screen_size
    
    {
        echo "PID\tCPU%\tMEM%\tCommand"
        echo "------------------------------------------------"
        ps -eo pid,comm,%cpu,%mem --sort=-%cpu | awk 'NR>1 && NR<21 {printf "%d\t%.1f\t%.1f\t%s\n", $1, $3, $4, $2}'
    } > /tmp/process_list.txt
    
    zenity_full text-info \
        --title="Running Processes (Top 20)" \
        --filename=/tmp/process_list.txt \
        --font="Monospace 12" \
        --ok-label="Continue to Kill" \
        --cancel-label="Cancel"
    
    if [ $? -ne 0 ]; then
        return
    fi
    
    PID=$(zenity_full forms \
        --title="Kill Process" \
        --text="Enter Process ID (PID) to terminate:" \
        --add-entry="PID:")
    
    if [ -z "$PID" ]; then
        return
    fi
    
    # Extract PID from form data
    PID=$(echo "$PID" | cut -d'|' -f1)
    
    if ! [[ "$PID" =~ ^[0-9]+$ ]]; then
        zenity_full error \
            --title="Error" \
            --text="Invalid PID! Please enter a numeric value."
        return
    fi
    
    if ! ps -p "$PID" > /dev/null 2>&1; then
        zenity_full error \
            --title="Error" \
            --text="Process with PID $PID does not exist!"
        return
    fi
    
    PROC_NAME=$(ps -p "$PID" -o comm= 2>/dev/null)
    
    SIGNAL=$(zenity_full list \
        --title="Kill Process" \
        --text="<b>Process: $PROC_NAME (PID: $PID)</b>\n\nSelect termination signal:" \
        --column="Signal" \
        --column="Description" \
        "15" "TERM - Graceful termination (recommended)" \
        "9" "KILL - Force immediate termination" \
        "2" "INT - Interrupt (like Ctrl+C)" \
        "1" "HUP - Hang up (restart)" \
        "3" "QUIT - Quit and core dump")
    
    if [ $? -ne 0 ] || [ -z "$SIGNAL" ]; then
        return
    fi
    
    SIGNAL_NUM=$(echo "$SIGNAL" | cut -d' ' -f1)
    
    zenity_full question \
        --title="Confirm Kill" \
        --text="Are you sure you want to send signal $SIGNAL_NUM to process:\n\n<b>$PROC_NAME (PID: $PID)</b>" \
        --ok-label="Yes, Terminate" \
        --cancel-label="Cancel"
    
    if [ $? -ne 0 ]; then
        return
    fi
    
    if kill -$SIGNAL_NUM "$PID" 2>/dev/null; then
        zenity_full info \
            --title="Success" \
            --text="Signal $SIGNAL_NUM sent successfully to process $PID" \
            --timeout=2
    else
        zenity_full error \
            --title="Error" \
            --text="Failed to send signal to process $PID.\nCheck permissions or process status."
    fi
}

# ==========================================
# List All Processes (Fullscreen)
# ==========================================
list_all_processes() {
    get_screen_size
    
    FILTER=$(zenity_full list \
        --title="List Processes" \
        --text="Select display option:" \
        --column="Option" \
        --column="Description" \
        "all" "All processes (full list)" \
        "user" "Only my processes" \
        "system" "System processes only")
    
    [ $? -ne 0 ] || [ -z "$FILTER" ] && return
    
    case "$FILTER" in
        "all")
            ps -eo pid,ppid,user,%cpu,%mem,stat,start,command --sort=-%cpu > /tmp/all_procs.txt
            TITLE="All Processes (Sorted by CPU)"
            ;;
        "user")
            ps -U $USER -o pid,ppid,%cpu,%mem,stat,start,command --sort=-%cpu > /tmp/user_procs.txt
            TITLE="My Processes (User: $USER)"
            ;;
        "system")
            ps -eo pid,ppid,user,%cpu,%mem,stat,start,command | grep -v "$USER" > /tmp/system_procs.txt
            TITLE="System Processes"
            ;;
    esac
    
    zenity_full text-info \
        --title="$TITLE" \
        --filename=/tmp/"$FILTER"_procs.txt \
        --font="Monospace 10" \
        --ok-label="Refresh" \
        --cancel-label="Back"
    
    if [ $? -eq 0 ]; then
        list_all_processes
    fi
}

# ==========================================
# Search Process by Name (Fullscreen)
# ==========================================
search_process() {
    get_screen_size
    
    SEARCH_TERM=$(zenity_full forms \
        --title="Search Process" \
        --text="Enter process name to search (partial names allowed):" \
        --add-entry="Search Term:")
    
    if [ -z "$SEARCH_TERM" ]; then
        return
    fi
    
    SEARCH_TERM=$(echo "$SEARCH_TERM" | cut -d'|' -f1)
    
    {
        echo "Search results for: '$SEARCH_TERM'"
        echo "========================================"
        echo ""
        echo "PID\tUSER\t%CPU\t%MEM\tCOMMAND"
        echo "------------------------------------------------"
        ps -eo pid,user,%cpu,%mem,comm | grep -i "$SEARCH_TERM" | grep -v grep
    } > /tmp/search_results.txt
    
    if [ $(wc -l < /tmp/search_results.txt) -le 3 ]; then
        zenity_full info \
            --title="No Results" \
            --text="No processes found matching '$SEARCH_TERM'"
        return
    fi
    
    zenity_full text-info \
        --title="Process Search Results" \
        --filename=/tmp/search_results.txt \
        --font="Monospace 12" \
        --ok-label="Search Again" \
        --cancel-label="Back"
    
    if [ $? -eq 0 ]; then
        search_process
    fi
}

# ==========================================
# Process Tree (Fullscreen)
# ==========================================
process_tree() {
    get_screen_size
    
    ROOT_PID=$(zenity_full forms \
        --title="Process Tree" \
        --text="Enter root PID (leave empty for init/systemd):" \
        --add-entry="PID:")
    
    TEMP_FILE="/tmp/proc_tree.txt"
    
    if [ -z "$ROOT_PID" ]; then
        {
            echo "Complete Process Tree"
            echo "====================="
            echo ""
            pstree -a -p
        } > "$TEMP_FILE"
    else
        ROOT_PID=$(echo "$ROOT_PID" | cut -d'|' -f1)
        
        if ! [[ "$ROOT_PID" =~ ^[0-9]+$ ]]; then
            zenity_full error --text="Invalid PID"
            return
        fi
        
        {
            echo "Process Tree for PID: $ROOT_PID"
            echo "================================"
            echo ""
            pstree -a -p "$ROOT_PID" 2>/dev/null
        } > "$TEMP_FILE"
        
        if [ $? -ne 0 ]; then
            zenity_full error \
                --title="Error" \
                --text="PID $ROOT_PID not found or no children"
            return
        fi
    fi
    
    zenity_full text-info \
        --title="Process Tree" \
        --filename="$TEMP_FILE" \
        --font="Monospace 12"
}

# ==========================================
# ZENITY SYSTEM DASHBOARD (Fullscreen)
# ==========================================
system_dashboard() {
    get_screen_size
    
    HOSTNAME=$(hostname)
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p | sed 's/up //')
    LOAD=$(uptime | awk -F'load average:' '{print $2}')
    
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    CPU_CORES=$(nproc)
    
    MEM_TOTAL=$(free -h | grep "^Mem:" | awk '{print $2}')
    MEM_USED=$(free -h | grep "^Mem:" | awk '{print $3}')
    MEM_FREE=$(free -h | grep "^Mem:" | awk '{print $4}')
    MEM_PERCENT=$(free | grep "^Mem:" | awk '{printf "%.1f%%", ($3/$2)*100}')
    
    DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
    DISK_USED=$(df -h / | tail -1 | awk '{print $3}')
    DISK_FREE=$(df -h / | tail -1 | awk '{print $4}')
    DISK_PERCENT=$(df -h / | tail -1 | awk '{print $5}')
    
    USERS=$(who | wc -l)
    
    zenity_full info \
        --title="📈 System Dashboard" \
        --text="<big><b>System Information</b></big>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>Hostname:</b> $HOSTNAME
<b>Kernel:</b> $KERNEL
<b>Uptime:</b> $UPTIME
<b>Users logged in:</b> $USERS

<big><b>CPU Information</b></big>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>Model:</b> $CPU_MODEL
<b>Cores:</b> $CPU_CORES
<b>Load Average:</b> $LOAD

<big><b>Memory Usage</b></big>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>Total:</b> $MEM_TOTAL
<b>Used:</b> $MEM_USED ($MEM_PERCENT)
<b>Free:</b> $MEM_FREE

<big><b>Disk Usage (/)</b></big>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>Total:</b> $DISK_TOTAL
<b>Used:</b> $DISK_USED ($DISK_PERCENT)
<b>Free:</b> $DISK_FREE" \
        --ok-label="Refresh" \
        --extra-button="Back"
    
    if [ $? -eq 0 ]; then
        system_dashboard
    fi
}

# ==========================================
# CPU SCHEDULING MAIN MENU (Fullscreen)
# ==========================================
cpu_menu() {
    get_screen_size
    
    while true; do
        CHOICE=$(zenity_full list \
            --title="⚙️ CPU Scheduling Algorithms" \
            --text="<big><b>Select Scheduling Algorithm:</b></big>\n\nCompare different CPU scheduling techniques:" \
            --column="Option" \
            --column="Algorithm" \
            --ok-label="Select" \
            --cancel-label="Back" \
            "1" "FCFS - First Come First Serve (Non-preemptive)" \
            "2" "SJF - Shortest Job First (Non-preemptive)" \
            "3" "SRTF - Shortest Remaining Time First (Preemptive)" \
            "4" "Round Robin - With Time Quantum" \
            "5" "Priority Scheduling (Non-preemptive)" \
            "6" "Hybrid Scheduling (Priority + FCFS + SJF)" \
            "7" "Compare All Algorithms")
        
        if [ $? -ne 0 ] || [ -z "$CHOICE" ]; then
            return
        fi
        
        case "$CHOICE" in
            "1"|"FCFS - First Come First Serve (Non-preemptive)")
                fcfs_input
                ;;
            "2"|"SJF - Shortest Job First (Non-preemptive)")
                sjf_input
                ;;
            "3"|"SRTF - Shortest Remaining Time First (Preemptive)")
                srtf_input
                ;;
            "4"|"Round Robin - With Time Quantum")
                rr_input
                ;;
            "5"|"Priority Scheduling (Non-preemptive)")
                priority_input
                ;;
            "6"|"Hybrid Scheduling (Priority + FCFS + SJF)")
                hybrid_input
                ;;
            "7"|"Compare All Algorithms")
                compare_input
                ;;
        esac
    done
}

# ==========================================
# GET PROCESS DATA FROM ZENITY (Fullscreen)
# ==========================================
get_process_count() {
    get_screen_size
    
    local count
    
    count=$(zenity_full forms \
        --title="Number of Processes" \
        --text="Enter number of processes (1-10):" \
        --add-entry="Number of Processes:")
    
    if [ $? -ne 0 ] || [ -z "$count" ]; then
        echo ""
        return
    fi
    
    count=$(echo "$count" | cut -d'|' -f1)
    
    if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ] || [ "$count" -gt 10 ]; then
        zenity_full error \
            --title="Invalid Input" \
            --text="Please enter a valid number between 1 and 10"
        echo ""
        return
    fi
    
    echo "$count"
}

get_process_details() {
    local n=$1
    local include_arrival=$2
    local include_quantum=$3
    
    get_screen_size
    
    declare -a fields
    
    for ((i=0; i<n; i++)); do
        fields+=("--add-entry=Process P$((i+1)) Burst Time")
    done
    
    if [ "$include_arrival" = "yes" ]; then
        for ((i=0; i<n; i++)); do
            fields+=("--add-entry=Process P$((i+1)) Arrival Time")
        done
    fi
    
    if [ "$include_quantum" = "yes" ]; then
        fields+=("--add-entry=Time Quantum")
    fi
    
    local data
    data=$(zenity_full forms \
        --title="Process Details" \
        --text="<big><b>Enter process information:</b></big>" \
        "${fields[@]}")
    
    if [ $? -ne 0 ] || [ -z "$data" ]; then
        echo ""
        return
    fi
    
    echo "$data"
}

# ==========================================
# FCFS INPUT
# ==========================================
fcfs_input() {
    n=$(get_process_count)
    [ -z "$n" ] && return
    
    data=$(get_process_details $n "yes" "no")
    [ -z "$data" ] && return
    
    IFS='|' read -ra values <<< "$data"
    
    for ((i=0; i<n; i++)); do
        bt[$i]=${values[$i]}
    done
    
    for ((i=0; i<n; i++)); do
        at[$i]=${values[$((n + i))]}
    done
    
    for ((i=0; i<n; i++)); do
        if ! [[ "${bt[$i]}" =~ ^[0-9]+$ ]] || [ "${bt[$i]}" -lt 1 ]; then
            zenity_full error --text="Invalid burst time for P$((i+1))"
            return
        fi
        if ! [[ "${at[$i]}" =~ ^[0-9]+$ ]]; then
            zenity_full error --text="Invalid arrival time for P$((i+1))"
            return
        fi
    done
    
    # UPDATED: Redirect algorithm output to Zenity instead of terminal
    {
        echo "========================================="
        echo "           FCFS SCHEDULING"
        echo "========================================="
        echo
        fcfs_calculate $n
    } > /tmp/output.txt

    zenity_full text-info \
        --title="FCFS - First Come First Serve Results" \
        --filename=/tmp/output.txt \
        --font="Monospace 11"
}

# ==========================================
# SJF INPUT
# ==========================================
sjf_input() {
    n=$(get_process_count)
    [ -z "$n" ] && return
    
    data=$(get_process_details $n "yes" "no")
    [ -z "$data" ] && return
    
    IFS='|' read -ra values <<< "$data"
    
    for ((i=0; i<n; i++)); do
        bt[$i]=${values[$i]}
    done
    
    for ((i=0; i<n; i++)); do
        at[$i]=${values[$((n + i))]}
    done
    
    for ((i=0; i<n; i++)); do
        if ! [[ "${bt[$i]}" =~ ^[0-9]+$ ]] || [ "${bt[$i]}" -lt 1 ]; then
            zenity_full error --text="Invalid burst time for P$((i+1))"
            return
        fi
        if ! [[ "${at[$i]}" =~ ^[0-9]+$ ]]; then
            zenity_full error --text="Invalid arrival time for P$((i+1))"
            return
        fi
    done
    
    # UPDATED: Redirect algorithm output to Zenity instead of terminal
    {
        echo "========================================="
        echo "    SJF (Shortest Job First) SCHEDULING"
        echo "========================================="
        echo
        sjf_calculate $n
    } > /tmp/output.txt

    zenity_full text-info \
        --title="SJF - Shortest Job First Results" \
        --filename=/tmp/output.txt \
        --font="Monospace 11"
}

# ==========================================
# SRTF INPUT
# ==========================================
srtf_input() {
    n=$(get_process_count)
    [ -z "$n" ] && return
    
    data=$(get_process_details $n "yes" "no")
    [ -z "$data" ] && return
    
    IFS='|' read -ra values <<< "$data"
    
    for ((i=0; i<n; i++)); do
        bt[$i]=${values[$i]}
    done
    
    for ((i=0; i<n; i++)); do
        at[$i]=${values[$((n + i))]}
    done
    
    for ((i=0; i<n; i++)); do
        if ! [[ "${bt[$i]}" =~ ^[0-9]+$ ]] || [ "${bt[$i]}" -lt 1 ]; then
            zenity_full error --text="Invalid burst time for P$((i+1))"
            return
        fi
        if ! [[ "${at[$i]}" =~ ^[0-9]+$ ]]; then
            zenity_full error --text="Invalid arrival time for P$((i+1))"
            return
        fi
    done
    
    # UPDATED: Redirect algorithm output to Zenity instead of terminal
    {
        echo "========================================="
        echo "  SRTF (Shortest Remaining Time First) SCHEDULING"
        echo "========================================="
        echo
        srtf_calculate $n
    } > /tmp/output.txt

    zenity_full text-info \
        --title="SRTF - Shortest Remaining Time First Results" \
        --filename=/tmp/output.txt \
        --font="Monospace 11"
}

# ==========================================
# ROUND ROBIN INPUT
# ==========================================
rr_input() {
    n=$(get_process_count)
    [ -z "$n" ] && return
    
    data=$(get_process_details $n "yes" "yes")
    [ -z "$data" ] && return
    
    IFS='|' read -ra values <<< "$data"
    
    for ((i=0; i<n; i++)); do
        bt[$i]=${values[$i]}
    done
    
    for ((i=0; i<n; i++)); do
        at[$i]=${values[$((n + i))]}
    done
    
    quantum=${values[$((2*n))]}
    
    for ((i=0; i<n; i++)); do
        if ! [[ "${bt[$i]}" =~ ^[0-9]+$ ]] || [ "${bt[$i]}" -lt 1 ]; then
            zenity_full error --text="Invalid burst time for P$((i+1))"
            return
        fi
        if ! [[ "${at[$i]}" =~ ^[0-9]+$ ]]; then
            zenity_full error --text="Invalid arrival time for P$((i+1))"
            return
        fi
    done
    
    if ! [[ "$quantum" =~ ^[0-9]+$ ]] || [ "$quantum" -lt 1 ]; then
        zenity_full error --text="Invalid quantum time"
        return
    fi
    
    # UPDATED: Redirect algorithm output to Zenity instead of terminal
    {
        echo "========================================="
        echo "   ROUND ROBIN SCHEDULING (Quantum = $quantum)"
        echo "========================================="
        echo
        rr_calculate $n $quantum
    } > /tmp/output.txt

    zenity_full text-info \
        --title="Round Robin Scheduling Results (Quantum=$quantum)" \
        --filename=/tmp/output.txt \
        --font="Monospace 11"
}

# ==========================================
# COMPARE ALL INPUT
# ==========================================
compare_input() {
    n=$(get_process_count)
    [ -z "$n" ] && return
    
    data=$(get_process_details $n "yes" "no")
    [ -z "$data" ] && return
    
    IFS='|' read -ra values <<< "$data"
    
    for ((i=0; i<n; i++)); do
        bt[$i]=${values[$i]}
    done
    
    for ((i=0; i<n; i++)); do
        at[$i]=${values[$((n + i))]}
    done
    
    for ((i=0; i<n; i++)); do
        if ! [[ "${bt[$i]}" =~ ^[0-9]+$ ]] || [ "${bt[$i]}" -lt 1 ]; then
            zenity_full error --text="Invalid burst time for P$((i+1))"
            return
        fi
        if ! [[ "${at[$i]}" =~ ^[0-9]+$ ]]; then
            zenity_full error --text="Invalid arrival time for P$((i+1))"
            return
        fi
    done
    
    # UPDATED: Redirect all comparison output to Zenity instead of terminal
    {
        echo "========================================="
        echo "      COMPARISON OF ALL ALGORITHMS"
        echo "========================================="
        echo
        echo "Process Details:"
        echo "----------------------------------------"
        printf "| %-8s | %-8s | %-8s |\n" "Process" "AT" "BT"
        echo "----------------------------------------"
        for ((i=0; i<n; i++)); do
            printf "| P%-7d | %-8d | %-8d |\n" $((i+1)) ${at[$i]} ${bt[$i]}
        done
        echo "----------------------------------------"
        echo

        echo "========== FCFS =========="
        fcfs_calculate $n

        echo
        echo "========== SJF =========="
        sjf_calculate $n

        echo
        echo "========== SRTF =========="
        srtf_calculate $n

        echo
        echo "========== ROUND ROBIN (Quantum=2) =========="
        rr_calculate $n 2
    } > /tmp/output.txt

    zenity_full text-info \
        --title="Comparison of All CPU Scheduling Algorithms" \
        --filename=/tmp/output.txt \
        --font="Monospace 11"
}

# ==========================================
# FCFS CALCULATION
# --- MODIFIED: Added execution timeline + idle time step-by-step print ---
# ==========================================
fcfs_calculate() {
    local n=$1

    declare -a l_bt l_at l_pid

    for ((i=0; i<n; i++)); do
        l_bt[$i]=${bt[$i]}
        l_at[$i]=${at[$i]}
        l_pid[$i]=$i
    done

    # Sort by arrival time (bubble sort)
    for ((i=0; i<n-1; i++)); do
        for ((j=0; j<n-i-1; j++)); do
            if [ ${l_at[$j]} -gt ${l_at[$j+1]} ]; then
                temp=${l_at[$j]}; l_at[$j]=${l_at[$j+1]}; l_at[$j+1]=$temp
                temp=${l_bt[$j]}; l_bt[$j]=${l_bt[$j+1]}; l_bt[$j+1]=$temp
                temp=${l_pid[$j]}; l_pid[$j]=${l_pid[$j+1]}; l_pid[$j+1]=$temp
            fi
        done
    done

    declare -a l_ct
    echo "Execution Timeline:"
    echo "-------------------"

    local time=0
    for ((i=0; i<n; i++)); do
        # --- MODIFIED: idle time prints step-by-step ---
        while [ $time -lt ${l_at[$i]} ]; do
            echo "Time : $time | Idle"
            time=$((time + 1))
        done
        echo "Time $time: Running P$((l_pid[$i]+1)) (BT=${l_bt[$i]})"
        time=$((time + l_bt[$i]))
        l_ct[$i]=$time
        echo "Time $time: P$((l_pid[$i]+1)) completed"
    done

    declare -a l_tat l_wt
    total_wt=0
    total_tat=0

    for ((i=0; i<n; i++)); do
        l_tat[$i]=$((l_ct[$i] - l_at[$i]))
        l_wt[$i]=$((l_tat[$i] - l_bt[$i]))
        total_wt=$((total_wt + l_wt[$i]))
        total_tat=$((total_tat + l_tat[$i]))
    done

    echo
    echo "----------------------------------------"
    printf "| %-8s | %-8s | %-8s | %-8s | %-8s | %-8s |\n" "Process" "AT" "BT" "CT" "TAT" "WT"
    echo "----------------------------------------"
    for ((i=0; i<n; i++)); do
        printf "| P%-7d | %-8d | %-8d | %-8d | %-8d | %-8d |\n" \
            $((l_pid[$i]+1)) ${l_at[$i]} ${l_bt[$i]} ${l_ct[$i]} ${l_tat[$i]} ${l_wt[$i]}
    done
    echo "----------------------------------------"
    echo
    echo "Average Waiting Time:     $(echo "scale=2; $total_wt / $n" | bc)"
    echo "Average Turnaround Time:  $(echo "scale=2; $total_tat / $n" | bc)"

    echo
    echo "Gantt Chart:"
    echo -n " "
    for ((i=0; i<n; i++)); do
        echo -n "--------"
    done
    echo
    echo -n "|"
    for ((i=0; i<n; i++)); do
        echo -n " P$((l_pid[$i]+1))    |"
    done
    echo
    echo -n " "
    for ((i=0; i<n; i++)); do
        echo -n "--------"
    done
    echo
    echo -n "${l_at[0]}"
    for ((i=0; i<n; i++)); do
        printf "       %d" ${l_ct[$i]}
    done
    echo
}

# ==========================================
# SJF CALCULATION (Non-preemptive)
# --- MODIFIED: Fixed idle time (step-by-step print), fixed Gantt chart order ---
# ==========================================
sjf_calculate() {
    local n=$1

    declare -a l_pid l_bt l_at l_completed l_ct l_wt l_tat
    # --- ADDED: gantt arrays to track execution order for Gantt chart ---
    declare -a gantt_pid gantt_start gantt_end
    local gantt_count=0

    for ((i=0; i<n; i++)); do
        l_pid[$i]=$i
        l_bt[$i]=${bt[$i]}
        l_at[$i]=${at[$i]}
        l_completed[$i]=0
    done

    local time=0
    local completed_count=0

    echo "Execution Timeline:"
    echo "-------------------"

    while [ $completed_count -lt $n ]; do
        local min_bt=99999
        local min_index=-1

        # Pick shortest job among arrived, not yet completed
        for ((i=0; i<n; i++)); do
            if [ ${l_completed[$i]} -eq 0 ] && [ ${l_at[$i]} -le $time ]; then
                if [ ${l_bt[$i]} -lt $min_bt ]; then
                    min_bt=${l_bt[$i]}
                    min_index=$i
                # --- MODIFIED: tie-break by arrival time (FCFS) ---
                elif [ ${l_bt[$i]} -eq $min_bt ] && [ ${l_at[$i]} -lt ${l_at[$min_index]} ]; then
                    min_index=$i
                fi
            fi
        done

        # --- MODIFIED: idle time prints step-by-step, not jump ---
        if [ $min_index -eq -1 ]; then
            echo "Time : $time | Idle"
            time=$((time + 1))
            continue
        fi

        echo "Time $time: Running P$((l_pid[$min_index]+1)) (BT=${l_bt[$min_index]})"

        # --- ADDED: record gantt entry ---
        gantt_pid[$gantt_count]=${l_pid[$min_index]}
        gantt_start[$gantt_count]=$time
        gantt_end[$gantt_count]=$((time + l_bt[$min_index]))
        gantt_count=$((gantt_count + 1))

        time=$((time + l_bt[$min_index]))
        l_ct[$min_index]=$time
        l_completed[$min_index]=1
        completed_count=$((completed_count + 1))
        echo "Time $time: P$((l_pid[$min_index]+1)) completed"
    done

    echo

    total_wt=0
    total_tat=0

    for ((i=0; i<n; i++)); do
        l_tat[$i]=$((l_ct[$i] - l_at[$i]))
        l_wt[$i]=$((l_tat[$i] - l_bt[$i]))
        total_wt=$((total_wt + l_wt[$i]))
        total_tat=$((total_tat + l_tat[$i]))
    done

    echo "----------------------------------------"
    printf "| %-8s | %-8s | %-8s | %-8s | %-8s | %-8s |\n" "Process" "AT" "BT" "CT" "TAT" "WT"
    echo "----------------------------------------"
    for ((i=0; i<n; i++)); do
        printf "| P%-7d | %-8d | %-8d | %-8d | %-8d | %-8d |\n" \
            $((i+1)) ${l_at[$i]} ${l_bt[$i]} ${l_ct[$i]} ${l_tat[$i]} ${l_wt[$i]}
    done
    echo "----------------------------------------"
    echo
    echo "Average Waiting Time:     $(echo "scale=2; $total_wt / $n" | bc)"
    echo "Average Turnaround Time:  $(echo "scale=2; $total_tat / $n" | bc)"

    echo
    echo "Gantt Chart:"
    echo -n " "
    for ((i=0; i<gantt_count; i++)); do
        echo -n "----------"
    done
    echo
    echo -n "|"
    for ((i=0; i<gantt_count; i++)); do
        printf " P%-6d |" $((gantt_pid[$i]+1))
    done
    echo
    echo -n " "
    for ((i=0; i<gantt_count; i++)); do
        echo -n "----------"
    done
    echo
    echo -n "${gantt_start[0]}"
    for ((i=0; i<gantt_count; i++)); do
        printf "         %d" ${gantt_end[$i]}
    done
    echo
}

# ==========================================
# SRTF CALCULATION (Preemptive)
# ==========================================
srtf_calculate() {
    local n=$1
    
    declare -a l_pid l_bt l_at l_remaining l_completed l_ct l_wt l_tat
    
    for ((i=0; i<n; i++)); do
        l_pid[$i]=$i
        l_bt[$i]=${bt[$i]}
        l_at[$i]=${at[$i]}
        l_remaining[$i]=${bt[$i]}
        l_completed[$i]=0
    done
    
    local time=0
    local completed_count=0
    local prev_process=-1
    
    echo "Execution Timeline:"
    echo "-------------------"
    
    while [ $completed_count -lt $n ]; do
        local min_remaining=99999
        local min_index=-1
        
        for ((i=0; i<n; i++)); do
            if [ ${l_completed[$i]} -eq 0 ] && [ ${l_at[$i]} -le $time ] && [ ${l_remaining[$i]} -gt 0 ]; then
                if [ ${l_remaining[$i]} -lt $min_remaining ]; then
                    min_remaining=${l_remaining[$i]}
                    min_index=$i
                fi
            fi
        done
        
        # --- MODIFIED: idle time prints step-by-step ---
        if [ $min_index -eq -1 ]; then
            echo "Time : $time | Idle"
            time=$((time + 1))
            continue
        fi
        
        if [ $prev_process -ne $min_index ]; then
            if [ $prev_process -ne -1 ]; then
                echo "Time $time: Preempted P$((prev_process+1)), starting P$((min_index+1))"
            else
                echo "Time $time: Starting P$((min_index+1))"
            fi
            prev_process=$min_index
        fi
        
        l_remaining[$min_index]=$((l_remaining[$min_index] - 1))
        time=$((time + 1))
        
        if [ ${l_remaining[$min_index]} -eq 0 ]; then
            l_ct[$min_index]=$time
            l_completed[$min_index]=1
            completed_count=$((completed_count + 1))
            echo "Time $time: P$((min_index+1)) completed"
            prev_process=-1
        fi
    done
    
    echo
    
    total_wt=0
    total_tat=0
    
    for ((i=0; i<n; i++)); do
        l_tat[$i]=$((l_ct[$i] - l_at[$i]))
        l_wt[$i]=$((l_tat[$i] - l_bt[$i]))
        total_wt=$((total_wt + l_wt[$i]))
        total_tat=$((total_tat + l_tat[$i]))
    done
    
    echo "----------------------------------------"
    printf "| %-8s | %-8s | %-8s | %-8s | %-8s | %-8s |\n" "Process" "AT" "BT" "CT" "TAT" "WT"
    echo "----------------------------------------"
    for ((i=0; i<n; i++)); do
        printf "| P%-7d | %-8d | %-8d | %-8d | %-8d | %-8d |\n" \
            $((i+1)) ${l_at[$i]} ${l_bt[$i]} ${l_ct[$i]} ${l_tat[$i]} ${l_wt[$i]}
    done
    echo "----------------------------------------"
    echo
    echo "Average Waiting Time:     $(echo "scale=2; $total_wt / $n" | bc)"
    echo "Average Turnaround Time:  $(echo "scale=2; $total_tat / $n" | bc)"
    echo
    echo "Gantt Chart:"
    echo -n " "
    for ((i=0; i<n; i++)); do
        echo -n "--------"
    done
    echo
    echo -n "|"
    for ((i=0; i<n; i++)); do
        echo -n " P$((l_pid[$i]+1))    |"
    done
    echo
    echo -n " "
    for ((i=0; i<n; i++)); do
        echo -n "--------"
    done
    echo
    echo -n "0"
    for ((i=0; i<n; i++)); do
        printf "       %d" ${l_ct[$i]}
    done
    echo
}

# ==========================================
# ROUND ROBIN CALCULATION
# ==========================================
rr_calculate() {
    local n=$1
    local quantum=$2
    
    declare -a l_pid l_bt l_at l_remaining l_ct l_wt l_tat
    
    for ((i=0; i<n; i++)); do
        l_pid[$i]=$i
        l_bt[$i]=${bt[$i]}
        l_at[$i]=${at[$i]}
        l_remaining[$i]=${bt[$i]}
        l_wt[$i]=0
    done
    
    local time=0
    local completed=0
    local queue=()
    local in_queue=()
    
    for ((i=0; i<n; i++)); do
        in_queue[$i]=0
    done
    
    for ((i=0; i<n; i++)); do
        if [ ${l_at[$i]} -eq 0 ]; then
            queue+=($i)
            in_queue[$i]=1
        fi
    done
    
    echo "Execution Order:"
    echo "----------------"
    
    while [ $completed -lt $n ]; do
        # --- MODIFIED: idle time prints step-by-step, not jump ---
        if [ ${#queue[@]} -eq 0 ]; then
            echo "Time : $time | Idle"
            time=$((time + 1))
            for ((i=0; i<n; i++)); do
                if [ ${l_at[$i]} -le $time ] && [ ${l_remaining[$i]} -gt 0 ] && [ ${in_queue[$i]} -eq 0 ]; then
                    queue+=($i)
                    in_queue[$i]=1
                fi
            done
            continue
        fi
        
        current=${queue[0]}
        queue=("${queue[@]:1}")
        in_queue[$current]=0
        
        if [ ${l_remaining[$current]} -gt $quantum ]; then
            execute=$quantum
        else
            execute=${l_remaining[$current]}
        fi
        
        echo "Time $time-$((time + execute)): P$((current+1))"
        
        time=$((time + execute))
        l_remaining[$current]=$((l_remaining[$current] - execute))
        
        for ((i=0; i<n; i++)); do
            arrival_time=${l_at[$i]}
            if [ $arrival_time -gt $((time - execute)) ] && [ $arrival_time -le $time ] && [ ${l_remaining[$i]} -gt 0 ] && [ ${in_queue[$i]} -eq 0 ]; then
                local already=0
                for q in "${queue[@]}"; do
                    if [ $q -eq $i ]; then
                        already=1
                        break
                    fi
                done
                if [ $already -eq 0 ]; then
                    queue+=($i)
                    in_queue[$i]=1
                fi
            fi
        done
        
        if [ ${l_remaining[$current]} -eq 0 ]; then
            l_ct[$current]=$time
            completed=$((completed + 1))
            echo "  -> P$((current+1)) completed at time $time"
        else
            queue+=($current)
            in_queue[$current]=1
        fi
    done
    
    echo
    
    total_wt=0
    total_tat=0
    
    for ((i=0; i<n; i++)); do
        l_tat[$i]=$((l_ct[$i] - l_at[$i]))
        l_wt[$i]=$((l_tat[$i] - l_bt[$i]))
        total_wt=$((total_wt + l_wt[$i]))
        total_tat=$((total_tat + l_tat[$i]))
    done
    
    echo "----------------------------------------"
    printf "| %-8s | %-8s | %-8s | %-8s | %-8s | %-8s |\n" "Process" "AT" "BT" "CT" "TAT" "WT"
    echo "----------------------------------------"
    for ((i=0; i<n; i++)); do
        printf "| P%-7d | %-8d | %-8d | %-8d | %-8d | %-8d |\n" \
            $((i+1)) ${l_at[$i]} ${l_bt[$i]} ${l_ct[$i]} ${l_tat[$i]} ${l_wt[$i]}
    done
    echo "----------------------------------------"
    echo
    echo "Average Waiting Time:     $(echo "scale=2; $total_wt / $n" | bc)"
    echo "Average Turnaround Time:  $(echo "scale=2; $total_tat / $n" | bc)"
    echo
    echo "Gantt Chart:"
    echo -n " "
    for ((i=0; i<n; i++)); do
        echo -n "--------"
    done
    echo
    echo -n "|"
    for ((i=0; i<n; i++)); do
        echo -n " P$((l_pid[$i]+1))    |"
    done
    echo
    echo -n " "
    for ((i=0; i<n; i++)); do
        echo -n "--------"
    done
    echo
    echo -n "0"
    for ((i=0; i<n; i++)); do
        printf "       %d" ${l_ct[$i]}
    done
    echo
}

# ==========================================
# --- ADDED: PRIORITY SCHEDULING INPUT ---
# ==========================================
priority_input() {
    n=$(get_process_count)
    [ -z "$n" ] && return

    # Build form: BT, AT, Priority for each process
    declare -a fields
    for ((i=0; i<n; i++)); do
        fields+=("--add-entry=P$((i+1)) Burst Time")
    done
    for ((i=0; i<n; i++)); do
        fields+=("--add-entry=P$((i+1)) Arrival Time")
    done
    for ((i=0; i<n; i++)); do
        fields+=("--add-entry=P$((i+1)) Priority (lower = higher priority)")
    done

    data=$(zenity_full forms \
        --title="Priority Scheduling - Process Details" \
        --text="<big><b>Enter process information:</b></big>
Lower priority number = Higher priority" \
        "${fields[@]}")

    [ $? -ne 0 ] || [ -z "$data" ] && return

    IFS='|' read -ra values <<< "$data"

    declare -a pr_bt pr_at pr_prio
    for ((i=0; i<n; i++)); do
        pr_bt[$i]=${values[$i]}
        pr_at[$i]=${values[$((n + i))]}
        pr_prio[$i]=${values[$((2*n + i))]}

        if ! [[ "${pr_bt[$i]}" =~ ^[0-9]+$ ]] || [ "${pr_bt[$i]}" -lt 1 ]; then
            zenity_full error --text="Invalid burst time for P$((i+1))"
            return
        fi
        if ! [[ "${pr_at[$i]}" =~ ^[0-9]+$ ]]; then
            zenity_full error --text="Invalid arrival time for P$((i+1))"
            return
        fi
        if ! [[ "${pr_prio[$i]}" =~ ^[0-9]+$ ]]; then
            zenity_full error --text="Invalid priority for P$((i+1))"
            return
        fi
    done

    # Load into global arrays used by priority_calculate
    for ((i=0; i<n; i++)); do
        bt[$i]=${pr_bt[$i]}
        at[$i]=${pr_at[$i]}
        prio[$i]=${pr_prio[$i]}
    done

    {
        echo "========================================="
        echo "   PRIORITY SCHEDULING (Non-preemptive)"
        echo "   (Lower value = Higher Priority)"
        echo "========================================="
        echo
        priority_calculate $n
    } > /tmp/output.txt

    zenity_full text-info \
        --title="Priority Scheduling Results" \
        --filename=/tmp/output.txt \
        --font="Monospace 11"
}

# ==========================================
# --- ADDED: PRIORITY SCHEDULING CALCULATE ---
# Non-preemptive. Tie-break: 1) arrival time  2) burst time
# ==========================================
priority_calculate() {
    local n=$1

    declare -a l_pid l_bt l_at l_prio l_completed l_ct l_tat l_wt
    declare -a gantt_pid gantt_start gantt_end
    local gantt_count=0

    for ((i=0; i<n; i++)); do
        l_pid[$i]=$i
        l_bt[$i]=${bt[$i]}
        l_at[$i]=${at[$i]}
        l_prio[$i]=${prio[$i]}
        l_completed[$i]=0
    done

    local time=0
    local completed_count=0

    echo "Execution Timeline:"
    echo "-------------------"

    while [ $completed_count -lt $n ]; do
        local best_prio=99999
        local min_index=-1

        # Pick highest priority (lowest value) among arrived, not completed
        for ((i=0; i<n; i++)); do
            if [ ${l_completed[$i]} -eq 0 ] && [ ${l_at[$i]} -le $time ]; then
                if [ ${l_prio[$i]} -lt $best_prio ]; then
                    best_prio=${l_prio[$i]}
                    min_index=$i
                # Tie-break 1: earliest arrival
                elif [ ${l_prio[$i]} -eq $best_prio ] && [ ${l_at[$i]} -lt ${l_at[$min_index]} ]; then
                    min_index=$i
                # Tie-break 2: shortest burst
                elif [ ${l_prio[$i]} -eq $best_prio ] && [ ${l_at[$i]} -eq ${l_at[$min_index]} ] && [ ${l_bt[$i]} -lt ${l_bt[$min_index]} ]; then
                    min_index=$i
                fi
            fi
        done

        # --- Idle time: print step-by-step ---
        if [ $min_index -eq -1 ]; then
            echo "Time : $time | Idle"
            time=$((time + 1))
            continue
        fi

        echo "Time $time: Running P$((l_pid[$min_index]+1)) (Priority=${l_prio[$min_index]}, BT=${l_bt[$min_index]})"

        gantt_pid[$gantt_count]=${l_pid[$min_index]}
        gantt_start[$gantt_count]=$time
        gantt_end[$gantt_count]=$((time + l_bt[$min_index]))
        gantt_count=$((gantt_count + 1))

        time=$((time + l_bt[$min_index]))
        l_ct[$min_index]=$time
        l_completed[$min_index]=1
        completed_count=$((completed_count + 1))
        echo "Time $time: P$((l_pid[$min_index]+1)) completed"
    done

    echo

    total_wt=0
    total_tat=0

    for ((i=0; i<n; i++)); do
        l_tat[$i]=$((l_ct[$i] - l_at[$i]))
        l_wt[$i]=$((l_tat[$i] - l_bt[$i]))
        total_wt=$((total_wt + l_wt[$i]))
        total_tat=$((total_tat + l_tat[$i]))
    done

    echo "------------------------------------------------------------"
    printf "| %-8s | %-8s | %-8s | %-8s | %-8s | %-8s | %-8s |\n" "Process" "AT" "BT" "Prio" "CT" "TAT" "WT"
    echo "------------------------------------------------------------"
    for ((i=0; i<n; i++)); do
        printf "| P%-7d | %-8d | %-8d | %-8d | %-8d | %-8d | %-8d |\n" \
            $((i+1)) ${l_at[$i]} ${l_bt[$i]} ${l_prio[$i]} ${l_ct[$i]} ${l_tat[$i]} ${l_wt[$i]}
    done
    echo "------------------------------------------------------------"
    echo
    echo "Average Waiting Time:     $(echo "scale=2; $total_wt / $n" | bc)"
    echo "Average Turnaround Time:  $(echo "scale=2; $total_tat / $n" | bc)"

    echo
    echo "Gantt Chart:"
    echo -n " "
    for ((i=0; i<gantt_count; i++)); do
        echo -n "----------"
    done
    echo
    echo -n "|"
    for ((i=0; i<gantt_count; i++)); do
        printf " P%-6d |" $((gantt_pid[$i]+1))
    done
    echo
    echo -n " "
    for ((i=0; i<gantt_count; i++)); do
        echo -n "----------"
    done
    echo
    echo -n "${gantt_start[0]}"
    for ((i=0; i<gantt_count; i++)); do
        printf "         %d" ${gantt_end[$i]}
    done
    echo
}

# ==========================================
# --- ADDED: HYBRID SCHEDULING INPUT ---
# Combines Priority + FCFS + SJF (non-preemptive)
# ==========================================
hybrid_input() {
    n=$(get_process_count)
    [ -z "$n" ] && return

    declare -a fields
    for ((i=0; i<n; i++)); do
        fields+=("--add-entry=P$((i+1)) Burst Time")
    done
    for ((i=0; i<n; i++)); do
        fields+=("--add-entry=P$((i+1)) Arrival Time")
    done
    for ((i=0; i<n; i++)); do
        fields+=("--add-entry=P$((i+1)) Priority (lower = higher priority)")
    done

    data=$(zenity_full forms \
        --title="Hybrid Scheduling - Process Details" \
        --text="<big><b>Hybrid Scheduling (Priority + FCFS + SJF)</b></big>

Selection rules:
  1. Highest priority (lowest value)
  2. If tie → earliest arrival (FCFS)
  3. If tie → shortest burst (SJF)" \
        "${fields[@]}")

    [ $? -ne 0 ] || [ -z "$data" ] && return

    IFS='|' read -ra values <<< "$data"

    for ((i=0; i<n; i++)); do
        bt[$i]=${values[$i]}
        at[$i]=${values[$((n + i))]}
        prio[$i]=${values[$((2*n + i))]}

        if ! [[ "${bt[$i]}" =~ ^[0-9]+$ ]] || [ "${bt[$i]}" -lt 1 ]; then
            zenity_full error --text="Invalid burst time for P$((i+1))"
            return
        fi
        if ! [[ "${at[$i]}" =~ ^[0-9]+$ ]]; then
            zenity_full error --text="Invalid arrival time for P$((i+1))"
            return
        fi
        if ! [[ "${prio[$i]}" =~ ^[0-9]+$ ]]; then
            zenity_full error --text="Invalid priority for P$((i+1))"
            return
        fi
    done

    {
        echo "========================================="
        echo "       HYBRID SCHEDULING"
        echo "   Priority -> FCFS -> SJF (Non-preemptive)"
        echo "========================================="
        echo
        hybrid_calculate $n
    } > /tmp/output.txt

    zenity_full text-info \
        --title="Hybrid Scheduling Results" \
        --filename=/tmp/output.txt \
        --font="Monospace 11"
}

# ==========================================
# --- ADDED: HYBRID SCHEDULING CALCULATE ---
# Rule: 1) Lowest priority value  2) Earliest arrival  3) Shortest burst
# ==========================================
hybrid_calculate() {
    local n=$1

    declare -a l_pid l_bt l_at l_prio l_completed l_ct l_tat l_wt
    declare -a gantt_pid gantt_start gantt_end
    local gantt_count=0

    for ((i=0; i<n; i++)); do
        l_pid[$i]=$i
        l_bt[$i]=${bt[$i]}
        l_at[$i]=${at[$i]}
        l_prio[$i]=${prio[$i]}
        l_completed[$i]=0
    done

    local time=0
    local completed_count=0

    echo "Execution Timeline:"
    echo "-------------------"

    while [ $completed_count -lt $n ]; do
        local best_prio=99999
        local min_index=-1

        for ((i=0; i<n; i++)); do
            if [ ${l_completed[$i]} -eq 0 ] && [ ${l_at[$i]} -le $time ]; then
                if [ $min_index -eq -1 ]; then
                    min_index=$i
                    best_prio=${l_prio[$i]}
                else
                    # Rule 1: lower priority value wins
                    if [ ${l_prio[$i]} -lt $best_prio ]; then
                        min_index=$i
                        best_prio=${l_prio[$i]}
                    # Rule 2: same priority -> earlier arrival (FCFS)
                    elif [ ${l_prio[$i]} -eq $best_prio ] && [ ${l_at[$i]} -lt ${l_at[$min_index]} ]; then
                        min_index=$i
                    # Rule 3: same priority + same arrival -> shorter burst (SJF)
                    elif [ ${l_prio[$i]} -eq $best_prio ] && [ ${l_at[$i]} -eq ${l_at[$min_index]} ] && [ ${l_bt[$i]} -lt ${l_bt[$min_index]} ]; then
                        min_index=$i
                    fi
                fi
            fi
        done

        # Idle time: step-by-step
        if [ $min_index -eq -1 ]; then
            echo "Time : $time | Idle"
            time=$((time + 1))
            continue
        fi

        echo "Time $time: Running P$((l_pid[$min_index]+1)) (Prio=${l_prio[$min_index]}, AT=${l_at[$min_index]}, BT=${l_bt[$min_index]})"

        gantt_pid[$gantt_count]=${l_pid[$min_index]}
        gantt_start[$gantt_count]=$time
        gantt_end[$gantt_count]=$((time + l_bt[$min_index]))
        gantt_count=$((gantt_count + 1))

        time=$((time + l_bt[$min_index]))
        l_ct[$min_index]=$time
        l_completed[$min_index]=1
        completed_count=$((completed_count + 1))
        echo "Time $time: P$((l_pid[$min_index]+1)) completed"
    done

    echo

    total_wt=0
    total_tat=0

    for ((i=0; i<n; i++)); do
        l_tat[$i]=$((l_ct[$i] - l_at[$i]))
        l_wt[$i]=$((l_tat[$i] - l_bt[$i]))
        total_wt=$((total_wt + l_wt[$i]))
        total_tat=$((total_tat + l_tat[$i]))
    done

    echo "------------------------------------------------------------"
    printf "| %-8s | %-8s | %-8s | %-8s | %-8s | %-8s | %-8s |\n" "Process" "AT" "BT" "Prio" "CT" "TAT" "WT"
    echo "------------------------------------------------------------"
    for ((i=0; i<n; i++)); do
        printf "| P%-7d | %-8d | %-8d | %-8d | %-8d | %-8d | %-8d |\n" \
            $((i+1)) ${l_at[$i]} ${l_bt[$i]} ${l_prio[$i]} ${l_ct[$i]} ${l_tat[$i]} ${l_wt[$i]}
    done
    echo "------------------------------------------------------------"
    echo
    echo "Average Waiting Time:     $(echo "scale=2; $total_wt / $n" | bc)"
    echo "Average Turnaround Time:  $(echo "scale=2; $total_tat / $n" | bc)"

    echo
    echo "Gantt Chart:"
    echo -n " "
    for ((i=0; i<gantt_count; i++)); do
        echo -n "----------"
    done
    echo
    echo -n "|"
    for ((i=0; i<gantt_count; i++)); do
        printf " P%-6d |" $((gantt_pid[$i]+1))
    done
    echo
    echo -n " "
    for ((i=0; i<gantt_count; i++)); do
        echo -n "----------"
    done
    echo
    echo -n "${gantt_start[0]}"
    for ((i=0; i<gantt_count; i++)); do
        printf "         %d" ${gantt_end[$i]}
    done
    echo
}

# ==========================================
# CUSTOM TERMINAL SECTION
# ==========================================
custom_terminal() {
    clear
    echo "======================================================="
    echo "                WELCOME TO SMART-SHELL                "
    echo "======================================================="

    while true; do
        printf "${GREEN}smart-shell > ${RESET}"
        read cmd args

        case $cmd in
            guide)
                echo -e "${CYAN}Available Commands:${RESET}"
                echo " guide          - Show all commands"
                echo " aboutbox       - Show system information"
                echo " time           - Show current time"
                echo " showpath       - Show current path"
                echo " changedir      - Change current directory"
                echo " del            - Delete file"
                echo " showfiles      - List files in directory"
                echo " showlarge      - Largest files first"
                echo " showsmall      - Smallest files first"
                echo " myid           - Display current user"
                echo " mkfile         - Create a file"
                echo " open           - View file content"
                echo " edit           - Edit file"
                echo " goto           - Change directory"
                echo " syshealth      - Show system health"
                echo " battery        - Show battery level"
                echo " wipe           - Clear terminal"
                echo " exit           - Return to main menu"
                ;;
            aboutbox)
                uname -a
                ;;
            time)
                echo "Current Time: $(date)"
                ;;
            showpath)
                echo "$(pwd)"
                ;;
            changedir)
                if [ -z "$args" ]; then
                    echo -e "${YELLOW}Usage: changedir <path>${RESET}"
                else
                    if [ -d "$args" ]; then
                        cd "$args"
                        echo "Moved to: $(pwd)"
                    else
                        echo -e "${YELLOW}Directory does not exist${RESET}"
                    fi
                fi
                ;;
            showfiles)
                ls
                ;;
            myid)
                whoami
                ;;
            mkfile)
                if [ -z "$args" ]; then
                    echo -e "${YELLOW}Usage: mkfile <filename>${RESET}"
                else
                    touch "$args"
                    echo "File created: $args"
                fi
                ;;
            open)
                if [ -z "$args" ]; then
                    echo -e "${YELLOW}Usage: open <filename>${RESET}"
                else
                    if [ -f "$args" ]; then
                        cat "$args"
                    else
                        echo "File not found!"
                    fi
                fi
                ;;
            edit)
                if [ -z "$args" ]; then
                    echo -e "${YELLOW}Usage: edit <filename>${RESET}"
                else
                    if command -v nano >/dev/null 2>&1; then
                        nano "$args"
                    elif command -v vi >/dev/null 2>&1; then
                        vi "$args"
                    else
                        echo "No editor found (install nano or vi)."
                    fi
                fi
                ;;
            showlarge)
                if [ -z "$args" ]; then
                    echo -e "${YELLOW}Usage: showlarge <number>${RESET}"
                else
                    if [[ "$args" =~ ^[0-9]+$ ]]; then
                        echo "Showing top $args largest files:"
                        ls -lhS | head -n "$args"
                    else
                        echo -e "${YELLOW}Please enter a valid number.${RESET}"
                    fi
                fi
                ;;
            showsmall)
                if [ -z "$args" ]; then
                    echo -e "${YELLOW}Usage: showsmall <number>${RESET}"
                else
                    if [[ "$args" =~ ^[0-9]+$ ]]; then
                        echo "Showing top $args smallest files:"
                        ls -lhS | tail -n "$args"
                    else
                        echo -e "${YELLOW}Please enter a valid number.${RESET}"
                    fi
                fi
                ;;
            del)
                if [ -z "$args" ]; then
                    echo "Usage: del <filename>"
                else
                    rm -f "$args" 2>/dev/null && echo "Deleted: $args" || echo "File not found!"
                fi
                ;;
            goto)
                if [ -d "$args" ]; then
                    cd "$args"
                else
                    echo -e "${YELLOW}Directory does not exist!${RESET}"
                fi
                ;;
            syshealth)
                echo "---- System Health ----"
                echo "CPU Load: $(uptime | awk -F'load average:' '{ print $2 }')"
                echo "RAM Usage:"
                free -h
                echo "Disk Usage:"
                df -h /
                echo "Uptime: $(uptime -p)"
                ;;
            battery)
                if command -v acpi >/dev/null 2>&1; then
                    acpi -b
                else
                    echo -e "${YELLOW}Battery info not supported on this system.${RESET}"
                fi
                ;;
            wipe)
                clear
                ;;
            exit)
                break
                ;;
            "")
                ;;
            *)
                echo -e "${YELLOW}Unknown command: $cmd${RESET}"
                echo "Type 'guide' to see commands."
                ;;
        esac
    done
}

# ==========================================
# ZENITY MAIN MENU (Fullscreen)
# ==========================================
main_menu() {
    get_screen_size
    
    while true; do
        CHOICE=$(zenity_full list \
            --title="🔷 S.M.A.R.T - Main Menu" \
            --text="<big><b>Welcome to System Monitoring And Resource Toolkit</b></big>\n\n<b>Please select an option:</b>" \
            --column="Option" \
            --column="Description" \
            --column="Icon" \
            --ok-label="Select" \
            --cancel-label="Exit" \
            "1" "📊 Process Manager - View and control running processes" "system-run" \
            "2" "📈 System Dashboard - CPU, Memory, Disk information" "utilities-system-monitor" \
            "3" "⚙️ CPU Scheduling - Algorithm simulation (FCFS, SJF, SRTF, RR)" "accessories-calculator" \
            "4" "💻 Custom Terminal - Smart-Shell command line" "terminal" \
            "5" "🔒 Reset Password - Change your login password" "dialog-password" \
            "6" "🚪 Exit - Close S.M.A.R.T" "application-exit")
        
        EXIT_STATUS=$?
        
        if [ $EXIT_STATUS -ne 0 ] || [ -z "$CHOICE" ]; then
            zenity_full question \
                --title="Exit S.M.A.R.T" \
                --text="Are you sure you want to exit S.M.A.R.T?" \
                --ok-label="Yes, Exit" \
                --cancel-label="Cancel"
            
            if [ $? -eq 0 ]; then
                exit_animation
                exit 0
            else
                continue
            fi
        fi
        
        case "$CHOICE" in
            "1"|"📊 Process Manager - View and control running processes")
                process_manager
                ;;
            "2"|"📈 System Dashboard - CPU, Memory, Disk information")
                system_dashboard
                ;;
            "3"|"⚙️ CPU Scheduling - Algorithm simulation (FCFS, SJF, SRTF, RR)")
                cpu_menu
                ;;
            "4"|"💻 Custom Terminal - Smart-Shell command line")
                zenity_full warning \
                    --title="Switch to Terminal Mode" \
                    --text="Custom Terminal will open in TEXT MODE.\n\nType 'guide' for available commands.\nType 'exit' to return to GUI menu."
                custom_terminal
                ;;
            "5"|"🔒 Reset Password - Change your login password")
                reset_password
                ;;
            "6"|"🚪 Exit - Close S.M.A.R.T")
                zenity_full question \
                    --title="Exit S.M.A.R.T" \
                    --text="Are you sure you want to exit?" \
                    --ok-label="Yes" \
                    --cancel-label="No"
                if [ $? -eq 0 ]; then
                    exit_animation
                    exit 0
                fi
                ;;
            *)
                zenity_full error \
                    --title="Error" \
                    --text="Invalid option selected!"
                ;;
        esac
    done
}

# ==========================================
# PROGRAM START
# ==========================================

# Check if running in terminal (for zenity to work properly)
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    echo "Error: This script requires a graphical environment (X11/Wayland) for Zenity."
    echo "Please run in a terminal with GUI access."
    exit 1
fi

# Check if zenity is installed
if ! command -v zenity &> /dev/null; then
    echo "Error: Zenity is not installed."
    echo "Please install it with: sudo apt install zenity"
    exit 1
fi

# Run boot animation and login
boot_animation
login_system

# If login fails or returns, exit
exit_animation
exit 0
