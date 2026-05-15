#!/usr/bin/env bash
# modules/10-recon.sh — network/host reconnaissance

info "Recon & scanning tools"

# --- APT-available ----------------------------------------------------------
apt_install \
    nmap masscan \
    dnsrecon dnsenum fierce \
    whatweb wafw00f \
    netcat-openbsd \
    arp-scan \
    nbtscan \
    onesixtyone \
    snmp snmp-mibs-downloader \
    smbclient smbmap cifs-utils \
    enum4linux \
    nikto \
    amass theharvester

# --- pipx -------------------------------------------------------------------
pipx_install enum4linux-ng
pipx_install dnsx           || true   # optional; install fails gracefully
pipx_install fierce         || true

# --- go-installed (faster modern scanners) ----------------------------------
go_install "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
go_install "github.com/projectdiscovery/httpx/cmd/httpx@latest"
go_install "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
go_install "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
go_install "github.com/OJ/gobuster/v3@latest"

# --- rustscan (cargo) -------------------------------------------------------
if command -v cargo &>/dev/null || [[ -f "${REAL_HOME}/.cargo/bin/cargo" ]]; then
    _run_as_user "install rustscan" \
        "source ${REAL_HOME}/.cargo/env 2>/dev/null; cargo install rustscan"
fi

ok "Recon module done."
