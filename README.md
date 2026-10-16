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
the required editors and command-line tools, including `clang-format` 21+, must
already be installed.

## What you get

- `epiclang` + Banana plugin — coding-style compiler wrapper (same `.debs`
  the dump installs, tracked from the Epitech PPA)
- `banana-check-repo` — delivery checker (binaries, filenames)
- Epitech emacs config + `epitech-emacs` launcher (tracked from GitHub)
- Epitech vim config (tracked from GitHub)
- Neovim + LazyVim configured for Epitech C development, through the
  [epitech.nvim](https://github.com/cempack/epitech.nvim) plugin:
  - C and `.h` editor settings mirror the installed Epitech Vim configuration
  - LazyVim's `<leader>cf` and its enabled format-on-save use `clang-format`
    with the plugin's `epitech.clang-format` profile derived from the installed
    Epitech C Coding Style PDF; no project `.clang-format` is created
  - the formatter covers four-space indentation (including `case` labels
    inside a `switch`), braces, spacing (also inside `#define` bodies),
    function separation, line and comment wrapping, the single blank line
    after a function's variable declarations, trailing spaces, and Banana C-G3
    preprocessor nesting
  - `<leader>cH` / `:EpitechHeader` inserts an interactive Epitech header
    using the current filetype's comment syntax: C, Makefile, shell/Python,
    Lua, HTML, and many others. This follows the installed Epitech Vim
    header styles where defined. Existing shebangs are preserved; a header
    in the wrong comment style can be replaced after confirmation.
  - Makefiles use `mbake` through Conform for formatting, including safe
    assignment spacing while preserving recipe tabs and the Epitech banner.
  - `<leader>cG` / `:EpitechGuard` wraps a named `.h` file in an include guard
    derived from its filename (for example, `my_macro_abs.h` becomes
    `MY_MACRO_ABS_H_`); an existing Epitech banner stays at the top
  - the header is preserved when the rest of the file is formatted; only
    trailing spaces are removed from it
  - LazyVim's clangd language extra is enabled
- Formatting does not silently rewrite program logic to satisfy structural or
  semantic Banana rules (such as function length, parameter count, or naming).
  Run `epiclang` to check those requirements after formatting.
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

lazy.nvim installs the plugin from GitHub like any other plugin. The weekly
`epitech-upgrade` timer refreshes the managed spec, updates epitech.nvim with
`:Lazy update epitech.nvim`, and refreshes the upstream Epitech Vim file that
its formatter loads. It does not update LazyVim itself or other plugins, or
touch unmanaged Neovim files. `epitech-upgrade --check` only reports available
updates. The installer also installs the pinned `mbake` Makefile formatter
through `uv`, and removes the copy of the plugin that older versions installed
under `~/.local/share/nvim/epitech-upgrade/`.

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
