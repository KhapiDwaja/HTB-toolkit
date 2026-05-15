#!/usr/bin/env bash
# modules/20-active-directory.sh
# Mirrors the HTB Academy "Active Directory Enumeration & Attacks" module.

info "Active Directory attack toolkit"

# --- APT --------------------------------------------------------------------
apt_install \
    ldap-utils \
    rpcbind \
    samba-common-bin \
    samba \
    krb5-user \
    freerdp2-x11 \
    rdesktop

# --- pipx — the heavy hitters -----------------------------------------------
pipx_install "impacket"
pipx_install "git+https://github.com/Pennyw0rth/NetExec.git"   # netexec (modern crackmapexec)
pipx_install "certipy-ad"
pipx_install "bloodhound"
pipx_install "git+https://github.com/CravateRouge/bloodyAD.git"
pipx_install "ldapdomaindump"
pipx_install "adidnsdump"
pipx_install "pywerview"
pipx_install "git+https://github.com/dirkjanm/mitm6.git"
pipx_install "donpapi"
pipx_install "git+https://github.com/Hackndo/pyGPOAbuse.git"

# Expose `crackmapexec` as a symlink to nxc so the HTB cheatsheet commands work as-is
NXC_PATH="${REAL_HOME}/.local/bin/nxc"
if [[ -x "${NXC_PATH}" ]]; then
    link_into_bin "${NXC_PATH}" "crackmapexec"
fi

# --- Responder — not in Ubuntu repos by default; clone source ---------------
git_clone "https://github.com/lgandx/Responder.git" "Responder"
if [[ -f "${HTB_TOOLS_DIR}/Responder/Responder.py" ]]; then
    link_into_bin "${HTB_TOOLS_DIR}/Responder/Responder.py" "responder"
fi

# --- Evil-WinRM — Ruby gem (not in Ubuntu repos anymore) --------------------
apt_install ruby ruby-dev
_run "install evil-winrm gem" gem install evil-winrm
# gem binary will be in /usr/local/bin or ~/.local/share/gem/ruby/X.Y.Z/bin
manifest_add file "evil-winrm" "ruby-gem"

# --- BloodHound CE (Docker) -------------------------------------------------
if command -v docker &>/dev/null; then
    mkdir -p "${HTB_TOOLS_DIR}/bloodhound-ce"
    if [[ ! -f "${HTB_TOOLS_DIR}/bloodhound-ce/docker-compose.yml" && ${DRY_RUN} -eq 0 ]]; then
        _run "fetch BloodHound CE docker-compose" curl -sSLo \
            "${HTB_TOOLS_DIR}/bloodhound-ce/docker-compose.yml" \
            "https://raw.githubusercontent.com/SpecterOps/BloodHound/main/examples/docker-compose/docker-compose.yml"
        chown -R "${REAL_USER}:${REAL_USER}" "${HTB_TOOLS_DIR}/bloodhound-ce"
        info "BloodHound CE pulled. Start with: cd ${HTB_TOOLS_DIR}/bloodhound-ce && docker compose up -d"
    fi
else
    warn "Docker not installed — BloodHound CE skipped"
    warn "Install with: sudo apt install docker.io docker-compose-v2"
fi

# --- Git-cloned tools -------------------------------------------------------
git_clone "https://github.com/ropnop/kerbrute.git" "kerbrute"
# Build kerbrute — use go build directly instead of Makefile (more reliable)
if [[ -d "${HTB_TOOLS_DIR}/kerbrute" && ${DRY_RUN} -eq 0 ]]; then
    GO_BIN="$(command -v go 2>/dev/null || echo /usr/local/go/bin/go)"
    if [[ -x "${GO_BIN}" ]]; then
        KERB_OUT="${HTB_TOOLS_DIR}/kerbrute/dist/kerbrute_linux_amd64"
        mkdir -p "${HTB_TOOLS_DIR}/kerbrute/dist"
        _run_as_user "build kerbrute" \
            "cd '${HTB_TOOLS_DIR}/kerbrute' && \
             export PATH=\"\$PATH:$(dirname "${GO_BIN}")\" && \
             export GOPATH=\"${REAL_HOME}/go\" && \
             ${GO_BIN} build -ldflags '-s -w' -trimpath -o '${KERB_OUT}' ."
        if [[ -f "${KERB_OUT}" ]]; then
            link_into_bin "${KERB_OUT}" "kerbrute"
        fi
    else
        warn "Go not found — kerbrute not built."
    fi
fi

git_clone "https://github.com/ropnop/windapsearch.git" "windapsearch"
git_clone "https://github.com/PowerShellMafia/PowerSploit.git" "PowerSploit"
git_clone "https://github.com/BloodHoundAD/SharpHound.git" "SharpHound"
git_clone "https://github.com/GhostPack/Rubeus.git" "Rubeus"
git_clone "https://github.com/Kevin-Robertson/Inveigh.git" "Inveigh"
git_clone "https://github.com/topotam/PetitPotam.git" "PetitPotam"
git_clone "https://github.com/cube0x0/CVE-2021-1675.git" "PrintNightmare"
git_clone "https://github.com/dirkjanm/PKINITtools.git" "PKINITtools"
git_clone "https://github.com/Greenwolf/ntlm_theft.git" "ntlm_theft"

ok "Active Directory module done."
