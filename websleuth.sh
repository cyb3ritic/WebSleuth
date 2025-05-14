#!/bin/bash

# WebSleuth - Advanced Website Reconnaissance Tool
VERSION="1.1"
START_TIME=$(date +%s)

# Colors
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
BOLD='\e[1m'
NC='\e[0m'

# Trap Ctrl+C
trap ctrl_c INT
function ctrl_c() {
    echo -e "\n${RED}[!] Interrupted by user. Exiting...${NC}"
    exit 130
}

# Dynamic Banner
function banner() {
    echo -e "${MAGENTA}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                  WebSleuth v$VERSION - Recon Tool         ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  ${CYAN}Author:${WHITE} cyb3ritic      ${CYAN}GitHub:${WHITE} github.com/cyb3ritic      ${MAGENTA}║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Source configs and helpers
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/helpers.sh"

# Source modules
for module_file in "${SCRIPT_DIR}/modules/"*.sh; do
    [ -f "$module_file" ] && source "$module_file"
done

# Root check
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run this script as root.${NC}"
    exit 1
fi

# Help menu
function help_menu() {
    echo -e "${BOLD}${CYAN}Usage:${NC} $0 -u <target> [options]"
    echo -e "${BOLD}${CYAN}Options:${NC}"
    echo -e "  -u, --url         Target URL or domain"
    echo -e "  -o, --output      Output file (optional)"
    echo -e "  -w, --wordlist    Custom wordlist for enumeration"
    echo -e "  -t, --threads     Number of threads (default: 10)"
    echo -e "  -a, --all         Run all modules"
    echo -e "      --dns         DNS enumeration"
    echo -e "      --subdomains  Subdomain enumeration"
    echo -e "      --dirs        Directory brute-forcing"
    echo -e "      --headers     HTTP headers analysis"
    echo -e "      --ports       Port scanning"
    echo -e "      --ssl         SSL/TLS checks"
    echo -e "      --whois       WHOIS lookup"
    echo -e "      --tech-stack  Technology stack detection"
    echo -e "      --timeout     Set timeout (seconds)"
    echo -e "      --exclude     Exclude ports (comma-separated)"
    echo -e "      --debug       Enable debug mode"
    echo -e "      --agressive-scan   Agressive port scan"
    echo -e "  -h, --help        Show this help menu"
    echo
    echo -e "${BOLD}${CYAN}Examples:${NC}"
    echo -e "  $0 -u example.com -a"
    echo -e "  $0 -u example.com --subdomains --dirs"
    echo
    exit 0
}

# Parse arguments
if [[ "$#" -eq 0 ]]; then
    banner
    help_menu
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--url) TARGET="$2"; shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -w|--wordlist) WORDLIST="$2"; shift 2 ;;
        -t|--threads)
            if [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -gt 0 ]; then
                THREADS="$2"
            else
                echo -e "${RED}[ERROR] Threads (-t) must be a positive integer.${NC}"; exit 1
            fi
            shift 2 ;;
        -a|--all) RUN_ALL=true; shift ;;
        -h|--help) banner; help_menu ;;
        --dns) DNS_ENUM=true; shift ;;
        --subdomains) SUBDOMAIN_ENUM=true; shift ;;
        --dirs) DIR_ENUM=true; shift ;;
        --headers) HEADERS_INSPECT=true; shift ;;
        --ports) PORT_SCAN=true; shift ;;
        --ssl) SSL_CHECK=true; shift ;;
        --whois) WHOIS_LOOKUP=true; shift ;;
        --tech-stack) TECH_STACK=true; shift ;;
        --timeout)
            if [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -ge 0 ]; then
                TIMEOUT="$2"
            else
                echo -e "${RED}[ERROR] Timeout (--timeout) must be a non-negative integer.${NC}"; exit 1
            fi
            shift 2 ;;
        --exclude) EXCLUDED_PORTS="$2"; shift 2 ;;
        --debug) DEBUG=true; shift ;;
        --agressive-scan) AGRESSIVE_SCAN=true; shift ;;
        *) echo -e "${RED}[ERROR] Unknown option: $1${NC}"; help_menu ;;
    esac
