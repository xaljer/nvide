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
    sql dockerfile
    # Editor / docs
    markdown
    make gitignore vim vimdoc
)

declare -A REPO_MAP=(
    [json5]="Joakker/tree-sitter-json5"
    [yaml]="ikatyang/tree-sitter-yaml"
    [perl]="ganezdragon/tree-sitter-perl"
    [c_sharp]="tree-sitter/tree-sitter-c-sharp"
    [dockerfile]="camdencheek/tree-sitter-dockerfile"
)

echo "========== Downloading parser repos to $SRC_DIR =========="
mkdir -p "$SRC_DIR"

for parser in "${PARSERS[@]}"; do
    echo "Downloading: $parser"
    rm -rf "$SRC_DIR/$parser"

    REPO=""
    if [[ -n "${REPO_MAP[$parser]-}" ]]; then
        REPO="${REPO_MAP[$parser]}"
    else
        REPO="tree-sitter/tree-sitter-$parser"
    fi

    git clone --depth 1 "https://github.com/$REPO" "$SRC_DIR/$parser" 2>/dev/null || {
        git clone --depth 1 "https://github.com/tree-sitter-grammars/tree-sitter-$parser" "$SRC_DIR/$parser" 2>/dev/null || {
            echo "  [SKIP] Failed to clone $parser"
            continue
        }
    }
    echo "  [OK] $parser"
done

echo "========== Done =========="
