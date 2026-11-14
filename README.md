# FAROLEIRO

> Roguelite de ação top-down onde **a luz é sua arma, sua visão e sua munição**.

O mar subiu e engoliu o litoral. Você é o último Faroleiro e desce pela Fossa para
reacender os Faróis — mas a luz que você carrega é a única coisa que os habitantes
do escuro conseguem ver.

**Status:** Fase 1 (vertical slice jogável) — em desenvolvimento.

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
inimigos (gotas) ou ficando parado em um foco de luz. Sem óleo, você fica cego
por 1,5 s — e vulnerável.

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