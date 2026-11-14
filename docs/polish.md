# Fase 9 — Game feel, áudio e itens

Este documento é o **plano de polimento** do FAROLEIRO. Ele vem depois da
Fase 8 (publicação) e antes de qualquer expansão de conteúdo grande.

O objetivo não é "ter mais coisas": é fazer o que já existe **responder** —
cada acerto, cada abate, cada gota de óleo e cada item precisa ser sentido.

---

## 0. Regras que valem para todos os eixos

1. **Nada de número mágico em lógica.** Curva de dificuldade, preço de
   desbloqueio, duração de hitstop: `@export` ou `.tres`.
2. **Item muda uma decisão, não um número** (`docs/design.md` §7). Item que só
   soma dano não entra.
3. **Apresentação não altera regra.** Tremor, flash e escala são
   cosméticos; dano e óleo continuam sendo calculados pelos sistemas.
4. **Acessibilidade primeiro.** `Settings` já tem `reduce_shake` e
   `reduce_flashes`; todo efeito novo lê essas flags antes de aparecer.
5. **Web é o alvo.** Nada de shader caro por partícula, nada de
   `AudioStreamGenerator` pesado: sintetizar em `tools/gen_audio.gd` e tocar
   WAV curto.
6. **Verificação**: `smoke_test` + `run_test` + benchmark (60 inimigos / 48
   projéteis < 12 ms) + `tools/web_check.mjs`.

---

## Eixo 1 — Game feel (juice)

### O que já existe

`TimeService` (hitstop), `ScreenShake`, `DamageNumbers`, `DeathBurst`,
`Vignette`, drone contínuo e 8 efeitos sonoros. A base está pronta; falta
**consistência**: nem todo evento tem resposta, e as respostas não conversam
entre si.

### 1.1 Feedback de acerto (prioridade alta)

Problema: o feixe tica 10x por segundo, mas o inimigo só pisca. O jogador não
sente o dano, sente o número.

- **Flash branco curto** no inimigo ao receber dano (`modulate` para branco e
  volta em 0,06 s). Usar um `Tween` reaproveitado, não um por hit.
- **Knockback leve** (empurrão de 4–8 px na direção do feixe), sem alterar
  IA nem colisão de dano.
- **Faísca** na direção do feixe: 3–5 partículas curtas, no máximo 1 `GPUParticles2D`
  por pool (reaproveitar o `ProjectilePool`/`DeathBurst`).
- **Pitch aleatório** no `hit` (±8%) para o som não virar metralhadora.
- **Hitstop só em evento grande** (abate, dano no jogador, chefe). Regra do
  `TimeService` continua valendo: nunca por tick.

Critério de aceite: ao acertar, o jogador vê **três** respostas simultâneas
(cor, movimento, partícula) e ouve o som. Medir no teste cego: 10 acertos
seguidos sem nenhuma repetição perceptível de áudio.

### 1.2 Movimento e dash (prioridade alta)

- **Lean**: o sprite inclina até ~8° na direção do movimento (lerp rápido).
- **Rastro de dash**: 3 "fantasmas" do sprite, opacidade decrescente, 0,2 s.
- **Poeira ao frear**: 4 partículas quando a velocidade cai de >60% para <10%
  em um frame.
- **Lanterna**: o `LightWell`/feixe acompanha a mira com atraso de 0,05 s
  (sensação de peso), sem afetar o dano (que usa a mira real).

Critério de aceite: o dash fica legível mesmo com 60 inimigos na tela; o rastro
não pode esconder projéteis inimigos (usar cor fria e alpha baixo).

### 1.3 Câmera (prioridade média)

- **Look-ahead**: deslocar a câmera até 40 px na direção da mira, com clamp.
- **Punch-in** de 2% no abate de chefe e no dano recebido.
- **Zoom-out** de 3% quando a Ressonância está cheia (o mundo "abre").

Critério de aceite: nenhum desses efeitos pode empurrar o HUD para fora da
tela nem causar enjoo com `reduce_shake`.

### 1.4 Feedback de recurso (prioridade alta — é o pilar)

- **Óleo baixo (<20%)**: barra pulsa, vinheta âmbar, `low_oil` tocando em loop
  curto, e o feixe **gagueja** (flicker de alpha) nos últimos 5%.
- **Seco**: o `dry` já existe; adicionar um "estalo" visual no cano da
  lanterna e 1 frame de congelamento de 30 ms.
- **Coleta de óleo**: a gota é **atraída** quando o jogador passa perto (raio
  em `.tres`), acelera e some com um "pop" na barra.

Critério de aceite: um jogador que fica sem óleo sabe disso **antes** de olhar
a barra.

