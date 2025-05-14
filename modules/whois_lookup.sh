#!/bin/bash

# WebSleuth - Advanced WHOIS Lookup Module (Pure Bash)

function whois_lookup() {
    if [ -z "$TARGET" ]; then
        echo -e "\033[1;31m[ERROR]\033[0m No target specified for WHOIS lookup."
        return 1
    fi

    local domain="$TARGET"
    local whois_output

    echo -e "\n\033[1;36m═══════════════════════════════════════════════════════"
    echo -e "        WHOIS Lookup for \033[1;33m$domain\033[1;36m"
    echo -e "═══════════════════════════════════════════════════════\033[0m"

    # Perform WHOIS lookup
    whois_output=$(whois "$domain" 2>/dev/null)

    if [[ -z "$whois_output" ]]; then
        echo -e "\033[1;31m[ERROR]\033[0m No WHOIS information found for $domain."
        return 1
    fi

    # Field labels and fallback patterns
    declare -A fields
    fields["Domain Name"]="Domain Name:"
    fields["Registrar"]="Registrar:"
    fields["Creation Date"]="Created:|Creation Date:|Activated:"
    fields["Updated Date"]="Updated:|Last Updated:"
    fields["Expiry Date"]="Expires:|Expiration Date:|Expiry Date:"
    fields["Name Server"]="Name Server:|Name Servers:|Nserver:"
    fields["Technical Contact"]="Technical Contact:"
    fields["Status"]="Status:|Domain Status:"
    fields["Registrant Organization"]="Registrant Organization:|Registrant:"
    fields["Admin Contact"]="Administrative Contact:|Admin Contact:"

    printf "\n\033[1;34m%-25s %-50s\033[0m\n" "Field" "Value"
    printf "\033[1;34m%-25s %-50s\033[0m\n" "-------------------------" "--------------------------------------------------"

    for key in "${!fields[@]}"; do
        IFS='|' read -ra patterns <<< "${fields[$key]}"
        value=""
        for pattern in "${patterns[@]}"; do
            value=$(echo "$whois_output" | grep -i "$pattern" | head -n 1 | awk -F: '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
            [[ -n "$value" ]] && break
        done
        if [[ -n "$value" ]]; then
            printf "\033[1;32m%-25s\033[0m %-50s\n" "$key:" "$value"
        fi
    done

    # Show all name servers if present
    ns_list=$(echo "$whois_output" | grep -iE "Name Servers:|Nserver:" | awk -F: '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' | sort -u)
    if [[ -n "$ns_list" ]]; then
        printf "\033[1;32m%-25s\033[0m %-50s\n" "All Name Servers:" ""
        while read -r ns; do
            [[ -n "$ns" ]] && printf "  %-23s %-50s\n" "" "$ns"
        done <<< "$ns_list"
    fi

    echo -e "\n\033[1;32m[✔] WHOIS lookup completed for $domain\033[0m"
}
