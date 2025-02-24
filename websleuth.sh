#!/bin/bash

# WebSleuth- Advanced Website Reconnaissance Tool
# Description: Comprehensive website reconnaissance with enhanced features and user-friendly output

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[1;31m[ERROR] Please run this script as root\033[0m"
    exit 1
fi

# Required tools check
REQUIRED_TOOLS=("curl" "nmap" "whois" "openssl" "whatweb" "gobuster" "seclists")

function check_requirements() {
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

        # Detect OS and package manager
        if command -v apt-get &> /dev/null; then
            INSTALL_CMD="sudo apt-get install -y ${missing_tools[*]}"
        elif command -v dnf &> /dev/null; then
            INSTALL_CMD="sudo dnf install -y ${missing_tools[*]}"
        elif command -v yum &> /dev/null; then
            INSTALL_CMD="sudo yum install -y ${missing_tools[*]}"
        elif command -v pacman &> /dev/null; then
            INSTALL_CMD="sudo pacman -S --noconfirm ${missing_tools[*]}"
        elif command -v brew &> /dev/null; then
            INSTALL_CMD="brew install ${missing_tools[*]}"
        else
            echo -e "${RED}[ERROR] Unsupported package manager. Please install manually.${NC}"
            exit 1
        fi

        # Ask user for permission to install missing tools
        echo -ne "${CYAN}[PROMPT] Do you want to install the missing tools? (y/n): ${NC}"
        read -r user_input
        if [[ "$user_input" =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}[INFO] Installing missing tools...${NC}"
            eval "$INSTALL_CMD"
            echo -e "${GREEN}[SUCCESS] Installation completed.${NC}"
        else
            echo -e "${RED}[EXIT] Missing dependencies. Exiting...${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}[SUCCESS] All required tools are installed.${NC}\n"
    fi
}


# Enhanced color palette
BOLD="\e[1m"
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
MAGENTA="\e[1;35m"
CYAN="\e[1;36m"
WHITE="\e[1;37m"
NC="\e[0m"

# Global variables
TARGET=""
OUTPUT=""
WORDLIST=""
THREADS=10
TIMEOUT=10
DEBUG=false
EXCLUDED_PORTS=""
RUN_ALL=false
TIMESTAMP=$(date +%Y%m%d_%H%M%S)


# Result formatting function
function format_result() {
    local type=$1
    local message=$2
    local timestamp=$(date "+%H:%M:%S")
    
    case $type in
        "INFO")    echo -e "${BLUE}[${timestamp}] ℹ ${NC}${message}";;
        "SUCCESS") echo -e "${GREEN}[${timestamp}] ✓ ${NC}${message}";;
        "WARNING") echo -e "${YELLOW}[${timestamp}] ⚠ ${NC}${message}";;
        "ERROR")   echo -e "${RED}[${timestamp}] ✗ ${NC}${message}";;
        "HEADER")  echo -e "${MAGENTA}${BOLD}[${timestamp}] ➤ ${NC}${BOLD}${message}${NC}";;
    esac
}

# Enhanced banner
function banner() {
    clear
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${CYAN}${BOLD}"
    echo "════════════════════════════════════════════"
    echo "              WebSleuth               "
    echo "Advanced Website Reconnaissance Tool    "
    echo "════════════════════════════════════════════"
    echo -e "${WHITE}Started at: ${timestamp}${NC}\n"
}

