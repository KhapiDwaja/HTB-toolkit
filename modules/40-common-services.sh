#!/usr/bin/env bash
# modules/40-common-services.sh
# Mirrors the HTB Academy "Attacking Common Services" module:
# FTP, SMB, NFS, SMTP, IMAP/POP3, SNMP, MySQL, MSSQL, Oracle, RDP, WinRM, IPMI...

info "Common services attack toolkit"

# --- APT --------------------------------------------------------------------
apt_install \
    ftp tftp tftp-hpa \
    smbclient smbmap cifs-utils nfs-common \
    swaks \
    snmp snmp-mibs-downloader snmpcheck \
    onesixtyone \
    redis-tools \
    mariadb-client postgresql-client \
    freerdp2-x11 rdesktop \
    sipcalc sipsak \
    ldap-utils

# --- MSSQL: handled by impacket (mssqlclient.py) + sqsh / mssqlcli ----------
apt_install mssqlcli || true     # not always packaged; pip fallback below
pipx_install "mssql-cli"   || true
pipx_install "impacket"    || true   # noop if 20-ad already did this

# --- Oracle: ODAT -----------------------------------------------------------
git_clone https://github.com/quentinhardy/odat.git odat
# odat is a python tool; install its deps
if [[ -d "${HTB_TOOLS_DIR}/odat" && ${DRY_RUN} -eq 0 ]]; then
    _run_as_user "odat python deps" \
        "cd '${HTB_TOOLS_DIR}/odat' && python3 -m pip install -r requirements.txt --break-system-packages 2>/dev/null || python3 -m pip install -r requirements.txt"
fi

# --- IPMI -------------------------------------------------------------------
apt_install ipmitool

# --- VOIP / SIP (if you do that path) ---------------------------------------
apt_install sipvicious || true

# --- Web services tools -----------------------------------------------------
apt_install curl wget httpie

ok "Common Services module done."
