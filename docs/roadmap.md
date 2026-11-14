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

## Fase 2 — Combate com peso ⏭️ (próxima)

- [ ] Hitstop (20 ms normal / 60 ms crítico) e screen shake por trauma
- [ ] Focos de luz (recarga de óleo por ambiente, com risco)
- [ ] 4 inimigos com comportamentos distintos (Iara, Boto, Curupira, estouro)
- [ ] Spawn director com orçamento de ameaça (substitui contagem fixa)
- [ ] Pool de números de dano e projéteis
- [ ] Telegrafia de ataques (wind-up ≥ 0,35 s)
- [ ] Ajuste de *game feel* com medição de FPS headless

**Critério de aceite:** combate com peso perceptível; sala de 60 s mantém 60 fps
com 40+ inimigos vivos.

---

## Fase 3 — Estrutura de run

- [ ] Santuário entre andares (escolha de 1 entre 3)
- [ ] Chefe 1: Cobra Grande
- [ ] 4º andar: sala do Farol (vitória)
- [ ] Tela de morte com resumo da run

---

## Fase 4 — Itens e sinergias

- [ ] `StatSheet` ligado ao `Player` (hoje existe, não é usado)
- [ ] 24+ itens em `data/items/*.tres`
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
| Sem pool de objetos | Performance em ondas grandes | Fase 2 |
| HUD com coordenadas absolutas | frágil a mudanças de layout | Fase 3 |
| `Arena._on_enemy_died` com `await` + token | frágil se houver salas concorrentes | Fase 3 |
| `StatSheet` não usado pelo Player | itens não alteram o personagem | Fase 4 |
| Sem save | progresso meta perdido ao recarregar | Fase 6 |