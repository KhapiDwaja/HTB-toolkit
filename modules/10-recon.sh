#!/usr/bin/env bash
# modules/10-recon.sh — network/host reconnaissance

info "Recon & scanning tools"

# --- APT (apt_install falls back per-package if batch fails) ---------------
apt_install \
    nmap \
    masscan \
    dnsrecon \
    dnsenum \
    whatweb \
    wafw00f \
    netcat-openbsd \
    arp-scan \
    nbtscan \
    onesixtyone \
    snmp \
    snmp-mibs-downloader \
    smbclient \
    cifs-utils \
    nikto \
    amass \
    theharvester \
    smbmap \
    enum4linux

# --- pipx (CLI apps) --------------------------------------------------------
# enum4linux-ng: from GitHub (PyPI version is a library, we want the CLI)
pipx_install "git+https://github.com/cddmp/enum4linux-ng.git"
pipx_install "fierce"

# --- Go-installed modern scanners -------------------------------------------
go_install "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
go_install "github.com/projectdiscovery/httpx/cmd/httpx@latest"
go_install "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
go_install "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
go_install "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
go_install "github.com/OJ/gobuster/v3@latest"

# --- rustscan (via cargo, if available) -------------------------------------
if [[ -f "${REAL_HOME}/.cargo/bin/cargo" ]] || command -v cargo &>/dev/null; then
    _run_as_user "install rustscan" \
        "source ${REAL_HOME}/.cargo/env 2>/dev/null; cargo install rustscan"
fi

ok "Recon module done."
