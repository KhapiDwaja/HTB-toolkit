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
    keepassxc

# john-jumbo provides ssh2john, office2john, keepass2john, zip2john, rar2john, pdf2john
# Ubuntu's john package usually IS john-jumbo; if scripts aren't on PATH, symlink them.
for j in ssh2john office2john keepass2john zip2john rar2john pdf2john; do
    if ! command -v "${j}" &>/dev/null; then
        # /usr/share/john/* on Ubuntu; some are .py, some are no-extension
        found=$(find /usr/share/john /usr/share/john-jumbo /usr/local/share/john 2>/dev/null \
                -type f \( -name "${j}" -o -name "${j}.py" -o -name "${j}.pl" \) | head -1)
        if [[ -n "${found}" ]]; then
            link_into_bin "${found}" "${j}"
        fi
    fi
done

# --- pipx -------------------------------------------------------------------
# patator: not on PyPI; install from GitHub
pipx_install "git+https://github.com/lanjelot/patator.git"

# --- Git-cloned tools (Linux post-exploit credential harvesting) ------------
git_clone "https://github.com/huntergregal/mimipenguin.git" "mimipenguin"
git_clone "https://github.com/AlessandroZ/LaZagne.git" "LaZagne"
git_clone "https://github.com/unode/firefox_decrypt.git" "firefox_decrypt"
git_clone "https://github.com/urbanadventurer/username-anarchy.git" "username-anarchy"

info "(Wordlists handled by the 90-wordlists module.)"
ok "Password Attacks module done."
