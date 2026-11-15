# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/). Projeto em 0.x.

## [0.9.0] — 2026-11-14

### Adicionado

- **Feedback de impacto**: `SparkPool` (pool fixo, 4 faíscas por acerto), sombra
  elíptica sob os inimigos e props no chão (pedras e tufos determinísticos).
- **Distribuicao**: preset `Windows Desktop` (x86_64, PCK embutido) gera
  `build/windows/Faroleiro.exe` (98 MB, template Godot 4.4.1, header `MZ` conferido).
  Preset `Android` (arm64, `com.littlecrow.faroleiro`) e workflow
  `.github/workflows/android.yml` para o APK: localmente o export aborta sem mensagem
  mesmo com SDK, build-tools 34, platform 34 e keystore de debug instalados, entao a
  rota do APK e o CI.
- **Rim light** (`assets/shaders/rim_light.gdshader`): um texel de luz na borda superior esquerda do
  personagem e dos inimigos, para a silhueta sair do chao escuro sem mudar o sprite.
- **6 itens novos**: Estopim (+1 dash), Pavio de Cera (+25% dano, -10% alcance),
  Olho de Vidro (+1 refração, -15% dano), Bolsão de Óleo (+30 óleo, -5% velocidade),
  Anzol de Osso (óleo por acerto) e Óleo Velho (-15% gasto, -10% dano). Banco em 31.
- **Áudio**: 7 efeitos novos sintetizados (`item`, `synergy`, `boss`, `death`,
  `ui_move`, `ui_confirm`, `unlock`), variação de pitch em hit, kill, pickup e
  dash, som de sinergia e de compra no título, e o drone abaixa na morte.
- **Controles de toque** (`scripts/ui/touch_controls.gd`): direcional analógico
  flutuante, botão de feixe (segurar) e dash, com mira automática no inimigo
  mais próximo — o mesmo `InputMap`, sem tocar no combate. Ativa no primeiro
  toque e força paisagem no celular.
- Testes: toque move, solta, atira e mira (101 asserções no `smoke_test`).
- **Fase 10 (passo visual) — pixel art.**
- Faroleiro redesenhado em 32×32 com paleta fixa (`tools/gen_sprites.mjs`), e os
  10 inimigos convertidos para a mesma paleta em 64×64
  (`tools/pixelate_sprites.mjs`).
- `docs/art.md` (grade, paleta, filtro nearest, escala inteira) e
  `docs/art/preview.html` com todos os sprites e capturas do build rodando.
- **Plano da Fase 9 (polimento)** em `docs/polish.md`: game feel/juice,
  áudio (buses, variação, música por bioma), 12 itens novos (8 imediatos + 4
  com comportamento) e 2 sinergias, com ordem de execução e teste cego de
  aceite. `docs/roadmap.md` aponta para o documento.
- **Fase 8 (publicação) — build web verificado em navegador real.**
- `tools/web_check.mjs`: sobe um servidor estático, abre o export Web em
  Chromium headless com WebGL2 e confere título, canvas 1280×720, cena de
  título desenhando, clique em **DESCER** abrindo a run e zero erros de
  console. Documentado em `docs/publish.md`.
- Preset Web passa a excluir `tests/*`: o build publicado não carrega mais os
  testes de fumaça (gzip do `index.wasm` caiu de 9,5 MB para 9,0 MB).
- **Fase 7 (passo 1) — inimigos que leem a luz.**
- **Boitatá** (`scripts/enemies/boitata.gd`): serpente de fogo que só a luz fere.
  Cada tique de feixe enche um medidor de calor; cheio, ela explode (onda de
  `DeathBurst` + dano em área), fica imune por 1,8 s e zera o calor. Inverte a
  decisão do jogo: aqui segurar o feixe é o erro.
- **Mapinguari** (`scripts/enemies/mapinguari.gd`): couraçado lento com muita
  vida. Dano de feixe a mais de 165 px é reduzido a 35% (o cone se espalha);
  de perto, dano cheio — mas a investida de 0,45 s pune quem fica colado.
- `DeathBurst` agora aceita `max_radius` e `duration` (reaproveitado pela
  explosão da Boitatá).
- Sprites SVG `assets/sprites/boitata.svg` e `mapinguari.svg`; cenas e
  `data/enemies/*.tres` com custo de ameaça 3 e 4.
- Testes: calor/imunidade da Boitatá e redução de dano do Mapinguari
  (71 asserções).
- **Cuca** (`scripts/enemies/cuca.gd`): 2º chefe e guardiã do Farol. Enquanto
  viva, aplica uma **aura** no `StatSheet` do jogador (`beam_range` ×0,65, origem
  `cuca`) — some quando ela morre. Ataca com sopro que drena óleo, mergulho
  (teleporte + rajada) e invocação de afogados. O `Main` agora escolhe o chefe
  por sala (`_boss_for`) e o `Arena` recebe `boss: EnemyData`.
- `Player.apply_aura()`: caminho único para modificadores temporários de inimigos.
- Testes: aura aplicada/removida e chefe na sala final (74 asserções).
- **Biomas como dados**: `resources/biome_data.gd` + `data/biomes/*.tres`
  (Maré Baixa, Fossa, Cripta Afundada, Coração do Farol). A arena lê a paleta
  do bioma (`Arena.biome`) e o `Main` escolhe por profundidade — o `match` de
  cores saiu da lógica.
- **Mula-sem-cabeça** (`scripts/enemies/mula.gd`): galopa em linha reta deixando
  rastro de fogo; depois do galope **ofega** (1,3 s) e apanha 40% mais.
