#!/usr/bin/env bash
# modules/60-web-app.sh — Web application & API pentesting

info "Web application testing toolkit"

# --- APT --------------------------------------------------------------------
apt_install \
    burpsuite \
    zaproxy \
    sqlmap \
    nikto \
    wfuzz \
    gobuster \
    feroxbuster \
    dirb dirbuster \
    whatweb wafw00f \
    wpscan \
    commix \
    xsser

# --- pipx -------------------------------------------------------------------
pipx_install dirsearch       || true
pipx_install pwntools        || true
pipx_install arjun           || true   # GET/POST param discovery
pipx_install paramspider     || true

# --- go-installed -----------------------------------------------------------
go_install "github.com/ffuf/ffuf/v2@latest"
go_install "github.com/projectdiscovery/katana/cmd/katana@latest"
go_install "github.com/tomnomnom/waybackurls@latest"
go_install "github.com/tomnomnom/assetfinder@latest"
go_install "github.com/lc/gau/v2/cmd/gau@latest"
go_install "github.com/hahwul/dalfox/v2@latest"

# --- Burp extension helpers -------------------------------------------------
git_clone https://github.com/PortSwigger/jython-standalone.git jython-standalone || true

ok "Web App module done."
