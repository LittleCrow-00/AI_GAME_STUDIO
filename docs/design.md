# FAROLEIRO — Design

> Documento vivo de design. Fonte de verdade para decisões criativas.
> Estado atual do código: `docs/roadmap.md`.

---

## 1. Pitch

Roguelite de ação top-down onde **a luz é simultaneamente arma, visão e munição**.
Você é o último Faroleiro, descendo por uma fossa afogada habitada por criaturas
do folclore costeiro brasileiro. Cada tiro seu ilumina o caminho — e gasta a
única coisa que te mantém vivo e enxergando.

> *"A luz que você gasta é a luz que você enxerga."*

### Referências e o que extraímos (sem copiar conteúdo)

| Referência | Lição aplicada |
|---|---|
| The Binding of Isaac | Sinergia emergente entre itens; builds que mudam o *verbo* do personagem |
| Balatro | Cadeias, multiplicadores, tensão risco × recompensa |
| Dead Cells | Responsividade: dash, i-frames, hitstop, peso |
| Vampire Survivors | Escalabilidade de poder e variedade de builds |
| Hellbrella | Identidade cultural brasileira e tom próprio |

Nenhum nome, arte, áudio ou valores das referências é reutilizado.

---

## 2. Universo

O mar subiu e engoliu o litoral. As luzes que guiavam os barcos se apagaram.
A **Fossa** guarda o que sobrou — e o que desceu junto.

**Tom:** melancólico, úmido, com humor seco.

**Criaturas planejadas** (folclore reinterpretado, não reprodução de obras):

| Criatura | Papel | Interação com a luz |
|---|---|---|
| Afogado | Base, perseguidor lento | Hesita sob o feixe *(implementado)* |
| Iara | Engodo | Mantém distância e dispara rajada que **drena óleo** *(implementado)* |
| Boto | Metamorfo | Telegrafa e **avança em linha reta**; pune ficar parado *(implementado)* |
| Curupira | Enganador | **Salta** para trás de você quando você tenta manter distância *(implementado)* |
| Cobra Grande | Chefe 1 | Enterra/emerge; vulnerável só sob luz contínua |
| Boitatá | Elite | Imune no escuro; queima se iluminado por muito tempo |
| Mapinguari | Tanque | Couraça só quebra com cone estreito |

---

## 3. Identidade visual e áudio

**Estilo:** silhuetas de alto contraste sobre névoa, com glow seletivo.
Viável com arte procedural — o que permite iterar feel antes de produzir arte final.

| Token | Valor |
|---|---|
| Fundo / abismo | `#0A1A22` |
| Preto profundo | `#050B0E` |
| Âmbar (sua luz) | `#FFB347` |
| Ciano-fantasma (inimigos) | `#57E0D8` |
| Vermelho-sangue (dano/risco) | `#C8323C` |

**Feedback:** squash/stretch, flash branco, knockback, damage numbers, hitstop.
**Áudio:** drone submerso, ping de sonar, clique seco ao ficar sem óleo, sino ao
acender um Farol. Áudio comunica estado, não enfeita.

---

## 4. Mecânica central — O Feixe

| Parâmetro | Base | Escalável por |
|---|---|---|
| Alcance | 260 px | Itens, foco |
| Semi-ângulo | 22° | Itens (largo = crowd, estreito = dano) |
| Dano | 8 / tick (0,1 s) | Itens |
| Consumo | 6 óleo/s ao disparar | Itens |
| Óleo máximo | 100 | Itens |
| Regeneração passiva | 0 | — |

**Regra de ouro:** o óleo **não regenera sozinho**. Recarrega ao:
1. Matar inimigos (gotas de óleo);
2. Ficar parado em um **Foco** (luz ambiente) — recarga rápida, mas te expõe.

**Estouro (0 óleo):** o feixe falha e você fica **cego por 1,5 s**. É o momento
de maior vulnerabilidade do jogo.

**Propriedades que itens podem modificar:** largura, alcance, refração (sub-feixes),
penetração, frequência/cor (estados), duração do rastro de luz.

**Sinergias emergentes (todas pelo mesmo sistema):**
- Refração + cone largo + penetração → "luz de estádio"
- Alcance curto + dano alto + refração → "shotgun de luz"
- Rastro longo + queimadura → "campo de fogo"

---

## 5. Combate

