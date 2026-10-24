#!/usr/bin/env bash
# Download tree-sitter parser repositories into fixed repo directory.
# Usage: ./scripts/download-parsers.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$ROOT_DIR/treesitter-src"

PARSERS=(
    # C/C++
    c cpp
    # Shell & scripting
    bash python ruby php perl lua
    # Web / frontend
    javascript typescript html css
    # Data / config
    json jsonc json5 yaml toml xml
    # Common backend/system languages
    go rust java kotlin c_sharp swift scala
    # SQL / infra
    sql dockerfile cmake
    # Editor / docs
    markdown
    make gitignore vim vimdoc
)

lookup_repo() {
    case "$1" in
        json5)     echo "Joakker/tree-sitter-json5" ;;
        yaml)      echo "ikatyang/tree-sitter-yaml" ;;
        perl)      echo "ganezdragon/tree-sitter-perl" ;;
        c_sharp)   echo "tree-sitter/tree-sitter-c-sharp" ;;
        dockerfile) echo "camdencheek/tree-sitter-dockerfile" ;;
        sql)       echo "DerekStride/tree-sitter-sql" ;;
        vimdoc)    echo "neovim/tree-sitter-vimdoc" ;;
        jsonc)     echo "https://gitlab.com/WhyNotHugo/tree-sitter-jsonc.git" ;;
        gitignore) echo "shunsambongi/tree-sitter-gitignore" ;;
        cmake)     echo "uyha/tree-sitter-cmake" ;;
        *)         echo "" ;;
    esac
}

# GitHub is unreachable from some networks (e.g. mainland China): a plain
# `git clone` hangs forever instead of failing, stalling the whole install.
# Fetch through a fallback chain: direct clone -> mirror clone -> mirror
# tarball. GITHUB_MIRROR (a space-separated list of proxy prefixes such as
# "https://ghfast.top") overrides the built-in mirror list; set it empty to
# disable mirrors.
GITHUB_MIRRORS=(${GITHUB_MIRROR:-"https://ghfast.top https://gh-proxy.com"})

# coreutils timeout is `gtimeout` on macOS (brew coreutils); without it we
# lose the hang protection but the fallback chain still works.
TIMEOUT_BIN="$(command -v timeout || command -v gtimeout || true)"

run_to() {
    local secs="$1"; shift
    if [[ -n "$TIMEOUT_BIN" ]]; then "$TIMEOUT_BIN" "$secs" "$@"; else "$@"; fi
}

# fetch_github <owner/repo> <dest> -- populate dest via the fallback chain.
# After the first direct-clone TIMEOUT (GitHub blackholed, not just a flaky
# failure) the remaining parsers skip the 60s direct wait entirely.
DIRECT_GITHUB_DEAD=0
fetch_github() {
    local repo="$1" dest="$2" m
    rm -rf "$dest"
    if [[ "$DIRECT_GITHUB_DEAD" -eq 0 ]]; then
        if run_to 60 git clone --depth 1 "https://github.com/$repo" "$dest" 2>/dev/null; then
            return 0
        fi
        [[ "$?" -eq 124 ]] && DIRECT_GITHUB_DEAD=1
    fi
    for m in "${GITHUB_MIRRORS[@]}"; do
        rm -rf "$dest"
        run_to 60 git clone --depth 1 "$m/https://github.com/$repo" "$dest" 2>/dev/null && return 0
        rm -rf "$dest"
        mkdir -p "$dest"
        if run_to 90 curl -fsSL "$m/https://github.com/$repo/archive/HEAD.tar.gz" 2>/dev/null \
            | tar xz -C "$dest" --strip-components=1 2>/dev/null; then
            return 0
        fi
        rm -rf "$dest"
    done
    return 1
}

echo "========== Downloading parser repos to $SRC_DIR =========="
mkdir -p "$SRC_DIR"

for parser in "${PARSERS[@]}"; do
    echo "Downloading: $parser"
    REPO="$(lookup_repo "$parser")"
    if [[ -z "$REPO" ]]; then
        REPO="tree-sitter/tree-sitter-$parser"
    fi

    # REPO may be a full URL (gitlab/etc) -- clone directly, no mirror chain;
    # else assume github and run the chain (with the grammars org as the
    # secondary source, as before).
    if [[ "$REPO" == *"://"* ]]; then
        rm -rf "$SRC_DIR/$parser"
        if ! run_to 120 git clone --depth 1 "$REPO" "$SRC_DIR/$parser" 2>/dev/null; then
            echo "  [SKIP] Failed to clone $parser"
            continue
        fi
    elif fetch_github "$REPO" "$SRC_DIR/$parser" \
        || fetch_github "tree-sitter-grammars/tree-sitter-$parser" "$SRC_DIR/$parser"; then
        :
    else
        echo "  [SKIP] Failed to fetch $parser"
        continue
    fi
    echo "  [OK] $parser"
done

echo "========== Done =========="
