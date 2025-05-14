#!/bin/bash

# WebSleuth - Subdomain Enumeration Module

function subdomain_enum() {
    if [[ -z "$TARGET" ]]; then
        echo -e "\e[1;31m[ERROR]\e[0m TARGET variable not set."
        return 1
    fi

    if ! command -v gobuster &>/dev/null; then
        echo -e "\e[1;31m[ERROR]\e[0m gobuster not found. Please install gobuster."
        return 1
    fi

    if ! command -v dig &>/dev/null; then
        echo -e "\e[1;31m[ERROR]\e[0m dig not found. Please install dnsutils."
        return 1
    fi

    local default_wordlist="/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-5000.txt"
    local fallback_wordlist="/usr/share/dnsrecon/subdomains-top1mil-5000.txt"
    local current_wordlist="${WORDLIST:-$default_wordlist}"

    if [[ ! -f "$current_wordlist" ]]; then
        echo -e "\e[1;33m[WARNING]\e[0m Wordlist not found: $current_wordlist. Trying fallback."
        current_wordlist="$fallback_wordlist"
        if [[ ! -f "$current_wordlist" ]]; then
            echo -e "\e[1;31m[ERROR]\e[0m No valid wordlist found. Please specify with -w or install seclists."
            return 1
        fi
    fi

    echo -e "\e[1;35m[*] Subdomain Enumeration for: \e[1;36m$TARGET\e[0m"
    echo -e "\e[1;34m[*] Using wordlist:\e[0m $current_wordlist"
    echo -e "\n\e[1mFound Subdomains (Live Check):\e[0m"
    echo "═════════════════════════════════════════════"

    gobuster dns -d "$TARGET" -w "$current_wordlist" -q 2>/dev/null | \
    awk '{print $2}' | while read -r sub; do
        if [[ -n "$sub" ]]; then
            if dig +short "$sub" | grep -qE '^[0-9a-fA-F:.]+'; then
                echo -e "\e[32m$sub\e[0m"
            else
                echo -e "\e[90m$sub (not live)\e[0m"
            fi
        fi
    done

    echo -e "\n\e[1;32m[+] Subdomain enumeration completed for $TARGET\e[0m"
}