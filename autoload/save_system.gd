extends Node
## Save da meta-progressão (fora da run).
##
## Guarda cera acumulada, runs, recorde e desbloqueios em `user://save.json`.
## Nao guarda estado de run: morrer e recomecar continua barato (decisao de
## design da Fase 1). O `ConfigFile` seria suficiente, mas JSON deixa o arquivo
## legivel para debug.

const PATH := "user://save.json"

## Caminho efetivo. Testes trocam para um arquivo temporário e restauram depois,
## para nunca tocar no save real do jogador.
var path: String = PATH

var total_cera: int = 0
var runs: int = 0
var best_score: int = 0
var unlocks: Array[String] = []


func _ready() -> void:
	load_game()


func load_game() -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	total_cera = int(parsed.get("total_cera", 0))
	runs = int(parsed.get("runs", 0))
	best_score = int(parsed.get("best_score", 0))

	unlocks.clear()
	var stored = parsed.get("unlocks", [])
	if typeof(stored) == TYPE_ARRAY:
		for entry in stored:
			unlocks.append(String(entry))


func save_game() -> void:
	var data := {
		"total_cera": total_cera,
		"runs": runs,
		"best_score": best_score,
		"unlocks": unlocks,
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))


## Deposita a cera da run e atualiza os recordes. Chamado no fim da run.
func record_run(cera: int, score: int) -> void:
	runs += 1
	total_cera = maxi(0, total_cera + maxi(0, cera))
	best_score = maxi(best_score, score)
	save_game()


func has_unlock(unlock_id: StringName) -> bool:
	return unlocks.has(String(unlock_id))


## Compra um desbloqueio. Devolve `false` se já existe ou falta cera.
func purchase(unlock_id: StringName) -> bool:
	var unlock := UnlockDatabase.get_unlock(unlock_id)
	if unlock == null or has_unlock(unlock_id):
		return false
	if total_cera < unlock.cost:
		return false

	total_cera -= unlock.cost
	unlocks.append(String(unlock_id))
	save_game()
	return true


## Itens entregues no início da próxima run.
func starting_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for unlock_id in unlocks:
		var unlock := UnlockDatabase.get_unlock(unlock_id)
		if unlock == null:
			continue
		var item := ItemDatabase.get_item(unlock.item_id)
		if item != null:
			result.append(item)
	return result


## Zera o save. Usado em testes para nao vazar estado entre execucoes.
func reset() -> void:
	total_cera = 0
	runs = 0
	best_score = 0
	unlocks.clear()
	save_game()