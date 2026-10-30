# shellcheck shell=bash
# Keeps this project's commands current: epitech-upgrade itself and the
# epitech-* commands in bin/, from a checkout of the project.
#
# epitech-upgrade calls upgrade_dump_tools. Versions of epitech-upgrade that
# predate it never update themselves, but they do source lib/neovim.sh from a
# fresh checkout, which calls this when the running epitech-upgrade has no
# do_tools: an old install catches up on its next weekly run.

# The pacman packages install.sh installs, read from its pacman line so the
# list lives in one place.
dump_packages() {
    local install_sh="${1}/install.sh"
    [ -f "$install_sh" ] || return 1
    sed -n '/pacman -S --needed --noconfirm/,/|| die/p' "$install_sh" \
        | sed 's/sudo pacman -S --needed --noconfirm//; s/|| die.*//; s/\\//g' \
        | tr -s ' \t' '\n' | sed '/^$/d'
}

# The ones not installed, space-separated.
missing_packages() {
    local package missing=""
    command -v pacman >/dev/null 2>&1 || return 0
    while IFS= read -r package; do
        pacman -Q "$package" >/dev/null 2>&1 || missing="${missing}${package} "
    done < <(dump_packages "$1")
    printf '%s' "${missing% }"
}

# Copies src over dst through a temporary file and a rename: a running
# epitech-upgrade keeps reading its old file instead of a half-written one.
replace_command() {
    local src="$1" dst="$2" tmp
    tmp=$(mktemp "${dst}.XXXXXX") || return 1
    cp "$src" "$tmp" && chmod 755 "$tmp" && mv -f "$tmp" "$dst" || { rm -f "$tmp"; return 1; }
}

upgrade_dump_tools() {
    local repo_dir="$1" check_only="${2:-0}" force="${3:-0}"
    local bin_dir="${PREFIX:-${HOME}/.local}/bin" tool name changed=0 missing
    mkdir -p "$bin_dir"
    for tool in "${repo_dir}/epitech-upgrade" "${repo_dir}"/bin/epitech-*; do
        [ -f "$tool" ] || continue
        name=$(basename "$tool")
        if [ "$force" -eq 0 ] && cmp -s "$tool" "${bin_dir}/${name}"; then
            continue
        fi
        changed=1
        if [ "$check_only" -eq 1 ]; then
            info "update available for ${name}"
        elif replace_command "$tool" "${bin_dir}/${name}"; then
            ok "${name} updated"
        else
            warn "could not install ${name}"
            return 1
        fi
    done
    [ "$changed" -eq 0 ] && ok "epitech-* commands up to date"
    missing=$(missing_packages "$repo_dir")
    if [ -n "$missing" ]; then
        info "packages the installer now adds are missing: sudo pacman -S --needed ${missing}"
    fi
    return 0
}
