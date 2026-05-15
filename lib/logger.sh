#!/usr/bin/env bash
# lib/logger.sh — pretty stdout + timestamped file log
# Requires HTB_LOG env var.

_ts() { date '+%Y-%m-%d %H:%M:%S'; }

log()     { printf "${C_DIM}[%s]${C_RESET} %s\n" "$(_ts)" "$*"  | tee -a "${HTB_LOG}" >/dev/null; }
info()    { printf "${C_BLUE}[i]${C_RESET} %s\n" "$*";    printf "[%s] [INFO] %s\n" "$(_ts)" "$*"  >> "${HTB_LOG}"; }
ok()      { printf "${C_GREEN}[+]${C_RESET} %s\n" "$*";   printf "[%s] [ OK ] %s\n" "$(_ts)" "$*"  >> "${HTB_LOG}"; }
warn()    { printf "${C_YELLOW}[!]${C_RESET} %s\n" "$*";  printf "[%s] [WARN] %s\n" "$(_ts)" "$*"  >> "${HTB_LOG}"; }
err()     { printf "${C_RED}[x]${C_RESET} %s\n" "$*" >&2; printf "[%s] [ERR ] %s\n" "$(_ts)" "$*"  >> "${HTB_LOG}"; }
section() {
    local title="$*"
    printf "\n${C_BOLD}${C_MAGENTA}=== %s ===${C_RESET}\n" "${title}"
    printf "[%s] === %s ===\n" "$(_ts)" "${title}" >> "${HTB_LOG}"
}