**Movimento:** aceleração 2200 px/s², atrito 2600 px/s², velocidade máx 220 px/s.
**Dash:** 0,15 s, 520 px/s, i-frames 0,18 s, cooldown 0,45 s. Recarrega ao matar.
**Impacto:** hitstop (45 ms em abate, 70 ms em dano), screen shake por trauma
(shake = trauma²), flash branco, knockback, damage numbers.
**Telegrafia:** todo ataque especial tem *wind-up* de 0,35–0,55 s com *tint*
pulsante — o inimigo para e avisa antes de agir.

**Por que hitstop só em eventos grandes:** o feixe tica 10×/s. Se cada tick
congelasse o jogo, o combate viraria pudim. Congelamos abates e dano recebido.

---

## 5.1 Focos de luz

Dois focos por sala. Dentro do raio, o óleo recarrega a **26/s**, mas o
Faroleiro anda a **40%** da velocidade.

É a decisão que faltava: *ficar e recarregar, ou sair e lutar*. O foco é visível
de longe (poça de luz quente), então o jogador escolhe o momento de usá-lo.

## 5.2 Tutorial quase imperceptível

Sem modal, sem parede de texto, sem bloquear *input*. O ensino é quase todo
diegético:

- A lanterna **encolhe e escurece** conforme o óleo cai (o jogador aprende a
  relação óleo↔visão sem ler nada).
- O foco de luz **pulsa**; a gota de óleo **voa** até o jogador após o abate.
- Texto só confirma, em alpha 0,34, uma vez por run:
  - 1ª onda: *"segure o feixe · a luz gasta"*
  - óleo < 30%: *"óleo baixo · você está quase cego"*
  - 1º foco: *"a luz te enche · mas te prende"*
  - 1º abate: *"o óleo volta"*
  - 1º dano sofrido: *"shift · o dash atravessa o perigo"*

Nada disso aparece duas vezes.

---

## 6. Ressonância (eixo Balatro)

Cadeia de acertos com janela de **1,2 s**.

```
Ressonância = 1 + 0,1 × cadeia
```

**Decisão deliberada:** a cadeia **não multiplica dano**. Dano vem de itens.
A cadeia multiplica **Pontos** e **Cera**, premiando agressividade sem
trivializar o combate. Assim os eixos "dano" e "pontuação" permanecem
independentes — e a ganância (continuar atacando = gastar óleo) vira decisão.

**Limiares (planejado):** 10 → +5% cadência; 25 → feixe perfura 1 alvo;
50 → "Estouro" (onda de luz).

---

## 7. Itens e sinergias

**Categorias:** Lente (feixe), Óleo (economia), Corpo (defesa/mobilidade),
Ressonância (multiplicadores), Maldição (alto custo, alto poder).

**Regra de design inviolável:** todo item deve mudar **uma decisão**, não apenas
um número. Item que só aumenta dano **não entra**.

**Implementação:** `ItemData` (`Resource` em `data/items/*.tres`) com lista de
`StatModifier`. O `StatSheet` agrega (soma dos ADD, produto dos MULTIPLY) com
cache. Nenhum item contém lógica própria.

**Archetypes alvo:**

| Archetype | Núcleo |
|---|---|
| Estádio | cone largo + refração + penetração |
| Estilete | cone estreito + dano + penetração |
| Incendiário | rastro + queimadura + Ressonância |
| Cego | baixa luz, alto óleo, dash |

**Anti-sinergia:** inimigos que criam zonas de escuridão (Polvo) impedem que um
único build resolva tudo.

---

## 8. Estrutura de run

```
Descida 1 (3 salas + mini-boss) → Santuário
Descida 2 (4 salas + elite)     → Santuário
Descida 3 (4 salas + Chefe)     → Santuário
Descida 4 (sala do Farol: vitória)
```

Duração alvo: **25–40 min**. Sem "continue".

**Loop:** entrar → ler ameaças → combater (óleo/cadeia/dash) → limpar → recompensa
→ santuário → descer.

**Meta-progressão:** Cera acumulada desbloqueia **itens iniciais e personagens**
(desbloqueios laterais), nunca apenas `+10% dano` — para não achatar a curva.

---

## 9. O que ainda não existe

- Itens e `StatSheet` conectado ao jogador (a classe existe, o uso não).
- Santuário/loja, Cera e meta-progressão.
- Chefe (Cobra Grande) e andares 3–4.
- Áudio.
- Cancelamento de dash e *benchmark* de estresse com 40+ inimigos.

Ver `docs/roadmap.md`.