# shellcheck shell=bash
# The system side, per distribution: which one this is, the packages the
# installer adds, how to install a missing one, and the tools some
# distributions ship too old (Neovim, clang-format) or not at all (lazygit),
# installed under ~/.local instead.
#
# Arch and its derivatives (Omarchy, EndeavourOS, Manjaro) use pacman and
# the AUR. Ubuntu and its derivatives (and Debian) use apt and Epitech's own
# PPA (ppa:epitech/ppa), the one the school's dump uses: its epitech-cpool
# package brings epiclang, Banana, Criterion, CSFML and the Pool's tools.
# Callers define log, ok, info and warn.

# "arch", "ubuntu" (apt-based) or "other". DUMP_OS overrides it (tests).
dump_os() {
    if [ -n "${DUMP_OS:-}" ]; then
        printf '%s' "$DUMP_OS"
        return
    fi
    local ids=""
    if [ -f /etc/os-release ]; then
        ids=$(. /etc/os-release; printf ' %s %s ' "${ID:-}" "${ID_LIKE:-}")
    fi
    case "$ids" in
        *" arch "*) printf 'arch' ;;
        *" ubuntu "* | *" debian "*) printf 'ubuntu' ;;
        *) printf 'other' ;;
    esac
}

# The pacman packages (the same list as the school's dump, plus the tools
# epitech-dump-arch adds).
ARCH_PACKAGES=(
    base-devel git gcovr csfml libjpeg-turbo libx11 freetype2 libvorbis
    openal libxi libxrandr xcb-util-image xcb-util criterion valgrind
    x264 tree unzip curl net-tools tcsh emacs vim neovim ripgrep fd
    clang clang21 llvm21-libs compiler-rt21 uv gdb lazygit github-cli
)

# The apt packages besides Epitech's epitech-cpool (which brings
# build-essential, gcovr, CSFML, Criterion, valgrind, tcsh, Banana…). Neovim,
# clang-format, uv and lazygit come from elsewhere when apt's are too old or
# missing (ensure_user_tools).
UBUNTU_PACKAGES=(
    git curl tar unzip python3 pipx libarchive-tools zstd locales
    emacs vim ripgrep fd-find gdb gh clang
)

# The Ubuntu releases Epitech's PPA publishes for.
EPITECH_PPA_SERIES="noble resolute"

ubuntu_series() {
    (. /etc/os-release 2>/dev/null; printf '%s' "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}")
}

# The packages of this distribution's list (one per line).
dump_packages() {
    case "$(dump_os)" in
        arch) printf '%s\n' "${ARCH_PACKAGES[@]}" ;;
        ubuntu) printf '%s\n' epitech-cpool "${UBUNTU_PACKAGES[@]}" ;;
    esac
}

package_installed() {
    case "$(dump_os)" in
        arch) pacman -Q "$1" >/dev/null 2>&1 ;;
        ubuntu) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed' ;;
        *) return 1 ;;
    esac
}

# The command that installs packages here: install_hint ARCH_NAME [UBUNTU_NAME].
install_hint() {
    case "$(dump_os)" in
        arch) printf 'sudo pacman -S --needed %s' "$1" ;;
        ubuntu) printf 'sudo apt install %s' "${2:-$1}" ;;
        *) printf 'install %s with your package manager' "${2:-$1}" ;;
    esac
}

# The machine as release assets name it.
release_arch() {
    case "$(uname -m)" in
        aarch64 | arm64) printf 'arm64' ;;
        *) printf 'x86_64' ;;
    esac
}

# The download URL of the latest release asset of a GitHub repository whose
# name matches the extended regex (case-insensitive): from the API, else
# (rate-limited, 60 calls an hour without a token) from the release's asset
# list page.
github_asset() {
    local repo="$1" pattern="$2" urls tag
    urls=$(curl -fsSL --max-time 30 "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
        | sed -n 's/.*"browser_download_url": *"\([^"]*\)".*/\1/p')
    if [ -z "$urls" ]; then
        tag=$(curl -fsSIL --max-time 30 -o /dev/null -w '%{url_effective}' \
            "https://github.com/${repo}/releases/latest" 2>/dev/null | grep -o '[^/]*$')
        [ -n "$tag" ] && [ "$tag" != latest ] && urls=$(curl -fsSL --max-time 30 \
            "https://github.com/${repo}/releases/expanded_assets/${tag}" 2>/dev/null \
            | grep -o 'href="[^"]*/releases/download/[^"]*"' | sed 's/^href="/https:\/\/github.com/; s/"$//')
    fi
    printf '%s\n' "$urls" | grep -iE "$pattern" | head -n 1
}

