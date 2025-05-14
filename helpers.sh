#!/bin/bash

# WebSleuth - Helper Functions

# Result formatting function
function format_result() {
    local type=$1
    local message=$2
    local timestamp=$(date "+%H:%M:%S")
    
    local formatted_message=""
    case $type in
        "INFO")    formatted_message="${BLUE}[${timestamp}] ℹ ${NC}${message}";;
        "SUCCESS") formatted_message="${GREEN}[${timestamp}] ✓ ${NC}${message}";;
        "WARNING") formatted_message="${YELLOW}[${timestamp}] ⚠ ${NC}${message}";;
        "ERROR")   formatted_message="${RED}[${timestamp}] ✗ ${NC}${message}";;
        "HEADER")  formatted_message="${MAGENTA}${BOLD}[${timestamp}] ➤ ${NC}${BOLD}${message}${NC}";;
        *)         formatted_message="[${timestamp}] ${message}";;
    esac
    output_result "$formatted_message"
}

# Output handling function (modified for clarity)
function output_result() {
    local message=$1
    
    # Print to stdout
    echo -e "$message"

    # If OUTPUT file is specified, append to it
    # ANSI colors are kept in the file as per original implicit behavior
    if [ -n "$OUTPUT" ]; then
        echo -e "$message" >> "$OUTPUT"
    fi

    # If DEBUG mode is enabled, print additional debug information to stdout
    if [ "$DEBUG" = true ]; then
        echo -e "${YELLOW}[DEBUG] ${message}${NC}"
    fi
}


# Enhanced banner
function banner() {
    # Clear screen before printing banner - original behavior.
    # Consider if `clear` is always desirable or should be conditional.
    # For now, keeping it as it might be part of the intended UX.
    clear 
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    # Use output_result for banner lines if they should also go to the log file
    # For now, banner is console-only as per typical tool behavior.
    echo -e "${CYAN}${BOLD}"
    echo "════════════════════════════════════════════"
    echo "              WebSleuth               "
    echo "Advanced Website Reconnaissance Tool    "
    echo "════════════════════════════════════════════"
    echo -e "${WHITE}Started at: ${timestamp}${NC}\n"
}

# Help menu
function help_menu() {
    # Help menu is console-only.
    echo -e "${BLUE}${BOLD}WebSleuth- Advanced Usage Guide${NC}\n"
    echo -e "${WHITE}${BOLD}Basic Usage:${NC}"
    echo "  ./websleuth.sh -u <URL> [OPTIONS]"
    
    echo -e "\n${WHITE}${BOLD}Essential Options:${NC}"
    echo -e "  ${GREEN}-u, --url${NC} <URL>          Target URL for reconnaissance"
    echo -e "  ${GREEN}-o, --output${NC} <FILE>      Save output to a file (Default: results_<domain>_<timestamp>.txt)"
    echo -e "  ${GREEN}-w, --wordlist${NC} <FILE>    Custom wordlist for brute-forcing (affects subdomains, dirs)"
    echo -e "  ${GREEN}-t, --threads${NC} <NUMBER>   Number of threads for tools like gobuster, ffuf (Default: 10)"
    echo -e "  ${GREEN}-a, --all${NC}                Run all reconnaissance modules"
    
    echo -e "\n${WHITE}${BOLD}Scan Modules:${NC}"
    echo -e "  ${CYAN}--dns${NC}                   DNS enumeration"
    echo -e "  ${CYAN}--subdomains${NC}            Subdomain enumeration"
    echo -e "  ${CYAN}--dirs${NC}                  Directory discovery"
    echo -e "  ${CYAN}--headers${NC}               HTTP headers analysis"
    echo -e "  ${CYAN}--ports${NC}                 Port scanning (Nmap)"
    echo -e "  ${CYAN}--ssl${NC}                   SSL/TLS analysis"
    echo -e "  ${CYAN}--whois${NC}                 WHOIS lookup"
    echo -e "  ${CYAN}--tech-stack${NC}            Technology stack identification (WhatWeb)"
    
    echo -e "\n${WHITE}${BOLD}Additional Options:${NC}"
    echo -e "  ${YELLOW}--timeout${NC} <SECONDS>     Set custom timeout for applicable tools (e.g., curl) (Default: 10)"
    echo -e "  ${YELLOW}--exclude${NC} <PORTS>       Exclude specific ports (Note: Nmap syntax, e.g., '80,443' - currently parsed but not implemented in port scan)"
    echo -e "  ${YELLOW}--agressive-scan${NC}            Perform a agressive Nmap port scan (all 65535 ports) instead of fast scan"
    echo -e "  ${YELLOW}--debug${NC}                 Enable debug mode (verbose output)"
    echo -e "  ${GREEN}-h, --help${NC}                Show this help menu"
    
    exit 0
}

# Required tools check
function check_requirements() {
    # This function directly echos, not using output_result as it's pre-run feedback.
    echo -e "${BLUE}[INFO] Checking for required tools...${NC}"

    local missing_tools=()
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${RED}[ERROR] Missing: $tool${NC}"
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "\n${YELLOW}[WARNING] The following tools are missing:${NC}"
        echo -e "${WHITE}${missing_tools[*]}${NC}"

        local INSTALL_CMD=""
        if command -v apt-get &> /dev/null; then
            INSTALL_CMD="sudo apt-get install -y ${missing_tools[*]}"
        elif command -v dnf &> /dev/null; then
            INSTALL_CMD="sudo dnf install -y ${missing_tools[*]}"
        elif command -v yum &> /dev/null; then
            INSTALL_CMD="sudo yum install -y ${missing_tools[*]}"
        elif command -v pacman &> /dev/null; then
            INSTALL_CMD="sudo pacman -S --noconfirm ${missing_tools[*]}"
        elif command -v brew &> /dev/null; # macOS
            INSTALL_CMD="brew install ${missing_tools[*]}"
        else
            echo -e "${RED}[ERROR] Unsupported package manager. Please install the missing tools manually.${NC}"
            exit 1
        fi

        echo -ne "${CYAN}[PROMPT] Do you want to attempt to install the missing tools? (y/n): ${NC}"
        read -r user_input
        if [[ "$user_input" =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}[INFO] Attempting to install missing tools...${NC}"
            # Using eval can be risky, ensure missing_tools[*] is controlled. Here it's from a predefined list.
            eval "$INSTALL_CMD"
            # Re-check after installation attempt
            local still_missing_tools=()
            for tool in "${missing_tools[@]}"; do
                if ! command -v "$tool" &> /dev/null; then
                    still_missing_tools+=("$tool")
                fi
            done
            if [ ${#still_missing_tools[@]} -ne 0 ]; then
                echo -e "${RED}[ERROR] Failed to install: ${still_missing_tools[*]}. Please install them manually.${NC}"
                exit 1
            else
                echo -e "${GREEN}[SUCCESS] Installation of missing tools completed.${NC}"
            fi
        else
            echo -e "${RED}[EXIT] Missing dependencies. Exiting...${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}[SUCCESS] All required tools are installed.${NC}\n"
    fi
}