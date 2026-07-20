#!/usr/bin/env bash
# install.sh — one-click bootstrap and plugin management for nvide.
#
# Auto-detects Linux (Ubuntu/Debian) and macOS. Idempotent: safe to re-run.
#
# Usage:
#   ./install.sh install    # full bootstrap (default)
#   ./install.sh update     # update plugins + LeaderF + parsers + coc exts
#   ./install.sh clean      # remove plugins no longer declared in init.vim
#   ./install.sh parsers    # re-download + rebuild tree-sitter parsers only
#   ./install.sh coc        # (re)install coc extensions only
#   ./install.sh --help

set -euo pipefail

# ---------- helpers ----------
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_MIN_VERSION="0.11"
CLANGD_MIN_VERSION="15"
COC_EXTS=(coc-snippets coc-syntax coc-word coc-pairs coc-lists coc-yank
	coc-spell-checker coc-json coc-python coc-vimlsp)

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
	C_GREEN=$'\033[32m'
	C_YELLOW=$'\033[33m'
	C_RED=$'\033[31m'
	C_BOLD=$'\033[1m'
	C_RESET=$'\033[0m'
else
	C_GREEN=""
	C_YELLOW=""
	C_RED=""
	C_BOLD=""
	C_RESET=""
fi

info() { printf "%s==>%s %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf "%s!!%s  %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
err() { printf "%sxx%s  %s\n" "$C_RED" "$C_RESET" "$*" >&2; }
step() { printf "\n%s[%s]%s %s\n" "$C_BOLD" "$1" "$C_RESET" "$2"; }

detect_os() {
	case "$(uname -s)" in
	Linux*) echo "linux" ;;
	Darwin*) echo "macos" ;;
	*)
		err "Unsupported OS: $(uname -s)"
		exit 1
		;;
	esac
}

OS="$(detect_os)"

# version_ge $cur $min — true if cur >= min (dot-separated numerics)
version_ge() {
	local cur="$1" min="$2"
	[[ "$cur" == "$(printf '%s\n%s' "$cur" "$min" | sort -V | tail -1)" ]]
}

have() { command -v "$1" >/dev/null 2>&1; }

# Prepend known install locations to PATH so the script finds binaries even when
# the user's shell rc (which adds them) is not loaded — e.g. non-interactive shells,
# CI, or first run before PATH is configured. Idempotent (no duplicate entries).
prepend_install_dirs() {
	case "$OS" in
	linux)
		local nv_dir="$HOME/Downloads/nvim"
		if [[ -x "$nv_dir/nvim" ]] && [[ ":$PATH:" != *":$nv_dir:"* ]]; then
			export PATH="$nv_dir:$PATH"
		fi
		local clangd_bin=""
		if [[ -d "$HOME/Downloads/clangd" ]]; then
			clangd_bin="$(find "$HOME/Downloads/clangd" -maxdepth 3 -type f -name clangd -path '*/bin/*' 2>/dev/null | head -1 || true)"
		fi
		if [[ -n "$clangd_bin" ]]; then
			local clangd_dir
			clangd_dir="$(dirname "$clangd_bin")"
			if [[ ":$PATH:" != *":$clangd_dir:"* ]]; then
				export PATH="$clangd_dir:$PATH"
			fi
		fi
		;;
	macos)
		for d in /opt/homebrew/bin /opt/homebrew/opt/llvm/bin /usr/local/bin /usr/local/opt/llvm/bin; do
			if [[ -d "$d" ]] && [[ ":$PATH:" != *":$d:"* ]]; then
				export PATH="$d:$PATH"
			fi
		done
		;;
	esac
}

nvim_version() { nvim --version 2>/dev/null | head -1 | sed 's/^NVIM //; s/ .*//'; }
clangd_version() { clangd --version 2>/dev/null | grep -oE 'version [0-9]+\.[0-9]+' | head -1 | awk '{print $2}'; }

prepend_install_dirs

# ---------- install steps ----------