# The system packages, with sudo. Returns non-zero on failure.
install_system_packages() {
    case "$(dump_os)" in
        arch) install_arch_packages ;;
        ubuntu) install_ubuntu_packages ;;
        *) warn "unknown distribution: install the packages yourself (see the README), then re-run with --no-sys"
           return 1 ;;
    esac
}

install_arch_packages() {
    log "system packages:"
    sudo pacman -Sy --noconfirm >/dev/null 2>&1 || { warn "pacman sync failed"; return 1; }
    sudo pacman -S --needed --noconfirm "${ARCH_PACKAGES[@]}" || { warn "pacman install failed"; return 1; }
    ok "pacman packages installed"

    log "AUR packages:"
    if ! command -v yay >/dev/null 2>&1; then
        info "installing yay-bin..."
        local tmp
        tmp=$(mktemp -d)
        git clone -q --depth 1 https://aur.archlinux.org/yay-bin.git "${tmp}/yay-bin" \
            || { warn "yay-bin clone failed"; return 1; }
        (cd "${tmp}/yay-bin" && makepkg -si --noconfirm) || { warn "yay install failed"; return 1; }
        rm -rf "$tmp"
    fi
    yay -S --needed --noconfirm teams-for-linux-bin || { warn "teams-for-linux install failed"; return 1; }
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
}

install_ubuntu_packages() {
    local series packages=("${UBUNTU_PACKAGES[@]}")
    series=$(ubuntu_series)
    log "system packages (apt):"
    sudo apt-get update -qq >/dev/null || { warn "apt-get update failed"; return 1; }
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq software-properties-common >/dev/null \
        || { warn "could not install software-properties-common"; return 1; }
    if [[ " ${EPITECH_PPA_SERIES} " == *" ${series} "* ]]; then
        if ! grep -rqs 'ppa.launchpadcontent.net/epitech/ppa\|ppa.launchpad.net/epitech/ppa' /etc/apt/sources.list.d/; then
            sudo add-apt-repository -y ppa:epitech/ppa >/dev/null || { warn "could not add ppa:epitech/ppa"; return 1; }
            ok "Epitech PPA added (ppa:epitech/ppa)"
        fi
        packages=(epitech-cpool "${packages[@]}")
    else
        warn "Epitech's PPA has no packages for ${series:-this release} (only ${EPITECH_PPA_SERIES// /, }):"
        warn "epiclang and Banana come from epitech-upgrade instead, Criterion and CSFML from Ubuntu"
        packages+=(build-essential gcovr libcsfml-dev valgrind tcsh tree net-tools x264 libcriterion-dev)
    fi
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${packages[@]}" >/dev/null \
        || { warn "apt install failed: sudo apt install ${packages[*]}"; return 1; }
    ok "apt packages installed"
    # lazygit is in apt from Ubuntu 25.04 on; ensure_user_tools covers older ones.
    if apt-cache show lazygit >/dev/null 2>&1; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq lazygit >/dev/null && ok "lazygit installed"
    fi
    install_teams_deb
    if ! locale -a 2>/dev/null | grep -qi "fr_fr"; then
        sudo locale-gen fr_FR.UTF-8 >/dev/null 2>&1 && ok "fr_FR.UTF-8 locale generated" \
            || warn "locale-gen failed (non-fatal)"
    else
        ok "fr_FR locale present"
    fi
}

# teams-for-linux's .deb from its latest release (it has no apt repository
# in Ubuntu).
install_teams_deb() {
    local url tmp arch=amd64
    [ "$(release_arch)" = arm64 ] && arch=arm64
    if dpkg-query -W -f='${Status}' teams-for-linux 2>/dev/null | grep -q 'install ok installed'; then
        ok "teams-for-linux present"
        return 0
    fi
    url=$(github_asset IsmaelMartinez/teams-for-linux "_${arch}\\.deb$")
    [ -n "$url" ] || { warn "could not find teams-for-linux's .deb (skipped)"; return 0; }
    tmp=$(mktemp -d)
    if curl -fsSL --max-time 300 -o "${tmp}/teams.deb" "$url" \
        && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${tmp}/teams.deb" >/dev/null; then
        ok "teams-for-linux installed"
    else
        warn "teams-for-linux install failed (non-fatal)"
    fi
    rm -rf "$tmp"
}