# Help menu
function help_menu() {
    echo -e "${BLUE}${BOLD}WebSleuth- Advanced Usage Guide${NC}\n"
    echo -e "${WHITE}${BOLD}Basic Usage:${NC}"
    echo "  ./websleuth.sh -u <URL> [OPTIONS]"
    
    echo -e "\n${WHITE}${BOLD}Essential Options:${NC}"
    echo -e "  ${GREEN}-u, --url${NC} <URL>          Target URL for reconnaissance"
    echo -e "  ${GREEN}-o, --output${NC} <FILE>      Save output to a file (Default: results_<domain>_<timestamp>.txt)"
    echo -e "  ${GREEN}-w, --wordlist${NC} <FILE>    Custom wordlist for brute-forcing"
    echo -e "  ${GREEN}-t, --threads${NC} <NUMBER>   Number of threads (Default: 10)"
    echo -e "  ${GREEN}-a, --all${NC}                Run all reconnaissance modules"
    
    echo -e "\n${WHITE}${BOLD}Scan Modules:${NC}"
    echo -e "  ${CYAN}--dns${NC}                   DNS enumeration"
    echo -e "  ${CYAN}--subdomains${NC}            Subdomain enumeration"
    echo -e "  ${CYAN}--dirs${NC}                  Directory discovery"
    echo -e "  ${CYAN}--headers${NC}               HTTP headers analysis"
    echo -e "  ${CYAN}--ports${NC}                 Port scanning"
    echo -e "  ${CYAN}--ssl${NC}                   SSL/TLS analysis"
    echo -e "  ${CYAN}--whois${NC}                 WHOIS lookup"
    echo -e "  ${CYAN}--tech-stack${NC}            Technology stack identification"
    
    echo -e "\n${WHITE}${BOLD}Additional Options:${NC}"
    echo -e "  ${YELLOW}--timeout${NC} <SECONDS>     Set custom timeout (Default: 10)"
    echo -e "  ${YELLOW}--exclude${NC} <PORTS>       Exclude specific ports"
    echo -e "  ${YELLOW}--debug${NC}                 Enable debug mode"
    
    exit 0
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -u|--url)
      TARGET="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT="$2"
      shift 2
      ;;
    -w|--wordlist)
      WORDLIST="$2"
      shift 2
      ;;
    -t|--threads)
      THREADS="$2"
      shift 2
      ;;
    -a|--all)
      RUN_ALL=true
      shift
      ;;
    -h|--help)
      banner
      help_menu
      ;;
    --dns)
      DNS_ENUM=true
      shift
      ;;
    --subdomains)
      SUBDOMAIN_ENUM=true
      shift
      ;;
    --dirs)
      DIR_ENUM=true
      shift
      ;;
    --headers)
      HEADERS_INSPECT=true
      shift
      ;;
    --ports)
      PORT_SCAN=true
      shift
      ;;
    --ssl)
      SSL_CHECK=true
      shift
      ;;
    --whois)
      WHOIS_LOOKUP=true
      shift
      ;;
    --tech-stack)
      TECH_STACK=true
      shift
      ;;
    *)
      echo -e "${RED}[ERROR] Unknown option: $1${NC}"
      help_menu
      ;;
  esac
done

# Output handling function
function output_result() {
    local message=$1
    if [ -n "$OUTPUT" ]; then
        echo -e "$message" | tee -a "$OUTPUT"
    else
        echo -e "$message"
    fi

    if $DEBUG; then
        echo -e "${YELLOW}[DEBUG] ${message}${NC}"
    fi
}

# DNS Enumeration module
function dns_enum() {
    format_result "HEADER" "DNS Enumeration Module"

    printf "${WHITE}${BOLD}%-15s %-40s %-20s${NC}\n" "Record Type" "Value" "TTL"
    echo "═════════════════════════════════════════════════════════════════════════"

    local record_types=("A" "AAAA" "MX" "TXT" "NS" "CNAME" "SOA")
    for type in "${record_types[@]}"; do
        local records=$(dig +noall +answer "$TARGET" "$type" 2>/dev/null)
        if [ -n "$records" ]; then
            while read -r record; do
                local value=$(echo "$record" | awk '{print $(NF)}')
                local ttl=$(echo "$record" | awk '{print $2}')
                printf "${CYAN}%-15s${NC} %-40s %-20s\n" "$type" "$value" "$ttl"
            done <<<"$records"
        fi
    done

    format_result "SUCCESS" "DNS Enumeration completed"
}

function subdomain_enum() {
    format_result "HEADER" "Subdomain Enumeration Module"

    local wordlist="${WORDLIST:-/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-5000.txt}"

    if [[ ! -f "$wordlist" ]]; then
        format_result "ERROR" "Wordlist not found: $wordlist"
        return 1
    fi

    echo -e "\n${WHITE}${BOLD}Found Subdomains (Real-Time):${NC}"
    echo "═════════════════════════════════════════════"

    gobuster dns -d "$TARGET" -w "$wordlist" -q | while read -r line; do
        printf "${GREEN}%-40s${NC} → ${CYAN}Live${NC}\n" "$line"
    done

    format_result "SUCCESS" "Subdomain enumeration completed"
}


