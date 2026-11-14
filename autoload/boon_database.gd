extends Node
## Banco de oferendas. Carregar de `res://data/boons/` em runtime seria mais
## "puro", mas o export Web nem sempre preserva a listagem de diretórios — então
## a lista é explícita aqui. Adicionar oferenda = criar o .tres + uma linha.

const ALL: Array[BoonData] = [
	preload("res://data/boons/lente_maior.tres"),
	preload("res://data/boons/pavio_grosso.tres"),
	preload("res://data/boons/oleo_frio.tres"),
	preload("res://data/boons/casca_grossa.tres"),
	preload("res://data/boons/passo_leve.tres"),
	preload("res://data/boons/folego.tres"),
	preload("res://data/boons/foco_rapido.tres"),
	preload("res://data/boons/angulo_largo.tres"),
	preload("res://data/boons/cera_velha.tres"),
]


func draw(count: int, stream: StringName = &"loot") -> Array[BoonData]:
	var pool := ALL.duplicate()
	var result: Array[BoonData] = []
	var picks := mini(count, pool.size())
	for i in range(picks):
		var index := RngService.randi_range(stream, 0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	return result