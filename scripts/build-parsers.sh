#!/usr/bin/env bash
# Build tree-sitter parsers and copy to nvim/parser/ from fixed repo directories.
# Usage: ./scripts/build-parsers.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOWNLOAD_DIR="$ROOT_DIR/treesitter-src"
PARSER_DIR="$ROOT_DIR/parser"
QUERY_DIR="$ROOT_DIR/queries"
TS_CLI="$ROOT_DIR/tools/node_modules/.bin/tree-sitter"

if [ ! -x "$TS_CLI" ]; then
  TS_CLI="tree-sitter"
fi

mkdir -p "$PARSER_DIR" "$QUERY_DIR"

echo "========== Building tree-sitter parsers =========="
echo "Source: $DOWNLOAD_DIR"
echo "Output parser dir: $PARSER_DIR"
echo "Output query dir : $QUERY_DIR"
echo "Tree-sitter CLI : $TS_CLI"

if [ ! -d "$DOWNLOAD_DIR" ]; then
    echo "Source directory not found: $DOWNLOAD_DIR"
    echo "Run ./scripts/download-parsers.sh first."
    exit 1
fi

for SRC_DIR in "$DOWNLOAD_DIR"/*; do
    [ -d "$SRC_DIR" ] || continue
    parser="$(basename "$SRC_DIR")"
    echo "Building: $parser"

    cd "$SRC_DIR"

    if ! "$TS_CLI" generate 2>/dev/null; then
        echo "  [SKIP] Failed to generate for $parser"
        cd /
        continue
    fi

    gcc -shared -fPIC -O2 -I src -o "$PARSER_DIR/$parser.so" \
        src/parser.c \
        src/scanner.c \
        src/scanner_wrapper.c \
        2>/dev/null || {
        gcc -shared -fPIC -O2 -I src -o "$PARSER_DIR/$parser.so" \
            src/parser.c \
            src/scanner.c \
            2>/dev/null || {
            gcc -shared -fPIC -O2 -I src -o "$PARSER_DIR/$parser.so" \
                src/parser.c \
                2>/dev/null || {
                echo "  [SKIP] Failed to build $parser"
                cd /
                continue
            }
        }
    }

    if [ -d "queries" ]; then
        mkdir -p "$QUERY_DIR/$parser"
        cp queries/*.scm "$QUERY_DIR/$parser/" 2>/dev/null || true
    fi

    echo "  [OK] $parser"

    cd /
done

echo "========== Done =========="
ls -la "$PARSER_DIR"/

cat <<'EOF'

Neovim parser lookup rule (native treesitter):
- Neovim loads parser by language name from runtimepath `parser/` directories.
- Example: language "python" => `parser/python.so`
- This script outputs to: <repo>/parser/*.so

If your config root is on runtimepath (e.g. ~/.config/nvim), Neovim will find:
- ~/.config/nvim/parser/*.so
- ~/.config/nvim/queries/<lang>/*.scm

For this repo artifact layout (CI checkout path is nvim.config/nvim):
- nvim.config/nvim/parser/*.so
- nvim.config/nvim/queries/<lang>/*.scm

It works after extracting to your NVIM_APPNAME config root.
EOF
