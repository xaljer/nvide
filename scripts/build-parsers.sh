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
	TS_CLI="$ROOT_DIR/tools/cargo/bin/tree-sitter"
fi

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

# Build a single grammar: run `tree-sitter generate` (or fall back to the
# committed src/parser.c when generate fails -- e.g. grammar.js requires another
# grammar's npm package that isn't installed), compile the .so, copy queries.
#   $1 = parser name (output <name>.so)
#   $2 = grammar dir (contains grammar.js + src/)
#   $3 = repo root (for queries/<name>/ lookup in multi-grammar repos)
build_one() {
	local name="$1" dir="$2" repo="$3"
	echo "Building: $name"
	cd "$dir" || { echo "  [SKIP] missing $dir"; return 1; }

	if ! "$TS_CLI" generate 2>/dev/null; then
		# generate fails when grammar.js requires another grammar's npm package
		# (e.g. cpp requires 'tree-sitter-c/grammar') and node_modules isn't
		# installed. Tree-sitter grammar repos ship a pre-generated src/parser.c,
		# so fall back to compiling that instead of skipping the whole parser.
		if [ -f "src/parser.c" ]; then
			echo "  [WARN] generate failed for $name, using committed src/parser.c"
		else
			echo "  [SKIP] Failed to generate for $name (no src/parser.c)"
			cd /
			return 1
		fi
	fi

	gcc -shared -fPIC -O2 -I src -o "$PARSER_DIR/$name.so" \
		src/parser.c src/scanner.c src/scanner_wrapper.c 2>/dev/null || {
		gcc -shared -fPIC -O2 -I src -o "$PARSER_DIR/$name.so" \
			src/parser.c src/scanner.c 2>/dev/null || {
			gcc -shared -fPIC -O2 -I src -o "$PARSER_DIR/$name.so" \
				src/parser.c 2>/dev/null || {
				echo "  [SKIP] Failed to build $name"
				cd /
				return 1
			}
		}
	}

	# queries: prefer the grammar dir's own queries/, else repo-root queries/<name>/
	if [ -d "queries" ]; then
		mkdir -p "$QUERY_DIR/$name"
		cp queries/*.scm "$QUERY_DIR/$name/" 2>/dev/null || true
	elif [ -d "$repo/queries/$name" ]; then
		mkdir -p "$QUERY_DIR/$name"
		cp "$repo/queries/$name"/*.scm "$QUERY_DIR/$name/" 2>/dev/null || true
	fi

	echo "  [OK] $name"
	cd /
	return 0
}

for SRC_DIR in "$DOWNLOAD_DIR"/*; do
	[ -d "$SRC_DIR" ] || continue
	parser="$(basename "$SRC_DIR")"

	if [ -f "$SRC_DIR/tree-sitter.json" ]; then
		# New-layout repo with tree-sitter.json declaring one or more grammars.
		# Multi-grammar (typescript->typescript+tsx, markdown->markdown+markdown_inline,
		# xml->xml+dtd, php->php+php_only): build each declared grammar under its
		# own json name -- those ARE the nvim language names.
		# Single-grammar (e.g. c-sharp repo): the json name can differ from the
		# nvim-expected name (json "c-sharp" vs nvim "c_sharp"), so use the dir
		# name (the PARSERS entry, curated to match nvim) as the .so name.
		grammars="$(python3 -c 'import json, sys
data = json.load(open(sys.argv[1]))
for g in data.get("grammars", []):
    n = g.get("name") or ""
    p = g.get("path") or "."
    if n:
        print(f"{n}\t{p}")
' "$SRC_DIR/tree-sitter.json")"
		count="$(printf '%s\n' "$grammars" | grep -c . || true)"
		if [ "$count" -le 1 ]; then
			# single grammar: use dir name as .so name; resolve its path ("." -> repo root)
			gpath="$(printf '%s' "$grammars" | cut -f2)"
			gdir="$SRC_DIR"
			[ "$gpath" != "." ] && [ -d "$SRC_DIR/$gpath" ] && gdir="$SRC_DIR/$gpath"
			build_one "$parser" "$gdir" "$SRC_DIR" || true
		else
			while IFS=$'\t' read -r gname gpath; do
				[ -n "$gname" ] || continue
				if [ -d "$SRC_DIR/$gpath" ]; then
					build_one "$gname" "$SRC_DIR/$gpath" "$SRC_DIR" || true
				else
					echo "Building: $gname"
					echo "  [SKIP] path '$gpath' missing in $parser"
				fi
			done <<< "$grammars"
		fi
	else
		build_one "$parser" "$SRC_DIR" "$SRC_DIR" || true
	fi
done

# Re-apply nvide-specific query overrides that upstream grammar queries omit.
# build_one copies the grammar's queries/*.scm verbatim, so these overrides
# must be re-applied after every build to survive (idempotent).
ensure_inherits() {
	local lang="$1" query_file="$2" inherit_lang="$3"
	local f="$QUERY_DIR/$lang/$query_file"
	[ -f "$f" ] || return 0
	grep -q "^; inherits: $inherit_lang" "$f" && return 0
	# Prepend the directive. Read the body into a variable instead of mktemp:
	# BSD mktemp (macOS CI) requires a template arg and aborts under set -e.
	local body; body=$(cat "$f")
	{ printf '; inherits: %s\n' "$inherit_lang"; printf '%s\n' "$body"; } > "$f"
	echo "  [PATCH] $lang/$query_file: inherits $inherit_lang"
}
# cpp highlights.scm only carries cpp-specific captures; it expects to inherit
# the base C captures (primitive types, return, function_definition, ...) from
# the c query but ships no `; inherits` directive, so cpp files get almost no
# highlight. Prepend `; inherits: c` so nvim merges the c highlights.
ensure_inherits cpp highlights.scm c

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
