# epitech-dump-arch

The Epitech "dump" for **Arch Linux** (Omarchy, EndeavourOS…) and **Ubuntu**
(24.04, 26.04 and derivatives): everything the school's `dump.sh` installs,
plus Neovim with LazyVim and epitech.nvim, the VS Code extension, and tools
that check your project before the moulinette does. One command to install
(the same on both), and it updates itself every week.

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/cempack/epitech-dump-arch/main/install.sh)
```

Then run `epitech-doctor` to see that everything works.

## What's in it

| | |
|---|---|
| **School tools** | `epiclang` with Banana and `banana-check-repo` (the same packages as the Epitech PPA), Criterion, CSFML, `tcsh`, Teams |
| **Editors** | Neovim with LazyVim and [epitech.nvim](https://github.com/cempack/epitech.nvim), the Epitech extension for VS Code (when VS Code, VSCodium or Code - OSS is installed), the Epitech Vim config, the Epitech Emacs config (`epitech-emacs`) |
| **Development** | gcc, clang 21, gdb, valgrind, gcovr, make, lazygit, gh, ripgrep, fd, `mbake` |
| **Its own commands** | `epitech-predeliver`, `epitech-mem`, `epitech-doctor`, `epitech-upgrade` |

## Before you push: `epitech-predeliver`

Run it in a project. It clones what you **committed** into a temporary
directory and checks it the way the moulinette will:

```
$ epitech-predeliver --allowed "malloc, free, write, opendir, readdir, closedir, stat"
epitech-predeliver /home/you/delivery/my_ls

Repository
  ✓ no uncommitted changes
  ✗ source files never added to git (the build will miss them):
    src/sort.c
  ✓ everything is pushed to origin/main
  ✗ build products or temporary files tracked (C-O1):
    src/display.o

Build (fresh clone of HEAD)
  ✓ make succeeds
  ✓ my_ls is built
  ✗ a second 'make' rebuilds my_ls (relink): only rebuild when a source changes
  ✓ clean and fclean remove what they should

Coding style
  ✗ Banana: 0 fatal · 2 major · 1 minor · 0 info · 3 hints

Authorized functions
  ✗ unauthorized functions: printf
    printf: src/display.c

Unit tests
  ✓ tests pass: Tested: 14 | Passing: 14 | Failing: 0 | Crashing: 0
    coverage lines: 81.2% (138 out of 170)

✗ 5 problem(s) to fix before delivering
```

What it checks:

- **Repository:** uncommitted changes, `.c`/`.h` files you never `git add`ed,
  unpushed commits, tracked build products (`.o`, `vgcore.*`, `a.out`,
  `unit_tests`, binaries, `.vscode/`…), large files, `banana-check-repo`.
- **Build, on a fresh clone:** `make` works without your local leftovers,
  the binary named by `NAME` appears, a second `make` doesn't relink,
  `clean`, `fclean` and `re` do their job, compiler warnings.
- **Coding style:** Banana on every tracked file.
- **Authorized functions:** every function the binary calls from outside
  (`nm`), against the subject's list. Give the list once with
  `--allowed "malloc, free, write(2), sf*"` (copied from the subject, man
  sections and `*` wildcards accepted); it's remembered for the project.
  Calls the compiler writes itself (`printf("text\n")` becomes `puts`) are
  recognized.
- **Unit tests:** `unit_tests`/`tests_run` pass, with coverage when gcovr is
  there.
- **Memory**, with `--run "ARGS"`: the program run under valgrind.

It exits 1 when something blocks the delivery, so it fits in a script or a
git hook. `--no-tests` skips the tests, `--keep` keeps the clone to look at.

## Leaks and crashes: `epitech-mem`

Valgrind's report, made readable: each problem in plain words, the line of
**your** code that caused it (not libc's), the line itself, and the second
place that explains it, where the overflowed block was allocated or where it
was first freed.

```
$ epitech-mem my_ls -l src
...the program's own output...