done

# Validate target
if [ -z "$TARGET" ]; then
    banner
    echo -e "${RED}[ERROR] Target URL (-u, --url) is required.${NC}"
    help_menu
fi

# At least one module
if ! $RUN_ALL && ! $DNS_ENUM && ! $SUBDOMAIN_ENUM && ! $DIR_ENUM && ! $HEADERS_INSPECT && ! $PORT_SCAN && ! $SSL_CHECK && ! $WHOIS_LOOKUP && ! $TECH_STACK; then
    banner
    echo -e "${YELLOW}[WARNING] No reconnaissance modules selected to run. Use -a for all or specify modules.${NC}"
    help_menu
fi

# Output file logic
if [ -n "$OUTPUT" ]; then
    OUTPUT_DIR=$(dirname "$OUTPUT")
    if [ ! -d "$OUTPUT_DIR" ]; then
        mkdir -p "$OUTPUT_DIR"
        echo -e "${BLUE}[INFO] Created output directory: ${WHITE}$OUTPUT_DIR${NC}"
    fi
    > "$OUTPUT"
    echo -e "${BLUE}[INFO] Logging output to: ${WHITE}$OUTPUT${NC}"
fi

# Start
banner
echo -e "${CYAN}[~] Starting reconnaissance for: ${WHITE}$TARGET${NC}"
[ -n "$OUTPUT" ] && echo -e "${CYAN}[~] Output will be saved to: ${WHITE}$OUTPUT${NC}"

# Enable all modules if requested
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

# Module status table
declare -A MODULE_STATUS
MODULE_STATUS=(
    [dns_enum]=false
    [subdomain_enum]=false
    [dir_enum]=false
    [headers_analysis]=false
    [port_scan]=false
    [ssl_check]=false
    [whois_lookup]=false
    [tech_stack]=false
)

# Run modules with progress
function run_module() {
    local name="$1"
    local func="$2"
    echo -ne "${YELLOW}[~] Running ${BOLD}${name//_/ }${NC} ... "
    if $func; then
        MODULE_STATUS[$name]=true
        echo -e "${GREEN}done${NC}"
    else
        MODULE_STATUS[$name]=false
        echo -e "${RED}failed${NC}"
    fi
}

[ "$DNS_ENUM" = true ] && run_module "dns_enum" dns_enum
[ "$SUBDOMAIN_ENUM" = true ] && run_module "subdomain_enum" subdomain_enum
[ "$DIR_ENUM" = true ] && run_module "dir_enum" dir_enum
[ "$HEADERS_INSPECT" = true ] && run_module "headers_analysis" headers_analysis
[ "$PORT_SCAN" = true ] && run_module "port_scan" port_scan
[ "$SSL_CHECK" = true ] && run_module "ssl_check" ssl_check
[ "$WHOIS_LOOKUP" = true ] && run_module "whois_lookup" whois_lookup
[ "$TECH_STACK" = true ] && run_module "tech_stack" tech_stack

# Summary Table
echo -e "\n${BOLD}${CYAN}Reconnaissance Summary:${NC}"
printf "${BOLD}%-20s %-10s${NC}\n" "Module" "Status"
echo "--------------------------------------"
for mod in "${!MODULE_STATUS[@]}"; do
    status="${MODULE_STATUS[$mod]}"
    if $status; then
        printf "%-20s ${GREEN}%-10s${NC}\n" "${mod//_/ }" "Success"
    else
        printf "%-20s ${RED}%-10s${NC}\n" "${mod//_/ }" "Skipped/Fail"
    fi
done

# Elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo -e "\n${GREEN}[+] All selected modules completed in ${BOLD}${ELAPSED}s${NC}"

if [ -n "$OUTPUT" ]; then
    echo -e "${BLUE}[INFO] Full reconnaissance output saved to: ${WHITE}$OUTPUT${NC}"
fi

exit 0