- **FirePatch** (`scripts/gameplay/fire_patch.gd`): fogo no chão com dano por
  tique e tempo de vida.
- Testes: galope/fogo/ofego e dano/expiração do fogo (80 asserções).
- **Caipora** (`scripts/enemies/caipora.gd`): oitava criatura. Mantém distância e
  semeia **poças de escuridão**; dentro delas o feixe encolhe 45%. Se já há zonas
  demais, ela ri e teleporta.
- **DarkZone** (`scripts/gameplay/dark_zone.gd`): zona que aplica a aura
  `beam_range` (origem `dark_zone`) e só devolve a luz quando nenhuma outra zona
  cobre o jogador.
- Testes: escurecimento dentro/fora da zona e semeadura da Caipora
  (83 asserções).
- **Áudio procedural**: `tools/gen_audio.gd` sintetiza 8 WAVs (drone de 8 s em
  loop, impacto, abate, coleta, dash, dano, clique seco, sino). `AudioService`
  (autoload) escuta o `SignalBus` e toca; o drone é a única cama sonora.
- `Settings.muted` persistido e entrada **"Som: ligado/mudo"** no `ESC`.
- **Prólogo diegético**: a run começa no Farol apagado; a única ação é apontar o
  feixe para acendê-lo. `Farol.charge_by_light` faz o mesmo Farol servir de
  tutorial e de objetivo final (sem texto de instrução).
- `SignalBus`: `oil_pickup_collected` e `farol_lit`.
- Testes: 8 efeitos carregados, mute/desmute e prólogo (89 asserções).
- **Animação por gait**: `Enemy.GAITS` define passada, frequência, inclinação e
  balanço de 5 estilos (`walk`, `lope`, `slither`, `hover`, `crawl`). Cada
  `EnemyData` escolhe o seu (`anim_style`), então o sprite é o mesmo e o
  movimento dá a espécie.
- **Curva de dificuldade como dados**: `DifficultyData` + `data/difficulty/*.tres`
  (4 andares). O `Arena` não calcula mais `1 + 0.18 * sala`; o `Main` injeta o
  andar.
- **Mais 2 desbloqueios**: Casca Grossa (35) e Pavio Duplo (50) — 5 no total.
- Testes: gaits e curva de dificuldade (95 asserções).

### Corrigido

- **Escuro demais:** a cena estava com 88,7% dos pixels quase pretos (média de
  luminância 0,018). `CanvasModulate` subiu de 0,22 para 0,78, as paletas de
  bioma foram clareadas e o filtro nearest entrou no projeto — a média foi para
  0,054, os pretos para 0% e o p99 da área do feixe de 0,326 para 0,781.
- Sprites de inimigos agora usam escala inteira: sem meia-pixel, sem "tremer"
  ao andar.
- `TitleScreen` chamava `set_input_as_handled()` depois de trocar de cena, o que
  gerava `Condition "!is_inside_tree()" is true` no console ao clicar em
  **DESCER**. O envio do evento agora é protegido por `is_inside_tree()`.

---

## [0.8.0] — 2026-11-14

### Adicionado

- **Fase 6 — Meta-progressão (parcial).**
- **`SaveSystem`** (autoload): `user://save.json` com cera total, número de runs,
  recorde de pontos e desbloqueios. O caminho é um campo (`path`) para os testes
  usarem um arquivo temporário sem tocar no save real.
- **Tela de título** (`scenes/main/title.tscn`): é a nova cena inicial; mostra
  saldo, runs e recorde, lista os desbloqueios com preço e o botão `DESCER`.
- **`UnlockDatabase` + `UnlockData`**: 3 desbloqueios que entregam **itens
  iniciais** na próxima run — Pavio Extra (`folego`), Óleo Frio (`cera_velha`) e
  Lente de Estádio (`fragmento`).
- **`Main`** aplica os itens desbloqueados no início da run e deposita a cera da
  run no fim (vitória ou morte).
- Testes: save/load, compra sem e com cera, item inicial e integração no
  `run_test` (65 + 7 asserções).

### Alterado

- `run/main_scene` passa a ser a tela de título; a run é carregada por
  `change_scene_to_file`.

---

## [0.7.1] — 2026-11-14

### Adicionado

- **Elites:** 12% de chance por inimigo a partir da 2ª sala. `Enemy.make_elite()`
  aplica 2,2× de vida, 1,3× de dano de contato, 3× de cera e um anel dourado; o
  sprite cresce 15%. A chance é um `@export` da `Arena`.
- **Paleta por profundidade:** a arena muda de tom a cada andar (mais fria e roxa
  conforme você desce).

### Corrigido

- **Maldição na sala 0:** o filtro sorteava `randf()` por item, então uma maldição
  podia escapar (falha intermitente no teste). Agora a sala 0 exclui maldições de
  forma determinística; o sorteio de 12% vale só da 2ª sala em diante.

---

## [0.7.0] — 2026-11-14

### Adicionado

- **Menu de pausa e acessibilidade** (`ui/pause_menu.gd`, `ESC`): continuar,
  reduzir tremor de tela, reduzir flashes, reiniciar run e sair. Não abre sobre o
  Santuário nem depois do fim da run.
- **`Settings`** (autoload): preferências persistidas em `user://settings.cfg`.
- `ScreenShake` respeita "reduzir tremor" (25% do trauma); inimigos respeitam
  "reduzir flashes" (modulate mais suave).
- README com tabela de controles.

### Corrigido

- Nada novo nesta versão (correções da 0.6.1 seguem valendo).

---

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