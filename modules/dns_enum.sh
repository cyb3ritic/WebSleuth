#!/bin/bash

# WebSleuth - DNS Enumeration Module

function dns_enum() {
    format_result "HEADER" "DNS Enumeration for $TARGET"

    local header_fmt="${WHITE}${BOLD}%-15s %-40s %-20s${NC}"
    local row_fmt="${CYAN}%-15s${NC} %-40s %-20s"
    
    output_result "$(printf "$header_fmt" "Record Type" "Value" "TTL")"
    output_result "═════════════════════════════════════════════════════════════════════════"

    local record_types=("A" "AAAA" "MX" "TXT" "NS" "CNAME" "SOA")
    local found_any=false
    for type in "${record_types[@]}"; do
        # Using +short for cleaner output, but losing TTL for some tools/versions.
        # The original 'dig +noall +answer' is better for detailed parsing.
        local records
        records=$(dig +noall +answer "$TARGET" "$type" 2>/dev/null)
        
        if [ -n "$records" ]; then
            found_any=true
            while IFS= read -r record_line; do
                # Skip empty lines that might result from awk
                [[ -z "$record_line" ]] && continue
                local value
                local ttl
                # More robust parsing considering potential tabs and different dig outputs
                value=$(echo "$record_line" | awk '{print $(NF)}') # Last field is usually the value
                ttl=$(echo "$record_line" | awk '{print $2}')     # Second field is often TTL

                # For MX records, value needs two fields (priority and server)
                if [ "$type" == "MX" ]; then
                    value=$(echo "$record_line" | awk '{print $(NF-1), $(NF)}')
                fi
                 # For SOA records, value is complex, take the whole relevant part
                if [ "$type" == "SOA" ]; then
                    value=$(echo "$record_line" | awk '{$1=$2=$3=$4=""; print $0}' | sed 's/^[ \t]*//')
                fi

                output_result "$(printf "$row_fmt" "$type" "$value" "$ttl")"
            done <<< "$records"
        fi
    done
    
    if ! $found_any; then
        format_result "INFO" "No DNS records found for common types for $TARGET."
    fi
    format_result "SUCCESS" "DNS Enumeration completed for $TARGET"
}