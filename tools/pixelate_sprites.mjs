#!/usr/bin/env node
// Converte os sprites desenhados em SVG (gradiente suave) para pixel art:
// rasteriza, amosta na grade e achata em uma paleta fixa.
//
//   node tools/pixelate_sprites.mjs [arquivos...]
//
// O resultado continua sendo .svg (um <path> por cor), então nenhum script do
// jogo muda: só a textura fica com pixels nítidos.

import fs from "node:fs";
import path from "node:path";
import sharp from "sharp";

const SIZE = 64;
const PALETTE = [
  "#070b0d", "#0d1519", "#122229", "#1a333b",
  "#21505c", "#2c7382", "#3f9aa8", "#6cc0cc", "#a8e0e6",
  "#3a2a18", "#6b4a22", "#a8763a", "#d9a066", "#f2c98a", "#fff0c8",
  "#4a1414", "#7f2420", "#b83a2c", "#e8623c",
  "#1d3a1a", "#2f5c26", "#4f8a34", "#7ab84a",
  "#2a1a3a", "#4a2f66", "#7a55a8",
  "#e8f4f8", "#4a4f55", "#8a949a",
].map((hex) => [
  parseInt(hex.slice(1, 3), 16),
  parseInt(hex.slice(3, 5), 16),
  parseInt(hex.slice(5, 7), 16),
]);

const files = process.argv.slice(2);
const targets = files.length > 0 ? files : fs
  .readdirSync("assets/sprites")
  .filter((f) => f.endsWith(".svg") && f !== "player.svg")
  .map((f) => path.join("assets/sprites", f));

function nearest(r, g, b) {
  let best = 0;
  let bestDist = Infinity;
  for (let i = 0; i < PALETTE.length; i += 1) {
    const [pr, pg, pb] = PALETTE[i];
    const d = (r - pr) ** 2 + (g - pg) ** 2 + (b - pb) ** 2;
    if (d < bestDist) {
      bestDist = d;
      best = i;
    }
  }
  return best;
}

function toSvg(rows) {
  const byColor = new Map();
  rows.forEach((row, y) => {
    let x = 0;
    while (x < row.length) {
      const idx = row[x];
      if (idx < 0) {
        x += 1;
        continue;
      }
      let run = 1;
      while (x + run < row.length && row[x + run] === idx) run += 1;
      if (!byColor.has(idx)) byColor.set(idx, []);
      byColor.get(idx).push(`M${x} ${y}h${run}v1h-${run}z`);
      x += run;
    }
  });
  const paths = [...byColor.entries()]
    .map(([idx, segs]) => `  <path fill="#${PALETTE[idx].map((c) => c.toString(16).padStart(2, "0")).join("")}" d="${segs.join("")}"/>`)
    .join("\n");
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${SIZE}" height="${SIZE}" viewBox="0 0 ${SIZE} ${SIZE}" shape-rendering="crispEdges" image-rendering="pixelated">\n${paths}\n</svg>\n`;
}

for (const file of targets) {
  const source = fs.readFileSync(file);
  const { data, info } = await sharp(source, { density: 384 })
    .resize(SIZE, SIZE, { fit: "fill", kernel: "nearest" })
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const rows = [];
  let filled = 0;
  for (let y = 0; y < SIZE; y += 1) {
    const row = [];
    for (let x = 0; x < SIZE; x += 1) {
      const i = (y * info.width + x) * 4;
      if (data[i + 3] < 110) {
        row.push(-1);
        continue;
      }
      row.push(nearest(data[i], data[i + 1], data[i + 2]));
      filled += 1;
    }
    rows.push(row);
  }

  const svg = toSvg(rows);
  fs.writeFileSync(file, svg);
  const colors = new Set(rows.flat().filter((v) => v >= 0)).size;
  console.log(`${path.basename(file)}: ${filled} px, ${colors} cores, ${(svg.length / 1024).toFixed(1)} KB`);
}