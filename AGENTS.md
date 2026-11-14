# AGENTS.md — FAROLEIRO

Regras para qualquer agente (humano ou IA) que trabalhe neste repositório.
Se você é um agente de desenvolvimento, **leia isto antes de escrever código**.

---

## 1. Identidade do projeto

**FAROLEIRO** — roguelite de ação top-down em Godot 4.
**Mecânica central:** o feixe de luz é arma, visão e munição. Consome óleo, que só
regenera ao matar inimigos ou em focos de luz.

Nunca implemente nada que quebre esse pilar. Se uma feature não conversa com
"luz = recurso", ela provavelmente não pertence ao jogo.

## 2. Comandos

```bash
# abrir editor
godot --path .

# importar (necessário após adicionar/remover arquivos)
godot --headless --path . --import

# rodar
godot --headless --path . --quit-after 600

# testes de fumaça (sempre rode antes de reportar conclusão)
godot --headless --path . res://tests/smoke_test.tscn

# exportar web
mkdir -p build/web
godot --headless --path . --export-release "Web" build/web/index.html
```

Versão alvo: **Godot 4.4.x estável**. Não use API de versão mais nova.

## 3. Estrutura

```
autoload/    serviços globais (SignalBus, RngService)
resources/   classes base de dados (Resource) e StatSheet
data/        conteúdo em .tres (itens, inimigos, ondas, salas)
scenes/      cenas .tscn (espelhadas com scripts/)
scripts/     código (espelhado com scenes/)
docs/        design, arquitetura, roadmap
tests/       testes de fumaça
```

`scenes/` e `scripts/` usam o **mesmo nome de arquivo** quando possível.

## 4. Regras de código

1. **Tipagem estática obrigatória.** `var x: int = 0`, `func f(a: float) -> void`.
   Não use `:=` com tipo ambíguo.
2. **Nada de `get_node("../..")` entre subsistemas.** Use `SignalBus`, grupos
   (`add_to_group`) ou injeção via `@export`.
3. **Nenhum número de balanceamento hardcoded** em lógica. Use `@export` ou
   `Resource` (`.tres`).
4. **`class_name` em PascalCase**; arquivos em `snake_case.gd`; cenas em
   `PascalCase.tscn`; sinais em `snake_case`.
5. **Sinais são eventos, não comandos.** Emissor não sabe quem escuta.
6. **Comentários só quando explicam POR QUÊ**, nunca o óbvio. Documentação
   longa vai em `docs/`, não em comentários.
7. **Não quebre a separação de camadas** (ver `docs/architecture.md`):
   apresentação nunca altera regras; sistemas não conhecem UI.
8. **Nada de `queue_free()` sem remover antes de sinais pendentes** — emita o
   sinal e depois libere.

## 5.Fluxo de trabalho

1. Antes de implementar, verifique `docs/roadmap.md` e a fase atual.
2. Implemente o menor incremento que satisfaz o critério de aceite da fase.
3. Rode `smoke_test.tscn`. Se falhar, corrija antes de continuar.
4. Rode o jogo por alguns segundos headless para detectar erros de runtime.
5. Atualize `docs/roadmap.md` e `docs/changelog.md` na mesma entrega.
6. Não faça commit sem pedido explícito do usuário.

## 6. Definição de pronto (por entrega)

- [ ] Projeto compila sem erros de script
- [ ] `smoke_test.tscn` passa
- [ ] Sem erros em 600+ frames headless
- [ ] Export Web funciona (quando aplicável)
- [ ] Documentação atualizada
- [ ] Nenhum número mágico novo em lógica

## 7. Escopo

Não adicione sistemas genéricos "para ter mais conteúdo". Todo sistema precisa
interagir com o feixe, com a Ressonância ou com a economia de óleo.
Itens que só aumentam dano **não entram** (ver `docs/design.md`).