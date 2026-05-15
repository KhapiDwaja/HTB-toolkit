#!/usr/bin/env bash
# modules/50-pivoting.sh
# Mirrors the HTB Academy "Pivoting, Tunneling, and Port Forwarding" module.

info "Pivoting / tunneling toolkit"

# --- APT --------------------------------------------------------------------
apt_install \
    proxychains4 \
    socat \
    sshuttle \
    iptables iproute2 \
    openvpn wireguard-tools \
    plink \
    ncat

# --- Chisel (precompiled binary) --------------------------------------------
CHISEL_VER="v1.10.1"
CHISEL_DIR="${HTB_TOOLS_DIR}/chisel"
mkdir -p "${CHISEL_DIR}"
if [[ ! -x "${CHISEL_DIR}/chisel" && ${DRY_RUN} -eq 0 ]]; then
    info "Downloading chisel ${CHISEL_VER}"
    _run "fetch chisel" curl -sSLo /tmp/chisel.gz \
        "https://github.com/jpillora/chisel/releases/download/${CHISEL_VER}/chisel_${CHISEL_VER#v}_linux_amd64.gz"
    gunzip -f /tmp/chisel.gz -c > "${CHISEL_DIR}/chisel"
    chmod +x "${CHISEL_DIR}/chisel"
    chown -R "${REAL_USER}:${REAL_USER}" "${CHISEL_DIR}"
    link_into_bin "${CHISEL_DIR}/chisel" "chisel"
fi

# --- Ligolo-ng (precompiled binaries) ---------------------------------------
LIGOLO_VER="v0.7.5"
LIGOLO_DIR="${HTB_TOOLS_DIR}/ligolo-ng"
mkdir -p "${LIGOLO_DIR}"
if [[ ! -x "${LIGOLO_DIR}/proxy" && ${DRY_RUN} -eq 0 ]]; then
    info "Downloading ligolo-ng ${LIGOLO_VER}"
    _run "fetch ligolo proxy" curl -sSLo /tmp/ligolo-proxy.tgz \
        "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VER}/ligolo-ng_proxy_${LIGOLO_VER#v}_linux_amd64.tar.gz"
    tar -xzf /tmp/ligolo-proxy.tgz -C "${LIGOLO_DIR}" proxy
    _run "fetch ligolo agent" curl -sSLo /tmp/ligolo-agent.tgz \
        "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VER}/ligolo-ng_agent_${LIGOLO_VER#v}_linux_amd64.tar.gz"
    tar -xzf /tmp/ligolo-agent.tgz -C "${LIGOLO_DIR}" agent
    chown -R "${REAL_USER}:${REAL_USER}" "${LIGOLO_DIR}"
    link_into_bin "${LIGOLO_DIR}/proxy" "ligolo-proxy"
    link_into_bin "${LIGOLO_DIR}/agent" "ligolo-agent"
fi

# --- ptunnel-ng (cheatsheet uses this) --------------------------------------
git_clone https://github.com/utoni/ptunnel-ng.git ptunnel-ng
if [[ -d "${HTB_TOOLS_DIR}/ptunnel-ng" && ${DRY_RUN} -eq 0 ]]; then
    _run_as_user "build ptunnel-ng" \
        "cd '${HTB_TOOLS_DIR}/ptunnel-ng' && ./autogen.sh"
    # ptunnel-ng binary may end up in src/
    if [[ -f "${HTB_TOOLS_DIR}/ptunnel-ng/src/ptunnel-ng" ]]; then
        link_into_bin "${HTB_TOOLS_DIR}/ptunnel-ng/src/ptunnel-ng" "ptunnel-ng"
    fi
fi

# --- SocksOverRDP — Windows-only; we just stash the link as ref -------------
cat > "${HTB_TOOLS_DIR}/_windows-refs.md" <<'EOF'
# Windows-side tools (just URLs — install on the Windows host you pop)
- SocksOverRDP   : https://github.com/nccgroup/SocksOverRDP/releases
- Plink          : https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
- Inveigh        : built from git clone (see /opt/htb-toolkit/Inveigh)
- Rubeus         : built from git clone (see /opt/htb-toolkit/Rubeus)
- mimikatz       : https://github.com/gentilkiwi/mimikatz/releases
EOF

ok "Pivoting module done."
