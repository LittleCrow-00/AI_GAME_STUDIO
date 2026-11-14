# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/). Projeto em 0.x.

## [0.6.1] — 2026-11-14

### Adicionado

- **`tests/run_test.tscn`** — teste de run ponta a ponta: limpa as 4 salas, compra
  um item no Santuário, acende o Farol e valida a vitória (6 asserções). Entra no
  CI e em `AGENTS.md`.

### Corrigido

- **Curupira** podia piscar para dentro de paredes: agora testa até 8 pontos
  livres (`intersect_point`) e desiste se não houver lugar.

### Alterado

- Sprites ganham animação por código: balanço ao andar, achatamento ao apanhar e
  pulso ao telegrafar (sem sprites animados).

---

## [0.6.0] — 2026-11-14

### Adicionado

- **Identidade visual (Fase 7, parcial).**
- **Sprites SVG** em `assets/sprites/`: jogador, Afogado, Iara, Boto, Curupira e
  Cobra Grande. `Enemy` ganha `sprite_texture` + `Sprite2D` escalado pelo
  `body_radius`, com rotação para o alvo; sem sprite, o desenho procedural antigo
  continua como fallback.
- **Arena** redesenhada: lajes com variação determinística, poças com brilho,
  paredes com borda e pilares nos cantos.
- **Vinheta** em shader (`ui/vignette.gd`), entre o mundo e a UI.
- **VFX:** `DeathBurst` (fragmentos ao matar), faísca no impacto do feixe, rastro
  do dash, rastro e brilho do projétil, gota de óleo com anel girando.
- **HUD:** ícones de vida/óleo/dash, moeda de cera desenhada, barra do próximo
  limiar da cadeia.
- **Santuário:** selo procedural por tag (`ui/item_sigil.gd`) no card.
- **Sumário:** régua divisória e linha de cera.

### Alterado

- `Player` desenha o corpo via sprite e mantém lanterna, sombra, rastro e
  i-frames em código (lanterna aponta para a mira).
- `LightWell` ganha anel de runas e brasas subindo.
- UI do jogo passa a viver na camada 10; vinheta na 5.

---

## [0.5.0] — 2026-11-14

### Adicionado

- **Fase 5 — Ressonância e economia.**
- **Limiares de cadeia** data-driven (`data/thresholds/chain_10|25|50.tres`):
  - **10 · Estopim** — +10 de óleo na hora
  - **25 · Alcance Longo** — +20% de alcance do feixe por 6 s
  - **50 · Estouro** — explosão de luz (40 de dano, raio 130)
- **`ThresholdData`** + **`ThresholdDatabase`** (autoload): o `Ressonancia`
  detecta a passagem e emite `threshold_reached`; o `Player` aplica (óleo,
  modificadores temporários com `StatSheet.remove_source`, explosão). Buffs
  temporários expiram e restauram os atributos.
- **Cera** como moeda da run: `EnemyData.cera_drop` / `Enemy.cera_drop` (1 por
  abate, por tipo), bônus por sala limpa (`room_clear_cera`), `SignalBus.cera_changed`.
- **Loja no Santuário:** a 1ª escolha é grátis, as seguintes custam cera
  (`shop_price_base` + `shop_price_step` por andar). O Santuário emite
  `purchase_requested`; o `Main` valida a carteira, cobra e devolve o saldo com
  `set_cera()`. `ESC`/`ENTER` desce sem comprar; item comprado fica "LEVADO".
- **HUD:** saldo de cera no readout e barra do próximo limiar da cadeia.

### Alterado

- `Sanctuary` virou loja (preço por card, recusa visual sem cera suficiente).
- `Player._detonate()` parametrizado (dano/raio), usado por itens e limiares.
- Testes de fumaça: limiares, loja, `cera_drop` e estresse de 60 inimigos
  (**47 asserções, 0 falhas**; 6,9 ms/frame headless).

---

## [0.4.0] — 2026-11-14

### Adicionado

- **Fase 4 — Itens e sinergias.**
- **25 itens** em `data/items/*.tres` (Lente, Pavio, Óleo, Casca, Corpo,
  Ressonância e Maldições), cada um com **um** comportamento no máximo.
