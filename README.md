# WebSleuth

**WebSleuth** is an advanced, modular website reconnaissance tool designed for ethical hackers, penetration testers, and security researchers. It automates the process of gathering intelligence about web targets, providing a comprehensive suite of modules for enumeration, analysis, and fingerprinting.

---

## Features

- **Modular Design:** Easily extensible with new modules.
- **Colorful, User-Friendly Output:** Terminal output is formatted for clarity and readability.
- **Comprehensive Reconnaissance:**
  - DNS Enumeration
  - Subdomain Enumeration
  - Directory/Path Brute-Forcing
  - HTTP Headers Analysis
  - Port Scanning (Fast & Aggressive)
  - SSL/TLS Analysis
  - WHOIS Lookup
  - Technology Stack Detection

---

## Installation

### Prerequisites

- Linux (tested on Ubuntu/Debian)
- Bash 4.x+
- The following tools must be installed:
  - `curl`
  - `nmap`
  - `whois`
  - `openssl`
  - `whatweb`
  - `gobuster`
  - `ffuf`
  - `jq`
  - `dig`
  - `feroxbuster` (for directory enumeration)
  - `wappalyzer` (optional, for tech stack detection)
  - `seclists` (for wordlists)

Install dependencies (Debian/Ubuntu example):

```bash
sudo apt update
sudo apt install curl nmap whois openssl whatweb gobuster ffuf jq dnsutils feroxbuster seclists
# For wappalyzer CLI: https://github.com/wappalyzer/wappalyzer
```

---

## Usage

```bash
sudo ./websleuth.sh -u <target> [options]
```

### Common Options

| Option                | Description                                 |
|-----------------------|---------------------------------------------|
| `-u, --url`           | Target URL or domain                        |
| `-o, --output`        | Output file (optional)                      |
| `-w, --wordlist`      | Custom wordlist for enumeration             |
| `-t, --threads`       | Number of threads (default: 10)             |
| `-a, --all`           | Run all modules                             |
| `--dns`               | DNS enumeration                             |
| `--subdomains`        | Subdomain enumeration                       |
| `--dirs`              | Directory brute-forcing                     |
| `--headers`           | HTTP headers analysis                       |
| `--ports`             | Port scanning                               |
| `--ssl`               | SSL/TLS checks                              |
| `--whois`             | WHOIS lookup                                |
| `--tech-stack`        | Technology stack detection                  |
| `--timeout`           | Set timeout (seconds)                       |
| `--exclude`           | Exclude ports (comma-separated)             |
| `--agressive-scan`    | Aggressive port scan                        |
| `--debug`             | Enable debug mode                           |
| `-h, --help`          | Show help menu                              |

### Examples

- Run all modules:
  ```bash
  sudo ./websleuth.sh -u example.com -a
  ```

- Run subdomain and directory enumeration:
  ```bash
  sudo ./websleuth.sh -u example.com --subdomains --dirs
  ```

- Fast port scan only:
  ```bash
  sudo ./websleuth.sh -u example.com --ports
  ```

- Aggressive port scan:
  ```bash
  sudo ./websleuth.sh -u example.com --ports --agressive-scan
  ```

---

## Module Descriptions

### DNS Enumeration (`dns_enum`)
Performs DNS record lookups for common types (A, AAAA, MX, TXT, NS, CNAME, SOA) and displays results in a table.

### Subdomain Enumeration (`subdomain_enum`)
Brute-forces subdomains using a wordlist and checks if they resolve (live check).

### Directory Enumeration (`dir_enum`)
Discovers hidden directories and files using `feroxbuster` and customizable wordlists. Shows HTTP status, method, length, URL, and redirection targets.

### HTTP Headers Analysis (`headers_analysis`)
Fetches and displays HTTP(S) headers, highlighting security-related headers and their presence.

### Port Scanning (`port_scan`)
Performs fast (`-F`) or aggressive (`-A -T4`) scans using Nmap. Supports custom/excluded ports.

### SSL/TLS Analysis (`ssl_check`)
Runs Nmap SSL scripts to enumerate certificates and supported ciphers.

### WHOIS Lookup (`whois_lookup`)
Fetches and parses WHOIS information, displaying key fields in a readable format.

### Technology Stack Detection (`tech_stack`)
Identifies technologies used by the target using WhatWeb, Wappalyzer, BuiltWith (if API key provided), and HTTP headers.

---

## Output

- **Color-coded, well-formatted terminal output**
- **Summary table** at the end of each run
- **Optional output file** (with color codes preserved)

---

## Extending WebSleuth

Add new modules to the `modules/` directory and source them in `websleuth.sh`. Follow the function pattern used in existing modules for consistency.

---

## Disclaimer

This tool is intended for **authorized security testing and research** only. Do not use against systems without explicit permission. The author is not responsible for misuse.

---

## License

MIT License

---

## Author

- [cyb3ritic](https://github.com/cyb3ritic)
