extends Node
## Banco de limiares da Ressonância.
##
## Lista explícita (como o `ItemDatabase`) porque o export Web nem sempre
## preserva a listagem de diretórios. Adicionar limiar = `.tres` + uma linha.

const ALL: Array[ThresholdData] = [
	preload("res://data/thresholds/chain_10.tres"),
	preload("res://data/thresholds/chain_25.tres"),
	preload("res://data/thresholds/chain_50.tres"),
]


func count() -> int:
	return ALL.size()


func get_threshold(threshold_id: StringName) -> ThresholdData:
	for threshold in ALL:
		if threshold.id == threshold_id:
			return threshold
	return null


## Menor limiar ainda não alcançado, ou `null` quando a cadeia passou de todos.
func next_after(chain: int) -> ThresholdData:
	var best: ThresholdData = null
	for threshold in ALL:
		if threshold.at_chain <= chain:
			continue
		if best == null or threshold.at_chain < best.at_chain:
			best = threshold
	return best


## Limiares cruzados entre `previous` e `current` (cadeia só cresce 1 por acerto,
## mas a checagem é por intervalo para não depender disso).
func crossed(previous: int, current: int) -> Array[ThresholdData]:
	var result: Array[ThresholdData] = []
	for threshold in ALL:
		if threshold.at_chain > previous and threshold.at_chain <= current:
			result.append(threshold)
	return result