epitech-mem ./my_ls -l src  (exit 0)

 MEMORY ERRORS
  ✗ reads 1 byte outside valid memory  (0 bytes after a block of size 8 alloc'd)
      at display.c:42 in print_name
           42 │ while (name[i] != '\0') {
      block allocated at parse.c:18 in add_entry
           18 │ entry->name = malloc(sizeof(char) * len);
  ✗ a condition reads an uninitialised value
      at sort.c:12 in sort_entries
           12 │ if (swapped) {
      the value is a local variable of sort_entries (sort.c:7), never set

 LEAKS
  ✗ 64 bytes in 2 blocks definitely lost
      allocated at parse.c:18 in add_entry
           18 │ entry->name = malloc(sizeof(char) * len);

 FILES LEFT OPEN
  ! file descriptor 3 (src) never closed
      opened at list.c:12 in read_dir
           12 │ dir = opendir(path);

 SUMMARY
  heap: 41 allocs, 39 frees, 4,312 bytes allocated
  ✗ 3 problem(s) (--full for valgrind's whole report)
```

A crash gets its own section with the line that crashed (`segmentation
fault (SIGSEGV) (address 0x0: a NULL pointer)`). In a terminal it's in
color. `epitech-mem my_ls` runs `./my_ls`; the program keeps the terminal,
so interactive ones (a shell) work. `--full` adds valgrind's whole report.

`epitech-mem --asan ./my_ls -l src` rebuilds with AddressSanitizer and
UndefinedBehaviorSanitizer (through `make re CC=…`, your Makefile isn't
changed), runs, then cleans the sanitized build away. It's faster than
valgrind and catches overflows on the stack and in globals, which valgrind
misses.

## Is everything working? `epitech-doctor`

```
$ epitech-doctor
Compiling and testing
  ✓ clang-format 21
  ✓ Criterion (a test): compiles and runs
  ✓ CSFML (a program using sfClock): compiles and runs
Coding style
  ✓ epiclang reports Banana's checks
Editors
  ✓ epitech.nvim loads in your Neovim
Git and GitHub
  ✗ git has no name or email: commits will be refused or anonymous
    fix: git config --global user.name "First Last" && git config --global user.email first.last@epitech.eu
  ! gh isn't logged in
    fix: gh auth login
...
```

It tests that things *work* (a Criterion test compiles and runs, epiclang
really reports Banana, the plugin loads), not just that they're installed,
and gives the command that fixes each problem. `--quick` skips the
compiling and Neovim checks.

## Neovim

You get [LazyVim](https://www.lazyvim.org/) with
[epitech.nvim](https://github.com/cempack/epitech.nvim) and the clangd
extra: format on save that passes Banana, Banana's reports live as you
save, meters for function length and nesting, one-key fixes, project
scaffolding with your Pool's libmy, `make` and Criterion results in the
quickfix list with coverage signs, and a whole-project check. Its README
shows all of it. Makefiles are formatted by `mbake`.

The installer is careful with your config:

- no `~/.config/nvim` (or an empty one): it installs the
  [LazyVim starter](https://github.com/LazyVim/starter);
- an existing LazyVim config: it only adds
  `lua/plugins/epitech-dump-arch.lua`;
- any other Neovim config: left alone, the Neovim part is skipped.

## VS Code

When `code`, `codium` or `code-oss` is installed, the installer adds the
[Epitech extension](https://github.com/cempack/epitech.nvim/tree/main/vscode)
to each of them, and the weekly update keeps it current. It's the Neovim
plugin's work brought to VS Code, without Neovim: the same Banana-proof
formatter (`Shift+Alt+F`, or format on save), Banana's reports in the
Problems panel with the rule on hover, `13/20 lines · 2/4 args` after each
function, the nesting depth, the file's function count in the status bar,
the `(void)` fix, headers and guards, and **Epitech: New Project** with the
same Makefile and files. `Ctrl+Shift+P`, then type `Epitech`, lists every
command.

Install VS Code after the dump? Run `epitech-upgrade` once.

## Arch or Ubuntu

The same command installs the same things; only where they come from
differs.

| | Arch | Ubuntu |
|---|---|---|
| School packages | pacman (`csfml`, `criterion`…) and the AUR (Teams) | Epitech's PPA (`ppa:epitech/ppa`, the school's own): `epitech-cpool` brings Banana, Criterion, CSFML, valgrind, tcsh… |
| epiclang and Banana | from Epitech's PPA, unpacked into `~/.local` | apt, from the PPA |
| Neovim 0.11+ | pacman | the official release in `~/.local` (Ubuntu 24.04 ships 0.9) |
| clang-format 21+ | pacman | `uv tool` in `~/.local/bin` (Ubuntu's is 18) |
| lazygit, Teams | pacman, the AUR | apt when it has it, else their GitHub releases |

The PPA covers Ubuntu 24.04 (noble) and 26.04 (resolute). On another
Ubuntu version, the installer uses Ubuntu's Criterion and CSFML, and
`epitech-upgrade` installs epiclang and Banana into `~/.local` as on Arch.

## Install options

```sh
git clone https://github.com/cempack/epitech-dump-arch.git
cd epitech-dump-arch
./install.sh            # everything
./install.sh --no-sys   # no package manager or sudo: user-space parts only
```

Re-running is safe. With `--no-sys`, the editors and tools (including
`clang-format` 21+) must already be installed.

## Updates

A weekly timer runs `epitech-upgrade`: epiclang and Banana from the Epitech
PPA, the Emacs and Vim configs, epitech.nvim (`:Lazy update epitech.nvim`
only, never your other plugins), the VS Code extension, and this project's
commands.

```sh
epitech-upgrade            # now
epitech-upgrade --check    # only report what's out of date
systemctl --user list-timers | grep epitech
```

System packages stay the package manager's: `yay -Syu` on Arch,
`sudo apt update && sudo apt upgrade` on Ubuntu (epiclang, Banana and
Criterion included there). The updater runs without a terminal, so it never
uses sudo: it tells you which packages the installer now adds
(`sudo pacman -S --needed …` or `sudo apt install …`) and when Criterion or
Teams have a new version. It also keeps the Neovim it put in `~/.local`
current.

Installs from before `epitech-doctor` existed catch up on their next update
(or run `epitech-upgrade` now): it installs the new commands and replaces
itself. The one exception is an install whose Neovim config isn't LazyVim:
re-run `install.sh` once.

## Uninstall

First, while epitech.nvim is still installed, run `:EpitechHooks remove` in
the repositories where you added its pre-push hook, and
`:EpitechLazygit remove` if you added its lazygit key. Then:

```sh
systemctl --user disable --now epitech-upgrade.timer
rm ~/.config/systemd/user/epitech-upgrade.{service,timer}
rm ~/.local/bin/{epitech-upgrade,epitech-doctor,epitech-predeliver,epitech-mem,epitech-emacs}
rm ~/.local/bin/{epiclang,epiclang.py,banana-check-repo,teams-for-linux}
rm ~/.config/nvim/lua/plugins/epitech-dump-arch.lua
code --uninstall-extension cempack.epitech   # or codium / code-oss
rm -rf ~/.local/share/nvim/lazy/epitech.nvim ~/.local/share/nvim/epitech.nvim
rm -rf ~/.local/lib/epiclang ~/.local/share/epitech-upgrade ~/.local/share/epitech-dump-arch
```

On Ubuntu, also `rm -rf ~/.local/share/epitech-dump-arch/nvim ~/.local/bin/nvim`
and `uv tool uninstall clang-format` if the installer added them. Optionally
remove the packages from `install.sh` (`sudo pacman -Rns`, `sudo apt remove`), and remove the
Epitech blocks from `~/.emacs`, `~/.vimrc`, `~/.vim/epitech.vim` and
`~/.emacs.d/lisp/{epitech,site-start.d}`. The LazyVim starter stays, since
your Neovim config may hold your own changes.

## Development

`test/run` runs the tests (set `EPITECH_NVIM_DIR` to test against a local
epitech.nvim checkout).

Unofficial, not affiliated with Epitech. Parity target: the school's
`dump.sh` and the Epitech PPA for Ubuntu 26.04.
