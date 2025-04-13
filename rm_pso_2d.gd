extends Node2D
'''NOTAS
Colocar obstaculos
ajustar el numero de iteraciones
guardo los 100 mejores distancias
y al final con una velocidad fija recorremos los 100 y ya hacemos
la comparacion con el tiempo
(y sera la comparacion)
como justificacion es el hecho nos interasa saber el tiempo definido (real)

'''

@export var global_iteration = 100 #iteracion de todo el algoritmo (reset)

@export var target_position: Vector2 = Vector2(100, 100)  # Objetivo que deben alcanzar las abejas
@export var w: float = 0.5  # Factor de inercia (0.4 - 0.9)
@export var c1: float = 1.5  # Coeficiente de aceleración personal (1.0 - 2.5)
@export var c2: float = 1.5  # Coeficiente de aceleración global (1.0 - 2.5)

# Nuevos parámetros para controlar la exploración
@export var exploration_factor: float = 0.3  # Cuánto exploran aleatoriamente (0-1)
@export var max_speed: float = 5.0  # Velocidad máxima inicial
@export var min_speed: float = 1.0  # Velocidad mínima para mantener exploración
@export var ignore_global_prob: float = 0.2  # Probabilidad de ignorar el mejor global

var global_best_position := Vector2.ZERO  # Mejor posición global
var bee_array = []
var iterations = 0
@export_enum("Sphere", "Rastrigin") var function_objective: String = "Sphere"
@export var numbers_of_bees = 40
var count = 0
var finish_iteration = false
var compare_distance_array = []
var shortest_distance
@onready var bee_scene = preload("res://scenes/bee.tscn")
@onready var honeycomb_scene = preload("res://scenes/honeycomb.tscn")

var cam
var drag = false #arrastrar cam

func _ready() -> void:
	print(function_objective)
	_create_honeycomb()
	for i in numbers_of_bees:
		_create_bee()
	global_best_position = bee_array[0].position  # Inicializar con una posición aleatoria

func _input(event):
	if event.is_action_pressed("ui_r"):
		get_tree().reload_current_scene()
	# Detectar cuando se presiona el botón del mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		drag = event.pressed

	# Si se está arrastrando, mover la cámara usando el cambio de posición (event.relative)
	if event is InputEventMouseMotion and drag and cam:
		cam.position -= event.relative  # Restar porque el movimiento del mouse es inverso

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		cam.zoom *= 0.95  # Acercar
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		cam.zoom *= 1.05  # Alejar

func _process(delta: float) -> void:
	iterations += 1
	for bee in bee_array:
		if bee.reached_goal:
			continue
		
		# Coeficientes que cambian con el tiempo para favorecer exploración al inicio
		var current_w = w * (1.0 - iterations/1000.0)  # Reducir inercia con el tiempo
		var current_c1 = c1 * (1.0 + exploration_factor * randf())  # Variar confianza personal
		var current_c2 = c2 * (0.5 + randf() * 0.5)  # Variar confianza global
		
		var r1 = randf()
		var r2 = randf()
		
		# A veces ignorar el mejor global para explorar
		var use_global = global_best_position
		if randf() < ignore_global_prob:
			use_global = bee.position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		
		# Componentes con factores de exploración
		var cognitive_component = current_c1 * r1 * (bee.best_position - bee.position)
		var social_component = current_c2 * r2 * (use_global - bee.position)
		var exploration_component = exploration_factor * Vector2(randf_range(-1, 1), randf_range(-1, 1)) * max_speed
		
		bee.velocity = (current_w * bee.velocity) + cognitive_component + social_component + exploration_component
		
		# Velocidad adaptativa - más lenta cuando cerca del objetivo para mejor precisión
		var target_dist = bee.position.distance_to(target_position)
		var adaptive_speed = lerp(min_speed, max_speed, clamp(target_dist/200.0, 0.1, 1.0))
		bee.velocity = bee.velocity.limit_length(adaptive_speed)
		
		bee.position += bee.velocity
		bee.distance_traveled += bee.velocity.length()
		
		if bee.position.distance_to(target_position) < 5.0:
			bee.velocity = Vector2.ZERO
			bee.reached_goal = true
			##print("Abeja ", bee.name, " llegó. Distancia total: ", bee.distance_traveled)
			count += 1
			if count == numbers_of_bees:
				_compare_distance()
		
		# Actualización de mejores posiciones
		if function_objective == "Sphere":
			var current_fitness = _sphere_function(bee.position)
			var best_fitness = _sphere_function(bee.best_position)
			if current_fitness < best_fitness:
				bee.best_position = bee.position
			if current_fitness < _sphere_function(global_best_position):
				global_best_position = bee.position
		elif function_objective == "Rastrigin":
			var current_fitness = _rastrigin_function(bee.position)
			var best_fitness = _rastrigin_function(bee.best_position)
			if current_fitness < best_fitness:
				bee.best_position = bee.position
			if current_fitness < _rastrigin_function(global_best_position):
				global_best_position = bee.position

func _create_bee():
	var ball_instance = bee_scene.instantiate()
	var bee_index = bee_array.size() + 1
	ball_instance.name = "Bee" + str(bee_index)
	
	var area_node = $Area2D/CollisionShape2D
	var shape = area_node.shape
	var area_size = shape.extents * 2
	var area_top_left = area_node.global_position - shape.extents
	
	var random_x = randf_range(area_top_left.x, area_top_left.x + area_size.x)
	var random_y = randf_range(area_top_left.y, area_top_left.y + area_size.y)
	ball_instance.position = Vector2(random_x, random_y)
	add_child(ball_instance)
	bee_array.append(ball_instance)
	ball_instance.best_position = ball_instance.position  # Inicializar mejor posición personal
	
	if ball_instance.name == "Bee1":
		#print("camera assign")
		
		print("Cámara creada")
		var camara = Camera2D.new()
		camara.zoom = Vector2(1, 1)
		camara.rotation_degrees = 0
		camara.name = "CAM"
		
		add_child(camara)
		camara.make_current()
		cam = get_node("CAM")
		pass

func _create_honeycomb():
	var ball_instance = honeycomb_scene.instantiate()
	ball_instance.position = target_position
	add_child(ball_instance)

func _compare_distance():
	print("ORDENAMIENTO BURBUJA TIEMPO")
	for j in bee_array.size() - 1:
		for i in bee_array.size() - 1:
			#if bee_array[i].time > bee_array[i+1].time:
			if bee_array[i].distance_traveled > bee_array[i+1].distance_traveled:
				var aux = bee_array[i]
				bee_array[i] = bee_array[i+1]
				bee_array[i+1] = aux
	
	for i in bee_array.size():
		print("Particula: ",bee_array[i].name," Posicion: ", i + 1, " Distancia: ", bee_array[i].distance_traveled, " Tiempo: ", bee_array[i].time)
	
	#MEJOR TIEMPO
	bee_array[0].color_line = Color(0,0,1)#azul
	bee_array[0].width = 4.0#anchura
	bee_array[0].z_index = 10#index

func _sphere_function(position: Vector2) -> float:
	var relative_position = position - target_position
	return relative_position.x * relative_position.x + relative_position.y * relative_position.y

func _rastrigin_function(position: Vector2) -> float:
	var A = 10
	var x_offset = position.x - target_position.x
	var y_offset = position.y - target_position.y
	return 2 * A + (x_offset * x_offset - A * cos(2 * PI * x_offset)) + (y_offset * y_offset - A * cos(2 * PI * y_offset))
