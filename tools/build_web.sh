#!/usr/bin/env bash
# Build de publicação do FAROLEIRO.
#
#   ./tools/build_web.sh            # usa `godot` do PATH
#   GODOT=/caminho/para/godot ./tools/build_web.sh
#
# Roda os dois testes, exporta o Web, gera o .zip do itch.io e mostra o
# tamanho real de transferência (gzip) — que é o número que importa no navegador.

set -euo pipefail

GODOT="${GODOT:-godot}"
OUT="build/web"
ZIP="build/faroleiro-web.zip"

echo "==> importando"
"$GODOT" --headless --path . --import

echo "==> testes de fumaça"
"$GODOT" --headless --path . res://tests/smoke_test.tscn

echo "==> teste de run ponta a ponta"
"$GODOT" --headless --path . res://tests/run_test.tscn

echo "==> exportando Web"
rm -rf "$OUT"
mkdir -p "$OUT"
"$GODOT" --headless --path . --export-release "Web" "$OUT/index.html"
touch "$OUT/.nojekyll"

echo "==> empacotando itch.io"
rm -f "$ZIP"
(cd "$OUT" && zip -qr "../faroleiro-web.zip" .)

echo
echo "Tamanho dos arquivos:"
ls -lh "$OUT/index.wasm" "$OUT/index.pck" | awk '{print "  " $9 " — " $5}'
echo "Transferência estimada (wasm+gzip):"
gzip -c "$OUT/index.wasm" | wc -c | awk '{printf "  %.1f MB\n", $1 / 1048576}'
echo "Pacote do itch: $(du -h "$ZIP" | cut -f1)"
echo
echo "Pronto: $ZIP"