# The tools a distribution may ship too old or not at all, into ~/.local
# (no sudo): Neovim 0.11.2+, uv, clang-format 21+, lazygit, and an fd name
# for Ubuntu's fdfind. On an up-to-date Arch they're all there already.
ensure_user_tools() {
    local bin="${HOME}/.local/bin"
    mkdir -p "$bin"
    case ":${PATH}:" in *":${bin}:"*) ;; *) export PATH="${bin}:${PATH}" ;; esac
    ensure_user_neovim || return 1
    if ! command -v uv >/dev/null 2>&1; then
        if command -v pipx >/dev/null 2>&1 && pipx install uv >/dev/null 2>&1 && command -v uv >/dev/null 2>&1; then
            ok "uv installed (pipx)"
        else
            warn "uv is missing: install it (pipx install uv)"
            return 1
        fi
    fi
    if ! clang_format_ok; then
        if uv tool install --force 'clang-format>=21' >/dev/null 2>&1 && clang_format_ok; then
            ok "clang-format $(clang-format --version | sed -n 's/.*version \([0-9.]*\).*/\1/p') installed (uv tool)"
        else
            warn "clang-format 21 or newer is missing: uv tool install 'clang-format>=21'"
            return 1
        fi
    fi
    if ! command -v lazygit >/dev/null 2>&1; then
        install_user_lazygit || warn "lazygit install failed (non-fatal)"
    fi
    if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
        ln -sf "$(command -v fdfind)" "${bin}/fd" && ok "fd linked to fdfind"
    fi
    return 0
}

clang_format_ok() {
    local version
    command -v clang-format >/dev/null 2>&1 || return 1
    version=$(clang-format --version | sed -n 's/.*version \([0-9][0-9]*\).*/\1/p' | head -n 1)
    [ -n "$version" ] && [ "$version" -ge 21 ]
}

nvim_ok() {
    command -v nvim >/dev/null 2>&1 && nvim --clean --headless -u NONE \
        "+lua if vim.fn.has('nvim-0.11.2') == 0 then vim.cmd('cquit 1') end" +qa >/dev/null 2>&1
}

USER_NVIM_DIR="${HOME}/.local/share/epitech-dump-arch/nvim"

# Neovim's official release into ~/.local when the system's is missing or
# older than 0.11.2 (Ubuntu 24.04 ships 0.9). epitech-upgrade keeps that copy
# current (upgrade_user_neovim).
ensure_user_neovim() {
    nvim_ok && return 0
    install_user_neovim || { warn "Neovim 0.11.2 or newer is required by LazyVim"; return 1; }
}

install_user_neovim() {
    local tmp url
    url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$(release_arch).tar.gz"
    tmp=$(mktemp -d)
    if ! curl -fsSL --max-time 300 -o "${tmp}/nvim.tar.gz" "$url" \
        || ! tar -xzf "${tmp}/nvim.tar.gz" -C "$tmp"; then
        rm -rf "$tmp"
        warn "could not download Neovim"
        return 1
    fi
    rm -rf "$USER_NVIM_DIR"
    mkdir -p "$(dirname "$USER_NVIM_DIR")" "${HOME}/.local/bin"
    mv "${tmp}/nvim-linux-$(release_arch)" "$USER_NVIM_DIR" && rm -rf "$tmp"
    ln -sf "${USER_NVIM_DIR}/bin/nvim" "${HOME}/.local/bin/nvim"
    hash -r
    nvim_ok || { warn "the downloaded Neovim doesn't run"; return 1; }
    ok "Neovim $(nvim --version | head -n 1 | sed 's/^NVIM //') installed in ~/.local"
}

# Updates the Neovim ensure_user_neovim installed, when a newer stable
# release is out. Leaves a system Neovim alone.
upgrade_user_neovim() {
    local check_only="${1:-0}" installed latest
    [ -x "${USER_NVIM_DIR}/bin/nvim" ] || return 0
    installed=$("${USER_NVIM_DIR}/bin/nvim" --version | head -n 1 | sed 's/^NVIM //')
    latest=$(curl -fsSIL --max-time 30 -o /dev/null -w '%{url_effective}' \
        https://github.com/neovim/neovim/releases/latest 2>/dev/null | grep -o '[^/]*$')
    if [ -z "$latest" ]; then
        warn "could not check Neovim's latest release (installed ${installed})"
        return 0
    fi
    if [ "$installed" = "$latest" ]; then
        ok "Neovim up to date (${installed})"
    elif [ "$check_only" -eq 1 ]; then
        info "Neovim ${installed} → ${latest} available"
    else
        install_user_neovim
    fi
}

install_user_lazygit() {
    local url tmp
    url=$(github_asset jesseduffield/lazygit "_linux_$(release_arch)\\.tar\\.gz$")
    [ -n "$url" ] || return 1
    tmp=$(mktemp -d)
    curl -fsSL --max-time 120 -o "${tmp}/lazygit.tar.gz" "$url" \
        && tar -xzf "${tmp}/lazygit.tar.gz" -C "$tmp" lazygit \
        && install -m 755 "${tmp}/lazygit" "${HOME}/.local/bin/lazygit" \
        && ok "lazygit installed in ~/.local/bin"
    local status=$?
    rm -rf "$tmp"
    return "$status"
}
