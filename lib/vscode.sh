# shellcheck shell=bash
# The Epitech extension for VS Code (and VSCodium, Code - OSS): built from
# epitech.nvim's vscode/ directory and published as epitech.vsix on that
# repository's releases. install.sh and epitech-upgrade install it into
# every VS Code found, and update it when a newer release is out. Nothing
# happens on a machine without VS Code.

# The release that holds the extension (overridable for the tests).
EPITECH_VSCODE_API="${EPITECH_VSCODE_API:-https://api.github.com/repos/cempack/epitech.nvim/releases/latest}"
EPITECH_VSCODE_ID="cempack.epitech"

# The VS Code command-line tools installed, one per line.
vscode_clis() {
    local cli
    for cli in code codium code-oss code-insiders; do
        command -v "$cli" >/dev/null 2>&1 && printf '%s\n' "$cli"
    done
}

# The installed version of the extension in one VS Code, or nothing.
vscode_installed_version() {
    "$1" --list-extensions --show-versions 2>/dev/null \
        | sed -n "s/^${EPITECH_VSCODE_ID}@//Ip" | head -n 1
}

# "<version> <download url>" of the latest release, from GitHub's API.
vscode_latest_release() {
    local json version url
    json=$(curl -fsSL --max-time 30 "$EPITECH_VSCODE_API" 2>/dev/null) || return 1
    version=$(printf '%s' "$json" | sed -n 's/.*"tag_name": *"vscode-v\([^"]*\)".*/\1/p' | head -n 1)
    url=$(printf '%s' "$json" | sed -n 's/.*"browser_download_url": *"\([^"]*epitech\.vsix\)".*/\1/p' | head -n 1)
    [ -n "$version" ] && [ -n "$url" ] || return 1
    printf '%s %s' "$version" "$url"
}

# Installs or updates the extension in every VS Code found. With check_only,
# only reports. force reinstalls the latest one even when it's there.
install_vscode_extension() {
    local check_only="${1:-0}" force="${2:-0}"
    local clis release version url cli installed vsix tmp status=0
    clis=$(vscode_clis)
    if [ -z "$clis" ]; then
        info "no VS Code found (code, codium, code-oss): extension skipped"
        return 0
    fi
    if ! release=$(vscode_latest_release); then
        warn "could not find the latest Epitech extension release"
        return 1
    fi
    version="${release%% *}"
    url="${release#* }"
    tmp=$(mktemp -d)
    vsix="${tmp}/epitech.vsix"
    while IFS= read -r cli; do
        installed=$(vscode_installed_version "$cli")
        if [ "$installed" = "$version" ] && [ "$force" -eq 0 ]; then
            ok "${cli}: Epitech extension up to date (${version})"
            continue
        fi
        if [ "$check_only" -eq 1 ]; then
            info "${cli}: Epitech extension ${installed:-not installed} → ${version} available"
            continue
        fi
        if [ ! -s "$vsix" ] && ! curl -fsSL --max-time 120 -o "$vsix" "$url"; then
            warn "could not download the Epitech extension"
            status=1
            break
        fi
        if "$cli" --install-extension "$vsix" --force >/dev/null 2>&1; then
            ok "${cli}: Epitech extension ${installed:+${installed} → }${version}"
        else
            warn "${cli}: could not install the Epitech extension (try: ${cli} --install-extension ${url})"
            status=1
        fi
    done <<< "$clis"
    rm -rf "$tmp"
    return "$status"
}
