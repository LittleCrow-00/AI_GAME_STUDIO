# Arte — pixel art

O FAROLEIRO usa **pixel art gerada por código**. Nada de banco de sprites de
terceiros: os desenhos saem de mapas ASCII e de conversões determinísticas, e
ficam versionados como `.svg` (que o Godot rasteriza em textura).

## Regras

1. **Grade e paleta fixas.** O Faroleiro é 32×32; os inimigos, 64×64. A paleta
   é a mesma para todos (ver `tools/gen_sprites.mjs` e `tools/pixelate_sprites.mjs`).
2. **Sem gradiente, sem antialias.** Cada cor é um `<path>` com
   `shape-rendering="crispEdges"`; o SVG tem `image-rendering="pixelated"`.
3. **Filtro nearest.** `rendering/textures/canvas_textures/default_texture_filter=0`
   no `project.godot`. Sem isso, o pixel art vira sopa.
4. **Escala inteira.** Personagem e inimigos usam `roundf()` na escala: 2×, 3×,
   nunca 1,4×.
5. **Silhueta primeiro.** O desenho tem que ser legível em preto: se a forma
   não fecha, a cor não conserta.
6. **Rim light de 1 px.** A borda superior/esquerda recebe um tom mais claro;
   é o que separa o personagem do chão escuro.

## Pipeline

```bash
node tools/gen_sprites.mjs        # sprites autorais (mapa ASCII -> .svg)
node tools/pixelate_sprites.mjs   # sprites convertidos de gradiente -> pixel art
```

`pixelate_sprites.mjs` usa `sharp` (dependência de desenvolvimento, não vai no
jogo): rasteriza o SVG original, amostra na grade e achata em uma paleta de 29
cores. O resultado continua `.svg`, então nenhum script muda.

## Como ver

- `docs/art/preview.html` — todos os sprites ampliados, com a paleta.
- `docs/art/shot_title.png`, `shot_run.png`, `shot_player.png` — capturas do
  build Web rodando (Chromium headless, 1280×720).

## Medição

O "está escuro demais" virou número: o build é medido em luminância
(luminância = 0,2126 R + 0,7152 G + 0,0722 B).

| Cena | Antes | Depois |
|---|---|---|
| Média da run | 0,018 | 0,054 |
| Pixels quase pretos (<0,02) | 88,7% | 0% |
| p99 (área do feixe) | 0,326 | 0,781 |

A meta é **claro o suficiente para ler o chão, escuro o suficiente para a luz
importar**: p50 da run entre 0,05 e 0,12, p99 acima de 0,7 na área do feixe.