- **`ItemData`** (`resources/item_data.gd`): modificadores, tags, stacks e
  `behavior_id` (`refraction`, `oil_on_hit`, `nova`, `pierce`).
- **`Inventory`** (`resources/inventory.gd`): única ponte entre itens e atributos.
  Agrega modificadores por stack e reconhece **sinergias compostas**:
  - **Luz de Estádio** — 2× `lente` + refração → +10% dano e alcance
  - **Cera Viva** — 2× `oleo` + óleo por acerto → +1 de óleo por abate
  - **Casco** — 3× `corpo` → +1 carga de dash
  - **Brasa Viva** — 2× `resonancia` + explosão → explosão 1,5× maior
- **`ItemDatabase`** (autoload) com sorteio sem repetição e **maldições** (12% a
  partir da 2ª sala; sala 0 nunca oferece maldição).
- **`Beam`**: **refração** (até 4 feixes extras) e **perfuração** (`pierce`
  ignora paredes no LOS).
- **`Player`**: `apply_item()`, recálculo via `Inventory`, óleo por acerto,
  explosão ao matar (`_in_nova` evita recursão) e bônus de óleo por abate.
- **Santuário** mostra nome, raridade (com "maldito"), tags e descrição do item.

### Removido

- Sistema antigo de oferendas: `BoonData`, `BoonDatabase`, `data/boons/*.tres` e
  `Player.apply_boon()`.

### Alterado

- `main.gd` sorteia itens por andar (`ItemDatabase.draw(3, room + 1)`).
- Testes de fumaça cobrem itens, stacks, refração e as 4 sinergias (33 asserções).

---

## [0.3.0] — 2026-11-14

### Adicionado

- **Fase 3 — Estrutura de run.**
- **Santuário** (`Sanctuary`): escolha de 1 entre 3 oferendas, com teclado (1/2/3)
  ou clique. Pausa a árvore durante a escolha.
- **9 oferendas** em `data/boons/*.tres` (Lente Maior, Pavio Grosso, Óleo Frio,
  Casca Grossa, Passo Leve, Fôlego, Foco Rápido, Ângulo Largo, Cera Velha).
- **`StatSheet` ligado ao `Player`**: vida, óleo, dano, alcance, ângulo, cadência,
  velocidade, cargas de dash e recarga em focos passam a ser derivados de
  modificadores — não mais constantes no script.
- **`BoonDatabase`** (autoload) com a lista de oferendas e o sorteio sem repetição.
- **Chefe 1: Cobra Grande** (`CobraGrande`):
  - **Blindada no escuro** (15% do dano) e **exposta** após 2,5 s de luz contínua.
  - Ataques: investida (telegrafa 0,6 s), rajada radial de 12 projéteis e
    invocação de 2 afogados.
  - Barra de vida de chefe no HUD.
  - Ao morrer, elimina os invocados.
- **Sala do Farol** (`Farol`): ilumina depois de limpa; o jogador precisa ficar
  2 s dentro do círculo para vencer. Saiu, o progresso escorre.
- **Tela de fim de run** (`RunSummary`): salas limpas, abates, pontos, tempo e
  semente.
- **Run completa**: 4 salas, chefe na sala 3 e Farol na sala 4.
- Testes: 22 asserções (incluindo blindagem/exposição do chefe, oferendas e Farol).
- Integração validada de ponta a ponta: 4 salas, chefe derrotado, Farol aceso,
  estado VITÓRIA.

### Mudado

- `Main` passou a controlar 4 salas, santuário, vitória e derrota.
- `Player` deixou de usar `@export` para valores derivados; os `base_*` alimentam
  o `StatSheet`.
- **Cegueira por estouro agora é real:** com óleo em 0, a lanterna cai para 6% de
  energia (tela quase preta) durante 1,5 s. Antes era só uma redução de luz.

### Conhecido

- Itens de run ainda não existem (só oferendas de santuário).
- Sem áudio, sem Cera/loja, sem meta-progressão.
- Sem *benchmark* de estresse no Web.

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