#!/usr/bin/env bash
set -euo pipefail

# Move to the script's directory so relative paths work regardless of invocation CWD
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

TEX_FILE="exo.tex"
BASENAME="${TEX_FILE%.tex}"

if [[ ! -f "$TEX_FILE" ]]; then
  echo "Error: $TEX_FILE not found." >&2
  exit 1
fi

if ! command -v pdflatex >/dev/null 2>&1; then
  echo "Error: pdflatex not found in PATH." >&2
  exit 1
fi

backup="${TEX_FILE}.bak"
cp -f "$TEX_FILE" "$backup"

cleanup_aux() {
  rm -f "${BASENAME}".{aux,log,out,toc,bbl,blg,fls,fdb_latexmk,nav,snm,vrb,lof,lot,idx,ilg,ind} 2>/dev/null || true
}

set_flags() {
  local sol="$1" hint="$2"
  local sol_val="false" hint_val="false"
  [[ "$sol" == "true" ]] && sol_val="true"
  [[ "$hint" == "true" ]] && hint_val="true"

  local tmp_file="${TEX_FILE}.tmp"
  sed -E \
    -e "s~^([[:space:]]*\\\\showsolutions)(true|false)~\\1${sol_val}~" \
    -e "s~^([[:space:]]*\\\\showhints)(true|false)~\\1${hint_val}~" \
    "$TEX_FILE" > "$tmp_file"
  mv -f "$tmp_file" "$TEX_FILE"
}

build_and_move() {
  local target="$1"
  cleanup_aux
  pdflatex -interaction=nonstopmode -halt-on-error "$TEX_FILE" >/dev/null
  pdflatex -interaction=nonstopmode -halt-on-error "$TEX_FILE" >/dev/null
  mv -f "${BASENAME}.pdf" "$target"
}

restore_original() {
  [[ -f "$backup" ]] && mv -f "$backup" "$TEX_FILE" || true
}

trap 'restore_original' EXIT

# 1) Without solutions and hints
set_flags false false
build_and_move "${BASENAME}_no_solutions_no_hints.pdf"
echo "Generated ${BASENAME}_no_solutions_no_hints.pdf"

# 2) With hints and without solutions
set_flags false true
build_and_move "${BASENAME}_hints_only.pdf"
echo "Generated ${BASENAME}_hints_only.pdf"

# 3) With both solutions and hints
set_flags true true
build_and_move "${BASENAME}_solutions_and_hints.pdf"
echo "Generated ${BASENAME}_solutions_and_hints.pdf"

# Restore original file and clean up
restore_original
cleanup_aux