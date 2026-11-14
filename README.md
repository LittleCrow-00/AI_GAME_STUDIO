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

**A run tem 4 salas:** combate → Santuário (1 de 3 oferendas) → combate →
Santuário → **Cobra Grande** → Santuário → **Farol** (vitória).

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
godot --headless --path . res://tests/smoke_test.tscn
```

Cobre os sistemas que sustentam a arquitetura: `StatSheet`, `Ressonância`,
morte de inimigos e o acerto do feixe.

---

## Build Web

```bash
mkdir -p build/web
godot --headless --path . --import
godot --headless --path . --export-release "Web" build/web/index.html
```

O deploy para GitHub Pages é automático via GitHub Actions a cada push em `main`.

---

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