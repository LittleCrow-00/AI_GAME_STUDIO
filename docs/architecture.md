# FAROLEIRO — Arquitetura

> Como o código é organizado e por quê. Leia junto com `AGENTS.md`.

---

## 1. Princípios

1. **Data-driven.** Inimigos, itens, oferendas, ondas e salas são `Resource`
   (`.tres`). Zero lógica em arquivo de dados.
2. **Event-driven.** `SignalBus` (autoload) desacopla combate de UI, áudio e VFX.
   Emissor nunca sabe quem escuta.
3. **Composição sobre herança.** Inimigos trocam o cérebro (`_think`), não o
   corpo. Oferendas são `StatModifier`, não subclasses.
4. **Pipeline de dano único.** `take_damage(amount, source_position)` é a
   interface comum a tudo que recebe dano.
5. **Atributos derivados.** Nada de dano/velocidade no meio da lógica: tudo vem
   do `StatSheet`, que agrega modificadores com cache.
6. **Determinismo.** `RngService` mantém *streams* independentes por semente.
7. **Pool quando doer.** Projéteis e números de dano já são *poolados*.

## 2. Camadas

```
┌─────────────────────────────────────────────────────┐
│ APRESENTAÇÃO  HUD, Santuário, Sumário, números,     │  lê estado, nunca altera regras
│               câmera                                │
├─────────────────────────────────────────────────────┤
│ GAMEPLAY      Player, Beam, Enemy, CobraGrande,     │  usa sistemas
│               Arena, Farol                          │
├─────────────────────────────────────────────────────┤
│ SISTEMAS      Ressonância, SpawnDirector, Tutorial, │  não conhecem UI
│               RunManager, Stats                     │
├─────────────────────────────────────────────────────┤
│ NÚCLEO        SignalBus, RngService, TimeService,   │  autoloads + Resources
│               ItemDatabase, Inventory, dados        │
└─────────────────────────────────────────────────────┘
```

Regra prática: **apresentação nunca altera regras; sistemas não conhecem UI.**

## 3. Mapa de arquivos (estado atual)

