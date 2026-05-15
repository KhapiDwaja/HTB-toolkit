#!/usr/bin/env bash
# lib/helpers.sh — install primitives used by every module
# Requires: logger.sh, DRY_RUN, REAL_USER, REAL_HOME, HTB_TOOLS_DIR

# ---------- Manifest ---------------------------------------------------------
# Every successful install appends one line to the manifest so remove.sh
# knows exactly what we put on disk (and nothing more).
# Format: <kind>\t<identifier>\t<extra>
#   kind = apt | pipx | git | go | binary | symlink | file
HTB_MANIFEST="${HTB_TOOLS_DIR}/.manifest"

manifest_init() {
    [[ ${DRY_RUN:-0} -eq 1 ]] && return 0
    mkdir -p "${HTB_TOOLS_DIR}"
    touch "${HTB_MANIFEST}"
    chown "${REAL_USER}:${REAL_USER}" "${HTB_MANIFEST}" 2>/dev/null || true
}

manifest_add() {
    # manifest_add <kind> <id> [extra]
    [[ ${DRY_RUN:-0} -eq 1 ]] && return 0
    local kind="$1" id="$2" extra="${3:-}"
    printf '%s\t%s\t%s\n' "${kind}" "${id}" "${extra}" >> "${HTB_MANIFEST}"
}

# ---------- Generic shell-out -------------------------------------------------
_run() {
    # _run "<description>" <cmd> [args...]
    local desc="$1"; shift
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        info "(dry-run) ${desc}: $*"
        return 0
    fi
    log "[exec] $*"
    if "$@" >>"${HTB_LOG}" 2>&1; then
        ok "${desc}"
        return 0
    else
        warn "${desc} (failed — see ${HTB_LOG})"
        return 1
    fi
}

# Run as the real (non-root) user. Useful for pipx, cargo, etc.
_run_as_user() {
    local desc="$1"; shift
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        info "(dry-run, as ${REAL_USER}) ${desc}: $*"
        return 0
    fi
    log "[exec as ${REAL_USER}] $*"
    if sudo -u "${REAL_USER}" -H bash -lc "$*" >>"${HTB_LOG}" 2>&1; then
        ok "${desc}"
        return 0
    else
        warn "${desc} (failed — see ${HTB_LOG})"
        return 1
    fi
}

# ---------- APT --------------------------------------------------------------
APT_UPDATED=0
apt_update_once() {
    [[ ${APT_UPDATED} -eq 1 ]] && return 0
    _run "apt update" apt-get update -y
    APT_UPDATED=1
}

apt_install() {
    # apt_install pkg1 pkg2 ...
    apt_update_once
    local pkgs=("$@")
    local missing=()
    for p in "${pkgs[@]}"; do
        if dpkg -s "$p" &>/dev/null; then
            log "apt: ${p} already pre-installed (not adding to manifest)"
        else
            missing+=("$p")
        fi
    done
    [[ ${#missing[@]} -eq 0 ]] && return 0
    if _run "apt install ${missing[*]}" apt-get install -y --no-install-recommends "${missing[@]}"; then
        for p in "${missing[@]}"; do manifest_add apt "${p}"; done
    fi
}

# ---------- pipx -------------------------------------------------------------
ensure_pipx() {
    if sudo -u "${REAL_USER}" -H bash -lc 'command -v pipx' &>/dev/null; then return 0; fi
    apt_install pipx
    _run_as_user "pipx ensurepath" "pipx ensurepath"
}

pipx_install() {
    # pipx_install <pkg-spec> [--include-deps] [--pip-args "..."]
    ensure_pipx
    local spec="$1"; shift
    # Extract the package name for uninstall (strip git+, version specifiers, etc.)
    local name="${spec##*/}"
    name="${name%.git}"
    name="${name%%[<>=!]*}"
    if _run_as_user "pipx install ${spec}" "pipx install --force ${spec} $*"; then
        manifest_add pipx "${name}" "${spec}"
    fi
}

# ---------- git clone into $HTB_TOOLS_DIR -----------------------------------
git_clone() {
    # git_clone <url> [destname]
    local url="$1"
    local name="${2:-$(basename "${url%.git}")}"
    local dest="${HTB_TOOLS_DIR}/${name}"
    if [[ -d "${dest}/.git" ]]; then
        info "git: ${name} already present, pulling latest"
        _run_as_user "git pull ${name}" "git -C '${dest}' pull --rebase --autostash"
    else
        if _run_as_user "git clone ${url} -> ${dest}" \
            "git clone --depth=1 '${url}' '${dest}'"; then
            manifest_add git "${dest}" "${url}"
        fi
    fi
}

# ---------- Go install -------------------------------------------------------
ensure_go() {
    if command -v go &>/dev/null; then return 0; fi
    apt_install golang-go
}

go_install() {
    # go_install <go-package@version>
    ensure_go
    local pkg="$1"
    # The binary name is the last path component, before the @
    local base="${pkg%@*}"
    local binname="${base##*/}"
    # Handle paths like .../cmd/foo
    if [[ "${binname}" == "cmd" ]]; then
        local rest="${base%/cmd}"
        binname="${rest##*/}"
    fi
    if _run_as_user "go install ${pkg}" \
        "GOPATH=${REAL_HOME}/go GOBIN=${REAL_HOME}/go/bin go install '${pkg}'"; then
        manifest_add go "${REAL_HOME}/go/bin/${binname}" "${pkg}"
    fi
}

# ---------- Symlink a tool into a PATH dir -----------------------------------
link_into_bin() {
    # link_into_bin <source-path> <link-name>
    local src="$1" name="$2"
    local bindir="${HTB_TOOLS_DIR}/bin"
    mkdir -p "${bindir}"
    chown "${REAL_USER}:${REAL_USER}" "${bindir}"
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        info "(dry-run) ln -sf ${src} ${bindir}/${name}"
        return 0
    fi
    ln -sf "${src}" "${bindir}/${name}"
    chmod +x "${src}" 2>/dev/null || true
    manifest_add symlink "${bindir}/${name}" "${src}"
    ok "linked ${name} -> ${src}"
}

# ---------- snap (optional, only when needed) -------------------------------
snap_install() {
    if ! command -v snap &>/dev/null; then
        warn "snap not available; skipping $*"
        return 0
    fi
    _run "snap install $*" snap install "$@"
}
