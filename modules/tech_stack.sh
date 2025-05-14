#!/bin/bash

# WebSleuth - Technology Stack Identification Module

function tech_stack() {
    format_result "HEADER" "Technology Stack Identification for $TARGET"

    output_result "\n${WHITE}${BOLD}Analyzing technology stack for: $TARGET${NC}"
    output_result "═══════════════════════════════════════════════════════"
    
    # Ensure full URL for scanning
    local target_url="$TARGET"
    if [[ ! "$target_url" =~ ^https?:// ]]; then
        if curl -s --head --max-time 5 "https://$target_url" > /dev/null; then
            target_url="https://$target_url"
        elif curl -s --head --max-time 5 "http://$target_url" > /dev/null; then
            target_url="http://$target_url"
        else
            format_result "WARNING" "Could not determine scheme (http/https) for $TARGET for WhatWeb. Assuming http."
            target_url="http://$target_url"
        fi
        format_result "INFO" "Using inferred URL for WhatWeb scan: $target_url"
    fi

    # WhatWeb scan (detailed)
    local whatweb_data
    whatweb_data=$(whatweb --color=never --log-verbose=- "$target_url" 2>/dev/null)

    # Wappalyzer CLI (if available)
    local wappalyzer_data=""
    if command -v wappalyzer >/dev/null 2>&1; then
        wappalyzer_data=$(wappalyzer "$target_url" 2>/dev/null)
    fi

    # BuiltWith API (if available and API key set)
    local builtwith_data=""
    if [[ -n "$BUILTWITH_API_KEY" ]] && command -v curl >/dev/null 2>&1; then
        builtwith_data=$(curl -s "https://api.builtwith.com/v20/api.json?KEY=$BUILTWITH_API_KEY&LOOKUP=$target_url")
    fi

    # Output WhatWeb results
    if [[ -n "$whatweb_data" ]]; then
        output_result "${CYAN}--- WhatWeb Analysis ---${NC}"
        echo "$whatweb_data" | grep -v "^#" | while IFS= read -r line; do
            output_result "  $line"
        done
    else
        format_result "WARNING" "No technology data found by WhatWeb for $target_url, or an error occurred."
    fi

    # Output Wappalyzer results
    if [[ -n "$wappalyzer_data" ]]; then
        output_result "${CYAN}--- Wappalyzer Analysis ---${NC}"
        echo "$wappalyzer_data" | jq -r '.technologies[] | "  \(.name) (\(.categories[0].name)) - \(.version // "N/A")"' 2>/dev/null || echo "  $wappalyzer_data"
    fi

    # Output BuiltWith results
    if [[ -n "$builtwith_data" ]]; then
        output_result "${CYAN}--- BuiltWith Analysis ---${NC}"
        echo "$builtwith_data" | jq -r '.Results[0].Result.Paths[0].Technologies[] | "  \(.Name) (\(.Tag))"' 2>/dev/null || echo "  $builtwith_data"
    fi

    # Additional HTTP headers for server info
    output_result "${CYAN}--- HTTP Headers ---${NC}"
    curl -s -I "$target_url" | grep -E 'Server:|X-Powered-By:|Set-Cookie:|Content-Type:' | while IFS= read -r header; do
        output_result "  $header"
    done

    format_result "SUCCESS" "Technology stack identification completed for $TARGET"
}