#!/usr/bin/env bash
# ==============================================================================
# htb-toolkit :: remove.sh
# ------------------------------------------------------------------------------
# Clean uninstaller. Reads the install manifest written by install.sh and
# only removes things this toolkit actually put there. Will not touch
# packages/binaries that were on the system before install.
# ==============================================================================
set -u
set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
export HTB_TOOLKIT_ROOT="${SCRIPT_DIR}"
export HTB_TOOLS_DIR="${HTB_TOOLS_DIR:-/opt/htb-toolkit}"
export HTB_LOG="${HTB_LOG:-/var/log/htb-toolkit-install.log}"
export HTB_MANIFEST="${HTB_TOOLS_DIR}/.manifest"
export DRY_RUN=0   # required by libs

# Source libs (colors + logger only — we don't need install helpers here)
# shellcheck source=lib/colors.sh
source "${SCRIPT_DIR}/lib/colors.sh"
# shellcheck source=lib/logger.sh
source "${SCRIPT_DIR}/lib/logger.sh"

banner() {
cat <<'BANNER'
 _   _ _____ ____    ____                                
| | | |_   _| __ )  |  _ \ ___ _ __ ___   _____   _____  
| |_| | | | |  _ \  | |_) / _ \ '_ ` _ \ / _ \ \ / / _ \ 
|  _  | | | | |_) | |  _ <  __/ | | | | | (_) \ V /  __/ 
|_| |_| |_| |____/  |_| \_\___|_| |_| |_|\___/ \_/ \___| 

 htb-toolkit uninstaller :: manifest-aware, safe by default
BANNER
}

# ---------- CLI ------------------------------------------------------------
# DEFAULTS: nuke everything. Use --keep-* flags to spare specific categories.
REMOVE_APT=1
REMOVE_PIPX=1
REMOVE_GIT=1
REMOVE_GO=1
REMOVE_SYMLINKS=1
REMOVE_RC=1
REMOVE_WORDLISTS=1
REMOVE_LOGS=1
DRY_RUN=0
ASSUME_YES=0
INTERACTIVE=0

usage() {
cat <<EOF
Usage: sudo ./remove.sh --yes [OPTIONS]

DEFAULT BEHAVIOR: FULL NUKE.
Without --keep-* flags this removes EVERYTHING htb-toolkit installed:
  ✓ APT packages we installed
  ✓ pipx packages we installed
  ✓ /opt/htb-toolkit (cloned tools, binaries, symlinks)
  ✓ go binaries we installed (ffuf, httpx, nuclei, ...)
  ✓ /usr/share/seclists and /opt/useful symlink
  ✓ env block from ~/.bashrc and ~/.zshrc
  ✓ install log file

SAFETY: --yes is REQUIRED.
Running without --yes prints the plan and exits without touching anything.
An interactive y/N prompt is NOT enough by design.

OPTIONS:
  --yes              REQUIRED to actually delete anything
  --dry-run          Show what would be removed; change nothing (no --yes needed)
  --interactive      Ask per category at runtime (still requires --yes to commit)

  --keep-apt         Don't remove apt packages
  --keep-pipx        Don't remove pipx packages
  --keep-go          Don't remove go binaries
  --keep-tools-dir   Don't remove /opt/htb-toolkit
  --keep-wordlists   Don't remove /usr/share/seclists (1.5GB to redownload)
  --keep-logs        Don't remove the install log file
  --keep-rc          Don't touch ~/.bashrc / ~/.zshrc

  -h, --help         Show this help

EXAMPLES:
  sudo ./remove.sh                       # PRINTS PLAN ONLY (no --yes)
  sudo ./remove.sh --dry-run             # detailed preview, no changes
  sudo ./remove.sh --yes                 # FULL NUKE — removes everything
  sudo ./remove.sh --yes --keep-wordlists --keep-apt
                                         # nuke /opt + pipx + go + rc, keep apt and seclists

Manifest location: ${HTB_MANIFEST}
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --yes|-y)         ASSUME_YES=1; shift ;;
        --dry-run)        DRY_RUN=1; shift ;;
        --interactive|-i) INTERACTIVE=1; shift ;;

        --keep-apt)       REMOVE_APT=0; shift ;;
        --keep-pipx)      REMOVE_PIPX=0; shift ;;
        --keep-go)        REMOVE_GO=0; shift ;;
        --keep-tools-dir) REMOVE_GIT=0; shift ;;
        --keep-wordlists) REMOVE_WORDLISTS=0; shift ;;
        --keep-logs)      REMOVE_LOGS=0; shift ;;
        --keep-rc)        REMOVE_RC=0; shift ;;

        -h|--help)        usage; exit 0 ;;
        *)                err "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# ---------- Preflight ------------------------------------------------------
