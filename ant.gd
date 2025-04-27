extends Node2D

@export var speed := 100.0

var current_city := 0
var path := []
var at_end := false
var target_city
func _ready():
	path.append(current_city)
	# Configurar apariencia visual
	$Sprite2D.modulate = Color(randf(), randf(), randf())  # Color aleatorio para cada hormiga

func _process(delta):
	# Puedes añadir lógica de animación aquí si lo deseas
	pass
