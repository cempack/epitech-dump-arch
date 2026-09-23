#!/usr/bin/env bash
# epitech-dump-arch — unofficial Epitech "dump" installer for Arch Linux / Omarchy.
#
# Gives you dump.sh parity without Ubuntu: system packages, AUR packages,
# epiclang + banana coding-style checker, Epitech emacs/vim configs, launchers,
# and a weekly systemd timer that keeps the Epitech bits up to date.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/cempack/epitech-dump-arch/main/install.sh)
#   ./install.sh [--no-sys]
#
#   --no-sys   skip pacman/AUR/sudo steps (user-space only). Use when you
#              manage system packages yourself, or for testing.

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

if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-} ${ID_LIKE:-}" in
        *arch*) ok "OS: ${PRETTY_NAME:-unknown}" ;;
        *) warn "not Arch/Omarchy (${PRETTY_NAME:-unknown}) — trying anyway" ;;
    esac
fi

if [ "$NO_SYS" -eq 0 ]; then
    command -v sudo >/dev/null 2>&1 || die "sudo is required (or re-run with --no-sys)"
    command -v pacman >/dev/null 2>&1 || die "pacman not found — this installer targets Arch/Omarchy"
    sudo -v || die "sudo authentication failed"
fi

if [ "$NO_SYS" -eq 0 ]; then
    log "system packages:"
    sudo pacman -Sy --noconfirm >/dev/null 2>&1 || die "pacman sync failed"
    sudo pacman -S --needed --noconfirm \
        base-devel git gcovr csfml libjpeg-turbo libx11 freetype2 libvorbis \
        openal libxi libxrandr xcb-util-image xcb-util criterion valgrind \
        x264 tree unzip curl net-tools tcsh emacs vim \
        clang21 llvm21-libs compiler-rt21 \
        || die "pacman install failed"
    ok "pacman packages installed"

    log "AUR packages:"
    if ! command -v yay >/dev/null 2>&1; then
        info "installing yay-bin..."
        YAY_TMP=$(mktemp -d)
        git clone -q --depth 1 https://aur.archlinux.org/yay-bin.git "${YAY_TMP}/yay-bin" \
            || die "yay-bin clone failed"
        (cd "${YAY_TMP}/yay-bin" && makepkg -si --noconfirm) || die "yay install failed"
        rm -rf "$YAY_TMP"
    fi
    yay -S --needed --noconfirm teams-for-linux-bin || die "teams-for-linux install failed"
    ok "teams-for-linux installed"

    if ! locale -a 2>/dev/null | grep -qi "fr_fr"; then
        if [ -f /etc/locale.gen ]; then
            sudo sed -i 's/^#\(fr_FR.UTF-8\)/\1/' /etc/locale.gen
            sudo locale-gen >/dev/null 2>&1 && ok "fr_FR.UTF-8 locale generated" \
                || warn "locale-gen failed (non-fatal)"
        fi
    else
        ok "fr_FR locale present"
    fi
else
    info "skipping system packages (--no-sys)"
fi

for cmd in curl git python3 bsdtar emacs vim; do
    command -v "$cmd" >/dev/null 2>&1 || die "missing required command: $cmd (run without --no-sys to install it)"
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ -f "${SCRIPT_DIR}/epitech-upgrade" ]; then
    REPO_DIR="$SCRIPT_DIR"
else
    log "fetching installer repo..."
    if [ -d "${LOCAL_REPO_DIR}/.git" ]; then
        git -C "$LOCAL_REPO_DIR" pull -q --ff-only 2>/dev/null || true
    else
        rm -rf "$LOCAL_REPO_DIR"
        git clone -q --depth 1 "$REPO_URL" "$LOCAL_REPO_DIR" || die "repo clone failed"
    fi
    REPO_DIR="$LOCAL_REPO_DIR"
fi

log "Epitech tooling:"
mkdir -p "${HOME}/.local/bin"
cp "${REPO_DIR}/epitech-upgrade" "${HOME}/.local/bin/epitech-upgrade"
chmod +x "${HOME}/.local/bin/epitech-upgrade"
"${HOME}/.local/bin/epitech-upgrade" --force || die "epitech-upgrade failed"

cat > "${HOME}/.local/bin/epitech-emacs" <<'EOF'
#!/usr/bin/env bash
# Epitech emacs launcher: start emacs with the Epitech configuration loaded.
exec emacs -L "$HOME/.emacs.d/lisp" -l site-start.d/epitech-init.el "$@"
EOF
chmod +x "${HOME}/.local/bin/epitech-emacs"
ok "epitech-emacs launcher installed"

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
log "  epitech-emacs, epitech-upgrade, teams-for-linux."
log "Re-run this installer or 'epitech-upgrade' anytime to update."
