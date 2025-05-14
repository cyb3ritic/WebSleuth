function dir_enum() {
    echo -e "\n\e[1;35m[*] Directory Enumeration for: \e[1;36m$TARGET\e[0m"

    local default_wordlist="/usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-directories.txt"
    local fallback_wordlist="/usr/share/wordlists/dirb/common.txt"
    local current_wordlist="${WORDLIST:-$default_wordlist}"

    if [[ ! -f "$current_wordlist" ]]; then
        echo -e "\e[1;33m[WARNING]\e[0m Wordlist not found: $current_wordlist. Trying fallback."
        current_wordlist="$fallback_wordlist"
        if [[ ! -f "$current_wordlist" ]]; then
            echo -e "\e[1;31m[ERROR]\e[0m No valid wordlist found."
            return 1
        fi
    fi

    local target_url="$TARGET"
    if [[ ! "$target_url" =~ ^https?:// ]]; then
        if curl -s --head --max-time 5 "https://$target_url" > /dev/null; then
            target_url="https://$target_url"
        elif curl -s --head --max-time 5 "http://$target_url" > /dev/null; then
            target_url="http://$target_url"
        else
            echo -e "\e[1;33m[WARNING]\e[0m Could not determine scheme. Assuming http."
            target_url="http://$target_url"
        fi
    fi

    local threads="${THREADS:-20}"
    local timeout="${TIMEOUT:-10}"
    local depth="${DEPTH:-1}"
    local status_codes="${CODES:-200,204,301,302,401,403}"
    local count=0

    echo -e "\e[1;34m[*] Using wordlist:\e[0m $current_wordlist"
    echo -e "\e[1;34m[*] Threads:\e[0m $threads | Timeout: $timeout sec | Depth: $depth"
    echo -e "\e[1;34m[*] Filtering for status codes:\e[0m $status_codes"

    echo -e "\n\e[1mStatus Legend:\e[0m \e[32m2xx=OK\e[0m \e[33m3xx=Redirect\e[0m"
    echo "════════════════════════════════════════════════════════════════════════════════════"
    printf "\e[1m%-7s %-7s %-8s %-60s\e[0m\n" "Method" "Status" "Length" "URL"
    echo "------------------------------------------------------------------------------------"

    feroxbuster -u "$target_url" \
                -w "$current_wordlist" \
                -t "$threads" \
                --timeout "$timeout" \
                -d "$depth" \
                --status-codes "$status_codes" \
                -q 2>/dev/null | while read -r line; do

        # Skip lines that don't match the expected format
        [[ "$line" == *"Auto-filtering"* ]] && continue

        method=$(echo "$line" | awk '{print $1}')
        status=$(echo "$line" | awk '{print $2}')
        length=$(echo "$line" | awk '{print $4}')
        url=$(echo "$line" | awk '{for(i=6;i<=NF;++i) printf $i" "; print ""}' | sed 's/[[:space:]]*$//')

        # Skip noise
        [[ -z "$url" ]] && continue

        # Color coding
        case "$status" in
            2*) color="\e[32m" ;;
            3*) color="\e[33m" ;;
            *) color="\e[37m" ;;
        esac

        printf "${color}%-7s %-7s\e[0m \e[36m%-8s\e[0m %-60s\n" "$method" "$status" "$length" "$url"
        ((count++))
    done

    # clean up
    rm ferox-https* 2>/dev/null
    rm ferox-http* 2>/dev/null

    echo "------------------------------------------------------------------------------------"
    echo -e "\n\e[1;32m[+] Directory enumeration completed for $TARGET\e[0m"
    echo -e "\e[1;34m[*] Total valid paths found:\e[0m $count"
    echo -e "\e[1;34m[*] Scan finished at:\e[0m $(date +'%Y-%m-%d %H:%M:%S')"
    echo "════════════════════════════════════════════════════════════════════════════════════"
}