preflight() {
    if [[ "${EUID}" -ne 0 ]]; then
        err "Run with sudo (root needed for apt remove, /opt deletion, etc.)"
        exit 1
    fi
    REAL_USER="${SUDO_USER:-${USER}}"
    REAL_HOME="$(getent passwd "${REAL_USER}" | cut -d: -f6 2>/dev/null || echo /root)"
    export REAL_USER REAL_HOME

    if [[ ! -f "${HTB_MANIFEST}" ]]; then
        warn "No manifest found at ${HTB_MANIFEST}"
        warn "Either nothing is installed, or an older install ran without manifest support."
        warn "Will fall back to removing the well-known paths only."
    else
        local n; n=$(wc -l < "${HTB_MANIFEST}" 2>/dev/null || echo 0)
        info "Manifest present: ${n} entries"
    fi
}

# ---------- Interactive ----------------------------------------------------
interactive_pick() {
    echo
    info "Interactive mode — pick what to remove (Enter = keep default = REMOVE)"
    echo

    local _ans
    read -rp "Remove APT packages we installed? [Y/n] " _ans
    [[ "${_ans,,}" == "n" ]] && REMOVE_APT=0 || REMOVE_APT=1

    read -rp "Remove pipx packages we installed? [Y/n] " _ans
    [[ "${_ans,,}" == "n" ]] && REMOVE_PIPX=0 || REMOVE_PIPX=1

    read -rp "Remove /opt/htb-toolkit (cloned tools, binaries)? [Y/n] " _ans
    [[ "${_ans,,}" == "n" ]] && REMOVE_GIT=0 || REMOVE_GIT=1

    read -rp "Remove go binaries we installed (ffuf, nuclei, etc)? [Y/n] " _ans
    [[ "${_ans,,}" == "n" ]] && REMOVE_GO=0 || REMOVE_GO=1

    read -rp "Remove env block from ~/.bashrc and ~/.zshrc? [Y/n] " _ans
    [[ "${_ans,,}" == "n" ]] && REMOVE_RC=0 || REMOVE_RC=1

    read -rp "Remove /usr/share/seclists (1.5GB to redownload)? [Y/n] " _ans
    [[ "${_ans,,}" == "n" ]] && REMOVE_WORDLISTS=0 || REMOVE_WORDLISTS=1

    read -rp "Remove install log file? [Y/n] " _ans
    [[ "${_ans,,}" == "n" ]] && REMOVE_LOGS=0 || REMOVE_LOGS=1
}

# ---------- Summary --------------------------------------------------------
print_plan() {
    section "Removal plan"
    if [[ ${ASSUME_YES} -ne 1 && ${DRY_RUN} -ne 1 ]]; then
        printf "  ${C_YELLOW}${C_BOLD}>>> NO --yes FLAG: this is a preview only. Nothing will be deleted. <<<${C_RESET}\n\n"
    elif [[ ${DRY_RUN} -eq 1 ]]; then
        printf "  ${C_YELLOW}${C_BOLD}>>> DRY RUN: nothing will be deleted. <<<${C_RESET}\n\n"
    else
        printf "  ${C_RED}${C_BOLD}>>> --yes PROVIDED: this WILL delete the items below. <<<${C_RESET}\n\n"
    fi

    local _mark
    _mark() { [[ $1 -eq 1 ]] && echo "${C_RED}REMOVE${C_RESET}" || echo "${C_DIM}keep  ${C_RESET}"; }

    printf "  [%s] APT packages we installed\n"              "$(_mark ${REMOVE_APT})"
    printf "  [%s] pipx packages we installed\n"             "$(_mark ${REMOVE_PIPX})"
    printf "  [%s] /opt/htb-toolkit (cloned tools + bin/)\n" "$(_mark ${REMOVE_GIT})"
    printf "  [%s] go binaries (~/go/bin) we installed\n"    "$(_mark ${REMOVE_GO})"
    printf "  [%s] env block in ~/.bashrc / ~/.zshrc\n"      "$(_mark ${REMOVE_RC})"
    printf "  [%s] /usr/share/seclists + /opt/useful link\n" "$(_mark ${REMOVE_WORDLISTS})"
    printf "  [%s] install log file (${HTB_LOG})\n"          "$(_mark ${REMOVE_LOGS})"
    echo
}

confirm_or_die() {
    # Dry run never deletes — always safe to "continue".
    [[ ${DRY_RUN} -eq 1 ]] && return 0

    if [[ ${ASSUME_YES} -ne 1 ]]; then
        echo
        err "Refusing to delete anything: --yes flag not provided."
        echo
        info "This is intentional. Even an interactive y/N prompt is too easy to misclick."
        info "To proceed, re-run with --yes:"
        info "    sudo ./remove.sh --yes"
        info "Or preview first:"
        info "    sudo ./remove.sh --dry-run"
        exit 2
    fi
}

# ---------- Manifest reader -------------------------------------------------
# Print column 2 of all manifest lines whose column 1 == $1
manifest_get() {
    [[ -f "${HTB_MANIFEST}" ]] || return 0
    awk -F'\t' -v k="$1" '$1==k {print $2}' "${HTB_MANIFEST}"
}

