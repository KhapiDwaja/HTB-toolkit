#!/usr/bin/env bash
# config/env.sh — sourced from ~/.bashrc and ~/.zshrc by htb-toolkit
# Lives at /opt/htb-toolkit/env.sh after installation.

# ---------- Paths -----------------------------------------------------------
export HTB_TOOLS="/opt/htb-toolkit"
export PATH="${PATH}:${HTB_TOOLS}/bin:${HOME}/.local/bin:${HOME}/go/bin"

# SecLists (set by 90-wordlists module)
export SECLISTS="/usr/share/seclists"
export WORDLISTS="${SECLISTS}"
export ROCKYOU="${SECLISTS}/Passwords/Leaked-Databases/rockyou.txt"

# ---------- Aliases — tools that don't auto-end-up on PATH ------------------
# Active Directory
alias kerbrute='${HTB_TOOLS}/kerbrute/dist/kerbrute_linux_amd64'
alias certipy='pipx run certipy-ad'
alias bloodyAD='${HTB_TOOLS}/bloodyAD/bloodyAD.py'
alias adidnsdump='pipx run adidnsdump'
alias ldapdomaindump='pipx run ldapdomaindump'
alias windapsearch='${HTB_TOOLS}/windapsearch/windapsearch.py'

# Pivoting
alias chisel='${HTB_TOOLS}/chisel/chisel'
alias ligolo-proxy='${HTB_TOOLS}/ligolo-ng/proxy'
alias ligolo-agent='${HTB_TOOLS}/ligolo-ng/agent'
alias ptunnel-ng='${HTB_TOOLS}/ptunnel-ng/src/ptunnel-ng'

# Password attacks (impacket *.py scripts — already on PATH via pipx)
alias mimipenguin='sudo python3 ${HTB_TOOLS}/mimipenguin/mimipenguin.py'
alias lazagne='python3 ${HTB_TOOLS}/LaZagne/Linux/laZagne.py'
alias firefox_decrypt='python3 ${HTB_TOOLS}/firefox_decrypt/firefox_decrypt.py'
alias username-anarchy='${HTB_TOOLS}/username-anarchy/username-anarchy'

# Convenience
alias ll='ls -lah'
alias htb-update='sudo ${HTB_TOOLS}/install.sh --update 2>/dev/null || sudo $(command -v htb-toolkit-install || echo install.sh) --update'

# ---------- Helper functions -------------------------------------------------

# htb-target <ip>  — set target IP env var used by other helpers
htb-target() {
    [[ -z "$1" ]] && { echo "usage: htb-target <ip>"; return 1; }
    export RHOST="$1"
    echo "[+] RHOST=$1"
}

# tun0ip  — print your tun0 IP (HTB VPN)
tun0ip() {
    ip -4 addr show tun0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1
}

# pyserve [port]  — quick HTTP server on tun0 IP
pyserve() {
    local port="${1:-8000}"
    local ip
    ip=$(tun0ip)
    echo "[+] Serving on http://${ip:-0.0.0.0}:${port}/"
    python3 -m http.server "${port}"
}

# smbserve [share_name] [dir]  — quick anonymous SMB share (impacket)
smbserve() {
    local share="${1:-SHARE}"
    local dir="${2:-$PWD}"
    impacket-smbserver -smb2support "${share}" "${dir}"
}

# crack-ntlm <hash>
crack-ntlm() {
    [[ -z "$1" ]] && { echo "usage: crack-ntlm <ntlm_hash>"; return 1; }
    hashcat -m 1000 -a 0 "$1" "${ROCKYOU}"
}

# Where am I?  — quick environment dump
htb-info() {
    echo "HTB_TOOLS  = ${HTB_TOOLS}"
    echo "SECLISTS   = ${SECLISTS}"
    echo "RHOST      = ${RHOST:-<unset, use 'htb-target <ip>'>}"
    echo "tun0       = $(tun0ip || echo not connected)"
}
