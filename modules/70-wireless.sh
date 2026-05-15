#!/usr/bin/env bash
# modules/70-wireless.sh — Wi-Fi / Bluetooth / SDR

info "Wireless attack toolkit"

apt_install \
    aircrack-ng \
    reaver \
    bully \
    pixiewps \
    hcxdumptool hcxtools \
    kismet \
    wifite \
    mdk4 \
    bettercap \
    bluez bluez-tools \
    rfkill \
    macchanger

# Optional SDR — only install if user has hardware
if [[ "${INSTALL_SDR:-0}" == "1" ]]; then
    apt_install rtl-sdr gqrx-sdr gnuradio
else
    info "Skipping SDR (set INSTALL_SDR=1 to include rtl-sdr/gqrx/gnuradio)"
fi

ok "Wireless module done."
