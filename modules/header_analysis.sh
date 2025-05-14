#!/bin/bash

# WebSleuth - HTTP Headers Analysis Module

function headers_analysis() {
    format_result "HEADER" "HTTP Headers Analysis for $TARGET"
    
    local http_target="http://$TARGET"
    local https_target="https://$TARGET"
    local effective_target=""
    local headers=""

    # Try HTTPS first
    headers=$(curl -sSLI "$https_target" --max-time "$TIMEOUT" 2>/dev/null)
    if [ -n "$headers" ]; then
        effective_target="$https_target"
    else
        # Fallback to HTTP if HTTPS fails or is empty
        format_result "INFO" "HTTPS request failed or returned no headers, trying HTTP for $TARGET"
        headers=$(curl -sSLI "$http_target" --max-time "$TIMEOUT" 2>/dev/null)
        if [ -n "$headers" ]; then
            effective_target="$http_target"
            format_result "WARNING" "Using insecure HTTP for $TARGET"
        else
            format_result "ERROR" "Failed to retrieve headers for $TARGET via HTTP and HTTPS."
            return 1
        fi
    fi
    
    local width=$((${#effective_target} + 20))
    local border=$(printf '%*s' "$width" | tr ' ' '-')
    
    output_result "${BLUE}${BOLD}$border${NC}"
    output_result "${BLUE}${BOLD}HTTP HEADERS: ${WHITE}$effective_target${NC}"
    output_result "${BLUE}${BOLD}$border${NC}"
    
    echo "$headers" | while IFS= read -r line; do
        # Trim carriage returns if present (from Windows servers)
        line=$(echo "$line" | tr -d '\r')
        if [[ -n "$line" ]]; then
            if [[ "$line" == *":"* ]]; then
                local header_name header_value
                header_name=$(echo "$line" | cut -d: -f1)
                header_value=$(echo "$line" | cut -d: -f2- | sed 's/^[[:space:]]*//') # Trim leading space
                output_result "${CYAN}${BOLD}${header_name}:${NC} ${header_value}"
            else
                output_result "${WHITE}${BOLD}${line}${NC}" # For status line
            fi
        fi
    done
    
    output_result "\n${WHITE}${BOLD}Security Headers Check:${NC}"
    output_result "═══════════════════════"
    local security_headers_to_check=("Strict-Transport-Security" "Content-Security-Policy" "X-Content-Type-Options" "X-Frame-Options" "Referrer-Policy" "Permissions-Policy")
    for header in "${security_headers_to_check[@]}"; do
        if echo "$headers" | grep -iq "^${header}:"; then
            output_result "${GREEN}[+]${NC} ${header}: Present"
        else
            output_result "${YELLOW}[!]${NC} ${header}: Missing"
        fi
    done
    
    format_result "SUCCESS" "Headers analysis completed for $TARGET"
}