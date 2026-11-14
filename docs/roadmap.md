# FAROLEIRO — Roadmap

> Estado real do repositório. Atualize a cada entrega (ver `AGENTS.md` §5).

**Versão:** 0.1.0 · **Motor:** Godot 4.4.x · **Alvo:** Web (GitHub Pages)

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
- [ ] Medição de FPS com 40+ inimigos (o teto atual é 14 vivos por sala)

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

## Fase 4 — Itens e sinergias ⏭️ (próxima)

- [x] `StatSheet` ligado ao `Player` (feito na Fase 3, via oferendas)
- [ ] 24+ itens em `data/items/*.tres`
- [ ] Itens persistentes na run (hoje só oferendas de santuário)
- [ ] Seleção de *boons* com *tags* e sinergias compostas
- [ ] Pelo menos 2 archetypes viáveis

---

## Fase 5 — Ressonância e economia

- [ ] Limiares de cadeia (10/25/50) com buffs
- [ ] Cera (moeda) e loja
- [ ] Curva de dificuldade calibrada

---

## Fase 6 — Meta-progressão

- [ ] `SaveSystem` (`user://save.json`, fallback Web)
- [ ] Desbloqueios laterais (itens iniciais, personagens)

---

## Fase 7 — Conteúdo e polimento

- [ ] 8+ inimigos, 2º chefe, biomas
- [ ] Áudio (drone, ping, clique seco, sino)
- [ ] Acessibilidade (reduzir shake, flashes)
- [ ] Tutorial diegético no Farol inicial

---

## Fase 8 — Publicação

- [ ] Export Web otimizado (< 20 MB wasm)
- [ ] Deploy no GitHub Pages verificado
- [ ] PWA opcional

---

## Dívida técnica conhecida

| Item | Impacto | Onde resolver |
|---|---|---|
| HUD com coordenadas absolutas | frágil a mudanças de layout | Fase 3 |
| `Arena` usa um único `SpawnDirector` por sala | salas concorrentes não são suportadas (não há, por design) | Fase 3 |
| `StatSheet` não usado pelo Player | itens não alteram o personagem | Fase 4 |
| Sem save | progresso meta perdido ao recarregar | Fase 6 |
| Teto de 14 inimigos vivos | ondas maiores podem pesar no Web | Fase 2 (medição) |
| `WaveData` existe mas não é usado | dados de onda ainda são orçamento numérico | Fase 3 |