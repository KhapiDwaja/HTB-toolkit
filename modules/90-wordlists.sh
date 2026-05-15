#!/usr/bin/env bash
# modules/90-wordlists.sh — SecLists + rockyou + a few classics

info "Wordlists"

# --- SecLists (big — ~1.5GB) ------------------------------------------------
SECLISTS_DIR="/usr/share/seclists"
if [[ ! -d "${SECLISTS_DIR}/.git" ]] && [[ ! -d "${SECLISTS_DIR}" ]]; then
    apt_install seclists 2>/dev/null || {
        info "apt seclists unavailable, cloning from GitHub (this is ~1.5GB)"
        if _run "git clone seclists" git clone --depth=1 \
            https://github.com/danielmiessler/SecLists.git "${SECLISTS_DIR}"; then
            manifest_add file "${SECLISTS_DIR}" "seclists"
        fi
    }
else
    info "SecLists already present at ${SECLISTS_DIR}"
fi

# Ensure rockyou is unpacked
ROCKYOU="${SECLISTS_DIR}/Passwords/Leaked-Databases/rockyou.txt"
ROCKYOU_GZ="${ROCKYOU}.gz"
if [[ -f "${ROCKYOU_GZ}" && ! -f "${ROCKYOU}" ]]; then
    info "Extracting rockyou.txt"
    _run "gunzip rockyou.txt.gz" gunzip -k "${ROCKYOU_GZ}"
fi
if [[ -f "${ROCKYOU}" ]]; then
    ok "rockyou.txt available at ${ROCKYOU}"
fi

# --- jsmith.txt etc. for kerbrute (from sec-lists itself) -------------------
# AD username lists already covered in SecLists/Usernames/Names/

# --- /opt/useful symlink pattern your cheatsheet uses -----------------------
mkdir -p /opt/useful
ln -sfn "${SECLISTS_DIR}" /opt/useful/seclists
manifest_add symlink "/opt/useful/seclists" "${SECLISTS_DIR}"
ok "Linked /opt/useful/seclists -> ${SECLISTS_DIR}"

ok "Wordlists module done."
