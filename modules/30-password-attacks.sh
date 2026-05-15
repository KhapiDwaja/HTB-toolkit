#!/usr/bin/env bash
# modules/30-password-attacks.sh
# Mirrors the HTB Academy "Password Attacks" module.

info "Password attack toolkit"

# --- APT --------------------------------------------------------------------
apt_install \
    hashcat \
    john \
    hydra \
    medusa \
    ncrack \
    crunch \
    cewl \
    hashid \
    pdfcrack \
    fcrackzip \
    bruteforce-luks \
    cifs-utils \
    keepassxc          # not for attack, for storing your own creds

# john-the-ripper jumbo (provides ssh2john, office2john, keepass2john, etc.)
# john from apt on Ubuntu is jumbo already; if symlinks aren't there, point them.
for j in ssh2john office2john keepass2john zip2john rar2john pdf2john; do
    if ! command -v "${j}" &>/dev/null; then
        found=$(find /usr -type f -name "${j}*" 2>/dev/null | head -1)
        [[ -n "${found}" ]] && link_into_bin "${found}" "${j}"
    fi
done

# --- pipx -------------------------------------------------------------------
pipx_install patator || true                # multi-protocol bruteforcer

# --- Git-cloned tools (creds harvesting on Linux victims) -------------------
git_clone https://github.com/huntergregal/mimipenguin.git mimipenguin
git_clone https://github.com/AlessandroZ/LaZagne.git LaZagne
git_clone https://github.com/unode/firefox_decrypt.git firefox_decrypt
git_clone https://github.com/urbanadventurer/username-anarchy.git username-anarchy

# --- Wordlists triggers (real install in 90-wordlists) ----------------------
info "(Wordlists handled by the 90-wordlists module.)"

ok "Password Attacks module done."
