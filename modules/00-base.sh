#!/usr/bin/env bash
# modules/00-base.sh — system & language toolchains everything else needs
# This module MUST run before any other.

info "Installing base build/runtime deps"

apt_install \
    build-essential pkg-config make cmake autoconf automake libtool \
    git curl wget unzip jq xclip ripgrep fd-find tree \
    python3 python3-pip python3-venv python3-dev pipx \
    golang-go \
    libssl-dev libffi-dev libpcap-dev libldap2-dev libsasl2-dev \
    libkrb5-dev krb5-user \
    libreadline-dev libsqlite3-dev libbz2-dev liblzma-dev \
    net-tools dnsutils whois iputils-ping traceroute \
    openvpn openssh-client tmux htop

ensure_pipx
ensure_go

# Cargo / rust (optional but several tools want it)
if ! command -v cargo &>/dev/null; then
    info "Installing rustup (for tools that need cargo)"
    _run_as_user "install rustup" \
        "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal"
fi

ok "Base toolchain ready."
