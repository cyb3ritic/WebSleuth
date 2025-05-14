#!/bin/bash

# WebSleuth - Configuration File

# Enhanced color palette
BOLD="\e[1m"
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
MAGENTA="\e[1;35m"
CYAN="\e[1;36m"
WHITE="\e[1;37m"
NC="\e[0m" # No Color

# Global variables
TARGET=""
OUTPUT=""
WORDLIST=""
THREADS=10
TIMEOUT=10
DEBUG=false
EXCLUDED_PORTS="" # Parsed but not used in original logic for port exclusion
RUN_ALL=false
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Module flags (set by argument parsing in main script)
DNS_ENUM=false
SUBDOMAIN_ENUM=false
DIR_ENUM=false
HEADERS_INSPECT=false
PORT_SCAN=false
SSL_CHECK=false
WHOIS_LOOKUP=false
TECH_STACK=false
AGRESSIVE_SCAN=false # For Nmap Agressive port scan

# Required tools
# 'seclists' is a package of wordlists; its presence is checked via file paths in modules.
REQUIRED_TOOLS=("curl" "nmap" "whois" "openssl" "whatweb" "gobuster" "ffuf" "jq" "dig")