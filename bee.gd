
extends Node2D
var velocity := Vector2.ZERO  # Velocidad inicial de la abeja
var best_position := Vector2.ZERO  # Mejor posición personal
var direction_timer
var best_iteration
var last_direction
#var delay_timer: Timer = 0.25

#@export_flags("Fire", "Water", "Earth", "Wind") var spell_elements
##@export_enum("Sphere", "Rastrigin") var function_objective: String = "Sphere"
#esto es solo para saber la distancia recorrida
var distance_traveled := 0.0  # Distancia total recorrida
var reached_goal := false  # Estado de la abeja
var color_line = Color(1,0,0)
var width = 2.0
var time := 0.0  # Inicia en 0 segundos
#'''

#varibales que no afectan al principal
var trail := []  # Lista para almacenar la trayectoria
func _ready() -> void:
	#print("soy una abeja")
	#print(name)
	pass
func _process(delta: float) -> void:
	
	#print("Tiempo transcurrido: ", tiempo)
	
	# Guardar la posición actual en el historial
	if !reached_goal:
		trail.append(position)
		time += delta  # Suma el tiempo transcurrido en cada frame
	
	# Limitar la cantidad de puntos en la trayectoria para no sobrecargar la memoria
	if trail.size() > 1000:
		trail.pop_front()#elimina el primer dato del aregglo
	
	# Llamar a queue_redraw() para actualizar la visualización
	queue_redraw()

func _draw() -> void:
	# Dibujar la trayectoria
	for i in range(1, trail.size()):
		
		draw_line(trail[i - 1] - global_position, trail[i] - global_position, color_line, width)
