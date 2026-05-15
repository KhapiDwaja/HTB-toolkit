#!/usr/bin/env bash
# modules/20-active-directory.sh
# Mirrors the HTB Academy "Active Directory Enumeration & Attacks" module.

info "Active Directory attack toolkit"

# --- APT ---------------------------------------------------------------------
apt_install \
    ldap-utils \
    rpcbind samba-common-bin \
    krb5-user \
    freerdp2-x11 rdesktop \
    samba

# --- pipx — the heavy hitters -----------------------------------------------
pipx_install "impacket"                                  # GetUserSPNs.py, secretsdump.py, ntlmrelayx.py, psexec.py, wmiexec.py, lookupsid.py, ticketer.py, raiseChild.py, smbserver.py, etc.
pipx_install "netexec"                                   # modern crackmapexec fork (the cheatsheet calls it `crackmapexec`)
pipx_install "certipy-ad"                                # AD-CS attacks (ESC1-ESC11)
pipx_install "bloodhound"                                # python collector
pipx_install "bloodyAD"                                  || true
pipx_install "ldapdomaindump"                            || true
pipx_install "adidnsdump"                                || true
pipx_install "pywerview"                                 || true
pipx_install "git+https://github.com/dirkjanm/mitm6.git" || true
pipx_install "donpapi"                                   || true
pipx_install "pyGPOAbuse" --pip-args "git+https://github.com/Hackndo/pyGPOAbuse" || true

# Expose `crackmapexec` as an alias to netexec for cheatsheet compatibility
ln -sf "$(sudo -u "${REAL_USER}" -H bash -lc 'command -v nxc')" "${HTB_TOOLS_DIR}/bin/crackmapexec" 2>/dev/null || true

# --- BloodHound CE (Docker) -------------------------------------------------
if command -v docker &>/dev/null; then
    mkdir -p "${HTB_TOOLS_DIR}/bloodhound-ce"
    if [[ ! -f "${HTB_TOOLS_DIR}/bloodhound-ce/docker-compose.yml" ]]; then
        _run "fetch BloodHound CE docker-compose" curl -sSLo \
            "${HTB_TOOLS_DIR}/bloodhound-ce/docker-compose.yml" \
            "https://raw.githubusercontent.com/SpecterOps/BloodHound/main/examples/docker-compose/docker-compose.yml"
        chown -R "${REAL_USER}:${REAL_USER}" "${HTB_TOOLS_DIR}/bloodhound-ce"
        info "BloodHound CE pulled. Start with: cd ${HTB_TOOLS_DIR}/bloodhound-ce && docker compose up -d"
    fi
else
    warn "Docker not installed — skipping BloodHound CE (install with: sudo apt install docker.io docker-compose-v2)"
fi

# --- Git-cloned tools -------------------------------------------------------
git_clone https://github.com/ropnop/kerbrute.git kerbrute
# Build kerbrute binary
if [[ -d "${HTB_TOOLS_DIR}/kerbrute" && ${DRY_RUN} -eq 0 ]]; then
    _run_as_user "build kerbrute" \
        "cd '${HTB_TOOLS_DIR}/kerbrute' && make all"
    link_into_bin "${HTB_TOOLS_DIR}/kerbrute/dist/kerbrute_linux_amd64" "kerbrute"
fi

git_clone https://github.com/ropnop/windapsearch.git windapsearch
git_clone https://github.com/PowerShellMafia/PowerSploit.git PowerSploit
git_clone https://github.com/BloodHoundAD/SharpHound.git SharpHound       || true
git_clone https://github.com/GhostPack/Rubeus.git Rubeus                  # compiled binaries needed for Windows host; we keep source/refs
git_clone https://github.com/Kevin-Robertson/Inveigh.git Inveigh
git_clone https://github.com/topotam/PetitPotam.git PetitPotam
git_clone https://github.com/cube0x0/CVE-2021-1675.git PrintNightmare
git_clone https://github.com/dirkjanm/PKINITtools.git PKINITtools
git_clone https://github.com/Greenwolf/ntlm_theft.git ntlm_theft

# Responder is in apt on recent Ubuntu/Debian; fall back to git
apt_install responder || git_clone https://github.com/lgandx/Responder.git Responder

# Evil-WinRM
apt_install evil-winrm || _run_as_user "gem install evil-winrm" "sudo gem install evil-winrm" || true

ok "Active Directory module done."
