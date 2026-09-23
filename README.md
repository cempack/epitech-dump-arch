# epitech-dump-arch

Unofficial Epitech "dump" installer for **Arch Linux** (Omarchy included —
same thing).

The school's `dump.sh` only runs on Ubuntu 26.04. This gives you the same
tooling on Arch: compilers, tests, the Banana coding-style checker, Epitech
emacs/vim configs, Teams, plus a weekly auto-updater. No root-owned hacks:
school binaries live under `~/.local`, system libs come from pacman.

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
pacman/AUR/sudo steps and only installs user-space parts.

## What you get

- `epiclang` + Banana plugin — coding-style compiler wrapper (same `.debs`
  the dump installs, tracked from the Epitech PPA)
- `banana-check-repo` — delivery checker (binaries, filenames)
- Epitech emacs config + `epitech-emacs` launcher (tracked from GitHub)
- Epitech vim config (tracked from GitHub)
- criterion, clang 21 + 22, gcc, gdb, valgrind, csfml, make, tcsh,
  tree, x264, net-tools… (pacman)
- `teams-for-linux` (AUR)
- `epitech-upgrade` + weekly systemd timer — keeps school tooling current

## Updating

Automatic (weekly timer): `systemctl --user list-timers | grep epitech`.
Manual anytime: `epitech-upgrade` (`--check` for report-only).
System packages still update via `yay -Syu` (the updater tells you when).

## Uninstall

```sh
systemctl --user disable --now epitech-upgrade.timer
rm ~/.config/systemd/user/epitech-upgrade.{service,timer}
rm ~/.local/bin/{epitech-upgrade,epitech-emacs,epiclang,epiclang.py,banana-check-repo,teams-for-linux}
rm -rf ~/.local/lib/epiclang ~/.local/share/epitech-upgrade ~/.local/share/epitech-dump-arch
```

Then optionally `sudo pacman -Rns` the packages from `install.sh`, and remove
the Epitech blocks from `~/.emacs`, `~/.vimrc`, `~/.vim/epitech.vim`,
`~/.emacs.d/lisp/{epitech,site-start.d}`.

## Disclaimer

Unofficial, not affiliated with Epitech. Parity target is the school's
`dump.sh` + Epitech PPA for Ubuntu 26.04 (Resolute).
