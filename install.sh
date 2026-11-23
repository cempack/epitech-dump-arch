#!/usr/bin/env bash
# epitech-dump-arch — unofficial Epitech "dump" installer for Arch Linux
# (Omarchy, EndeavourOS…) and Ubuntu (24.04, 26.04 and derivatives).
#
# System packages (pacman and the AUR on Arch; apt and Epitech's own PPA on
# Ubuntu), epiclang + banana coding-style checker, Epitech editor configs,
# Neovim with LazyVim and epitech.nvim, the VS Code extension, launchers,
# and a weekly systemd timer that keeps the Epitech bits up to date.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/cempack/epitech-dump-arch/main/install.sh)
#   ./install.sh [--no-sys]
#
#   --no-sys   skip the package manager and sudo (user-space only). Use when
#              you manage system packages yourself, or for testing.

set -u

REPO_URL="https://github.com/cempack/epitech-dump-arch"
LOCAL_REPO_DIR="${HOME}/.local/share/epitech-dump-arch"
NO_SYS=0

log()  { printf '%s\n' "$*"; }
ok()   { printf '  [ok] %s\n' "$*"; }
info() { printf '  [..] %s\n' "$*"; }
warn() { printf '  [!!] %s\n' "$*"; }
die()  { printf '  [FAIL] %s\n' "$*"; exit 1; }

for arg in "$@"; do
    case "$arg" in
        --no-sys) NO_SYS=1 ;;
        -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# //; s/^#//'; exit 0 ;;
        *) die "unknown option: $arg" ;;
    esac
done

[ "$EUID" -eq 0 ] && die "do not run as root — run as your user (sudo is used where needed)"

# Tools installed under ~/.local (Neovim, clang-format, uv…) must be found
# by the rest of the installer.
mkdir -p "${HOME}/.local/bin"
case ":${PATH}:" in *":${HOME}/.local/bin:"*) ;; *) export PATH="${HOME}/.local/bin:${PATH}" ;; esac

if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    ok "OS: $(. /etc/os-release; printf '%s' "${PRETTY_NAME:-unknown}")"
fi

if [ "$NO_SYS" -eq 0 ]; then
    command -v sudo >/dev/null 2>&1 || die "sudo is required (or re-run with --no-sys)"
    sudo -v || die "sudo authentication failed"
    # git, to fetch the rest of the installer.
    if ! command -v git >/dev/null 2>&1; then
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm git >/dev/null || die "could not install git"
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update -qq >/dev/null && sudo apt-get install -y -qq git curl >/dev/null \
                || die "could not install git"
        else
            die "install git first"
        fi
    fi
fi
command -v git >/dev/null 2>&1 || die "missing required command: git"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ -f "${SCRIPT_DIR}/epitech-upgrade" ]; then
    REPO_DIR="$SCRIPT_DIR"
else
    log "fetching installer repo..."
    if [ -d "${LOCAL_REPO_DIR}/.git" ]; then
        git -C "$LOCAL_REPO_DIR" pull -q --ff-only \
            || die "could not update ${LOCAL_REPO_DIR}; inspect the checkout and retry"
    elif [ -e "$LOCAL_REPO_DIR" ] && ! [ -d "$LOCAL_REPO_DIR" ]; then
        die "${LOCAL_REPO_DIR} exists and is not a directory"
    elif [ -d "$LOCAL_REPO_DIR" ] && [ -n "$(find "$LOCAL_REPO_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
        die "${LOCAL_REPO_DIR} contains unrelated files; leaving it unchanged"
    else
        git clone -q --depth 1 "$REPO_URL" "$LOCAL_REPO_DIR" || die "repo clone failed"
    fi
    REPO_DIR="$LOCAL_REPO_DIR"
fi

# shellcheck source=lib/system.sh
. "${REPO_DIR}/lib/system.sh" || die "could not load the system installer"
case "$(dump_os)" in
    arch | ubuntu) ;;
    *) warn "neither Arch nor Ubuntu: the package step won't run, install the packages yourself (see the README)" ;;
