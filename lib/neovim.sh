#!/usr/bin/env bash

is_empty_dir() {
    [ -d "$1" ] && [ -z "$(find "$1" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]
}

is_lazyvim_config() {
    local config_dir="$1"
    [ -f "${config_dir}/init.lua" ] \
        && [ -f "${config_dir}/lua/config/lazy.lua" ] \
        && grep -Fq 'LazyVim/LazyVim' "${config_dir}/lua/config/lazy.lua"
}

ensure_make_formatter() {
    if command -v mbake >/dev/null 2>&1; then
        return 0
    fi
    if ! command -v uv >/dev/null 2>&1; then
        warn "uv is required to install the Makefile formatter mbake"
        return 1
    fi
    if ! uv tool install 'mbake==1.4.6' >/dev/null 2>&1 \
        || ! command -v mbake >/dev/null 2>&1; then
        warn "could not install the Makefile formatter mbake"
        return 1
    fi
    ok "Makefile formatter mbake installed"
}

upgrade_managed_nvim() {
    local repo_dir="$1" check_only="${2:-0}" force="${3:-0}"
    local config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
    local config_dir="${config_home}/nvim"
    local plugin_dir="${data_home}/nvim/epitech-upgrade/nvim/epitech.nvim"
    local spec_file="${config_dir}/lua/plugins/epitech-dump-arch.lua"
    local plugin_source="${repo_dir}/nvim/epitech.nvim"
    local spec_source="${repo_dir}/nvim/lazyvim-spec.lua"

    if ! is_lazyvim_config "$config_dir" \
        || [ ! -f "${plugin_dir}/.epitech-dump-arch" ] \
        || [ ! -f "$spec_file" ] \
        || ! grep -q '^-- Managed by epitech-dump-arch' "$spec_file"; then
        info "managed integration not installed; leaving Neovim unchanged"
        return 0
    fi
    if [ "$check_only" -eq 0 ]; then
        ensure_make_formatter || return 1
    elif ! command -v mbake >/dev/null 2>&1; then
        info "Makefile formatter mbake is not installed"
    fi
    if [ ! -f "${plugin_source}/.epitech-dump-arch" ] \
        || [ ! -f "${plugin_source}/epitech.clang-format" ] \
        || [ ! -f "${plugin_source}/after/ftplugin/c.lua" ] \
        || [ ! -f "${plugin_source}/lua/epitech/init.lua" ] \
        || [ ! -f "$spec_source" ]; then
        warn "bundled Neovim integration is incomplete"
        return 1
    fi
    if ! command -v clang-format >/dev/null 2>&1 \
        || ! clang-format --dump-config \
            --style="file:${plugin_source}/epitech.clang-format" >/dev/null 2>&1; then
        warn "clang-format cannot load the Epitech profile (version 21 or newer required)"
        return 1
    fi

    if cmp -s "${plugin_source}/.epitech-dump-arch" "${plugin_dir}/.epitech-dump-arch" \
        && cmp -s "${plugin_source}/epitech.clang-format" "${plugin_dir}/epitech.clang-format" \
        && cmp -s "${plugin_source}/after/ftplugin/c.lua" "${plugin_dir}/after/ftplugin/c.lua" \
        && cmp -s "${plugin_source}/lua/epitech/init.lua" "${plugin_dir}/lua/epitech/init.lua" \
        && cmp -s "$spec_source" "$spec_file" \
        && [ "$force" -eq 0 ]; then
        ok "up to date"
        return 0
    fi
    if [ "$check_only" -eq 1 ]; then
        info "update available for the managed Epitech plugin"
        return 0
    fi

    if ! cp "${plugin_source}/.epitech-dump-arch" "${plugin_dir}/.epitech-dump-arch" \
        || ! cp "${plugin_source}/epitech.clang-format" "${plugin_dir}/epitech.clang-format" \
        || ! cp "${plugin_source}/after/ftplugin/c.lua" "${plugin_dir}/after/ftplugin/c.lua" \
        || ! cp "${plugin_source}/lua/epitech/init.lua" "${plugin_dir}/lua/epitech/init.lua" \
        || ! cp "$spec_source" "$spec_file"; then
        warn "could not update the managed Epitech plugin"
        return 1
    fi
    ok "managed Epitech plugin updated (LazyVim unchanged)"
}

install_lazyvim() {
    local config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
    local config_dir="${config_home}/nvim"
    local plugin_dir="${data_home}/nvim/epitech-upgrade/nvim/epitech.nvim"
    local spec_file="${config_dir}/lua/plugins/epitech-dump-arch.lua"
    local plugin_source="${REPO_DIR}/nvim/epitech.nvim"
    local spec_source="${REPO_DIR}/nvim/lazyvim-spec.lua"
    local starter_url="${LAZYVIM_STARTER_URL:-https://github.com/LazyVim/starter.git}"
    local tmp

    log "Neovim/LazyVim:"
    [ -f "${plugin_source}/.epitech-dump-arch" ] \
        || { warn "bundled epitech.nvim plugin is missing"; return; }
    [ -f "${plugin_source}/epitech.clang-format" ] \
        || { warn "bundled Epitech clang-format profile is missing"; return; }
    if ! command -v clang-format >/dev/null 2>&1 \
        || ! clang-format --dump-config \
            --style="file:${plugin_source}/epitech.clang-format" >/dev/null 2>&1; then
        warn "clang-format cannot load the Epitech profile (version 21 or newer required)"
        return
    fi
    [ -f "$spec_source" ] \
        || { warn "bundled LazyVim plugin spec is missing"; return; }
    if [ -e "$plugin_dir" ] && [ ! -f "${plugin_dir}/.epitech-dump-arch" ]; then
        warn "${plugin_dir} exists and is not managed by this installer"
        warn "Neovim Epitech integration skipped"
        return
    fi

    if [ ! -e "$config_dir" ] || is_empty_dir "$config_dir"; then
        info "installing the official LazyVim starter..."
        tmp=$(mktemp -d)
        mkdir -p "${tmp}/export"
        if ! git clone -q --depth 1 "$starter_url" "${tmp}/starter" \
            || ! git -C "${tmp}/starter" archive -o "${tmp}/starter.tar" HEAD \
            || ! tar -xf "${tmp}/starter.tar" -C "${tmp}/export"; then
            rm -rf "$tmp"
            warn "LazyVim starter download failed (Neovim integration skipped)"
            return
        fi
        mkdir -p "$config_dir"
        if ! cp -a "${tmp}/export/." "$config_dir/"; then
            rm -rf "$tmp"
            warn "LazyVim starter installation failed (Neovim integration skipped)"
            return
        fi
        rm -rf "$tmp"
        ok "LazyVim starter installed"
    elif ! is_lazyvim_config "$config_dir"; then
        warn "${config_dir} is not a LazyVim config; leaving it unchanged"
        warn "Neovim Epitech integration skipped"
        return
    else
        ok "existing LazyVim config detected"
    fi

    ensure_make_formatter || { warn "Neovim Epitech integration skipped"; return; }

    if [ -e "$spec_file" ] && ! grep -q '^-- Managed by epitech-dump-arch' "$spec_file"; then
        warn "${spec_file} exists and is not managed by this installer"
        warn "Neovim Epitech integration skipped"
        return
    fi

    if ! mkdir -p "${plugin_dir}/after/ftplugin" "${plugin_dir}/lua/epitech" \
        "$(dirname "$spec_file")" \
        || ! cp "${plugin_source}/.epitech-dump-arch" "${plugin_dir}/" \
        || ! cp "${plugin_source}/epitech.clang-format" "${plugin_dir}/epitech.clang-format" \
        || ! cp "${plugin_source}/after/ftplugin/c.lua" "${plugin_dir}/after/ftplugin/c.lua" \
        || ! cp "${plugin_source}/lua/epitech/init.lua" "${plugin_dir}/lua/epitech/init.lua" \
        || ! cp "$spec_source" "$spec_file"; then
        warn "could not install the Epitech LazyVim plugin"
        return
    fi
    ok "Epitech LazyVim plugin installed"

    if timeout 180 nvim --headless \
        "+lua vim.wait(3000)" \
        "+lua local ok, conform = pcall(require, 'conform'); vim.bo.filetype = 'c'; local found = false; if ok then for _, formatter in ipairs(conform.list_formatters(0)) do found = found or formatter.name == 'epitech_vim' end end; if not found or vim.api.nvim_get_commands({ builtin = false }).EpitechHeader == nil then vim.cmd('cquit 1') end" \
        +qa >/dev/null 2>&1; then
        ok "Neovim configuration verified"
    else
        warn "Neovim files are installed, but headless verification failed"
        warn "start nvim once, then run :LazyHealth"
    fi
}