install_nvim() {
	step 1 "Neovim binary (>= $NVIM_MIN_VERSION)"
	local cur
	cur="$(nvim_version 2>/dev/null || echo "")"
	if [[ -n "$cur" ]] && version_ge "$cur" "$NVIM_MIN_VERSION"; then
		info "skip: nvim $cur already in PATH"
		return
	fi
	case "$OS" in
	linux)
		local dest="$HOME/Downloads/nvim"
		mkdir -p "$dest"
		info "downloading nvim appimage to $dest/nvim"
		curl -fL -o "$dest/nvim" \
			https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage ||
			{
				rm -f "$dest/nvim"
				err "download failed"
				exit 1
			}
		chmod +x "$dest/nvim"
		warn "nvim installed at $dest/nvim — add to PATH:"
		warn "  export PATH=\$HOME/Downloads/nvim:\$PATH"
		warn "(your mydotfiles/zsh/local.ubuntu.zsh is the place if you use it)"
		;;
	macos)
		if have brew; then
			info "brew install neovim bash (bash 5+ required by download-parsers.sh)"
			brew install neovim bash
		else
			err "Homebrew not found. Install brew or nvim manually (>= $NVIM_MIN_VERSION)."
			exit 1
		fi
		;;
	esac
}

install_clangd() {
	step 2 "clangd (>= $CLANGD_MIN_VERSION, for coc.nvim C/C++ LSP)"
	local cur
	cur="$(clangd_version 2>/dev/null || echo "")"
	if [[ -n "$cur" ]] && version_ge "$cur" "$CLANGD_MIN_VERSION"; then
		info "skip: clangd $cur already in PATH"
		return
	fi
	case "$OS" in
	linux)
		local dest="$HOME/Downloads/clangd"
		local ver="22.1.6"
		mkdir -p "$dest"
		info "downloading clangd $ver to $dest"
		curl -fLO --output-dir "$dest" \
			"https://github.com/clangd/clangd/releases/download/$ver/clangd-linux-$ver.zip"
		(cd "$dest" && unzip -o "clangd-linux-$ver.zip" >/dev/null)
		warn "clangd extracted to $dest/clangd_$ver/bin/clangd — add to PATH:"
		warn "  export PATH=\$HOME/Downloads/clangd/clangd_$ver/bin:\$PATH"
		;;
	macos)
		if have brew; then
			info "brew install llvm (provides clangd)"
			brew install llvm
			warn "add brew llvm to PATH: export PATH=\$(brew --prefix llvm)/bin:\$PATH"
		else
			warn "Homebrew not found — install clangd manually (>= $CLANGD_MIN_VERSION)"
		fi
		;;
	esac
}

link_config() {
	step 3 "Symlink ~/.config/nvim -> $REPO_DIR"
	local target="$HOME/.config/nvim"
	mkdir -p "$HOME/.config"
	if [[ -L "$target" && "$(readlink -f "$target")" == "$REPO_DIR" ]]; then
		info "skip: symlink already points to this repo"
		return
	fi
	if [[ -e "$target" && ! -L "$target" ]]; then
		local bak
		bak="$target.bak.$(date +%s)"
		warn "existing $target is not a symlink — backing up to $bak"
		mv "$target" "$bak"
	fi
	ln -sfn "$REPO_DIR" "$target"
	info "linked"
}

install_vimplug() {
	step 4 "vim-plug"
	local dest="$REPO_DIR/autoload/plug.vim"
	if [[ -f "$dest" ]]; then
		info "skip: plug.vim present"
		return
	fi
	curl -fLo "$dest" --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	info "installed plug.vim"
}

install_plugins() {
	step 5 "Plugins (vim-plug :PlugInstall)"
	if ! have nvim; then
		err "nvim not in PATH — fix PATH first (see step 1), then re-run"
		exit 1
	fi
	# try/catch wrapper: init.vim references plugin modules after plug#end()
	# that fail when plugged/ is empty on first install — harmless, suppressed here.
	nvim --headless \
		-c "try | silent! source $REPO_DIR/init.vim | catch | endtry" \
		-c "PlugInstall" \
		-c "qa!" 2>/dev/null || true
	info "PlugInstall done"
}

