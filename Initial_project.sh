#!/bin/bash
# ==========================================
# S.M.A.R.T - System Monitoring And Resource Toolkit
# CSE 324 - Final Version
# Team: Saif, Mahadi, Abir, Roshaed, Tonmoy
# ==========================================

# Color codes
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RESET="\e[0m"

pause() {
    echo
    read -p "Press Enter to continue..."
}


#Login system function
login_system() {

    PASS_FILE="$HOME/password.txt"
    MAX_TRY=3

    # First Time Password Setup

    if [ ! -f "$PASS_FILE" ]; then
        echo "No password found!"
        echo "Please set a new password: "
        read -s NEW_PASS
        echo
        echo "Confirm password: "
        read -s CONFIRM_PASS
        echo

        if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
            echo "Password mismatch! Run again."
            return 1
        fi

        echo "$NEW_PASS" > "$PASS_FILE"
        echo "Password saved successfully!"
     
    fi

    # =================
    # Login System
    # =================
    TRY=1

    while [ $TRY -le $MAX_TRY ]; do
        echo -n "Enter password: "
        read -s INPUT_PASS
        echo

        STORED_PASS=$(cat "$PASS_FILE")

        if [ "$INPUT_PASS" = "$STORED_PASS" ]; then
            echo "Login successful!"
			#main menu call
			main_menu
			break
        else
            echo "Wrong password! Attempt $TRY/$MAX_TRY"
        fi

        TRY=$((TRY + 1))
    done

    echo "Too many wrong attempts! Access denied."
    sleep 2
    exit_animation
}

reset_password() {
    clear
    PASS_FILE="$HOME/password.txt"

    echo -n "Enter current password: "
    read -s CUR_PASS
    echo

    STORED_PASS=$(cat "$PASS_FILE")

    if [ "$CUR_PASS" != "$STORED_PASS" ]; then
        echo "Incorrect password!"
        sleep 1
        return
    fi

    echo -n "Enter new password: "
    read -s NEW_PASS
    echo
    echo -n "Confirm new password: "
    read -s CONFIRM_PASS
    echo

    if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
        echo "Passwords do not match!"
        sleep 1
        return
    fi

    echo "$NEW_PASS" > "$PASS_FILE"
    echo "Password successfully changed!"
    pause
}



# -----------------------------
# BOOT ANIMATION
# -----------------------------
boot_animation() {
    clear
    echo "=========================================="
    echo "      S.M.A.R.T System Initializing...    "
    echo "=========================================="
    sleep 1
    
    echo "[ OK ] Loading Kernel Modules..."
    sleep 0.4
    echo "[ OK ] Checking System Resources..."
    sleep 0.4
    echo "[ OK ] Starting User Interface..."
    sleep 0.4
    
    # A simple loop to print dots (...)
    echo -n "Booting System"
    for i in {1..6}; do
        echo -n "."
        sleep 0.2
    done
    echo " Done!"
    sleep 0.8
}

# -----------------------------
# FAKE EXIT ANIMATION
# -----------------------------
exit_animation() {
    clear
    echo "=========================================="
    echo "         Shutting Down S.M.A.R.T          "
    echo "=========================================="
    sleep 0.5
    
    echo "[ OK ] Stopping Background Services..."
    sleep 0.4
    echo "[ OK ] Saving Session State..."
    sleep 0.4
    echo "[ OK ] Releasing Memory..."
    sleep 0.4
    
    echo -n "Powering Off"
    for i in {1..6}; do
        echo -n "."
        sleep 0.2
    done
    echo
    echo "Goodbye!"
    sleep 1
    clear
}

# -----------------------------
# 1. PROCESS MANAGER
# -----------------------------
process_manager() {
    while true; do
        clear
        echo "===== PROCESS MANAGER ====="
        echo "1. Top CPU Processes"
        echo "2. Top Memory Processes"
        echo "3. Kill a Process"
        echo "4. Return"
        read -p "Enter choice: " ch

        case "$ch" in
            1)
                echo "--- Top CPU Processes ---"
                echo "Enter how many top CPU processes you want to see:"
                read a
                ps -eo pid,comm,%cpu --sort=-%cpu | head -n $(( a + 1 ))
                pause
                ;;
            2)
                echo "--- Top Memory Processes ---"
                echo "Enter how many top Memory processes you want to see:"
                read a
                ps -eo pid,comm,%mem --sort=-%mem | head -n $(( a + 1 ))

                pause
                ;;
            3)
                echo "--- Kill a Process ---"
                echo "Enter PID to kill:"
                read pid
                if kill "$pid" 2>/dev/null; then
                    echo "Process $pid killed."
                else
                    echo "Failed to kill process (Check PID)."
                fi
                pause
                ;;
            4)
                return
                ;;
            *)
                echo "Invalid choice"; sleep 1 ;;
        esac
    done
} 

# -----------------------------
# 2. SYSTEM DASHBOARD
# -----------------------------
system_dashboard() {
    clear
    echo "===== SYSTEM DASHBOARD ====="
    echo
    echo "[ CPU Load ]"
    uptime
    echo
    echo "[ Memory Usage ]"
    free -h
    echo
    echo "[ Disk Usage ]"
    df -h --total | head -n 6
    echo
    pause
}