### 1.5 Itens, sinergia e progressão (prioridade média)

- **Item no chão**: flutua, pulsa, e voa até o jogador com `Tween` ao ser
  pego; o sigil correspondente no HUD pisca.
- **Sinergia ativada**: texto curto no centro ("LENTE DE ESTÁDIO"), flash
  dourado no HUD e um acorde no áudio (ver Eixo 2).
- **Ressonância**: anel no chão cresce com o medidor; ao encher, o anel
  "quebra" em 8 cacos por 0,3 s.

### 1.6 Morte e fim de run (prioridade média)

- **Último golpe de chefe**: `Engine.time_scale` 0,25 por 0,4 s, zoom-in,
  explosão de partículas e som grave.
- **Morte do jogador**: o drone silencia por 0,5 s, a tela dessatura e o
  resumo aparece com fade de 0,6 s.
- **Resumo**: contar cera/pontos com `Tween` (número subindo), não mostrar o
  valor pronto.

Critério de aceite: a transição morte → resumo não pode ter frame sem imagem
preta nem clique "cego" (o botão só aceita input depois do fade).

---

## Eixo 2 — Áudio

### O que já existe

`AudioService` com 10 vozes, 8 WAVs sintetizados, cooldown de `hit`, drone
contínuo e mute persistido. Falta **música, variação e mixagem**.

### 2.1 Variação e mix (prioridade alta)

- `AudioService.play(sound, pitch_variation, volume_db)` com `pitch_scale`
  aleatório por chamada; `hit` e `kill` nunca repetem a mesma altura duas
  vezes seguidas.
- **Buses**: `Master`, `Music`, `SFX`, `UI`, com `AudioEffectLimiter` no
  Master. `Settings` ganha sliders de `Music` e `SFX` (além do mute).
- **Ducking**: o drone e a música abaixam 4 dB quando um SFX grande toca
  (chefe, dano no jogador).

Critério de aceite: com 10 abates por segundo, nenhum pico passa de 0 dBFS
(limiter) e o `hit` não vira zumbido.

### 2.2 Música por bioma (prioridade média)

- Três camadas sintetizadas em `gen_audio.gd`: **base** (drone), **pulso**
  (percussão) e **melodia** (modo menor, 4 compassos).
- `AudioService` faz **crossfade de 2 s** entre biomas; cada `BiomeData` aponta
  o conjunto de camadas e o volume base.
- Sem música fora de combate no Santuário (só ambiência).

Critério de aceite: trocar de bioma não corta o som; a transição acontece
durante a descida, não durante a luta.

### 2.3 Intensidade de combate (prioridade média)

- O `SpawnDirector` publica `combat_intensity` (0–3) no `SignalBus` com
  histerese (não oscilar a cada morte).
- `AudioService` liga/desliga camadas conforme a intensidade: 0 = só base,
  1 = +pulso, 2 = +melodia, 3 = +percussão dobrada.
- Regra de dados: limiares em `data/difficulty/*.tres`, não no script.

### 2.4 SFX que faltam (prioridade alta, barato)

| Evento | Som | Gancho |
|---|---|---|
| Item pego | arpejo curto | `SignalBus.item_collected` (novo) |
| Sinergia ativada | acorde | `SignalBus.synergy_changed` (novo) |
| Dash recarregado | clique metálico | `dash_charges_changed` (existe) |
| Chefe aparece | rugido + sub-grave | `SignalBus.boss_spawned` (novo) |
| Chefe morre | explosão longa | `enemy_killed` (filtrar chefe) |
| Morte do jogador | queda + silêncio | `player_died` (existe?) |
| Menu: mover / confirmar / comprar | 3 cliques | `TitleScreen`/`PauseMenu` |
| Unlock comprado | sino | `SaveSystem.purchase` → sinal |

Critério de aceite: nenhum evento importante do jogo acontece em silêncio.
Fila de implementação: primeiro os ganchos de sinal, depois o áudio.

### 2.5 Ambiência (prioridade baixa)

- Loop de mar + vento + gotejar, com volume por bioma e `AudioStreamPlayer2D`
  nas bordas da arena (não centralizado).
- Regra: ambiência nunca compete com o `hit` — ela vive em -18 dB.

---

## Eixo 3 — Itens novos

### Como um item entra

1. Criar `data/items/<id>.tres` (Resource, sem lógica).
2. Se precisar de comportamento novo, implementar em `Inventory.rebuild()` +
   no consumidor (`Beam`/`Player`) e documentar no comentário de `behavior_id`.