compile_leaderf() {
	step 6 "LeaderF C extension"
	local lf="$REPO_DIR/plugged/LeaderF"
	if [[ ! -d "$lf" ]]; then
		warn "skip: LeaderF not installed yet"
		return
	fi
	(cd "$lf" && ./install.sh >/dev/null 2>&1) || warn "LeaderF install.sh failed (non-fatal)"
	info "LeaderF compiled"
}

install_ts_cli() {
	step 7 "tree-sitter CLI"
	local cargo_ts="$REPO_DIR/tools/cargo/bin/tree-sitter"
	if [[ -x "$cargo_ts" ]]; then
		info "skip: $cargo_ts present"
		return
	fi
	if have cargo; then
		info "cargo install tree-sitter-cli (builds from source, glibc-safe)"
		cargo install tree-sitter-cli --root "$REPO_DIR/tools/cargo" >/dev/null 2>&1 ||
			{
				warn "cargo install failed, falling back to npm"
				install_ts_cli_npm
			}
		return
	fi
	warn "cargo not found, using npm (may hit glibc issues on older systems)"
	install_ts_cli_npm
}

install_ts_cli_npm() {
	mkdir -p "$REPO_DIR/tools"
	(cd "$REPO_DIR/tools" && {
		[[ -f package.json ]] || npm init -y >/dev/null
		npm install tree-sitter-cli >/dev/null 2>&1 || err "npm install tree-sitter-cli failed"
	})
}

build_parsers() {
	step 8 "tree-sitter parsers"
	if [[ ! -f "$REPO_DIR/scripts/download-parsers.sh" ]]; then
		err "scripts/download-parsers.sh not found"
		return
	fi
	chmod +x "$REPO_DIR/scripts/download-parsers.sh" "$REPO_DIR/scripts/build-parsers.sh"
	# download-parsers.sh uses bash 4+ associative arrays; macOS /bin/bash is 3.2,
	# so use brew bash 5+ there (installed in install_nvim's macos branch).
	local bash_bin="bash"
	if [[ "$OS" == "macos" ]]; then
		bash_bin="$(brew --prefix 2>/dev/null)/bin/bash"
		[[ -x "$bash_bin" ]] || bash_bin="bash"
	fi
	"$bash_bin" "$REPO_DIR/scripts/download-parsers.sh"
	"$bash_bin" "$REPO_DIR/scripts/build-parsers.sh"
	info "parsers built"
}

install_coc_exts() {
	step 9 "coc.nvim extensions"
	local ext_dir="$HOME/.config/coc/extensions"
	mkdir -p "$ext_dir"
	(cd "$ext_dir" && {
		[[ -f package.json ]] || echo '{"dependencies":{}}' >package.json
		npm install "${COC_EXTS[@]}" \
			--global-style --ignore-scripts --no-bin-links --no-package-lock --only=prod \
			>/dev/null 2>&1 || err "coc extension install failed"
	})
	info "coc extensions installed: ${COC_EXTS[*]}"
}

