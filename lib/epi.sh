# shellcheck shell=bash
# epi, the CLI that keeps an Epitech folder organized (cempack/epi): one
# binary per architecture on that repository's releases, epi-linux-<arch>,
# with a SHA256SUMS file. install.sh and epitech-upgrade put it in
# ~/.local/bin and update it when a newer release is out. The first install
# also hooks it into bash and zsh so that plain `epi` can move the shell
# into a project; a hook you remove stays removed.

# The release that holds the binaries (overridable for the tests).
EPITECH_EPI_API="${EPITECH_EPI_API:-https://api.github.com/repos/cempack/epi/releases/latest}"

epi_bin() { printf '%s/bin/epi' "${PREFIX:-${HOME}/.local}"; }

# The release asset name for this machine, or nothing on an unsupported one.
epi_asset() {
    case "$(uname -m)" in
        x86_64|amd64) printf 'epi-linux-amd64' ;;
        aarch64|arm64) printf 'epi-linux-arm64' ;;
        *) return 1 ;;
    esac
}

# The installed version ("1.0.0"), or nothing.
epi_installed_version() {
    local bin
    bin=$(epi_bin)
    [ -x "$bin" ] || return 0
    "$bin" version 2>/dev/null | sed -n 's/^epi //p' | head -n 1
}

# "<version> <binary url> <SHA256SUMS url>" of the latest release.
epi_latest_release() {
    local asset="$1" json version url sums
    json=$(curl -fsSL --max-time 30 "$EPITECH_EPI_API" 2>/dev/null) || return 1
    version=$(printf '%s' "$json" | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -n 1)
    url=$(printf '%s' "$json" | sed -n "s/.*\"browser_download_url\": *\"\([^\"]*\/${asset}\)\".*/\1/p" | head -n 1)
    sums=$(printf '%s' "$json" | sed -n 's/.*"browser_download_url": *"\([^"]*\/SHA256SUMS\)".*/\1/p' | head -n 1)
    [ -n "$version" ] && [ -n "$url" ] && [ -n "$sums" ] || return 1
    printf '%s %s %s' "$version" "$url" "$sums"
}

# Adds the shell function that lets `epi` cd, once, to each shell's rc file.
epi_shell_hook() {
    local rc line='command -v epi >/dev/null && eval "$(command epi shell)"'
    for rc in "${HOME}/.bashrc" "${ZDOTDIR:-${HOME}}/.zshrc"; do
        [ -f "$rc" ] || continue
        grep -q 'epi shell' "$rc" && continue
        printf '\n# epi (epitech-toolkit): plain `epi` goes into the project you pick.\n%s\n' "$line" >> "$rc" \
            && ok "epi hooked into $(basename "$rc") (open a new terminal)"
    done
}

# Installs or updates epi. With check_only, only reports. force reinstalls the
# latest release even when it's there.
install_epi() {
    local check_only="${1:-0}" force="${2:-0}"
    local asset release version url sums installed bin tmp want got
    if ! asset=$(epi_asset); then
        info "epi has no build for $(uname -m): skipped"
        return 0
    fi
    if ! release=$(epi_latest_release "$asset"); then
        warn "could not find the latest epi release"
        return 1
    fi
    read -r version url sums <<< "$release"
    installed=$(epi_installed_version)
    if [ "$installed" = "$version" ] && [ "$force" -eq 0 ]; then
        ok "epi up to date (${version})"
        return 0
    fi
    if [ "$check_only" -eq 1 ]; then
        info "epi ${installed:-not installed} → ${version} available"
        return 0
    fi
    bin=$(epi_bin)
    mkdir -p "$(dirname "$bin")"
    # Download next to the destination, check it, then rename over: a broken
    # download never replaces a working epi.
    tmp=$(mktemp "${bin}.XXXXXX") || return 1
    if ! curl -fsSL --max-time 120 -o "$tmp" "$url"; then
        rm -f "$tmp"
        warn "could not download epi"
        return 1
    fi
    want=$(curl -fsSL --max-time 30 "$sums" 2>/dev/null | awk -v a="$asset" '$2 == a || $2 == "*"a {print $1}')
    got=$(sha256sum "$tmp" | awk '{print $1}')
    if [ -z "$want" ] || [ "$want" != "$got" ]; then
        rm -f "$tmp"
        warn "epi download doesn't match the release checksum: not installed"
        return 1
    fi
    chmod 755 "$tmp"
    if ! "$tmp" version >/dev/null 2>&1; then
        rm -f "$tmp"
        warn "the downloaded epi doesn't run: not installed"
        return 1
    fi
    mv -f "$tmp" "$bin" || { rm -f "$tmp"; warn "could not install epi"; return 1; }
    ok "epi ${installed:+${installed} → }${version}"
    [ -n "$installed" ] || epi_shell_hook
}
