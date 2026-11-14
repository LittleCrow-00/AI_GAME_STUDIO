# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/). Projeto em 0.x.

## [0.1.0] — 2026-11-14

### Adicionado

- **Fase 0 — Fundação.** `project.godot` (Godot 4.4, GL Compatibility, 1280×720),
  `.gitignore`, `icon.svg`, estrutura de pastas, `AGENTS.md`, `docs/`
  (design, arquitetura, roadmap).
- **CI/CD corrigido.** Workflow de deploy para GitHub Pages com tag Godot válida
  (`4.4.1`), download de *export templates*, etapa de importação, testes de
  fumaça e `.nojekyll`.
- **Núcleo.** `SignalBus` (barramento global de eventos) e `RngService`
  (aleatoriedade determinística por *stream*).
- **Sistemas de dados.** `StatModifier`, `StatSheet` (agregação com cache),
  `ItemData`, `EnemyData`, `WaveData`.
- **Jogador.** Movimento com aceleração/atrito, dash com i-frames e recarga por
  abate, gerenciamento de óleo com *estouro* (cegueira de 1,5 s), dano, cura,
  luz de visão.
- **Feixe.** Cone de luz com dano por *tick*, checagem de linha de visão contra
  o mundo e visual procedural (sem *assets*).
- **Inimigos.** `Enemy` base: perseguição, dano por contato, *knockback*, morte,
  *glow* *unshaded* para leitura no escuro.
- **Arena.** Paredes, 3 ondas por sala, dificuldade escalando por andar, fim de
  sala e *token* de onda.
- **Run.** `Main` orquestra 3 salas, vitória, derrota e reinício (`R`).
- **Apresentação.** HUD reativo (vida, óleo, dash, cadeia, pontos, ondas),
  números de dano flutuantes, escuridão com `CanvasModulate` + luz 2D.
- **Ressonância.** Cadeia de acertos com janela de 1,2 s; multiplicador
  `1 + 0,1 × cadeia` aplicado a pontos (não a dano).
- **Testes.** `tests/smoke_test.tscn`: 9 asserções cobrindo `StatSheet`,
  `Ressonância`, morte de inimigos e acerto/erro do feixe.

### Conhecido

- Sem hitstop, screen shake ou telegrafia de ataques especiais.
- Sem focos de luz: a única recarga de óleo hoje vem de abates.
- `StatSheet` existe mas ainda não alimenta o `Player`.
- Sem áudio, sem *save*, sem itens.