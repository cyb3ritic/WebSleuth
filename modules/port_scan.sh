#!/bin/bash

# WebSleuth - Advanced Port Scanning Module

function port_scan() {
    format_result "HEADER" "Port Scanning for $TARGET"

    output_result "\n${WHITE}${BOLD}Scanning target: $TARGET${NC}"
    output_result "═══════════════════════════════════════════════════════"

    # Default to fast scan
    local scan_mode_desc="Fast Scan (-F, open ports and services)"
    local nmap_args="-F"

    # If AGRESSIVE_SCAN is set, use aggressive scan
    if [ "$AGRESSIVE_SCAN" = true ]; then
        scan_mode_desc="Aggressive Scan (-A -T4, OS/service/script detection)"
        nmap_args="-A -T4"
    fi

    # Allow user to specify custom port ranges
    if [ -n "$CUSTOM_PORTS" ]; then
        nmap_args="$nmap_args -p $CUSTOM_PORTS"
        scan_mode_desc="$scan_mode_desc | Custom Ports: $CUSTOM_PORTS"
    fi

    # Exclude ports if specified
    if [ -n "$EXCLUDED_PORTS" ]; then
        nmap_args="$nmap_args --exclude-ports $EXCLUDED_PORTS"
        scan_mode_desc="$scan_mode_desc | Excluding: $EXCLUDED_PORTS"
    fi

    output_result "Scan Mode: $scan_mode_desc"
    output_result "Nmap Command: nmap $nmap_args \"$TARGET\""
    output_result "═══════════════════════════════════════════════════════"

    # Run Nmap and display output directly
    nmap $nmap_args "$TARGET"

    format_result "SUCCESS" "Port scanning completed for $TARGET"
}