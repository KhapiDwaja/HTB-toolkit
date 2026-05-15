#!/usr/bin/env bash
# ==============================================================================
# htb-toolkit :: install.sh
# ------------------------------------------------------------------------------
# One-shot installer for a HackTheBox / OSCP / red-team Linux loadout.
# Forked & extended from: github.com/ericsherlock/pentools-install
# Target distro: Pop!OS / Ubuntu / Debian (apt-based)
# ==============================================================================
set -u  # don't use -e: we *want* to continue past a single failed tool
set -o pipefail

# ---------- Resolve paths --------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
export HTB_TOOLKIT_ROOT="${SCRIPT_DIR}"
export HTB_TOOLS_DIR="${HTB_TOOLS_DIR:-/opt/htb-toolkit}"
export HTB_LOG="${HTB_LOG:-/var/log/htb-toolkit-install.log}"

# ---------- Source libs ----------------------------------------------------
# shellcheck source=lib/colors.sh
source "${SCRIPT_DIR}/lib/colors.sh"
# shellcheck source=lib/logger.sh
source "${SCRIPT_DIR}/lib/logger.sh"
# shellcheck source=lib/helpers.sh
source "${SCRIPT_DIR}/lib/helpers.sh"

# ---------- Banner ---------------------------------------------------------
banner() {
cat <<'BANNER'
 _   _ _____ ____    _____           _ _    _ _
| | | |_   _| __ )  |_   _|__   ___ | | | _(_) |_
| |_| | | | |  _ \    | |/ _ \ / _ \| | |/ / | __|
|  _  | | | | |_) |   | | (_) | (_) | |   <| | |_
|_| |_| |_| |____/    |_|\___/ \___/|_|_|\_\_|\__|

 HackTheBox / OSCP red-team loadout :: Pop!OS / Ubuntu / Debian
BANNER
}

# ---------- Modules definition ---------------------------------------------
# Order matters: base first.
ALL_MODULES=(
    "00-base"
    "10-recon"
    "20-active-directory"
    "30-password-attacks"
    "40-common-services"
    "50-pivoting"
    "60-web-app"
    "70-wireless"
    "80-post-exploit"
    "90-wordlists"
)

# ---------- CLI parsing ----------------------------------------------------
ACTION="install"
SELECTED_MODULES=()
DRY_RUN=0
NO_CONFIRM=0

usage() {
cat <<EOF
Usage: sudo ./install.sh [OPTIONS]

OPTIONS:
  --all                Install every module
  --module <name,...>  Install only the listed modules (comma-separated)
  --list               List available modules and exit
  --update             git-pull every cloned repo under \$HTB_TOOLS_DIR
  --dry-run            Show what would be installed; change nothing
  --no-confirm         Don't prompt; assume yes
  --uninstall          Remove env block from shell rc files and \$HTB_TOOLS_DIR
  -h, --help           Show this help

EXAMPLES:
  sudo ./install.sh                              # interactive menu
  sudo ./install.sh --all
  sudo ./install.sh --module active-directory,password-attacks
  sudo ./install.sh --update
  sudo ./install.sh --dry-run --all

Modules:
$(for m in "${ALL_MODULES[@]}"; do echo "  - ${m#*-}"; done)

Logs go to: ${HTB_LOG}
Tools land in: ${HTB_TOOLS_DIR}
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)         SELECTED_MODULES=("${ALL_MODULES[@]}"); shift ;;
        --module)      IFS=',' read -ra _mods <<< "$2"
                       for m in "${_mods[@]}"; do SELECTED_MODULES+=("$m"); done
                       shift 2 ;;
        --list)        for m in "${ALL_MODULES[@]}"; do echo "${m#*-}"; done; exit 0 ;;
        --update)      ACTION="update"; shift ;;
        --uninstall)   ACTION="uninstall"; shift ;;
        --dry-run)     DRY_RUN=1; shift ;;
        --no-confirm)  NO_CONFIRM=1; shift ;;
        -h|--help)     usage; exit 0 ;;
        *)             err "Unknown option: $1"; usage; exit 1 ;;
    esac
done

export DRY_RUN

# ---------- Pre-flight -----------------------------------------------------
preflight() {
    if [[ "${EUID}" -ne 0 ]]; then
        err "Run with sudo (root needed for apt, /opt writes, snap, etc.)"
        exit 1
    fi

    if ! command -v apt-get &>/dev/null; then
        err "apt-get not found. This fork targets Pop!OS / Ubuntu / Debian only."
        exit 1
    fi

    # We need to know the *real* user to install pipx things into their home,
    # set up their .bashrc, and chown /opt/htb-toolkit afterwards.
    REAL_USER="${SUDO_USER:-${USER}}"
    if [[ "${REAL_USER}" == "root" ]]; then
        warn "You're running as actual root (not via sudo). pipx installs and shell rc"
        warn "updates will target /root. That's probably not what you want on an HTB VM."
    fi
    REAL_HOME="$(getent passwd "${REAL_USER}" | cut -d: -f6)"
    export REAL_USER REAL_HOME

    mkdir -p "${HTB_TOOLS_DIR}"
    chown "${REAL_USER}:${REAL_USER}" "${HTB_TOOLS_DIR}"
    touch "${HTB_LOG}"
    chmod 644 "${HTB_LOG}"

    manifest_init

    log "User:           ${REAL_USER}  (home: ${REAL_HOME})"
    log "Tools dir:      ${HTB_TOOLS_DIR}"
    log "Log file:       ${HTB_LOG}"
    log "Dry run:        $([[ ${DRY_RUN} -eq 1 ]] && echo YES || echo no)"
}

