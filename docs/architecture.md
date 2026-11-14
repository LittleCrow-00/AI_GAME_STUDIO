# FAROLEIRO — Arquitetura

> Como o código é organizado e por quê. Leia junto com `AGENTS.md`.

---

## 1. Princípios

1. **Data-driven.** Inimigos, itens, ondas e salas são `Resource` (`.tres`).
   Zero lógica em arquivo de dados.
2. **Event-driven.** `SignalBus` (autoload) desacopla combate de UI, áudio e VFX.
   Emissor nunca sabe quem escuta.
3. **Composição sobre herança.** Inimigos trocam *brain* por composição de nós;
   itens são `StatModifier` + comportamento, não subclasses.
4. **Pipeline de dano único.** `take_damage(amount, source_position)` é a
   interface comum a tudo que recebe dano.
5. **Determinismo.** `RngService` mantém *streams* independentes por semente.
6. **Pool quando doer.** Projéteis e números de dano são candidatos a pool na
   Fase 2 (orçamento: 60 fps no Web).

## 2. Camadas

```
┌───────────────────────────────────────────────┐
│ APRESENTAÇÃO   HUD, números de dano, luzes    │  lê estado, nunca altera regras
├───────────────────────────────────────────────┤
│ GAMEPLAY       Player, Beam, Enemy, Arena     │  usa sistemas
├───────────────────────────────────────────────┤
│ SISTEMAS       Ressonância, SpawnDirector,    │  não conhecem UI
│                RunManager, Stats              │
├───────────────────────────────────────────────┤
│ NÚCLEO         SignalBus, RngService, dados   │  autoloads + Resources
└───────────────────────────────────────────────┘
```

Regra prática: **apresentação nunca altera regras; sistemas não conhecem UI.**

## 3. Mapa de arquivos (estado atual)

```
autoload/
  signal_bus.gd          barramento global de eventos
  rng_service.gd         aleatoriedade determinística por stream
resources/
  stat_modifier.gd       modificador atômico de atributo (ADD/MULTIPLY)
  stat_sheet.gd          agregação com cache (base → ADD → MULTIPLY)
  item_data.gd           item de run (.tres)
  enemy_data.gd          template de inimigo (.tres)
  wave_data.gd           definição de onda (.tres)
data/
  enemies/afogado.tres   dados do inimigo base (consumido por Arena)
scripts/
  player/player.gd       movimento, dash, óleo, integração com o feixe
  beam/beam.gd           cone de luz: dano por tick + LOS + visual procedural
  enemies/enemy_base.gd  perseguição, dano por contato, morte
  systems/ressonancia.gd cadeia de acertos, multiplicador, pontos
  gameplay/arena.gd      paredes, ondas, fim de sala
  gameplay/main.gd       sequência de salas, vitória, derrota
  ui/hud.gd              barras, leitura, banner
  vfx/light_factory.gd   texturas procedurais de luz
  vfx/damage_numbers.gd  números flutuantes
  pickups/oil_drop.gd    gota de óleo com delay e homing
scenes/                  espelha scripts/ (mesmos nomes)
tests/smoke_test.tscn    gate de regressão dos sistemas
```

## 4. Fluxo de dados

### Combate
```
Beam._apply_damage()
  → Enemy.take_damage(amount, origin)
      → SignalBus.enemy_hit            (VFX/áudio)
      → SignalBus.damage_number_requested
      → morreu?
          → SignalBus.enemy_died       (Arena conta, Player recarrega dash)
          → SignalBus.enemy_killed     (Arena cria gota de óleo)
  → SignalBus.beam_hit_enemy           (Ressonância)
```

### Sala
```
Main._start_room(index)
  → Arena.setup(index)     # dificuldade e ondas
  → Arena._ready → start → _next_wave
  → inimigos morrem → _alive-- → 0?
      → Arena.room_cleared → Main avança (ou vitória)
```

### Recursos
```
Player._handle_beam()  → drena óleo → SignalBus.oil_changed → Hud
OilDrop (por kill)     → Player.add_oil() → SignalBus.oil_changed → Hud
Player.take_damage()   → SignalBus.health_changed → Hud
```

## 5. Decisões técnicas

| Decisão | Motivo |
|---|---|
| `SignalBus` autoload | Evita acoplamento; UI e áudio nascem desacoplados |
| Feixe com consulta matemática + raycast | Cone não é nativo do Godot; raycast resolve LOS barato |
| Visual procedural (`_draw`, `Polygon2D`) | Permite iterar feel sem produzir arte |
| `CanvasModulate` + `PointLight2D` | Escuridão e revelação sem shader custom na Fase 1 |
| Inimigos com glow *unshaded* | Garante leitura justa no escuro (fairness > realismo) |
| `StatSheet` com cache | Sinergia de itens sem recalcular por frame |
| Tipagem estática | Projeto pequeno agora; evita dívida em escala |
| `RngService` com streams | Reprodutibilidade para testes e daily runs |

## 6. Pontos de extensão (onde a Fase 4+ entra)

- **Novos inimigos:** novo `EnemyData` + cena que compõe `Enemy` (trocar brain).
- **Novos itens:** novo `ItemData` em `data/items/` — **sem tocar em código**.
- **Novas ondas/salas:** novos `WaveData`/`RoomData` em `data/`.
- **Refracao/estados:** propriedades do `Beam` + `StatusSystem` (a criar).
- **Meta-progressão:** `SaveSystem` (a criar), desbloqueios laterais.

## 7. Convenções

Ver `AGENTS.md` seção 4. Resumo: tipagem estática, sem números mágicos em lógica,
sinais como eventos, comentários só para o "porquê".

## 8. Limitações conhecidas

- Sem pool de objetos (aceitável na Fase 1; necessário antes de ondas grandes).
- `Arena._on_enemy_died` usa `await` com token — frágil se surgirem salas
  concorrentes (não há, por design: uma sala por vez).
- HUD desenha em coordenadas absolutas; quebra se o viewport mudar sem
  `canvas_items` stretch (o stretch está ativo, então está correto hoje).
- Save inexistente: ao recarregar a página, o progresso meta se perde.