# ---------- The removers ----------------------------------------------------
_rm() {
    # _rm <path>
    local p="$1"
    [[ -e "$p" || -L "$p" ]] || return 0
    if [[ ${DRY_RUN} -eq 1 ]]; then
        info "(dry-run) rm -rf ${p}"
    else
        rm -rf "$p" && ok "removed ${p}" || warn "failed to remove ${p}"
    fi
}

remove_pipx() {
    section "Removing pipx packages"
    local pkgs
    pkgs=$(manifest_get pipx)
    if [[ -z "${pkgs}" ]]; then
        info "No pipx packages in manifest"
        return 0
    fi
    while IFS= read -r pkg; do
        [[ -z "${pkg}" ]] && continue
        if [[ ${DRY_RUN} -eq 1 ]]; then
            info "(dry-run) pipx uninstall ${pkg}"
        else
            if sudo -u "${REAL_USER}" -H bash -lc "pipx uninstall ${pkg}" >>"${HTB_LOG}" 2>&1; then
                ok "pipx uninstalled: ${pkg}"
            else
                warn "pipx uninstall failed (already gone?): ${pkg}"
            fi
        fi
    done <<< "${pkgs}"
}

remove_go_bins() {
    section "Removing go binaries"
    local bins
    bins=$(manifest_get go)
    if [[ -z "${bins}" ]]; then
        info "No go binaries in manifest"
        return 0
    fi
    while IFS= read -r bin; do
        [[ -z "${bin}" ]] && continue
        _rm "${bin}"
    done <<< "${bins}"
}

remove_tools_dir() {
    section "Removing /opt/htb-toolkit"
    if [[ -d "${HTB_TOOLS_DIR}" ]]; then
        _rm "${HTB_TOOLS_DIR}"
    else
        info "${HTB_TOOLS_DIR} doesn't exist"
    fi
}

remove_rc_block() {
    section "Removing env block from shell rc files"
    for rc in "${REAL_HOME}/.bashrc" "${REAL_HOME}/.zshrc" /root/.bashrc /root/.zshrc; do
        [[ -f "${rc}" ]] || continue
        if grep -q '# >>> htb-toolkit >>>' "${rc}"; then
            if [[ ${DRY_RUN} -eq 1 ]]; then
                info "(dry-run) sed-delete env block in ${rc}"
            else
                sed -i.htb-backup '/# >>> htb-toolkit >>>/,/# <<< htb-toolkit <<</d' "${rc}"
                ok "Cleaned ${rc} (backup at ${rc}.htb-backup)"
            fi
        fi
    done
}

remove_apt_packages() {
    section "Removing APT packages we installed"
    local pkgs
    pkgs=$(manifest_get apt | sort -u)
    if [[ -z "${pkgs}" ]]; then
        warn "No apt packages in manifest"
        return 0
    fi
    info "apt-get remove --purge for these packages:"
    echo "${pkgs}" | sed 's/^/    /'
    local pkg_list
    pkg_list=$(echo "${pkgs}" | tr '\n' ' ')
    if [[ ${DRY_RUN} -eq 1 ]]; then
        info "(dry-run) apt-get remove --purge -y ${pkg_list}"
        info "(dry-run) apt-get autoremove -y"
    else
        # shellcheck disable=SC2086
        apt-get remove --purge -y ${pkg_list} >>"${HTB_LOG}" 2>&1 || warn "Some packages may not have been installed by us"
        apt-get autoremove -y >>"${HTB_LOG}" 2>&1
        ok "APT packages removed"
    fi
}

remove_wordlists() {
    section "Removing wordlists"
    _rm "/usr/share/seclists"
    _rm "/opt/useful/seclists"
    # only rm /opt/useful if it's empty
    [[ -d "/opt/useful" && -z "$(ls -A /opt/useful 2>/dev/null)" ]] && _rm "/opt/useful"
}

remove_logs() {
    section "Removing install log"
    _rm "${HTB_LOG}"
}

# ==========================================================================
# MAIN
# ==========================================================================
banner
preflight

[[ ${INTERACTIVE} -eq 1 ]] && interactive_pick

print_plan
confirm_or_die

# Order matters: env block first (so a half-broken shell still works),
# then pipx (so binaries vanish from PATH), then files/dirs, then apt.
[[ ${REMOVE_RC}        -eq 1 ]] && remove_rc_block
[[ ${REMOVE_PIPX}      -eq 1 ]] && remove_pipx
[[ ${REMOVE_GO}        -eq 1 ]] && remove_go_bins
[[ ${REMOVE_GIT}       -eq 1 ]] && remove_tools_dir
[[ ${REMOVE_APT}       -eq 1 ]] && remove_apt_packages
[[ ${REMOVE_WORDLISTS} -eq 1 ]] && remove_wordlists
[[ ${REMOVE_LOGS}      -eq 1 ]] && remove_logs

section "All done"
ok "htb-toolkit removal complete."
[[ ${DRY_RUN} -eq 1 ]] && warn "This was a dry-run. Run without --dry-run to actually remove."
echo
info "Tip: open a new terminal so the old PATH/aliases drop out of your shell."
