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

# kismet: requires its own apt repo — too fragile for auto-install (key servers hang)
if ! command -v kismet &>/dev/null; then
    info "Kismet not auto-installed (needs its own repo, can hang)."
    info "  Manual install: https://www.kismetwireless.net/docs/readme/packages/"
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
