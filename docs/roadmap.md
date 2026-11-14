# FAROLEIRO — Roadmap

> Estado real do repositório. Atualize a cada entrega (ver `AGENTS.md` §5).

**Versão:** 0.8.0 · **Motor:** Godot 4.4.x · **Alvo:** Web (GitHub Pages)

---

## Fase 0 — Fundação ✅

**Meta:** abrir no editor, compilar, exportar na Web, ter convenções.

- [x] `project.godot` (4.4, GL Compatibility, 1280×720, autoloads, input map)
- [x] `.gitignore`, `icon.svg`
- [x] Estrutura de pastas (`autoload`, `resources`, `data`, `scenes`, `scripts`, `docs`, `tests`)
- [x] `AGENTS.md` com convenções e comandos
- [x] CI corrigido (tag `4.4.1` existente, download de templates, `--import`, testes, `.nojekyll`)
- [x] Export Web validado localmente (`build/web/index.html`)
- [x] `docs/` (design, arquitetura, roadmap)

**Critério de aceite:** ✅ projeto abre, compila, exporta e roda headless.

---

## Fase 1 — Vertical slice de sensação ✅ (parcial)

**Meta:** 60 s jogáveis e divertidos; feixe e dash responsivos.

- [x] Movimento com aceleração/atrito (snappy)
- [x] Dash com i-frames, cooldown e recarga por abate
- [x] Feixe: cone, dano por tick, linha de visão contra paredes
- [x] Óleo: consumo, gotas de inimigos, *estouro* (cegueira de 1,5 s)
- [x] Inimigo base (Afogado): perseguição, dano por contato, morte, drop
- [x] Inimigo definido por dados (`data/enemies/afogado.tres` → `EnemyData`),
      não por constantes no script da arena
- [x] Arena com paredes, 3 ondas por sala, dificuldade por andar
- [x] Loop de run: 3 salas → vitória; morte → restart (`R`)
- [x] HUD: vida, óleo, cargas de dash, cadeia, pontos, ondas
- [x] Escuridão com `CanvasModulate` + luz do jogador + glow de inimigos
- [x] Números de dano flutuantes
- [x] Testes de fumaça (9 asserções)

**Critério de aceite:** ✅ um jogador leigo consegue se mover, mirar, atirar,
matar, morrer e reiniciar sem ajuda.

**Não entregue nesta fase (foi para a 2):** hitstop, screen shake, telegrafia de
ataques especiais, focos de luz.

---

## Fase 2 — Combate com peso ✅ (parcial)

- [x] Hitstop (45 ms em abate, 70 ms em dano) e screen shake por trauma
- [x] Focos de luz: recarga de óleo por ambiente, com penalidade de movimento
- [x] 4 inimigos com comportamentos distintos (Afogado, Iara, Boto, Curupira)
- [x] Spawn director com orçamento de ameaça (substitui contagem fixa)
- [x] Pool de números de dano (40) e de projéteis (48)
- [x] Telegrafia de ataques (0,35–0,55 s, com *tint* pulsante)
- [x] **Tutorial quase imperceptível**: dicas em alpha 0,34, uma vez por run,
      sem modal e sem bloquear *input*; lanterna encolhe com o óleo (diegético)
- [x] Medição de estresse: 60 inimigos em 6,9 ms/frame (headless, CPU)

**Critério de aceite:** parcialmente atendido — peso perceptível e 16/16 testes
passando; falta o *benchmark* de estresse.

---

## Fase 3 — Estrutura de run ✅

- [x] **Santuário** entre andares: escolha de 1 entre 3 oferendas
- [x] Oferendas ligadas ao `StatSheet` do jogador (9 oferendas em `data/boons/`)
- [x] **Chefe 1: Cobra Grande** — blindada no escuro, exposta após 2,5 s de luz
      contínua; investida, rajada radial e invocação
- [x] **4º andar: sala do Farol** — acender o Farol para vencer
- [x] **Tela de fim de run** com resumo (salas, abates, pontos, tempo, semente)
- [x] Run completa validada de ponta a ponta (4 salas → vitória)

**Critério de aceite:** ✅ run completa jogável, 22/22 testes passando.

---

## Fase 4 — Itens e sinergias ✅ (parcial)

- [x] `StatSheet` ligado ao `Player` (feito na Fase 3, via oferendas)
- [x] 25 itens em `data/items/*.tres`
- [x] Itens com **tags** (`lente`, `oleo`, `corpo`, `resonancia`) e stacks
- [x] Sinergias compostas em `Inventory.rebuild()` (4 sinergias)
- [x] Comportamentos que mudam o *verbo*: refração, perfuração, óleo por acerto,
      explosão ao matar
