# FAROLEIRO — Arquitetura

> Como o código é organizado e por quê. Leia junto com `AGENTS.md`.

---

## 1. Princípios

1. **Data-driven.** Inimigos, itens, ondas e salas são `Resource` (`.tres`).
   Zero lógica em arquivo de dados.
2. **Event-driven.** `SignalBus` (autoload) desacopla combate de UI, áudio e VFX.
   Emissor nunca sabe quem escuta.
3. **Composição sobre herança.** Inimigos trocam o cérebro (`_think`), não o
   corpo. Itens são `StatModifier` + comportamento, não subclasses.
4. **Pipeline de dano único.** `take_damage(amount, source_position)` é a
   interface comum a tudo que recebe dano.
5. **Determinismo.** `RngService` mantém *streams* independentes por semente.
6. **Pool quando doer.** Projéteis e números de dano já são *poolados*.

## 2. Camadas

```
┌───────────────────────────────────────────────┐
│ APRESENTAÇÃO   HUD, dicas, números, câmera    │  lê estado, nunca altera regras
├───────────────────────────────────────────────┤
│ GAMEPLAY       Player, Beam, Enemy, Arena     │  usa sistemas
├───────────────────────────────────────────────┤
│ SISTEMAS       Ressonância, SpawnDirector,    │  não conhecem UI
│                Tutorial, RunManager, Stats    │
├───────────────────────────────────────────────┤
│ NÚCLEO         SignalBus, RngService,         │  autoloads + Resources
│                TimeService, dados             │
└───────────────────────────────────────────────┘
```

Regra prática: **apresentação nunca altera regras; sistemas não conhecem UI.**

## 3. Mapa de arquivos (estado atual)

```
autoload/
  signal_bus.gd          barramento global de eventos
  rng_service.gd         aleatoriedade determinística por stream
  time_service.gd        hitstop global (altera Engine.time_scale)
resources/
  stat_modifier.gd       modificador atômico de atributo (ADD/MULTIPLY)
  stat_sheet.gd          agregação com cache (base → ADD → MULTIPLY)
  item_data.gd           item de run (.tres)
  enemy_data.gd          template de inimigo (.tres)
  wave_data.gd           definição de onda (.tres) — ainda não usado
data/
  enemies/               afogado, iara, boto, curupira (.tres)
scripts/
  player/player.gd       movimento, dash, óleo, focos de luz, visão
  beam/beam.gd           cone de luz: dano por tick + LOS + visual procedural
  enemies/enemy_base.gd  esqueleto: vida, contato, morte, telegrafia
  enemies/afogado.gd     perseguidor puro
  enemies/iara.gd        mantém distância, rajada que drena óleo
  enemies/boto.gd        orbita, telegrafa, avança em linha reta
  enemies/curupira.gd    salta para trás do jogador
  systems/ressonancia.gd cadeia de acertos, multiplicador, pontos
  systems/spawn_director.gd orçamento de ameaça + teto de vivos
  systems/tutorial_director.gd dicas de alpha baixo, 1x por run
  gameplay/arena.gd      geometria, focos, pool, ciclo de ondas
  gameplay/light_well.gd foco de luz: recarrega óleo, penaliza movimento
  gameplay/main.gd       sequência de salas, vitória, derrota
  ui/hud.gd              barras, leitura, dicas, banner
  vfx/light_factory.gd   texturas procedurais de luz
  vfx/screen_shake.gd    trauma-based shake na Camera2D
  vfx/damage_numbers.gd  números flutuantes com pool (Node2D, segue a câmera)
  vfx/projectile.gd      projétil reciclado (Area2D)
  vfx/projectile_pool.gd pool fixo de 48 projéteis
  pickups/oil_drop.gd    gota de óleo com delay e homing
scenes/                  espelha scripts/ (mesmos nomes)
tests/smoke_test.tscn    gate de regressão (16 asserções)
```

## 4. Fluxo de dados

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
  → SignalBus.beam_hit_enemy               (Ressonância)

Player.take_damage()
  → TimeService.hitstop(70) + SignalBus.shake_requested
```

### Sala
```
Main._start_room(index)
  → Arena.setup(index) → add_child → Arena._ready
      → ProjectilePool + LightWells + SpawnDirector
      → start() → _start_wave()
  → SpawnDirector gasta orçamento → spawn_enemy(data) → Arena posiciona
  → inimigos morrem → _alive-- → orçamento == 0 e _alive == 0?
      → próxima onda (após 0,7 s) ou room_cleared → Main avança
```

### Recursos
```
Player._handle_light_wells()  → óleo sobe (26/s) → SignalBus.oil_changed
Player._handle_beam()         → óleo desce (6/s) → SignalBus.oil_changed
OilDrop (por kill)            → Player.add_oil()  → SignalBus.oil_changed
Iara (projétil)               → Player.remove_oil() → SignalBus.oil_removed
Player._update_vision()       → lanterna encolhe com o óleo (diegético)
```

### Tutorial
```
SignalBus (oil_changed / light_well_entered / enemy_died / player_damaged)
  → TutorialDirector decide (1x por gatilho)
      → Hud.show_hint(texto, duração, posição)  # alpha 0,34
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
| Tutorial diegético + texto em alpha 0,34 | Ensina sem interromper nem parecer tutorial |
| `StatSheet` com cache | Sinergia de itens sem recalcular por frame |
| `RngService` com streams | Reprodutibilidade para testes e daily runs |

## 6. Pontos de extensão (Fase 3+)

- **Novos inimigos:** `EnemyData` + cena que estende `Enemy` e sobrescreve
  `_think` / `_on_telegraph_end`. **Nenhum código novo na arena.**
- **Novos itens:** novo `ItemData` em `data/items/` — **sem tocar em código**.
- **Novas ondas/salas:** `WaveData`/`RoomData` (a substituir o orçamento numérico).
- **Refração/estados:** propriedades do `Beam` + `StatusSystem` (a criar).
- **Meta-progressão:** `SaveSystem` (a criar), desbloqueios laterais.

## 7. Convenções

Ver `AGENTS.md` §4. Resumo: tipagem estática, sem números mágicos em lógica,
sinais como eventos, comentários só para o "porquê".

## 8. Limitações conhecidas

- Teto de 14 inimigos vivos por sala (orçamento do Web; falta *benchmark* real).
- `WaveData` existe mas as ondas ainda são orçamento numérico, não `.tres`.
- HUD desenha em coordenadas absolutas; quebra se o viewport mudar sem
  `canvas_items` stretch (o stretch está ativo, então está correto hoje).
- Save inexistente: ao recarregar a página, o progresso meta se perde.
- `StatSheet` não alimenta o `Player` — itens ainda não alteram o personagem.