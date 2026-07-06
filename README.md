# nvide

nvide: Personal Neovim configuration for use as an IDE, powered by modern plugins such as coc.nvim, LeaderF, nvim-treesitter, and more.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start: One-click Install](#quick-start-one-click-install)
- [Quick Start: Download CI Artifact](#quick-start-download-ci-artifact)
- [Build from Scratch](#build-from-scratch)
- [Plugin Management](#plugin-management)
- [Post-Installation](#post-installation)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Update](#update)

## Prerequisites

The following tools must be installed on your system:

| Tool | Version | Purpose |
|------|---------|---------|
| [Neovim](https://github.com/neovim/neovim/releases) | ≥ 0.9 | Core editor |
| Python 3 | ≥ 3.8 | LeaderF, coc.nvim |
| Node.js + npm | ≥ 16 | coc.nvim extensions, tree-sitter CLI |
| git | any | Plugin management (vim-plug) |
| gcc / clang | any | Compile LeaderF C extension |
| ripgrep (rg) | any | Fuzzy search (LeaderF) |
| ctags / gtags | any | Code navigation (optional) |

### ⚠️ Critical: Install pynvim (most commonly forgotten)

Neovim's Python 3 provider requires the `pynvim` package:

```bash
pip install pynvim
```

Without this step, LeaderF will refuse to load with the error:

> LeaderF requires Vim compiled with python and/or a compatible python version.

## Quick Start: One-click Install

The `install.sh` script auto-detects your OS (Ubuntu/Debian or macOS) and bootstraps everything: Neovim binary, clangd, config symlink, vim-plug, plugins, tree-sitter parsers, and coc extensions. It is idempotent — safe to re-run.

```bash
git clone https://github.com/your-username/nvide.git ~/nvide
cd ~/nvide
./install.sh install
```

On Linux the script downloads the nvim appimage to `~/Downloads/nvim/` and clangd to `~/Downloads/clangd/`, and prints the exact `export PATH=...` lines to add to your shell rc (add them, then restart your shell). On macOS it uses Homebrew (`brew install neovim llvm`).

After the PATH lines are in place:

```bash
nvim   # open Neovim — see Verification below
```

Run `./install.sh --help` for all subcommands (`install`, `update`, `clean`, `parsers`, `coc`).

> If you hit any issue, the script runs the same steps documented in [Build from Scratch](#build-from-scratch) below — you can follow that section to debug a specific step.

## Quick Start: Download CI Artifact

This is the fastest way to get started. The CI pipeline pre-builds everything on Ubuntu and macOS.

### Step 1: Download Neovim

Download the latest [Neovim nightly](https://github.com/neovim/neovim/releases/tag/nightly):

- **Linux**: Download `nvim-linux-x86_64.appimage`
- **macOS**: Download `nvim-macos-x86_64.tar.gz` (or `nvim-macos-arm64.tar.gz` for Apple Silicon)

Extract and place the `nvim` binary in a convenient location, e.g.:

```bash
# macOS
tar xzf nvim-macos-x86_64.tar.gz
# The binary is at ./nvim-macos-x86_64/bin/nvim
```

### Step 2: Download the Config Artifact

1. Go to the [GitHub Actions page](https://github.com/your-username/nvide/actions) of this repository.
2. Select the latest successful workflow run.
3. Download the artifact matching your OS — each run produces three, named after the build platform:
   - `nvim-config-ubuntu-2204` (Ubuntu 22.04)
   - `nvim-config-ubuntu-2404` (Ubuntu 24.04)
   - `nvim-config-macos` (macOS, latest)
4. Extract it (the tarball filename matches the artifact name):

```bash
tar xzf nvim-config-ubuntu-2404.tar.gz   # adjust to your OS
```

### Step 3: Set Up the Directory Structure

Place nvim and config side by side:

```
your-project/
├── nvim             # Neovim binary (renamed from the downloaded package)
└── nvim.config/     # Extracted artifact
    └── nvim/        # Config files (init.vim, plugged/, etc.)
```

Then run:

```bash
./nvim
```

### Step 4: Recompile Tree-sitter Parsers

CI artifacts contain parsers compiled for the CI server's Neovim version, which may differ from your local version. Recompile them:

```bash
cd nvim.config/nvim
chmod +x scripts/download-parsers.sh scripts/build-parsers.sh
./scripts/download-parsers.sh
./scripts/build-parsers.sh
```

### Step 5: Verify

```bash
./nvim
```

See the [Verification](#verification) section below for what to check.

## Build from Scratch

This method builds everything from source and avoids all version-mismatch issues.

### Step 1: Install Neovim

- **macOS (Homebrew)**:
  ```bash
  brew install neovim
  ```
- **Linux (AppImage)**:
  ```bash
  curl -fLo nvim --create-dirs https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage
  chmod u+x nvim
  ```
- **macOS (manual)**:
  Download from [Neovim releases](https://github.com/neovim/neovim/releases) and extract.

### Step 2: Clone the Config

```bash
git clone https://github.com/your-username/nvide.git ~/.config/nvim
```

If you already have an existing `~/.config/nvim`, back it up first:

```bash
mv ~/.config/nvim ~/.config/nvim.bak
```

### Step 3: Install vim-plug

```bash
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

### Step 4: Install Plugins

Because `init.vim` references plugin modules immediately after `plug#end()` (e.g. `require("onedarkpro")`), plugins must be installed **before** `init.vim` loads fully. Use a wrapper to bypass the initial loading errors:

```bash
nvim --headless \
  -c "try | silent! source ~/.config/nvim/init.vim | catch | endtry" \
  -c "PlugInstall" \
  -c "qa!"
```

This suppresses errors from post-`plug#end()` plugin references and runs the installation successfully.

> **Note**: The errors are harmless — they only occur because the plugins haven't been downloaded yet. Once installed, `init.vim` loads cleanly on subsequent launches.

### Step 5: Install Tree-sitter Parsers

```bash
cd ~/.config/nvim
chmod +x scripts/download-parsers.sh scripts/build-parsers.sh
./scripts/download-parsers.sh
./scripts/build-parsers.sh
```

### Step 6: Install coc.nvim Extensions

```bash
mkdir -p ~/.config/coc/extensions
cd ~/.config/coc/extensions
echo '{"dependencies":{}}' > package.json
npm install coc-snippets coc-syntax coc-word coc-pairs coc-lists coc-yank \
  coc-spell-checker coc-json coc-python coc-vimlsp \
  --global-style --ignore-scripts --no-bin-links --no-package-lock --only=prod
```

### Step 7: Verify

```bash
nvim
```

## Post-Installation

### Compile LeaderF C Extension

LeaderF uses a C extension for performance. It **must** be compiled after installation:

```bash
cd ~/.config/nvim/plugged/LeaderF && ./install.sh
```

> This step is also required after any Neovim upgrade, as the C extension is compiled against a specific version.

### Set Your Python Virtual Environment (Optional)

If you use a Python virtual environment, set it in `init.vim`:

```vim
let g:NvideConf_PythonVirtualEnv = '/path/to/your/venv'
```

Otherwise, leave it as empty string `''` and nvim will use the system Python 3.

## Plugin Management

Plugins are managed by [vim-plug](https://github.com/junegunn/vim-plug). The list of plugins is declared with `Plug '...'` lines in `init.vim`. Two ways to manage them:

### Via install.sh subcommands (one command, no nvim interaction)

| Command | What it does |
|---------|--------------|
| `./install.sh update` | `:PlugUpdate` (upgrade all plugins) + recompile LeaderF + rebuild tree-sitter parsers + `npm update` coc extensions |
| `./install.sh clean` | `:PlugClean` (remove plugins whose `Plug` line you deleted from init.vim) |
| `./install.sh parsers` | Re-download and rebuild tree-sitter parsers only |
| `./install.sh coc` | (Re)install coc extensions only |

### Via nvim interactive commands (inside nvim)

| Command | When to use |
|---------|-------------|
| `:PlugInstall` | After you **add** a new `Plug '...'` line to init.vim — installs the new plugin |
| `:PlugUpdate` | Upgrade all plugins to their latest upstream version |
| `:PlugClean` | After you **delete** a `Plug '...'` line from init.vim — removes the now-unwanted plugin directory |
| `:PlugUpgrade` | Upgrade vim-plug itself (the plugin manager) |
| `:PlugStatus` | See installed plugins and their status |

### Common workflows

**Add a plugin**: add a `Plug 'author/repo'` line in the plugin section of `init.vim`, save, then either restart nvim and run `:PlugInstall`, or run `./install.sh install` from the shell.

**Remove a plugin**: delete its `Plug '...'` line from `init.vim`, save, then run `:PlugClean` inside nvim (or `./install.sh clean` from the shell).

**Upgrade everything**: `./install.sh update` — one command updates plugins, LeaderF, parsers, and coc extensions together.

## Verification

After installation, open Neovim and check the following:

1. **No error messages** on startup.
2. **LeaderF works**: Press `<C-P>` to fuzzy-find files.
3. **Tree-sitter highlights**: Open a C or Python file — syntax highlighting should be rich and accurate.
4. **coc.nvim works**: In a C file, move cursor to a symbol and press `gd` — it should jump to the definition.

## Troubleshooting

### "LeaderF requires Vim compiled with python"

**Cause**: `pynvim` is not installed or Neovim can't find Python 3.

**Fix**:

```bash
pip install pynvim
# Verify
python3 -c "import pynvim"  # Should print nothing (no error)
```

Then recompile the C extension:

```bash
cd ~/.config/nvim/plugged/LeaderF && rm -rf build && ./install.sh
```

### Tree-sitter parser ABI mismatch

```
Error: Parser could not be created for buffer 1 and language "vim"
```

**Cause**: CI/backup parsers were compiled for a different Neovim version.

**Fix**: Recompile parsers for your local Neovim:

```bash
cd ~/.config/nvim
./scripts/download-parsers.sh
./scripts/build-parsers.sh
```

### "E117: Unknown function: LfRegisterPythonExtension"

**Cause**: LeaderF failed to load (usually due to missing `pynvim`), so `LfRegisterSelf` and `LfRegisterPythonExtension` were never defined. LeaderF-marks then tries to call undefined functions.

**Fix**: Install `pynvim` and recompile LeaderF (see above).

### "require(...) module not found" on first PlugInstall

**Cause**: `init.vim` references plugin modules (e.g. `onedarkpro`, `Comment.nvim`) after `plug#end()`. When `plugged/` is empty (first install), these references fail.

**Fix**: Use the wrapper command from [Step 4](#step-4-install-plugins) to bypass errors during installation. After plugins are installed, this error goes away permanently.

### coc.nvim extensions not loading

**Cause**: Node modules not installed.

**Fix**:

```bash
cd ~/.config/coc/extensions
npm install
```

### "E227: Mapping already exists" for `*` / `#`

**Cause**: Multiple plugins define the same mappings. This is cosmetic and does not affect functionality.

**Fix**: None needed — the mappings still work.

## Update

**One command** (updates plugins, LeaderF, tree-sitter parsers, and coc extensions together):

```bash
cd ~/.config/nvim
./install.sh update
```

To update to the latest config from this repository first:

```bash
cd ~/.config/nvim
git pull
./install.sh update
```

### Manual (without install.sh)

```bash
# plugins
nvim +PlugUpdate +qall --headless
# coc extensions
cd ~/.config/coc/extensions && npm update
# LeaderF C extension + tree-sitter parsers (after a plugin or nvim upgrade)
cd ~/.config/nvim/plugged/LeaderF && ./install.sh
cd ~/.config/nvim && ./scripts/build-parsers.sh
```