```
autoload/
  signal_bus.gd          barramento global de eventos
  rng_service.gd         aleatoriedade determinística por stream
  time_service.gd        hitstop global (altera Engine.time_scale)
  item_database.gd       lista de itens + sorteio (sem repetição, maldições)
  threshold_database.gd  limiares da Ressonância (10/25/50) + cruzamento
  settings.gd            preferências (tremor/flashes/som) em user://settings.cfg
  audio_service.gd       toca os WAVs a partir do SignalBus (drone + efeitos)
  unlock_database.gd     desbloqueios da meta-progressão + consulta de itens iniciais
  save_system.gd         save JSON em user://save.json (cera, runs, recorde, unlocks)
resources/
  stat_modifier.gd       modificador atômico (ADD/MULTIPLY)
  stat_sheet.gd          agregação com cache (base → ADD → MULTIPLY)
  item_data.gd           item de run (.tres): modificadores + 1 comportamento
  inventory.gd           itens → modificadores, sinergias compostas, comportamentos
  threshold_data.gd      recompensa de limiar (.tres): óleo, modificador, explosão
  unlock_data.gd         desbloqueio (.tres): id, nome, custo, item inicial
  biome_data.gd          paleta do bioma (.tres)
  enemy_data.gd          template de inimigo (.tres)
  wave_data.gd           definição de onda (.tres) — ainda não usado
data/
  enemies/               afogado, iara, boto, curupira, cobra_grande (.tres)
  items/                 25 itens (.tres)
  thresholds/            chain_10, chain_25, chain_50 (.tres)
  unlocks/               pavio_extra, oleo_frio, lente_estadio (.tres)
  biomes/                mare_baixa, fossa, cripta_afundada, coracao_do_farol
assets/
  audio/                 8 WAVs gerados por tools/gen_audio.gd
  sprites/               jogador, 4 inimigos e chefe em SVG (Sprite2D)
tools/
  gen_audio.gd           sintetiza os WAVs do jogo (--script, headless)
scripts/
  player/player.gd       movimento, dash, óleo, focos, visão, StatSheet
  beam/beam.gd           cone de luz: dano por tick + LOS + visual procedural
  enemies/enemy_base.gd  esqueleto: vida, contato, morte, telegrafia
  enemies/afogado.gd     perseguidor puro
  enemies/iara.gd        mantém distância, rajada que drena óleo
  enemies/boto.gd        orbita, telegrafa, avança em linha reta
  enemies/curupira.gd    salta para trás do jogador
  enemies/cobra_grande.gd chefe: blindagem/exposição + 3 ataques
  enemies/cuca.gd        chefe 2: aura de escuridão + 3 ataques
  enemies/mula.gd        galope em linha reta, rastro de fogo, ofego
  enemies/caipora.gd     semeia zonas de escuridão, teleporta
  systems/ressonancia.gd cadeia de acertos, multiplicador, pontos
  systems/spawn_director.gd orçamento de ameaça + teto de vivos
  vfx/death_burst.gd     explosão de fragmentos ao matar (visual puro)
  vfx/screen_shake.gd    tremor por trauma
  ui/vignette.gd         vinheta em shader (camada 5, abaixo da UI)
  ui/item_sigil.gd       selo procedural do item (por tag)
  ui/pause_menu.gd       pausa + acessibilidade (camada 40)
  systems/tutorial_director.gd dicas de alpha baixo, 1x por run
  gameplay/arena.gd      geometria, focos, pool, ondas, chefe, farol
  gameplay/light_well.gd foco de luz: recarrega óleo, penaliza movimento
  gameplay/fire_patch.gd fogo no chão deixado pela Mula (dano por tique)
  gameplay/dark_zone.gd  poça de escuridão: encolhe o feixe de quem entra
  gameplay/farol.gd      farol: carrega por proximidade (final) ou pelo feixe (prólogo)
  gameplay/main.gd       sequência de salas, santuário, vitória, derrota
  ui/hud.gd              barras, leitura, dicas, chefe
  ui/sanctuary.gd        escolha de 1 entre 3 oferendas (pausa a árvore)
  ui/summary.gd          recibo da run
  ui/title.gd            tela de título: saldo, recorde e desbloqueios (scene root)
  vfx/light_factory.gd   texturas procedurais de luz
  vfx/screen_shake.gd    trauma-based shake na Camera2D
  vfx/damage_numbers.gd  números flutuantes com pool (Node2D, segue a câmera)
  vfx/projectile.gd      projétil reciclado (Area2D)
  vfx/projectile_pool.gd pool fixo de 48 projéteis
  pickups/oil_drop.gd    gota de óleo com delay e homing
scenes/                  espelha scripts/ (mesmos nomes)
tests/smoke_test.tscn    gate de regressão (22 asserções)
```

## 4. Fluxo de dados

### Run
```
Main._start_room(index)
  → Arena.setup(index) → add_child → Arena._ready
      → ProjectilePool + LightWells + (Farol?) + SpawnDirector
      → start() → _start_wave()
  → sala limpa → Main pausa a árvore → Sanctuary.open(itens, cera, preço)
      → Sanctuary.purchase_requested(item, price)
      → Main valida a carteira → Player.apply_item() → sanctuary.set_cera()
      → ESC → sanctuary.closed → Main._start_room(index + 1)
  → sala 4 (Farol) acesa → VITÓRIA
```

### Economia
```
Enemy._die() → SignalBus.enemy_died(enemy, pos) → Main._add_cera(enemy.cera_drop)
sala limpa   → Main._add_cera(room_clear_cera)
Ressonancia.register_hit() → SignalBus.threshold_reached(ThresholdData)
                             → Player aplica óleo/modificador/explosão
```
O `Main` é a única autoridade da carteira; o Santuário só mostra e pede.

### Combate
```
Beam._apply_damage()
  → Enemy.take_damage(amount, origin)
      → SignalBus.enemy_hit                (VFX/áudio)
      → SignalBus.damage_number_requested  (pool de números)
      → morreu?
          → SignalBus.enemy_died           (Arena conta, Player recarrega dash,
                                              TimeService.hitstop, shake)
          → SignalBus.enemy_killed         (Arena cria gota de óleo)
  → SignalBus.beam_hit_enemy               (Ressonância + exposição do chefe)

Player.take_damage()
  → TimeService.hitstop(70) + SignalBus.shake_requested
```

