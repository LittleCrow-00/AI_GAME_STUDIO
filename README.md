# FAROLEIRO

> Roguelite de ação top-down onde **a luz é sua arma, sua visão e sua munição**.

O mar subiu e engoliu o litoral. Você é o último Faroleiro e desce pela Fossa para
reacender os Faróis — mas a luz que você carrega é a única coisa que os habitantes
do escuro conseguem ver.

**Status:** Fase 3 (estrutura de run) — em desenvolvimento.

---

## Como o jogo funciona

É um roguelite de salas, tipo *The Binding of Isaac* — **mas a sua arma é uma
lanterna.**

1. **Atirar gasta óleo.** O feixe é sua arma, sua mira e sua visão.
2. **O óleo não regenera sozinho.** Ele volta ao **matar** (gotas) ou ao ficar
   **parado num foco de luz** (você anda a 40% da velocidade).
3. **Óleo em 0 → 1,5 s cego.** A lanterna apaga e você fica exposto.

Ou seja: **atirar demais te deixa cego — mas matar devolve óleo.** O erro não é
atacar; é segurar o botão em vazio. A decisão é constante: *atiro agora ou guardo
óleo para não ficar cego?*

**A run tem 4 salas:** combate → Santuário (1 de 3 itens) → combate →
Santuário → **Cobra Grande** → Santuário → **Farol** (vitória).

> Os itens têm **tags** (`lente`, `oleo`, `corpo`, `resonancia`). Combiná-las
> acende **sinergias** (Luz de Estádio, Cera Viva, Casco, Brasa Viva) que mudam
> mais do que um número — e as maldições aparecem só a partir da 2ª sala.
>
> **Cera** é a moeda da run: cai de abates e de salas limpas. No Santuário a
> 1ª escolha é grátis; as outras custam cera. A **cadeia** de acertos (10/25/50)
> devolve óleo, alcance e uma explosão de luz.

> A Cobra Grande é **imune no escuro**. Você precisa segurar a luz nela por 2,5 s
> para expô-la — a luta obriga a parar de desviar e apontar.

---

## Rodando localmente

Requisitos: **Godot 4.4+** (versão alvo: 4.4.x estável).

```bash
# abrir o editor
godot --path .

# ou rodar direto
godot --path .
```

**Controles**

| Ação | Tecla |
|---|---|
| Mover | `W A S D` |
| Mirar | Mouse |
| Feixe de luz | Botão esquerdo do mouse (segure) |
| Dash (i-frames) | `Shift` |
| Reiniciar | `R` |

**O feixe consome óleo.** O óleo não regenera sozinho: ele é recuperado ao matar
inimigos (gotas) ou ficando **parado dentro de um foco de luz** — mas dentro do
foco você anda a 40% da velocidade. Sem óleo, você fica cego por 1,5 s.

**Dica:** a lanterna encolhe quando o óleo está baixo. É o jogo te avisando.

---

## Testes

```bash
# peças isoladas (stats, itens, sinergias, limiares, loja, estresse)
godot --headless --path . res://tests/smoke_test.tscn

# run completa de ponta a ponta (4 salas → santuário → farol → vitória)
godot --headless --path . res://tests/run_test.tscn
```

O `smoke_test` cobre os sistemas que sustentam a arquitetura; o `run_test` dirige
a `Main` de verdade e é o gate do fluxo (pausa, compra, progressão e fim de run).

---

## Build Web

```bash
mkdir -p build/web
godot --headless --path . --import
godot --headless --path . --export-release "Web" build/web/index.html
```

O deploy para GitHub Pages é automático via GitHub Actions a cada push em `main`.

---

## Arte

- **Sprites:** `assets/sprites/*.svg` (jogador, 4 inimigos e chefe). O Godot importa
  SVG nativamente; `Enemy.sprite_texture` + `Sprite2D` cuidam de escala e rotação.
  Sem sprite, o desenho procedural antigo continua como fallback.
- **Ambiente, HUD e VFX:** procedurais (`_draw` + shader de vinheta). Nenhuma fonte,
  textura ou plugin externo.
- **Efeitos:** explosão de morte, faísca no impacto do feixe, rastro do dash, rastro
  do projétil e gota de óleo com anel.

## Documentação

| Arquivo | Conteúdo |
|---|---|
| [`docs/design.md`](docs/design.md) | Proposta criativa: universo, mecânica central, combate, progressão |
| [`docs/architecture.md`](docs/architecture.md) | Arquitetura técnica, sistemas, convenções |
| [`docs/roadmap.md`](docs/roadmap.md) | Fases, critérios de aceite e estado atual |
| [`AGENTS.md`](AGENTS.md) | Regras de código para agentes e contribuidores |

---

## Licença

Protótipo de jogo. Todo o conteúdo (código, arte procedural, texto) é original.