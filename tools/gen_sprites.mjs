#!/usr/bin/env node
// Gera os sprites do FAROLEIRO em pixel art (32x32, paleta fixa).
//
//   node tools/gen_sprites.mjs
//
// Cada sprite e um mapa ASCII de 32 linhas: uma letra por pixel da paleta,
// '.' transparente. O SVG sai com um <path> por cor e `crispEdges`, sem
// gradiente nem antialias — e por isso fica nitido com filtro nearest.

import fs from "node:fs";
import path from "node:path";

const SIZE = 32;

const PALETTE = {
  k: "#0a0e10",
  c: "#123a42",
  C: "#1d5a66",
  l: "#2f8b98",
  g: "#c9a45a",
  G: "#8a6a34",
  s: "#d9a066",
  S: "#9c6238",
  h: "#0e171a",
  H: "#1b2b30",
  b: "#3a2a18",
  y: "#ffb347",
  Y: "#fff6d0",
  m: "#4a4f55",
  w: "#e8f4f8",
};

const SPRITES = {
  player: [
    "................................",
    "................................",
    "................................",
    "................................",
    "...........hhhhhhhhhh...........",
    "..........hhhhhhhhhhhh..........",
    "........hhhhhhhhhhhhhhhh........",
    "......hhhhhhhhhhhhhhhhhhhh......",
    "......hhhhhhhhhhhhhhhhhhhh......",
    "......kkkkkkkkkkkkkkkkkkkk......",
    "...........hhsssssshh...........",
    "...........hssssssssh...........",
    "...........hskssskssh...........",
    "...........hssssssssh...........",
    "...........hhsssssshh...........",
    "........lCCCCCCCCCCCCCCCC.......",
    ".......lCCCCCCCCCCCCCCCCCCC.....",
    ".......lCCCCCCCCCCCCCCCCCCC.....",
    ".......lCcccccccccccccccccC.....",
    ".......lCcccccccccccccccccs.....",
    ".......lCccccccccccccccccyyyy...",
    ".......lbggbbbbbbbbbbbbbyYYy....",
    ".......lCccccccccccccccccyYYy...",
    ".......lCccccccccccccccccyyyy...",
    ".......lCcccccccccccccccccC.....",
    ".......lCCCCCCCCCCCCCCCCCCC.....",
    "..........cccc....cccc..........",
    "..........cccc....cccc..........",
    "..........kkkk....kkkk..........",
    "..........kkkk....kkkk..........",
    "................................",
    "................................",
  ],
};

function validate(name, rows) {
  if (rows.length !== SIZE) {
    throw new Error(`${name}: ${rows.length} linhas (esperado ${SIZE})`);
  }
  rows.forEach((row, i) => {
    if (row.length > SIZE) {
      throw new Error(`${name}:${i} tem ${row.length} colunas (max ${SIZE})`);
    }
    for (const ch of row) {
      if (ch !== "." && !(ch in PALETTE)) {
        throw new Error(`${name}:${i} usa a cor desconhecida "${ch}"`);
      }
    }
  });
}

function toSvg(rows) {
  const byColor = new Map();
  rows.forEach((row, y) => {
    let x = 0;
    while (x < row.length) {
      const ch = row[x];
      if (ch === ".") {
        x += 1;
        continue;
      }
      let run = 1;
      while (x + run < row.length && row[x + run] === ch) run += 1;
      if (!byColor.has(ch)) byColor.set(ch, []);
      byColor.get(ch).push(`M${x} ${y}h${run}v1h-${run}z`);
      x += run;
    }
  });
  const paths = [...byColor.entries()]
    .map(([ch, segs]) => `  <path fill="${PALETTE[ch]}" d="${segs.join("")}"/>`)
    .join("\n");
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${SIZE}" height="${SIZE}" viewBox="0 0 ${SIZE} ${SIZE}" shape-rendering="crispEdges" image-rendering="pixelated">\n${paths}\n</svg>\n`;
}

function coverage(rows) {
  let filled = 0;
  for (const row of rows) for (const ch of row) if (ch !== ".") filled += 1;
  return filled;
}

const outDir = path.join("assets", "sprites");
fs.mkdirSync(outDir, { recursive: true });

for (const [name, rows] of Object.entries(SPRITES)) {
  validate(name, rows);
  const file = path.join(outDir, `${name}.svg`);
  fs.writeFileSync(file, toSvg(rows));
  const colors = new Set(rows.join("").replace(/\./g, "")).size;
  console.log(`${name}: ${coverage(rows)} px, ${colors} cores -> ${file}`);
}