### Recursos
```
Player._handle_light_wells()  → óleo sube (26/s × modificador)
Player._handle_beam()         → óleo desce (consumo × modificador)
OilDrop (por kill)            → Player.add_oil()
Iara (projétil)               → Player.remove_oil()
Player._update_vision()       → lanterna encolhe com o óleo (diegético)
```

### Chefe
```
CobraGrande._on_beam_hit()    → exposure += 0.04/tick
  → exposure >= 1 → exposed_left = 4 s → dano cheio
  → caso contrário → take_damage(amount × 0.15)
```

## 5. Decisões técnicas

| Decisão | Motivo |
|---|---|
| `SignalBus` autoload | Evita acoplamento; UI e áudio nascem desacoplados |
| Feixe com consulta matemática + raycast | Cone não é nativo do Godot; raycast resolve LOS barato |
| Visual procedural (`_draw`, `Polygon2D`) | Permite iterar feel sem produzir arte |
| `CanvasModulate` + `PointLight2D` | Escuridão e revelação sem shader custom |
| Inimigos com glow *unshaded* | Leitura justa no escuro (fairness > realismo) |
| `TimeService` com tempo real | Hitstop não pode depender do `time_scale` que ele altera |
| Shake por trauma (shake = trauma²) | Impactos pequenos não irritam; queda suave |
| Hitstop só em abate/dano | O feixe tica 10×/s; congelar sempre destruiria o ritmo |
| Pool de projéteis e números | Evita picos de frame no Web/WASM |
| `SpawnDirector` por orçamento | Escala ondas sem estourar o teto de entidades |
| `StatSheet` para atributos | Oferendas (e futuros itens) não tocam em lógica |
| Santuário pausa a árvore + `await` no sinal | Fluxo linear, sem máquina de estados paralela |
| Tutorial diegético + texto em alpha 0,34 | Ensina sem interromper nem parecer tutorial |
| `RngService` com streams | Reprodutibilidade para testes e daily runs |

## 6. Pontos de extensão (Fase 4+)

- **Novos inimigos:** `EnemyData` + cena que estende `Enemy` e sobrescreve
  `_think` / `_on_telegraph_end`. **Nenhum código novo na arena.**
- **Novos itens:** novo `ItemData` em `data/items/` + uma linha no `ItemDatabase`.
  Modificadores e o comportamento são dados; **nenhuma regra nova no Player**.
- **Novas sinergias:** novo bloco em `Inventory.rebuild()` que devolve
  modificadores/comportamentos com origem `synergies`. O Player não sabe quais
  itens existem — só lê o resultado.
- **Novos comportamentos:** um `match` em `Inventory.rebuild()` que soma/ativa o
  efeito, e um alvo em `Player`/`Beam` (`refraction`, `oil_on_hit`, `nova`,
  `pierce`).
- **Refração/estados:** propriedades do `Beam` + `StatusSystem` (a criar).
- **Meta-progressão:** `SaveSystem` + `UnlockDatabase`. Desbloqueios são dados
  (`UnlockData`) e o único efeito em jogo é `starting_items()`, aplicado pelo
  `Main` antes da primeira sala. Nenhuma regra nova no `Player`.

## 7. Convenções

Ver `AGENTS.md` §4. Resumo: tipagem estática, sem números mágicos em lógica,
sinais como eventos, comentários só para o "porquê".

## 8. Limitações conhecidas

- Teto de 14 inimigos vivos por sala (falta *benchmark* real no Web).
- `WaveData` existe mas as ondas ainda são orçamento numérico.
- HUD desenha em coordenadas absolutas (1280×720); depende do `canvas_items`
  stretch estar ativo — está.
- Sem save: ao recarregar a página, o progresso meta se perde.
- Itens de run ainda não existem: só oferendas de santuário.
- `CobraGrande` invoca afogados fora do orçamento da arena (intencional: são
  "adds", mortos junto com o chefe).