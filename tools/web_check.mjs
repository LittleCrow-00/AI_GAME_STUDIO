#!/usr/bin/env node
// Verifica o build Web em um navegador real (headless).
//
// Uso:
//   npm i playwright-core && npx playwright-core install chromium
//   node tools/web_check.mjs [build/web]
//
// Confere: WebGL2 disponivel, canvas no tamanho pedido, cena de titulo
// desenhando, clique iniciando a run e nenhum erro de console.

import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright-core";

const ROOT = path.resolve(process.argv[2] ?? "build/web");
const PORT = 8931;

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".json": "application/json",
  ".png": "image/png",
  ".css": "text/css",
};

const server = http.createServer((req, res) => {
  const urlPath = decodeURIComponent(req.url.split("?")[0]);
  const filePath = path.join(ROOT, urlPath === "/" ? "index.html" : urlPath);
  if (!filePath.startsWith(ROOT)) {
    res.writeHead(403).end();
    return;
  }
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404).end("not found");
      return;
    }
    res.writeHead(200, {
      "Content-Type": MIME[path.extname(filePath)] ?? "application/octet-stream",
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
    });
    res.end(data);
  });
});

// Le a tela reduzida e conta cores/area clara: suficiente para provar que
// algo foi desenhado, sem depender de screenshot legivel por humano.
function sampleCanvas() {
  const canvas = document.querySelector("canvas");
  const copy = document.createElement("canvas");
  copy.width = 320;
  copy.height = 180;
  const ctx = copy.getContext("2d");
  ctx.drawImage(canvas, 0, 0, copy.width, copy.height);
  const data = ctx.getImageData(0, 0, copy.width, copy.height).data;
  const colors = new Set();
  let bright = 0;
  for (let i = 0; i < data.length; i += 4) {
    colors.add((data[i] >> 4) + "," + (data[i + 1] >> 4) + "," + (data[i + 2] >> 4));
    if (data[i] + data[i + 1] + data[i + 2] > 90) bright += 1;
  }
  return { colors: colors.size, brightRatio: +(bright / (data.length / 4)).toFixed(3) };
}

const failures = [];
const check = (ok, label) => {
  console.log(`${ok ? "PASS" : "FAIL"}  ${label}`);
  if (!ok) failures.push(label);
};

async function main() {
  if (!fs.existsSync(path.join(ROOT, "index.html"))) {
    console.error(`build nao encontrado em ${ROOT}`);
    process.exit(1);
  }
  await new Promise((resolve) => server.listen(PORT, resolve));

  const browser = await chromium.launch({
    args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--no-sandbox"],
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  page.on("pageerror", (e) => errors.push(`pageerror: ${e.message}`));
  page.on("console", (msg) => {
    if (msg.type() === "error") errors.push(`console: ${msg.text()}`);
  });

  await page.goto(`http://127.0.0.1:${PORT}/index.html`, { waitUntil: "load", timeout: 60000 });
  await page.waitForTimeout(9000);

  const boot = await page.evaluate(() => {
    const canvas = document.querySelector("canvas");
    const gl = canvas ? canvas.getContext("webgl2") : null;
    return {
      title: document.title,
      canvas: canvas ? [canvas.width, canvas.height] : null,
      webgl2: !!gl,
    };
  });
  check(boot.title === "FAROLEIRO", `titulo da pagina (${boot.title})`);
  check(boot.canvas !== null, `canvas presente (${boot.canvas})`);
  check(boot.canvas?.[0] === 1280 && boot.canvas?.[1] === 720, "canvas 1280x720");
  check(boot.webgl2, "WebGL2 disponivel");

  const titleFrame = await page.evaluate(sampleCanvas);
  check(titleFrame.colors > 20, `titulo desenha (${titleFrame.colors} cores)`);

  // Primeira linha do menu (DESCER) fica em y=286..318, x=340..940.
  await page.mouse.click(640, 300);
  await page.waitForTimeout(5000);
  const runFrame = await page.evaluate(sampleCanvas);
  check(runFrame.colors > 20, `run abre apos o clique (${runFrame.colors} cores)`);

  check(errors.length === 0, `sem erros de console (${errors.length})`);
  if (errors.length > 0) {
    for (const e of errors.slice(0, 5)) console.log(`      ${e}`);
  }

  await browser.close();
  server.close();

  console.log(failures.length === 0 ? "WEB CHECK: OK" : `WEB CHECK: ${failures.length} falha(s)`);
  process.exit(failures.length === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error("FALHA:", e.message);
  process.exit(1);
});