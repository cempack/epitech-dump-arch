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

    if [ -e "$spec_file" ] && ! grep -q '^-- Managed by epitech-dump-arch' "$spec_file"; then
        warn "${spec_file} exists and is not managed by this installer"
        warn "Neovim Epitech integration skipped"
        return
    fi

    if ! mkdir -p "${plugin_dir}/after/ftplugin" "${plugin_dir}/lua/epitech" \
        "$(dirname "$spec_file")" \
        || ! cp "${plugin_source}/.epitech-dump-arch" "${plugin_dir}/" \
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