install_yazi() {
	step 10 "yazi (terminal file manager, used by tfm.nvim <Leader>t)"
	if have yazi; then
		info "skip: yazi already in PATH"
		return
	fi
	if ! have cargo; then
		warn "cargo not found — skipping yazi. Install Rust via rustup, then re-run (or install yazi manually)."
		return
	fi
	# cargo-binstall fetches prebuilt binaries — far faster than building yazi from source.
	if ! have cargo-binstall; then
		info "installing cargo-binstall (prebuilt)"
		curl -L --proto '=https' --tlsv1.2 -sSf \
			https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh \
			| bash >/dev/null 2>&1 || {
			warn "cargo-binstall install failed — skipping yazi (non-fatal)"
			return
		}
	fi
	# Prebuilt GNU build needs GLIBC_2.39 (absent on Ubuntu 22.04); force the musl
	# static build on Linux so it runs on older glibc. macOS default target is fine.
	local binstall_args=(-y)
	if [[ "$OS" == "linux" ]]; then
		case "$(uname -m)" in
			x86_64) binstall_args+=(--target x86_64-unknown-linux-musl) ;;
			aarch64 | arm64) binstall_args+=(--target aarch64-unknown-linux-musl) ;;
			*) warn "unrecognized arch $(uname -m) — trying default target (may need newer glibc)" ;;
		esac
	fi
	info "cargo binstall yazi-fm yazi-cli (prebuilt)"
	if cargo binstall "${binstall_args[@]}" yazi-fm yazi-cli >/dev/null 2>&1; then
		info "yazi installed to ~/.cargo/bin/"
		warn "ensure ~/.cargo/bin is on PATH (rustup adds it by default)"
	else
		warn "cargo binstall yazi failed (non-fatal) — install yazi manually"
	fi
}

do_install() {
	info "${C_BOLD}nvide bootstrap ($OS)${C_RESET}"
	install_nvim
	prepend_install_dirs
	install_clangd
	prepend_install_dirs
	link_config
	install_vimplug
	install_plugins
	compile_leaderf
	install_ts_cli
	build_parsers
	install_coc_exts
	install_yazi
	step "✓" "Done. Open nvim to verify. If nvim/clangd/yazi PATH warnings appeared, add them to your shell rc and restart."
}

do_update() {
	info "${C_BOLD}update plugins + LeaderF + parsers + coc${C_RESET}"
	step 1 "PlugUpdate"
	nvim --headless +PlugUpdate +qa 2>/dev/null || true
	step 2 "Recompile LeaderF"
	compile_leaderf
	step 3 "Rebuild tree-sitter parsers"
	build_parsers
	step 4 "Update coc extensions"
	local ext_dir="$HOME/.config/coc/extensions"
	if [[ -d "$ext_dir" ]]; then
		if ! (cd "$ext_dir" && npm update >/dev/null 2>&1); then
			warn "coc npm update failed"
		fi
	fi
	step "✓" "Update done"
}

do_clean() {
	info "PlugClean — remove plugins no longer in init.vim"
	nvim --headless +PlugClean +qa 2>/dev/null || true
	info "done"
}

do_parsers() {
	info "Rebuild tree-sitter parsers"
	build_parsers
}

do_coc() {
	info "(re)install coc extensions"
	install_coc_exts
}

show_help() {
	cat <<'EOF'
nvide install.sh — bootstrap and plugin management

Usage: ./install.sh <command>

Commands:
  install    Full bootstrap: nvim, clangd, config symlink, vim-plug,
             plugins, LeaderF, tree-sitter, coc extensions, yazi. (default)
  update     Update plugins (:PlugUpdate), recompile LeaderF,
             rebuild parsers, update coc extensions.
  clean      Remove plugins no longer declared in init.vim (:PlugClean).
  parsers    Re-download and rebuild tree-sitter parsers only.
  coc        (Re)install coc extensions only.
  --help     Show this help.

Interactive plugin commands inside nvim (see README for full guide):
  :PlugInstall    install plugins newly added to init.vim
  :PlugUpdate     upgrade all plugins to latest
  :PlugClean      remove plugins deleted from init.vim
  :PlugUpgrade    upgrade vim-plug itself

Notes:
  - Linux: nvim appimage goes to ~/Downloads/nvim/, clangd to ~/Downloads/clangd/.
    Add both to PATH in your shell rc (the script prints the exact lines).
  - macOS: uses Homebrew (brew install neovim llvm).
  - Idempotent: re-running `install` skips steps already satisfied.
EOF
}

# ---------- dispatch ----------
case "${1:-install}" in
install) do_install ;;
update) do_update ;;
clean) do_clean ;;
parsers) do_parsers ;;
coc) do_coc ;;
--help | -h) show_help ;;
*)
	err "unknown command: $1"
	show_help
	exit 1
	;;
esac
