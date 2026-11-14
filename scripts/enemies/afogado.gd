class_name Afogado
extends Enemy
## Inimigo base: persegue sem parar. Não tem ataque especial — é a unidade que
## ensina o jogador a ler o espaço e a gastar óleo com parcimônia.

func _ready() -> void:
	sprite_texture = preload("res://assets/sprites/afogado.svg")
	super._ready()