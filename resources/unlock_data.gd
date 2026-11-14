class_name UnlockData
extends Resource
## Desbloqueio permanente da meta-progressão.
##
## Todo desbloqueio entrega um **item inicial** na próxima run — nunca um "+10% de
## dano" genérico. Assim a meta-progressão conversa com o Feixe e com as sinergias.

@export var id: StringName
@export var display_name: String
@export var description: String
@export var cost: int = 30
## Item entregue no início da run (id em `ItemDatabase`).
@export var item_id: StringName