# -----------------------------
# 3. FCFS CPU SCHEDULING
# -----------------------------
fcfs() {
    clear
    echo "===== FCFS SCHEDULING ====="

    read -p "Number of processes: " n

    declare -a pid bt wt tat

    # Input Loop
    echo "--- Enter Process Details ---"
    for ((i=0;i<n;i++)); do
        read -p "Process ID [$((i+1))]: " pid[$i]
        read -p "Burst Time: " bt[$i]
    done

    # Calculation: Waiting Time (WT)
    # First process waits 0
    wt[0]=0
    for ((i=1;i<n;i++)); do
        # Current WT = Previous WT + Previous BT
        wt[$i]=$(( wt[i-1] + bt[i-1] ))
    done

    # Output Table
    echo
    echo "PID    BT    WT    TAT"
    echo "------------------------"
    for ((i=0;i<n;i++)); do
        # Calculation: Turn Around Time (TAT = WT + BT)
        tat[$i]=$(( wt[i] + bt[i] ))
        # Fixed syntax: added $ inside braces for strict correctness
        printf "%-6s %-5s %-5s %-5s\n" "${pid[$i]}" "${bt[$i]}" "${wt[$i]}" "${tat[$i]}"
    done

    pause
}

cpu_menu() {
    while true; do
        clear
        echo "===== CPU SCHEDULING ====="
        echo "1. FCFS Algorithm"
        echo "2. Return"
        read -p "Enter choice: " ch

        case "$ch" in
            1) fcfs ;;
            2) return ;;
            *) echo "Invalid choice"; sleep 1 ;;
        esac
    done
}

#Custom terminal section
custom_terminal() {

clear

echo "======================================================="
echo "                WELCOME TO SMART-SHELL                "
echo "======================================================="


    while true; do
        printf "${GREEN}smart-shell > ${RESET}"
        read cmd args

        case $cmd in

            # GUIDE (help)
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

            # About information
            aboutbox)
                uname -a
                ;;

            # Time showing function
            time)
                echo "Current Time: $(date)"
                ;;

            # Show path
            showpath)
                echo "$(pwd)"
                ;;

            # Change directory function
            changedir)
                if [ -z "$args" ]; then
                    echo -e "${YELLOW}Usage: changedir <path>${RESET}"
                    echo "Example: changedir /home/abir/Documents"
                else
                    if [ -d "$args" ]; then
                        cd "$args"
                        echo "Moved to: $(pwd)"
                    else
                        echo -e "${YELLOW}Directory does not exist${RESET}"
                    fi
                fi
                ;;

            # Show files
            showfiles)
                ls
                ;;

            # User info
            myid)
                whoami
                ;;

            # Create new file
            mkfile)
                if [ -z "$args" ]; then
                    echo -e "${YELLOW}Usage: mkfile <filename>${RESET}"
                else
                    touch "$args"
                    echo "File created: $args"
                fi
                ;;

            # Read file
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

            # Edit file
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

            # Show largest files
            showlarge)
                if [ -z "$args" ]; then
                    echo -e "${YELLOW}Usage: showlarge <number>${RESET}"
                    echo "Example: showlarge 5"
                else
                    if [[ "$args" =~ ^[0-9]+$ ]]; then
                        echo "Showing top $args largest files:"
                        ls -lhS | head -n "$args"
                    else
                        echo -e "${YELLOW}Please enter a valid number.${RESET}"
                    fi
                fi
                ;;

            # Show smallest files
            showsmall)
                if [ -z "$args" ]; then
                    echo -e "${YELLOW}Usage: showsmall <number>${RESET}"
                    echo "Example: showsmall 5"
                else
                    if [[ "$args" =~ ^[0-9]+$ ]]; then
                        echo "Showing top $args smallest files:"
                        ls -lhS | tail -n "$args"
                    else
                        echo -e "${YELLOW}Please enter a valid number.${RESET}"
                    fi
                fi
                ;;

            # Delete function
            del)
                if [ -z "$args" ]; then
                    echo "Usage: del <filename>"
                else
                    rm -f "$args" 2>/dev/null && echo "Deleted: $args" || echo "File not found!"
                fi
                ;;

            # Change directory (duplicate feature)
            goto)
                if [ -d "$args" ]; then

                    cd "$args"
                else
                    echo -e "${YELLOW}Directory does not exist!${RESET}"
                fi
                ;;

            # System health
            syshealth)
                echo "---- System Health ----"
                echo "CPU Load: $(uptime | awk -F'load average:' '{ print $2 }')"
                echo "RAM Usage:"
                free -h
                echo "Disk Usage:"
                df -h /
                echo "Uptime: $(uptime -p)"
                ;;

            # Battery info
            battery)
                if command -v acpi >/dev/null 2>&1; then
                    acpi -b
                else
                    echo -e "${YELLOW}Battery info not supported on this system.${RESET}"
                fi
                ;;

            # Clear terminal
            wipe)
                clear
                ;;

            # Exit
            exit)
                break
                ;;

            "")
                ;; # ignore empty input

            *)
                echo -e "${YELLOW}Unknown command: $cmd${RESET}"
                echo "Type 'guide' to see commands."
                ;;
        esac
    done
}

# -----------------------------
# MAIN MENU
# -----------------------------

# Run Boot Animation once at start

main_menu(){
	while true; do
    clear
    echo "=============================="
    echo "       S.M.A.R.T MENU         "
    echo "=============================="
    echo "1. Process Manager"
    echo "2. System Dashboard"
    echo "3. CPU Scheduling"
    echo "4. Custom Terminal"
    echo "5. Reset Password"
    echo "6. Exit"
    read -p "Enter choice: " choice

    case "$choice" in
        1) process_manager ;;
        2) system_dashboard ;;
        3) cpu_menu ;;
        4) custom_terminal ;;
        5) reset_password ;;
        6) 
           # Run Exit Animation before closing
           exit_animation 
           exit 0 
           ;;
        *) echo "Invalid choice"; sleep 1 ;;
    esac
done
}

boot_animation
login_system

