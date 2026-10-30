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

# The epitech.nvim plugin lives in its own repository and lazy.nvim installs it
# from there; this project only manages the LazyVim spec that points to it.
EPITECH_NVIM_LAZY_NAME="epitech.nvim"

clang_format_supported() {
    local version
    command -v clang-format >/dev/null 2>&1 || return 1
    version=$(clang-format --version | sed -n 's/.*version \([0-9][0-9]*\).*/\1/p' | head -n 1)
    [ -n "$version" ] && [ "$version" -ge 21 ]
}

# Before epitech.nvim had its own repository, the installer copied it here.
remove_legacy_plugin() {
    local data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
    local legacy_dir="${data_home}/nvim/epitech-upgrade/nvim/epitech.nvim"
    if [ -f "${legacy_dir}/.epitech-dump-arch" ]; then
        rm -rf "$legacy_dir"
        rmdir "${data_home}/nvim/epitech-upgrade/nvim" "${data_home}/nvim/epitech-upgrade" 2>/dev/null || true
        info "removed the old bundled copy of epitech.nvim"
    fi
}

upgrade_managed_nvim() {
    local repo_dir="$1" check_only="${2:-0}" force="${3:-0}"
    local config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
    local config_dir="${config_home}/nvim"
    local plugin_dir="${data_home}/nvim/lazy/${EPITECH_NVIM_LAZY_NAME}"
    local spec_file="${config_dir}/lua/plugins/epitech-dump-arch.lua"
    local spec_source="${repo_dir}/nvim/lazyvim-spec.lua"
    local local_head remote_head

    # An epitech-upgrade from before lib/tools.sh never updates itself or the
    # epitech-* commands, but it runs this: do it for it.
    if ! declare -F do_tools >/dev/null && [ -f "${repo_dir}/lib/tools.sh" ]; then
        # shellcheck source=lib/tools.sh
        if . "${repo_dir}/lib/tools.sh"; then
            log "epitech-* commands:"
            upgrade_dump_tools "$repo_dir" "$check_only" "$force" || warn "could not update the epitech-* commands"
        fi
    fi

    if ! is_lazyvim_config "$config_dir" \
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
    if [ ! -f "$spec_source" ]; then
        warn "bundled LazyVim plugin spec is missing"
        return 1
    fi
    if ! clang_format_supported; then
        warn "clang-format 21 or newer is required for the Epitech formatter"
        return 1
    fi

    if [ "$check_only" -eq 1 ]; then
        if ! cmp -s "$spec_source" "$spec_file"; then
            info "update available for the managed LazyVim spec"
        fi
        if [ ! -d "${plugin_dir}/.git" ]; then
            info "epitech.nvim is not installed yet; lazy.nvim installs it when nvim starts"
            return 0
        fi
        local_head=$(git -C "$plugin_dir" rev-parse HEAD 2>/dev/null) || local_head=""
        remote_head=$(git -C "$plugin_dir" ls-remote origin HEAD 2>/dev/null | cut -f1) || remote_head=""
        if [ -z "$remote_head" ]; then
            warn "could not reach the epitech.nvim repository"
        elif [ "$local_head" != "$remote_head" ]; then
            info "update available for epitech.nvim"
        else
            ok "epitech.nvim up to date"
        fi
        return 0
    fi

    if [ "$force" -eq 1 ] || ! cmp -s "$spec_source" "$spec_file"; then
        if ! cp "$spec_source" "$spec_file"; then
            warn "could not update the managed LazyVim spec"
            return 1
        fi
        ok "managed LazyVim spec updated"
    fi
    if ! timeout 300 nvim --headless "+Lazy! update ${EPITECH_NVIM_LAZY_NAME}" +qa >/dev/null 2>&1; then
        warn "could not update epitech.nvim through lazy.nvim"
        return 1
    fi
    ok "epitech.nvim updated through lazy.nvim (other plugins unchanged)"
}

install_lazyvim() {
    local config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local config_dir="${config_home}/nvim"
    local spec_file="${config_dir}/lua/plugins/epitech-dump-arch.lua"
    local spec_source="${REPO_DIR}/nvim/lazyvim-spec.lua"
    local starter_url="${LAZYVIM_STARTER_URL:-https://github.com/LazyVim/starter.git}"
    local tmp

    log "Neovim/LazyVim:"
    if ! clang_format_supported; then
        warn "clang-format 21 or newer is required for the Epitech formatter"
        return
    fi
    [ -f "$spec_source" ] \
        || { warn "bundled LazyVim plugin spec is missing"; return; }

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

    if ! mkdir -p "$(dirname "$spec_file")" || ! cp "$spec_source" "$spec_file"; then
        warn "could not install the Epitech LazyVim plugin spec"
        return
    fi
    remove_legacy_plugin
    ok "Epitech LazyVim plugin spec installed (epitech.nvim comes from GitHub)"

    if timeout 300 nvim --headless "+Lazy! install" +qa >/dev/null 2>&1 \
        && timeout 180 nvim --headless \
        "+lua vim.wait(3000)" \
        "+lua local ok, conform = pcall(require, 'conform'); vim.bo.filetype = 'c'; local found = false; if ok then for _, formatter in ipairs(conform.list_formatters(0)) do found = found or formatter.name == 'epitech_vim' end end; if not found or vim.api.nvim_get_commands({ builtin = false }).EpitechHeader == nil then vim.cmd('cquit 1') end" \
        +qa >/dev/null 2>&1; then
        ok "Neovim configuration verified"
    else
        warn "Neovim files are installed, but headless verification failed"
        warn "start nvim once, then run :LazyHealth"
    fi
}
