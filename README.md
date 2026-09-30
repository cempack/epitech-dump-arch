# epitech-dump-arch

Unofficial Epitech "dump" installer for **Arch Linux** (Omarchy included —
same thing).

The school's `dump.sh` only runs on Ubuntu 26.04. This gives you the same
tooling on Arch: compilers, tests, the Banana coding-style checker, Epitech
editor configs (Emacs, Vim, and Neovim/LazyVim), Teams, plus a weekly
auto-updater. No root-owned hacks: school binaries live under `~/.local`,
system libraries come from pacman.

## Install

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/cempack/epitech-dump-arch/main/install.sh)
```

Or clone and run:

```sh
git clone https://github.com/cempack/epitech-dump-arch.git
cd epitech-dump-arch
./install.sh
```

Re-running is safe (idempotent). `./install.sh --no-sys` skips the
pacman/AUR/sudo steps and only installs user-space parts. With `--no-sys`,
the required editors and command-line tools must already be installed.

## What you get

- `epiclang` + Banana plugin — coding-style compiler wrapper (same `.debs`
  the dump installs, tracked from the Epitech PPA)
- `banana-check-repo` — delivery checker (binaries, filenames)
- Epitech emacs config + `epitech-emacs` launcher (tracked from GitHub)
- Epitech vim config (tracked from GitHub)
- Neovim + LazyVim configured for Epitech C development:
  - C and `.h` files use the installed Epitech Vim indentation rules
  - LazyVim's `<leader>cf` and its enabled format-on-save use the Epitech formatter
  - `<leader>cH` / `:EpitechHeader` inserts an interactive Epitech header
  - the header is preserved exactly when the rest of the file is formatted
  - LazyVim's clangd language extra is enabled
- criterion, clang 21 and the system clang, gcc, gdb, valgrind, csfml, make, tcsh,
  tree, x264, net-tools, ripgrep, fd… (pacman)
- `teams-for-linux` (AUR)
- `epitech-upgrade` + weekly systemd timer — keeps school tooling current

### Neovim safety

If `~/.config/nvim` is absent or empty, the installer bootstraps the official
[LazyVim starter](https://github.com/LazyVim/starter). If an existing LazyVim
configuration is detected, only the managed Epitech plugin specification is
added under `lua/plugins/`. A non-LazyVim configuration is never overwritten;
the installer reports that the Neovim integration was skipped.

The bundled plugin is installed under
`~/.local/share/nvim/epitech-upgrade/nvim/epitech.nvim`. Re-run `install.sh` to
update the bundled plugin. The weekly updater continues to update the upstream
Epitech Vim file that the Neovim formatter loads.

## Updating

Automatic (weekly timer): `systemctl --user list-timers | grep epitech`.
Manual anytime: `epitech-upgrade` (`--check` for report-only).
System packages still update via `yay -Syu` (the updater tells you when).
Run `:LazyHealth` inside Neovim to inspect the LazyVim installation.

## Uninstall

```sh
systemctl --user disable --now epitech-upgrade.timer
rm ~/.config/systemd/user/epitech-upgrade.{service,timer}
rm ~/.local/bin/{epitech-upgrade,epitech-emacs,epiclang,epiclang.py,banana-check-repo,teams-for-linux}
rm ~/.config/nvim/lua/plugins/epitech-dump-arch.lua
rm -rf ~/.local/share/nvim/epitech-upgrade/nvim/epitech.nvim
rm -rf ~/.local/lib/epiclang ~/.local/share/epitech-upgrade ~/.local/share/epitech-dump-arch
```

Then optionally `sudo pacman -Rns` the packages from `install.sh`, and remove
the Epitech blocks from `~/.emacs`, `~/.vimrc`, `~/.vim/epitech.vim`,
`~/.emacs.d/lisp/{epitech,site-start.d}`.

The installer leaves the LazyVim starter itself in place because the Neovim
configuration may contain unrelated user changes.

## Disclaimer

Unofficial, not affiliated with Epitech. Parity target is the school's
`dump.sh` + Epitech PPA for Ubuntu 26.04 (Resolute).
