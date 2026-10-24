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

# ---------- GitHub access helpers ----------
# GitHub (and its raw/releases CDNs) is unreachable from some networks:
# downloads hang instead of failing, which stalls the whole bootstrap. All
# GitHub fetches go through gh_curl: direct first, then proxy mirrors.
# GITHUB_MIRROR (a space-separated list of prefixes such as
# "https://ghfast.top") overrides the built-in mirror list.
GITHUB_MIRRORS=(${GITHUB_MIRROR:-"https://ghfast.top https://gh-proxy.com"})

# coreutils timeout is `gtimeout` on macOS (brew coreutils); without it we
# lose the hang protection but the mirror fallback still works.
TIMEOUT_BIN="$(command -v timeout || command -v gtimeout || true)"

run_to() {
	local secs="$1"; shift
	if [[ -n "$TIMEOUT_BIN" ]]; then "$TIMEOUT_BIN" "$secs" "$@"; else "$@"; fi
}

# gh_curl <github-url> [curl args...] -- curl a github.com /
# raw.githubusercontent.com URL through the mirror fallback chain. After the
# first direct attempt times out (exit 28), the rest skip direct entirely.
GH_CURL_DIRECT_DEAD=0
gh_curl() {
	local url="$1"; shift
	local m
	if [[ "$GH_CURL_DIRECT_DEAD" -eq 0 ]]; then
		if curl -fsSL --max-time 120 "$url" "$@"; then
			return 0
		fi
		[[ "$?" -eq 28 ]] && GH_CURL_DIRECT_DEAD=1
	fi
	for m in "${GITHUB_MIRRORS[@]}"; do
		curl -fsSL --max-time 120 "$m/$url" "$@" && return 0
	done
	return 1
}

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
		gh_curl https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage \
			-o "$dest/nvim" ||
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
			info "brew install neovim bash coreutils (bash 5+ for download-parsers.sh, coreutils for timeout)"
			brew install neovim bash coreutils
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
		gh_curl "https://github.com/clangd/clangd/releases/download/$ver/clangd-linux-$ver.zip" \
			-O --output-dir "$dest"
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

install_neocmakelsp() {
	step "2b" "neocmakelsp (for coc.nvim CMake LSP)"
	local dest="$HOME/.local/bin"
	if have neocmakelsp || [[ -x "$dest/neocmakelsp" ]]; then
		info "skip: neocmakelsp already installed"
		return
	fi
	mkdir -p "$dest"
	local ver="0.11.0"
	local arch
	case "$OS" in
	linux)
		case "$(uname -m)" in
			x86_64)  arch="x86_64-unknown-linux-gnu" ;;
			aarch64) arch="aarch64-unknown-linux-gnu" ;;
			*) warn "unsupported linux arch $(uname -m) -- install neocmakelsp manually (cargo install neocmakelsp)"; return ;;
		esac
		;;
	macos)
		arch="universal-apple-darwin"
		;;
	esac
	local asset="neocmakelsp-$arch.tar.gz"
	local tmpdir="$HOME/.cache/nvide-neocmakelsp-$$"
	mkdir -p "$tmpdir"
	info "downloading neocmakelsp $ver"
	if gh_curl "https://github.com/neocmakelsp/neocmakelsp/releases/download/v$ver/$asset" -o "$tmpdir/$asset"; then
		tar xzf "$tmpdir/$asset" -C "$tmpdir"
		install -m755 "$tmpdir/neocmakelsp" "$dest/neocmakelsp"
		info "neocmakelsp installed to $dest/neocmakelsp"
	else
		warn "download failed -- install neocmakelsp manually (cargo install neocmakelsp or GitHub releases)"
	fi
	rm -rf "$tmpdir"
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
	gh_curl https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
		-o "$dest" --create-dirs
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
	# -x alone is not enough: a tree copied from another OS keeps a foreign
	# binary there (exec format error), silently breaking `tree-sitter generate`.
	if [[ -x "$cargo_ts" ]] && "$cargo_ts" --version >/dev/null 2>&1; then
		info "skip: $cargo_ts present"
		return
	fi
	if [[ "$OS" == "macos" ]] && have brew; then
		# bottle install, by far the fastest; `cargo install` can also fail on
		# macOS setups where cargo fetches git deps over a broken SSH config
		info "brew install tree-sitter-cli"
		if brew install tree-sitter-cli >/dev/null 2>&1 && tree-sitter --version >/dev/null 2>&1; then
			return
		fi
		warn "brew tree-sitter-cli failed, falling back to cargo"
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
		gh_curl \
			https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh \
			| bash >/dev/null 2>&1 || {
			warn "cargo-binstall install failed — skipping binstall, trying release archive"
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
	if have cargo-binstall; then
		info "cargo binstall yazi-fm yazi-cli (prebuilt)"
		if run_to 300 cargo binstall "${binstall_args[@]}" yazi-fm yazi-cli >/dev/null 2>&1; then
			info "yazi installed to ~/.cargo/bin/"
			warn "ensure ~/.cargo/bin is on PATH (rustup adds it by default)"
			return
		fi
		warn "cargo binstall yazi failed (non-fatal) — trying release archive"
	fi
	# binstall itself downloads from GitHub and hangs on blocked networks;
	# fall back to the release zip through the mirror chain.
	local yarch
	case "$OS/$(uname -m)" in
	macos/arm64) yarch="aarch64-apple-darwin" ;;
	macos/x86_64) yarch="x86_64-apple-darwin" ;;
	linux/x86_64) yarch="x86_64-unknown-linux-musl" ;;
	linux/aarch64) yarch="aarch64-unknown-linux-musl" ;;
	*)
		warn "unsupported arch $(uname -m) for yazi release fallback"
		return
		;;
	esac
	local ztmp
	ztmp="$(mktemp -d)"
	if gh_curl "https://github.com/sxyazi/yazi/releases/latest/download/yazi-$yarch.zip" -o "$ztmp/yazi.zip" \
		&& unzip -oq "$ztmp/yazi.zip" -d "$ztmp" \
		&& install -m755 "$ztmp/yazi-$yarch/yazi" "$ztmp/yazi-$yarch/ya" "$HOME/.cargo/bin/"; then
		info "yazi installed to ~/.cargo/bin/ (release archive)"
	else
		warn "yazi release archive failed (non-fatal) — install yazi manually"
	fi
	rm -rf "$ztmp"
}

do_install() {
	info "${C_BOLD}nvide bootstrap ($OS)${C_RESET}"
	install_nvim
	prepend_install_dirs
	install_clangd
	prepend_install_dirs
	install_neocmakelsp
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
