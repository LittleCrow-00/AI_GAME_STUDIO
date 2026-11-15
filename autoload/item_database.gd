extends Node
## Banco de itens da run.
##
## A lista é explícita (e não uma varredura de `res://data/items/`) porque o
## export Web nem sempre preserva a listagem de diretórios. Adicionar item =
## criar o `.tres` + uma linha aqui.

const ALL: Array[ItemData] = [
	preload("res://data/items/lente_maior.tres"),
	preload("res://data/items/pavio_grosso.tres"),
	preload("res://data/items/oleo_frio.tres"),
	preload("res://data/items/casca_grossa.tres"),
	preload("res://data/items/passo_leve.tres"),
	preload("res://data/items/folego.tres"),
	preload("res://data/items/foco_rapido.tres"),
	preload("res://data/items/angulo_largo.tres"),
	preload("res://data/items/cera_velha.tres"),
	preload("res://data/items/pavio_duplo.tres"),
	preload("res://data/items/oleo_espesso.tres"),
	preload("res://data/items/amuleto_de_osso.tres"),
	preload("res://data/items/lamparina.tres"),
	preload("res://data/items/casca_fina.tres"),
	preload("res://data/items/pavio_curto.tres"),
	preload("res://data/items/bota_de_couro.tres"),
	preload("res://data/items/lente_rachada.tres"),
	preload("res://data/items/sino_rachado.tres"),
	preload("res://data/items/olho_de_boto.tres"),
	preload("res://data/items/fragmento.tres"),
	preload("res://data/items/olho_vitreo.tres"),
	preload("res://data/items/brasa.tres"),
	preload("res://data/items/contagio.tres"),
	preload("res://data/items/sangue_quente.tres"),
	preload("res://data/items/furador.tres"),
	preload("res://data/items/estopim.tres"),
	preload("res://data/items/pavio_de_cera.tres"),
	preload("res://data/items/olho_de_vidro.tres"),
	preload("res://data/items/bolsao_de_oleo.tres"),
	preload("res://data/items/anzol_de_osso.tres"),
	preload("res://data/items/oleo_velho.tres"),
]

const CURSED_CHANCE: float = 0.12


func count() -> int:
	return ALL.size()


func get_item(item_id: StringName) -> ItemData:
	for item in ALL:
		if item.id == item_id:
			return item
	return null


## Sorteia `count` itens distintos. Maldições só aparecem a partir da 2ª sala.
func draw(count: int, room_index: int = 0, stream: StringName = &"loot") -> Array[ItemData]:
	var pool := ALL.duplicate()
	if room_index < 1:
		pool = _without_cursed(pool)
	else:
		pool = _filter_cursed(pool)

	var picks := mini(count, pool.size())
	var result: Array[ItemData] = []
	for i in range(picks):
		var index := RngService.randi_range(stream, 0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	return result


## Sala 0 é determinística: nenhuma maldição, sem sorteio.
func _without_cursed(pool: Array) -> Array:
	var filtered := []
	for item in pool:
		if item.rarity != ItemData.Rarity.CURSED:
			filtered.append(item)
	return filtered


## A partir da 2ª sala, cada maldição tem 12% de chance de entrar no sorteio.
func _filter_cursed(pool: Array) -> Array:
	var filtered := []
	for item in pool:
		if item.rarity == ItemData.Rarity.CURSED and randf() > CURSED_CHANCE:
			continue
		filtered.append(item)
	return filtered