esac

if [ "$NO_SYS" -eq 0 ]; then
    install_system_packages || die "the system packages aren't installed (see above)"
else
    info "skipping system packages (--no-sys)"
fi

log "user-space tools:"
ensure_user_tools || die "a required tool is missing (see above)"

for cmd in curl git python3 bsdtar emacs vim nvim clang-format tar uv; do
    command -v "$cmd" >/dev/null 2>&1 || die "missing required command: $cmd (run without --no-sys to install it)"
done

# shellcheck source=lib/neovim.sh
. "${REPO_DIR}/lib/neovim.sh" || die "could not load the Neovim installer"
# shellcheck source=lib/vscode.sh
. "${REPO_DIR}/lib/vscode.sh" || die "could not load the VS Code installer"

log "Epitech tooling:"
mkdir -p "${HOME}/.local/bin"
cp "${REPO_DIR}/epitech-upgrade" "${HOME}/.local/bin/epitech-upgrade"
chmod +x "${HOME}/.local/bin/epitech-upgrade"
for tool in "${REPO_DIR}"/bin/epitech-*; do
    install -m 755 "$tool" "${HOME}/.local/bin/$(basename "$tool")" || die "could not install $(basename "$tool")"
done
ok "epitech-doctor, epitech-predeliver and epitech-mem installed"
"${HOME}/.local/bin/epitech-upgrade" --force || die "epitech-upgrade failed"

cat > "${HOME}/.local/bin/epitech-emacs" <<'EOF'
#!/usr/bin/env bash
# Epitech emacs launcher: start emacs with the Epitech configuration loaded.
exec emacs -L "$HOME/.emacs.d/lisp" -l site-start.d/epitech-init.el "$@"
EOF
chmod +x "${HOME}/.local/bin/epitech-emacs"
ok "epitech-emacs launcher installed"

install_lazyvim

log "VS Code:"
install_vscode_extension 0 0 || warn "the Epitech extension for VS Code isn't installed: epitech-upgrade retries"

if [ -x /opt/teams-for-linux/teams-for-linux ]; then
    ln -sf /opt/teams-for-linux/teams-for-linux "${HOME}/.local/bin/teams-for-linux"
    ok "teams-for-linux linked on PATH"
else
    warn "/opt/teams-for-linux not found (teams step skipped or failed)"
fi

log "auto-update timer:"
: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"; export XDG_RUNTIME_DIR
mkdir -p "${HOME}/.config/systemd/user"
cp "${REPO_DIR}/systemd/epitech-upgrade.service" "${REPO_DIR}/systemd/epitech-upgrade.timer" \
    "${HOME}/.config/systemd/user/"
if systemctl --user daemon-reload 2>/dev/null \
    && systemctl --user enable --now epitech-upgrade.timer 2>/dev/null; then
    ok "weekly timer enabled (systemctl --user list-timers)"
else
    warn "could not enable user timer — run 'epitech-upgrade' manually"
fi

case ":${PATH}:" in
    *":${HOME}/.local/bin:"*) ;;
    *) warn "${HOME}/.local/bin is not on PATH — add it to your shell rc" ;;
esac
log ""
log "Epitech dump installed. Commands: epiclang, banana-check-repo,"
log "  epitech-emacs, epitech-upgrade, teams-for-linux, nvim,"
log "  epitech-doctor (is everything working?), epitech-predeliver (is this"
log "  project ready to push?), epitech-mem (leaks and memory errors)."
log "LazyVim: <leader>cf formats C; <leader>cH inserts an Epitech header."
log "         <leader>cG adds a filename-based include guard to a .h file."
log "VS Code: the Epitech extension formats on save (Shift+Alt+F), shows"
log "         Banana's reports and the meters; Ctrl+Shift+P > Epitech for the rest."
log "Re-run this installer to update integrations; use 'epitech-upgrade'"
log "for the upstream Epitech tools."
