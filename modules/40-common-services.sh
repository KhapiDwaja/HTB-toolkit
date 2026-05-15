#!/usr/bin/env bash
# modules/40-common-services.sh
# Mirrors the HTB Academy "Attacking Common Services" module.

info "Common services attack toolkit"

# --- APT --------------------------------------------------------------------
# Ubuntu/Pop!OS uses 'tnftp' or 'ftp' (filesystem hierarchy of which exists varies by release).
# apt_install tolerates per-package failure, so list them all.
apt_install \
    ftp \
    tnftp \
    tftp \
    tftp-hpa \
    smbclient \
    smbmap \
    cifs-utils \
    nfs-common \
    swaks \
    snmp \
    snmp-mibs-downloader \
    snmpcheck \
    onesixtyone \
    redis-tools \
    mariadb-client \
    postgresql-client \
    sipcalc \
    sipsak \
    ldap-utils \
    ipmitool \
    sipvicious \
    httpie \
    curl \
    wget

# --- MSSQL: impacket's mssqlclient.py covers it; mssql-cli is optional ------
pipx_install "mssql-cli"
# impacket already installed by 20-active-directory; pipx --force is idempotent
pipx_install "impacket"

# --- Oracle: ODAT -----------------------------------------------------------
git_clone "https://github.com/quentinhardy/odat.git" "odat"
if [[ -d "${HTB_TOOLS_DIR}/odat" && ${DRY_RUN} -eq 0 ]]; then
    # On Ubuntu 23.04+/Pop!OS 22.04+, system pip refuses without --break-system-packages.
    # We don't want to pollute system Python anyway; use a venv just for odat.
    _run_as_user "odat venv setup" \
        "cd '${HTB_TOOLS_DIR}/odat' && \
         python3 -m venv .venv && \
         .venv/bin/pip install --upgrade pip && \
         .venv/bin/pip install -r requirements.txt"
    # Provide a wrapper that uses the venv's python
    cat > "${HTB_TOOLS_DIR}/odat/odat.sh" <<'EOF'
#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"
exec "${SCRIPT_DIR}/.venv/bin/python" "${SCRIPT_DIR}/odat.py" "$@"
EOF
    chmod +x "${HTB_TOOLS_DIR}/odat/odat.sh"
    chown "${REAL_USER}:${REAL_USER}" "${HTB_TOOLS_DIR}/odat/odat.sh"
    link_into_bin "${HTB_TOOLS_DIR}/odat/odat.sh" "odat"
fi

ok "Common Services module done."