- [x] Maldições no sorteio (12% a partir da 2ª sala)
- [x] Pelo menos 2 archetypes viáveis (Estádio e Brasa)
- [ ] Itens persistentes na run (só em memória; save é Fase 6)

---

## Fase 5 — Ressonância e economia ✅ (parcial)

- [x] Limiares de cadeia (10/25/50) com buffs, em `data/thresholds/*.tres`
- [x] Cera: ganha por abate (`Enemy.cera_drop`) e por sala limpa
- [x] Loja no Santuário: 1ª escolha grátis, extras custam cera (10 + 4/andar)
- [x] HUD mostra saldo de cera e o próximo limiar da cadeia
- [x] Curva de dificuldade calibrada (inimigos/ondas por andar) — `DifficultyData`
      + `data/difficulty/*.tres` (vida, dano, velocidade, orçamento e elite)
- [ ] Cera acumulada entre runs (meta-progressão → Fase 6)

---

## Fase 6 — Meta-progressão ✅ (parcial)

- [x] `SaveSystem` (`user://save.json`): cera total, runs, recorde e desbloqueios
- [x] Tela de título (`scenes/main/title.tscn`): desce, mostra saldo e recordes
- [x] 3 desbloqueios que entregam **itens iniciais** na run (Pavio Extra, Óleo
      Frio, Lente de Estádio)
- [x] Cera da run é depositada no fim (vitória ou morte)
- [ ] Mais desbloqueios e personagens (5 desbloqueios hoje; personagens depois)

---

## Fase 7 — Conteúdo e polimento

- [x] Sprites SVG para jogador, 4 inimigos e chefe (fallback procedural)
- [x] Arena: lajes irregulares, poças, paredes e pilares
- [x] Vinheta em shader (abaixo do HUD)
- [x] VFX: explosão de morte, faísca de impacto do feixe, rastro do dash,
      rastro de projétil, gota de óleo com anel
- [x] HUD com ícones, moeda de cera e barra do próximo limiar
- [x] Santuário com selo por tag
- [x] Elite: 12% de chance a partir da 2ª sala (2,2× vida, 1,3× dano, 3× cera,
      anel dourado)
- [x] Paleta da arena muda com a profundidade
- [x] 8+ inimigos, biomas
  - [x] Boitatá (elite de fogo: a luz enche o calor, explode e a deixa imune)
  - [x] Mapinguari (couraçado: dano reduzido de longe, investida pune a proximidade)
  - [x] Cuca (2º chefe: encolhe o alcance do feixe em 35% enquanto viva)
  - [x] Mula-sem-cabeça (galopa deixando rastro de fogo, ofega e apanha mais)
  - [x] Caipora (semeia poças de escuridão que encolhem o feixe)
  - [x] Biomas como dados (`data/biomes/*.tres`, paleta por profundidade)
  - [x] 8 tipos de inimigos + 2 chefes
- [x] Animação por gait (sprites estáticos + passada por código): 5 estilos
      (`walk`, `lope`, `slither`, `hover`, `crawl`) com passada, inclinação e
      balanço próprios, escolhidos por `EnemyData.anim_style`
- [x] Áudio procedural (drone ambiente, impacto, abate, coleta, dash, dano,
      clique seco, sino) — `tools/gen_audio.gd` gera os WAVs, `AudioService` toca
      e o `ESC` tem "Som: ligado/mudo"
- [x] Acessibilidade: menu de pausa (`ESC`) com reduzir tremor e flashes,
      persistido em `user://settings.cfg`
- [x] Tutorial diegético: o prólogo é o Farol apagado — a única ação é apontar o
      feixe para acendê-lo (sem texto explicando o botão)

---

## Fase 8 — Publicação

- [ ] Export Web otimizado (< 20 MB wasm)
- [ ] Deploy no GitHub Pages verificado
- [ ] PWA opcional
- [ ] Build para itch.io (gratuito, página do jogo)

---

## Dívida técnica conhecida

| Item | Impacto | Onde resolver |
|---|---|---|
| HUD com coordenadas absolutas | frágil a mudanças de layout | Fase 3 |
| `Arena` usa um único `SpawnDirector` por sala | salas concorrentes não são suportadas (não há, por design) | Fase 3 |
| Itens não persistem entre recarregamentos | build perdido ao fechar o jogo | Fase 6 |
| Sem save | progresso meta perdido ao recarregar | Fase 6 |
| Teto de 14 inimigos vivos | ondas maiores podem pesar no Web | Fase 2 (medição) |
| `WaveData` existe mas não é usado | dados de onda ainda são orçamento numérico | Fase 3 |