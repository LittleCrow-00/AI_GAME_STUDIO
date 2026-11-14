# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/). Projeto em 0.x.

## [0.2.0] — 2026-11-14

### Adicionado

- **Fase 2 — Combate com peso.**
- `TimeService` (autoload): hitstop global usando tempo real, para não depender do
  `time_scale` que ele mesmo altera.
- **Hitstop** em abate (45 ms) e dano recebido (70 ms) — nunca por tick de feixe.
- **Screen shake** por trauma (`shake = trauma²`), em `Camera2D` no jogador.
- **Focos de luz** (`LightWell`): recarregam óleo a 26/s, mas reduzem a velocidade
  do jogador a 40%. Dois por sala, com `PointLight2D` próprio.
- **Quatro inimigos com comportamentos distintos**, todos estendendo `Enemy` e
  sobrescrevendo `_think`:
  - **Afogado** — perseguidor puro.
  - **Iara** — mantém distância, rajada de 3 projéteis que **drenam óleo**.
  - **Boto** — orbita, telegrafa 0,4 s e avança em linha reta.
  - **Curupira** — salta para trás do jogador quando ele tenta manter distância.
- **Telegrafia** de 0,35–0,55 s com *tint* pulsante antes de todo ataque especial.
- **`SpawnDirector`**: orçamento de ameaça por onda + teto de vivos, substituindo a
  contagem fixa de inimigos.
- **Pools**: 40 números de dano e 48 projéteis (sem *tweens* por acerto).
- **Tutorial quase imperceptível**: dicas em alpha 0,34, no máximo uma vez por run,
  sem modal e sem bloquear *input*; a lanterna encolhe conforme o óleo cai
  (ensino diegético).
- **Câmera** no jogador; números de dano agora vivem no mundo (seguem a câmera).
- Testes: 16 asserções (incluindo hitstop, focos de luz, pool e ciclo de sala).

### Mudado

- `Enemy` deixou de ter o cérebro embutido: agora é esqueleto + `_think` virtual.
- Arena passou a instanciar inimigos a partir de `EnemyData` (`.tres`) com
  orçamento, em vez de contagem fixa por onda.
- `Arena` usa `ProjectilePool` e cria os focos de luz.

### Conhecido

- Sem itens, Santuário, Cera, chefes ou áudio.
- Teto de 14 inimigos vivos; falta *benchmark* de estresse no Web.
- `WaveData` ainda não é usado como dado.

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