# HTTP Headers Analysis module
function headers_analysis() {
    
    echo -e "\n${BOLD}[HTTP Headers Analysis]${NC}"
    
    # Get headers
    headers=$(curl -sI "https://$TARGET" --max-time "$TIMEOUT" 2>/dev/null)
    if [ -z "$headers" ]; then
        headers=$(curl -sI "http://$TARGET" --max-time "$TIMEOUT" 2>/dev/null)
        [ -z "$headers" ] && echo -e "${RED}[-]${NC} Failed to retrieve headers" && return 1
        echo -e "${YELLOW}[!]${NC} Using insecure HTTP"
    fi
    
    # Display headers with enhanced formatting
    local target=$TARGET
    local width=$((${#target} + 20))
    local border=$(printf '%*s' "$width" | tr ' ' '-')
    
    echo -e "${BLUE}${BOLD}$border${NC}"
    echo -e "${BLUE}${BOLD}HTTP HEADERS: ${WHITE}$target${NC}"
    echo -e "${BLUE}${BOLD}$border${NC}"
    
    # Process and display each header with formatting
    echo "$headers" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            # Split header into name and value
            if [[ "$line" == *":"* ]]; then
                header_name=$(echo "$line" | cut -d: -f1)
                header_value=$(echo "$line" | cut -d: -f2- | sed 's/^ //')
                echo -e "${CYAN}${BOLD}$header_name:${NC} $header_value"
            else
                # For status line or other non-header lines
                echo -e "${WHITE}${BOLD}$line${NC}"
            fi
        fi
    done
    
    # Check security headers
    echo -e "\n${WHITE}Security Headers Check:${NC}"
    echo "═══════════════════════"
    for header in "Strict-Transport-Security" "Content-Security-Policy" "X-Content-Type-Options" "X-Frame-Options"; do
        if echo "$headers" | grep -qi "$header:"; then
            echo -e "${GREEN}[+]${NC} $header: Present"
        else
            echo -e "${YELLOW}[!]${NC} $header: Missing"
        fi
    done
    
    echo -e "\n${GREEN}[+]${NC} Headers analysis completed"
}



# Port Scanning module
function port_scan() {
    format_result "HEADER" "Port Scanning Module"


    echo -e "\n${WHITE}${BOLD}Open Ports:${NC}"
    echo "════════════════════════════════════"

    nmap -p- --open "$TARGET"

    format_result "SUCCESS" "Port scanning completed"
}

# SSL/TLS Analysis module
function ssl_analysis() {
    format_result "HEADER" "SSL/TLS Analysis Module"

    openssl s_client -connect "$TARGET:443" -showcerts </dev/null

    format_result "SUCCESS" "SSL/TLS analysis completed"
}

# WHOIS Lookup module
function whois_lookup() {
    format_result "HEADER" "WHOIS Lookup Module"


    whois "$TARGET"

    format_result "SUCCESS" "WHOIS lookup completed"
}

# Technology Stack Identification module
function tech_stack() {
    format_result "HEADER" "Technology Stack Identification Module"


    whatweb "$TARGET"

    format_result "SUCCESS" "Technology stack identification completed"
}


# Running the script
check_requirements
banner
# Run all modules if -a/--all is specified
if $RUN_ALL; then
  DNS_ENUM=true
  SUBDOMAIN_ENUM=true
  DIR_ENUM=true
  HEADERS_INSPECT=true
  PORT_SCAN=true
  SSL_CHECK=true
  WHOIS_LOOKUP=true
  TECH_STACK=true
fi

# Execute selected modules
[ "$DNS_ENUM" == true ] && dns_enum
[ "$SUBDOMAIN_ENUM" == true ] && subdomain_enum
[ "$DIR_ENUM" == true ] && dir_enum
[ "$HEADERS_INSPECT" == true ] && headers_analysis
[ "$PORT_SCAN" == true ] && port_scan
[ "$SSL_CHECK" == true ] && ssl_check
[ "$WHOIS_LOOKUP" == true ] && whois_lookup
[ "$TECH_STACK" == true ] && tech_stack

output_result "\n${GREEN}[SUCCESS] WebSleuth completed all selected modules.${NC}"
