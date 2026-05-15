#!/usr/bin/env bash
# modules/70-wireless.sh — Wi-Fi / Bluetooth / SDR

info "Wireless attack toolkit"

# --- APT --------------------------------------------------------------------
apt_install \
    aircrack-ng \
    reaver \
    bully \
    pixiewps \
    hcxdumptool \
    hcxtools \
    mdk4 \
    bettercap \
    bluez \
    bluez-tools \
    rfkill \
    macchanger

# kismet: not in Ubuntu/Pop!OS default repos; use Kismet's own apt repo
if ! command -v kismet &>/dev/null && [[ ${DRY_RUN} -eq 0 ]]; then
    info "Adding Kismet repository"
    _run "add kismet gpg key" bash -c \
        "wget -qO- https://www.kismetwireless.net/repos/kismet-release.gpg.key | gpg --dearmor > /usr/share/keyrings/kismet-archive-keyring.gpg 2>/dev/null"
    CODENAME=$(lsb_release -cs 2>/dev/null || echo jammy)
    echo "deb [signed-by=/usr/share/keyrings/kismet-archive-keyring.gpg] https://www.kismetwireless.net/repos/apt/release/${CODENAME} ${CODENAME} main" \
        > /etc/apt/sources.list.d/kismet.list 2>/dev/null
    APT_UPDATED=0
    apt_update_once
    apt_install kismet
fi

# --- wifite: not in Ubuntu repos; install from GitHub -----------------------
git_clone "https://github.com/derv82/wifite2.git" "wifite2"
if [[ -f "${HTB_TOOLS_DIR}/wifite2/Wifite.py" ]]; then
    # provide a launcher
    cat > "${HTB_TOOLS_DIR}/wifite2/wifite-launcher.sh" <<'EOF'
#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"
exec sudo python3 "${SCRIPT_DIR}/Wifite.py" "$@"
EOF
    chmod +x "${HTB_TOOLS_DIR}/wifite2/wifite-launcher.sh"
    chown "${REAL_USER}:${REAL_USER}" "${HTB_TOOLS_DIR}/wifite2/wifite-launcher.sh"
    link_into_bin "${HTB_TOOLS_DIR}/wifite2/wifite-launcher.sh" "wifite"
fi

# --- Optional SDR — only with INSTALL_SDR=1 ---------------------------------
if [[ "${INSTALL_SDR:-0}" == "1" ]]; then
    apt_install rtl-sdr gqrx-sdr gnuradio
else
    info "Skipping SDR (set INSTALL_SDR=1 to include rtl-sdr/gqrx/gnuradio)"
fi

ok "Wireless module done."