3. Adicionar uma linha em `ItemDatabase.ALL` (explícito de propósito).
4. Teste: `smoke_test` verifica que todo item tem `display_name`, `description`
   e pelo menos um modificador **ou** comportamento.

### 3.1 Itens que só usam o que já existe (rápido)

| Item | Efeito | Decisão que muda |
|---|---|---|
| **Estopim** | +1 carga de dash | troca "quando fugir" por "fugir mais vezes" |
| **Pavio de Cera** | +25% dano, -10% alcance | obriga a chegar perto |
| **Olho de Vidro** | +1 refração, -15% dano por feixe | prefere alvos múltiplos |
| **Bolsão de Óleo** | +30 óleo máx., -5% velocidade | fica mais tempo na luz |
| **Anzol de Osso** | `oil_on_hit` +0,5 | recompensa acertar, não matar |
| **Manto de Limpa** | -1 dano recebido, -1 carga de dash | troca mobilidade por vida |
| **Sino de Latão** | +10% Ressonância por abate | escala a corrente |
| **Lanterna Furta-cor** | +15% alcance, -10% dano | joga de longe |

Nenhum desses muda código além do `.tres` + linha no banco.

### 3.2 Itens que exigem comportamento novo (médio)

| Comportamento | Item | Efeito | Custo de implementação |
|---|---|---|---|
| `ricochet` | **Espelho Rachado** | o feixe rebate 1x na parede | `Beam`: 1 raycast extra na reflexão |
| `lingering` | **Rastro de Fogo** | deixa uma poça de luz por 1,5 s | reaproveitar `FirePatch` (dano em área) |
| `magnet` | **Ímã de Osso** | atrai gotas de óleo num raio maior | `OilDrop`: raio de atração |
| `phase` | **Passo de Afogado** | o dash atravessa inimigos e dá 0,2 s de invulnerabilidade | `Player._dash`: ignorar colisão no dash |

Regras: `ricochet` **não** soma dano; `lingering` usa o mesmo dano do feixe
(corrente nunca multiplica); `phase` não pode virar invencibilidade permanente
(custo: 1 carga e 3 s de recarga).

### 3.3 Sinergias novas (uma por eixo)

- **Espelho + Lente** (2 `lente` + `ricochet`): o ricochete vira 2. Só muda a
  geometria, não o dano.
- **Ímã + Bolsão** (2 `oleo` + `magnet`): gotas valem +1 cera ao ser
  coletadas.

Implementar em `Inventory.rebuild()` com `tag_count` como as sinergias atuais,
e expor o nome via `SignalBus.synergy_changed` para o HUD e o áudio.

### 3.4 Curadoria (não fazer)

- Item que só aumenta dano (`+10% dano`, `+1 dano`) — proibido por design.
- Item que dá invencibilidade global, ou que remove o custo de óleo.
- Item que muda a win condition (matar sem luz, por exemplo).

---

## Eixo 4 — Extras de apresentação (baixo custo)

- **Menu de opções**: sliders de música/SFX, `reduce_shake`, `reduce_flashes`,
  `Esc` volta. Reaproveita `PauseMenu`.
- **Gamepad**: o esquema de input já é `InputMap`; falta o layout e o texto
  "A / B" no tutorial.
- **Tutorial**: 3 frases, não 10; mostrar o `dry` (óleo vazio) como
  oportunidade, não como punição.
- **Tela de resumo**: mostrar itens da run em fila (o inventário já existe) e
  o bioma alcançado.

---

## Ordem de execução (estimativas)

| Etapa | Conteúdo | Entrega |
|---|---|---|
| 9.1 | Juice de acerto + movimento + recurso (Eixo 1.1–1.2, 1.4) | build jogável, testes verdes |
| 9.2 | Áudio: variação, buses, SFX faltantes (2.1, 2.4) | jogo nunca silencioso |
| 9.3 | Itens 3.1 (8 itens) + 3.2 (4 comportamentos) | 37 itens no banco |
| 9.4 | Música por bioma + intensidade (2.2–2.3) | trilha reativa |
| 9.5 | Câmera, sinergia visual, resumo (1.3, 1.5, 1.6, Eixo 4) | polimento final |

Cada etapa termina com: `smoke_test` (95+ checks), `run_test`, benchmark
< 12 ms, boot headless de 600+ frames e `tools/web_check.mjs` verdes.

## Teste cego (definição de pronto do polimento)

Antes de considerar a Fase 9 pronta, jogar 10 minutos sem olhar o código e
anotar:

1. três momentos em que o jogo **respondeu** bem;
2. três momentos em que **faltou** resposta;
3. qualquer evento importante **em silêncio**.

Se sobrar item na lista 2 ou 3, a etapa não fechou.