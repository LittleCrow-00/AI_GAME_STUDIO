extends Node
## Banco de desbloqueios da meta-progressão.
##
## Lista explícita (como `ItemDatabase`/`ThresholdDatabase`) para sobreviver ao
## export Web. Adicionar desbloqueio = `.tres` + uma linha aqui.

const ALL: Array[UnlockData] = [
	preload("res://data/unlocks/pavio_extra.tres"),
	preload("res://data/unlocks/oleo_frio.tres"),
	preload("res://data/unlocks/lente_estadio.tres"),
	preload("res://data/unlocks/casca_grossa.tres"),
	preload("res://data/unlocks/pavio_duplo.tres"),
]


func count() -> int:
	return ALL.size()


func get_unlock(unlock_id: StringName) -> UnlockData:
	for unlock in ALL:
		if unlock.id == unlock_id:
			return unlock
	return null


## Desbloqueios ainda não comprados, na ordem do banco.
func locked() -> Array[UnlockData]:
	var result: Array[UnlockData] = []
	for unlock in ALL:
		if not SaveSystem.has_unlock(unlock.id):
			result.append(unlock)
	return result