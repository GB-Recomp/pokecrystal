#!/usr/bin/env bash
#
# Regenerate the recompiled C sources in this repo from a fresh pret/pokecrystal
# build via gb-recompiled.
#
# Usage:
#   tools/regen.sh <path-to-pret/pokecrystal> <path-to-gb-recompiled>
#
# Requirements (on PATH):
#   - rgbds (rgbasm, rgblink, rgbfix) — to build the ROM
#   - make
#   - cmake, a C/C++ compiler — to build gbrecomp
#
# What it does:
#   1. (Re)build pret/pokecrystal to produce pokecrystal.gb + pokecrystal.sym
#   2. (Re)build gbrecomp from the gb-recompiled clone
#   3. Run gbrecomp with --emit-asset-loader --prefix-symbols on the ROM
#   4. BSS-ify the ROM data buffer (per pgbcomp project convention)
#   5. Copy the generated pokecrystal_*.c / .h / manifest / metadata into this
#      repo's root, overwriting the previous regen.
#
# After running, build to confirm:
#   cd build && cmake --build . -j$(nproc)
# and commit the changes.

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <pret/pokecrystal-path> <gb-recompiled-path>" >&2
    exit 1
fi

PRET_DIR="$(realpath "$1")"
GBRECOMP_DIR="$(realpath "$2")"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -d "$PRET_DIR" ]]; then
    echo "pret/pokecrystal directory not found: $PRET_DIR" >&2; exit 1
fi
if [[ ! -d "$GBRECOMP_DIR" ]]; then
    echo "gb-recompiled directory not found: $GBRECOMP_DIR" >&2; exit 1
fi

echo "[regen] pret  : $PRET_DIR"
echo "[regen] gbrec : $GBRECOMP_DIR"
echo "[regen] repo  : $REPO_DIR"

# 1. Build the ROM.
echo "[regen] Building pokecrystal ROM..."
(cd "$PRET_DIR" && make pokecrystal)

ROM="$PRET_DIR/pokecrystal.gb"
SYM="$PRET_DIR/pokecrystal.sym"
for f in "$ROM" "$SYM"; do
    [[ -f "$f" ]] || { echo "Missing $f" >&2; exit 1; }
done

# 2. Build gbrecomp.
echo "[regen] Building gbrecomp..."
(cd "$GBRECOMP_DIR" && cmake -B build -S . > /dev/null && cmake --build build -j"$(nproc)" --target gbrecomp)
GBRECOMP_BIN="$GBRECOMP_DIR/build/recompiler/gbrecomp"
[[ -x "$GBRECOMP_BIN" ]] || { echo "Missing $GBRECOMP_BIN" >&2; exit 1; }

# 3. Run recompiler.
OUT_DIR="$(mktemp -d)"
trap "rm -rf '$OUT_DIR'" EXIT
echo "[regen] Recompiling to $OUT_DIR..."
"$GBRECOMP_BIN" \
    --emit-asset-loader \
    --prefix-symbols \
    --symbols "$SYM" \
    -o "$OUT_DIR" \
    "$ROM"

# 4. BSS-ify ROM data.
BSS_TOOL="$GBRECOMP_DIR/tools/bss_rom_data.py"
[[ -f "$BSS_TOOL" ]] || BSS_TOOL=""  # tool may live in pgbcomp instead
if [[ -n "$BSS_TOOL" ]]; then
    echo "[regen] BSS-ifying ROM data..."
    python3 "$BSS_TOOL" "$OUT_DIR/pokecrystal_rom.c" "$OUT_DIR/pokecrystal.c"
fi

# 5. Copy back. Keep launcher_main.cpp and CMakeLists.txt — those are repo-
#    level, not generated.
echo "[regen] Copying generated sources into repo..."
cp -v "$OUT_DIR/pokecrystal_main.c" "$REPO_DIR/"
cp -v "$OUT_DIR/pokecrystal.c" "$REPO_DIR/"
cp -v "$OUT_DIR/pokecrystal_rom.c" "$REPO_DIR/"
cp -v "$OUT_DIR/pokecrystal_dispatch_chunk_"*.c "$REPO_DIR/"
cp -v "$OUT_DIR/pokecrystal_funcs_"*.c "$REPO_DIR/"
cp -v "$OUT_DIR/pokecrystal.h" "$REPO_DIR/"
cp -v "$OUT_DIR/pokecrystal_internal.h" "$REPO_DIR/"
cp -v "$OUT_DIR/assets_manifest_pokecrystal.h" "$REPO_DIR/"
cp -v "$OUT_DIR/pokecrystal_metadata.json" "$REPO_DIR/" 2>/dev/null || true

echo "[regen] Done. Build & test:"
echo "  (cd $REPO_DIR && cmake -B build -S . && cmake --build build -j\$(nproc))"
