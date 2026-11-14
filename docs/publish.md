# Publicação

O FAROLEIRO é **gratuito**. Distribuição prevista: **itch.io** (página HTML5) e
**GitHub Pages** (build de CI). Nada de paywall — a decisão é do autor, e está
registrada no `README.md`.

## Antes de publicar (transparência)

O jogo é feito com apoio de IA. A página deve dizer isso com todas as letras:

> Jogo de autoria própria feito com apoio de IA (Godot 4, GDScript). Arte
> procedural/SVG, áudio sintetizado e código revisados manualmente.

Nomes de terceiros (Binding of Isaac, Balatro etc.) **não** aparecem como
referência oficial: as semelhanças são de gênero, não de conteúdo.

## Build local

```bash
./tools/build_web.sh              # ou GODOT=/caminho/godot ./tools/build_web.sh
```

Gera `build/web/` e `build/faroleiro-web.zip` (este é o arquivo do itch).

## GitHub Pages

O workflow `.github/workflows/deploy.yml` roda em todo push na `main`:

1. instala os templates de exportação do Godot 4.4.1,
2. roda `smoke_test.tscn` e `run_test.tscn` (se falharem, o deploy não acontece),
3. exporta o Web e publica o artefato.

Habilite **Settings → Pages → Source: GitHub Actions** na primeira vez. A URL
final fica em `https://<usuario>.github.io/<repo>/`.

## itch.io

1. **Create new project** → tipo **HTML**.
2. Upload do `build/faroleiro-web.zip`.
3. Marque **"This file will be played in the browser"**.
4. Viewport **1280×720**, *Embed in page* liberado.
5. Preço: **free** (ou "no minimum price", se quiser gorjeta).
6. Descrição: o que é o jogo, controles, e a nota de transparência acima.

### Tamanho

| Métrica | Valor medido |
|---|---|
| `index.wasm` | ~43 MB |
| `index.wasm` gzip | ~9,5 MB |
| `index.pck` | ~0,5 MB |

O número que importa é o gzip/transferência: ~10 MB. Se o itch reclamar do
tamanho do upload, o `.zip` é a forma correta (ele comprime na entrega).
## Verificação no navegador

Antes de publicar, o build exportado é aberto em um Chromium headless com
WebGL2 real (SwiftShader). O teste prova o que o `--headless` do Godot não
prova: que o WASM sobe no navegador, que o canvas nasce em 1280×720, que a
tela de título desenha e que o clique em **DESCER** abre a run — tudo sem erro
de console.

```bash
npm i playwright-core
npx playwright-core install chromium
node tools/web_check.mjs build/web
```

Resultado medido em 2026-11-14:

```
PASS  titulo da pagina (FAROLEIRO)
PASS  canvas presente (1280,720)
PASS  canvas 1280x720
PASS  WebGL2 disponivel
PASS  titulo desenha (78 cores)
PASS  run abre apos o clique (62 cores)
PASS  sem erros de console (0)
WEB CHECK: OK
```

O FPS medido nesse ambiente (~14) é do rasterizador por software e não
representa hardware real; use `--headless --path .` e o teste de estresse
(60 inimigos + 48 projéteis) para orçamento de CPU.
