#!/bin/bash

# WebSleuth - SSL/TLS Analysis Module

function ssl_check() {
    format_result "HEADER" "SSL/TLS Analysis for $TARGET"

    # Check if target is just a domain or includes https://
    local domain_to_scan="$TARGET"
    if [[ "$domain_to_scan" == https://* ]]; then
        domain_to_scan="${domain_to_scan#https://}"
    elif [[ "$domain_to_scan" == http://* ]]; then
        # SSL check is usually for HTTPS, if http:// is passed, inform user.
        format_result "WARNING" "SSL check performed on domain '$domain_to_scan' (port 443), ignoring http:// prefix."
        domain_to_scan="${domain_to_scan#http://}"
    fi
    # Remove trailing slash if any
    domain_to_scan="${domain_to_scan%/}"


    format_result "INFO" "Running Nmap SSL scripts for ${domain_to_scan} on port 443..."
    output_result "Nmap Command: nmap --script ssl-cert,ssl-enum-ciphers -p 443 \"$domain_to_scan\""

    # Nmap's output for scripts can be lengthy.
    # We'll capture it and then print using output_result.
    local nmap_ssl_output
    nmap_ssl_output=$(nmap --script ssl-cert,ssl-enum-ciphers -p 443 "$domain_to_scan" 2>/dev/null)

    if [ -n "$nmap_ssl_output" ]; then
        # Filter for relevant parts if too verbose, or print all
        # For now, printing the relevant block from Nmap
        output_result "\n${WHITE}${BOLD}Nmap SSL Scan Results:${NC}"
        output_result "═══════════════════════════════════════════════════════"
        # Process line by line to use output_result formatting for log
        echo "$nmap_ssl_output" | while IFS= read -r line; do
             # Indent Nmap's output slightly for readability within module's section
            output_result "  $line"
        done
    else
        format_result "WARNING" "Nmap SSL scan did not return results for $domain_to_scan (port 443). Target might not be listening or an error occurred."
    fi

    format_result "SUCCESS" "SSL/TLS analysis completed for $TARGET"
}