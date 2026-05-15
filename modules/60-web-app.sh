#!/usr/bin/env bash
# modules/60-web-app.sh — Web application & API pentesting

info "Web application testing toolkit"

# --- APT (per-package fallback handles missing ones) ------------------------
apt_install \
    sqlmap \
    nikto \
    wfuzz \
    gobuster \
    dirb \
    whatweb \
    wafw00f \
    commix \
    xsser \
    zaproxy

# --- Burp Suite Community: not in standard Ubuntu repos -------------------
# We don't auto-install Burp here (huge JAR + EULA). Point the user instead.
if ! command -v burpsuite &>/dev/null; then
    info "Burp Suite Community not auto-installed."
    info "  Manual: https://portswigger.net/burp/releases/community/latest"
fi

# --- WPScan: Ruby gem -------------------------------------------------------
apt_install ruby ruby-dev
_run "install wpscan gem" gem install wpscan
manifest_add file "wpscan" "ruby-gem"

# --- feroxbuster: from GitHub release (binary) ------------------------------
if ! command -v feroxbuster &>/dev/null; then
    FEROX_DIR="${HTB_TOOLS_DIR}/feroxbuster"
    mkdir -p "${FEROX_DIR}"
    chown "${REAL_USER}:${REAL_USER}" "${FEROX_DIR}"
    if [[ ${DRY_RUN} -eq 0 ]]; then
        info "Downloading feroxbuster latest"
        _run "fetch feroxbuster" curl -sSLo /tmp/feroxbuster.zip \
            "https://github.com/epi052/feroxbuster/releases/latest/download/x86_64-linux-feroxbuster.zip"
        if [[ -f /tmp/feroxbuster.zip ]]; then
            _run "extract feroxbuster" unzip -o /tmp/feroxbuster.zip -d "${FEROX_DIR}"
            chmod +x "${FEROX_DIR}/feroxbuster" 2>/dev/null
            link_into_bin "${FEROX_DIR}/feroxbuster" "feroxbuster"
            rm -f /tmp/feroxbuster.zip
        fi
    fi
fi

# --- pipx -------------------------------------------------------------------
pipx_install "dirsearch"
pipx_install "arjun"
# paramspider: from GitHub (not on PyPI)
pipx_install "git+https://github.com/devanshbatham/ParamSpider.git"
# pwntools belongs in post-exploit but useful here too
pipx_install "pwntools"

# --- Go-installed -----------------------------------------------------------
go_install "github.com/ffuf/ffuf/v2@latest"
go_install "github.com/projectdiscovery/katana/cmd/katana@latest"
go_install "github.com/tomnomnom/waybackurls@latest"
go_install "github.com/tomnomnom/assetfinder@latest"
go_install "github.com/lc/gau/v2/cmd/gau@latest"
go_install "github.com/hahwul/dalfox/v2@latest"

ok "Web App module done."
