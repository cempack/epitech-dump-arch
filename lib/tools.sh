# shellcheck shell=bash
# Keeps this project's commands current: epitech-upgrade itself and the
# epitech-* commands in bin/, from a checkout of the project.
#
# epitech-upgrade calls upgrade_dump_tools. Versions of epitech-upgrade that
# predate it never update themselves, but they do source lib/neovim.sh from a
# fresh checkout, which calls this when the running epitech-upgrade has no
# do_tools: an old install catches up on its next weekly run.

# The packages install.sh adds that aren't installed, space-separated. The
# lists live in lib/system.sh, next to this file in the checkout.
missing_packages() {
    local package missing=""
    [ -f "${1}/lib/system.sh" ] || return 0
    # shellcheck source=lib/system.sh
    . "${1}/lib/system.sh" || return 0
    case "$(dump_os)" in arch | ubuntu) ;; *) return 0 ;; esac
    while IFS= read -r package; do
        package_installed "$package" || missing="${missing}${package} "
    done < <(dump_packages)
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
    # shellcheck source=lib/system.sh
    [ -f "${repo_dir}/lib/system.sh" ] && . "${repo_dir}/lib/system.sh"
    missing=$(missing_packages "$repo_dir")
    if [ -n "$missing" ]; then
        info "packages the installer now adds are missing: $(install_hint "$missing")"
    fi
    return 0
}