# ---------- Interactive menu ----------------------------------------------
interactive_menu() {
    echo
    info "No --all or --module flag given. Choose what to install:"
    echo
    local i=1
    for m in "${ALL_MODULES[@]}"; do
        printf "  ${C_CYAN}%2d${C_RESET}) %s\n" "$i" "${m#*-}"
        ((i++))
    done
    printf "  ${C_CYAN}%2d${C_RESET}) %s\n" "$i" "ALL"
    echo
    read -rp "Enter numbers (space-separated), or just hit Enter for ALL: " choice
    if [[ -z "${choice// }" ]]; then
        SELECTED_MODULES=("${ALL_MODULES[@]}")
        return
    fi
    for n in ${choice}; do
        if [[ "$n" == "$i" ]]; then
            SELECTED_MODULES=("${ALL_MODULES[@]}")
            return
        fi
        local idx=$((n-1))
        if [[ ${idx} -ge 0 && ${idx} -lt ${#ALL_MODULES[@]} ]]; then
            SELECTED_MODULES+=("${ALL_MODULES[idx]}")
        else
            warn "Skipping invalid choice: $n"
        fi
    done
}

# ---------- Confirmation ---------------------------------------------------
confirm_or_die() {
    [[ ${NO_CONFIRM} -eq 1 ]] && return 0
    echo
    info "About to install ${#SELECTED_MODULES[@]} module(s):"
    for m in "${SELECTED_MODULES[@]}"; do echo "    - ${m#*-}"; done
    echo
    read -rp "Proceed? [y/N] " ans
    [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]] || { warn "Aborted by user."; exit 0; }
}

# ---------- Module runner --------------------------------------------------
run_module() {
    local short="$1"
    # accept both '20-active-directory' and 'active-directory'
    local file
    file=$(ls "${SCRIPT_DIR}/modules/" 2>/dev/null | grep -E "^[0-9]+-${short#*-}\.sh$" || true)
    if [[ -z "${file}" ]]; then
        # maybe they passed the full prefix already
        file=$(ls "${SCRIPT_DIR}/modules/" 2>/dev/null | grep -E "^${short}\.sh$" || true)
    fi
    if [[ -z "${file}" ]]; then
        err "Module not found: ${short}"
        return 1
    fi

    section "Module :: ${file%.sh}"
    log "--- BEGIN module ${file} ---"
    if [[ ${DRY_RUN} -eq 1 ]]; then
        info "(dry-run) would source ${SCRIPT_DIR}/modules/${file}"
    else
        # shellcheck disable=SC1090
        source "${SCRIPT_DIR}/modules/${file}" || warn "Module ${file} exited non-zero"
    fi
    log "--- END module ${file} ---"
}

# ---------- Update path ----------------------------------------------------
do_update() {
    section "Updating all git-cloned tools under ${HTB_TOOLS_DIR}"
    find "${HTB_TOOLS_DIR}" -maxdepth 2 -name .git -type d | while read -r gitdir; do
        local dir="${gitdir%/.git}"
        info "git pull :: ${dir}"
        sudo -u "${REAL_USER}" git -C "${dir}" pull --rebase --autostash || warn "  -> failed"
    done
    ok "Update finished."
}

# ---------- Uninstall path -------------------------------------------------
do_uninstall() {
    section "Delegating to remove.sh"
    if [[ -x "${SCRIPT_DIR}/remove.sh" ]]; then
        exec "${SCRIPT_DIR}/remove.sh" "$@"
    else
        err "remove.sh not found at ${SCRIPT_DIR}/remove.sh"
        err "Run remove.sh directly with sudo, or restore the repo and try again."
        exit 1
    fi
}

# ---------- env.sh wiring --------------------------------------------------
wire_shell_rc() {
    local env_src="${SCRIPT_DIR}/config/env.sh"
    local env_dst="${HTB_TOOLS_DIR}/env.sh"
    install -m 0644 -o "${REAL_USER}" -g "${REAL_USER}" "${env_src}" "${env_dst}"

    for rc in "${REAL_HOME}/.bashrc" "${REAL_HOME}/.zshrc"; do
        [[ -f "${rc}" ]] || continue
        if grep -q '# >>> htb-toolkit >>>' "${rc}"; then
            info "Env block already present in ${rc} (skipping)"
            continue
        fi
        info "Appending env block to ${rc}"
        {
            echo ''
            echo '# >>> htb-toolkit >>>'
            echo "[ -f \"${env_dst}\" ] && source \"${env_dst}\""
            echo '# <<< htb-toolkit <<<'
        } >> "${rc}"
        chown "${REAL_USER}:${REAL_USER}" "${rc}"
        manifest_add file "${rc}" "env-block"
    done
    ok "Shell rc files wired. Open a new shell or 'source ~/.bashrc' to pick it up."
}

# ==========================================================================
# MAIN
# ==========================================================================
banner
preflight

case "${ACTION}" in
    update)    do_update;    exit 0 ;;
    uninstall) do_uninstall; exit 0 ;;
esac

if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
    interactive_menu
fi

if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
    err "Nothing selected. Bye."
    exit 1
fi

confirm_or_die

for mod in "${SELECTED_MODULES[@]}"; do
    run_module "${mod}"
done

if [[ ${DRY_RUN} -eq 0 ]]; then
    section "Wiring shell environment"
    wire_shell_rc
fi

section "All done"
ok "Installed modules: ${SELECTED_MODULES[*]}"
ok "Log: ${HTB_LOG}"
ok "Run 'source ~/.bashrc' (or open a new terminal) to use the new PATH/aliases."
