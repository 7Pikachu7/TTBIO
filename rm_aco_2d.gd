extends Node2D

# Configuración del ACO
const NUM_ANTS = 20 #20
const MAX_ITERATIONS = 20#50

#Valor 0.5-2.0 al disminuirLas hormigas exploran más aleatoriamente
const ALPHA = 1.7#1.0  # Influencia de la feromona 

#Valor típico: Usualmente mayor que ALPHA (ej. 2.0-5.0)Efecto al aumentar:Las hormigas prefieren caminos más cortos
const BETA = 3.5 #0.1  # 1 Influencia de la distancia/heurística

#aumentar Los rastros de feromonas desaparecen más rápido
const RHO = 0.2    # Tasa de evaporación Valor típico: Entre 0.01-0.2

#Efecto al aumentar:Los caminos buenos se refuerzan más rápidamente
const Q = 1.0      # Cantidad de feromona a depositar Valor típico: Suele ser 1.0, pero depende de la escala de tus distancias

var cities = []    # Nodos/ciudades
var distances = [] # Matriz de distancias
var pheromones = [] # Matriz de feromonas
var best_path = []
var best_distance = INF

var ant_scene = preload("res://scenes/ant.tscn")

# Puntos de inicio y fin
var start_point = Vector2(100, 300)
var end_point = Vector2(900, 300)
@export var intermediate_points = 30 # Puntos intermedios

func _ready():
	# Inicializar ciudades
	initialize_cities()
	
	# Calcular matriz de distancias
	calculate_distances()
	
	# Inicializar feromonas
	initialize_pheromones()
	
	# Ejecutar el algoritmo ACO
	run_aco()

func initialize_cities():
	# Punto de inicio
	cities.append(start_point)
	
	# Puntos intermedios aleatorios
	for i in range(intermediate_points):
		cities.append(Vector2(
			randf_range(150, 850),
			randf_range(100, 500)
		))
	
	# Punto final
	cities.append(end_point)

func calculate_distances():
	distances.resize(cities.size())
	for i in cities.size():
		distances[i] = []
		distances[i].resize(cities.size())
		for j in cities.size():
			distances[i][j] = cities[i].distance_to(cities[j])

func initialize_pheromones():
	pheromones.resize(cities.size())
	for i in cities.size():
		pheromones[i] = []
		pheromones[i].resize(cities.size())
		for j in cities.size():
			pheromones[i][j] = 0.1  # Valor inicial pequeño

func run_aco():
	for iteration in MAX_ITERATIONS:
		var ants = []
		var paths = []
		var path_distances = []
		
		# Crear hormigas
		for i in NUM_ANTS:
			var ant = ant_scene.instantiate()
			add_child(ant)
			ants.append(ant)
			ant.position = start_point
			ant.current_city = 0
			ant.path = [0]
			ant.at_end = false
		
		# Mover todas las hormigas en paralelo
		await move_ants_parallel(ants, iteration)
		
		# Actualizar feromonas con los caminos encontrados
		update_pheromones_from_ants(ants)
		
		# Evaporar feromonas
		evaporate_pheromones()
		
		# Dibujar el mejor camino hasta ahora
		queue_redraw()
		
		# Pequeña pausa para visualización
		await get_tree().create_timer(0.5).timeout

func move_ants_parallel(ants: Array, iteration: int):
	var ants_finished = 0
	var ants_moving = ants.duplicate()
	
	while ants_finished < ants.size():
		for ant in ants_moving:
			if ant.at_end:
				continue
				
			# Seleccionar siguiente ciudad
			var next_city = select_next_city(ant)
			if next_city == -1:
				ant.at_end = true
				ants_finished += 1
				continue
				
			# Mover hormiga (sin esperar)
			var tween = create_tween()
			tween.tween_property(ant, "position", cities[next_city], 0.3)
			
			# Actualizar estado de la hormiga
			ant.current_city = next_city
			ant.path.append(next_city)
			
			# Verificar si llegó al final
			if next_city == cities.size() - 1:
				ant.at_end = true
				ants_finished += 1
				
				# Calcular distancia del camino
				var dist = calculate_path_distance(ant.path)
				if dist < best_distance:
					best_distance = dist
					best_path = ant.path.duplicate()
		
		# Pequeña pausa entre movimientos
		await get_tree().create_timer(0.1).timeout

func select_next_city(ant) -> int:
	var current = ant.current_city
	var unvisited = []
	
	# Encontrar ciudades no visitadas
	for i in cities.size():
		if i != current and not ant.path.has(i):
			unvisited.append(i)
	
	if unvisited.is_empty():
		return -1  # No hay ciudades no visitadas
	
	# Calcular probabilidades
	var probabilities = []
	var total = 0.0
	
	for city in unvisited:
		var pheromone = pheromones[current][city]
		var distance = distances[current][city]
		var value = pow(pheromone, ALPHA) * pow(1.0/distance, BETA)
		probabilities.append(value)
		total += value
	
	# Seleccionar ciudad basada en probabilidades
	if total == 0:
		return unvisited[randi() % unvisited.size()]
	
	var r = randf() * total
	var sum = 0.0
	
	for i in probabilities.size():
		sum += probabilities[i]
		if r <= sum:
			return unvisited[i]
	
	return unvisited[-1]

func calculate_path_distance(path: Array) -> float:
	var distance = 0.0
	for i in path.size() - 1:
		distance += distances[path[i]][path[i+1]]
	return distance

func update_pheromones_from_ants(ants: Array):
	for ant in ants:
		if ant.path.size() < 2 or ant.path[-1] != cities.size() - 1:
			continue  # Solo considerar hormigas que llegaron al final
			
		var distance = calculate_path_distance(ant.path)
		var delta_pheromone = Q / distance
		
		for j in ant.path.size() - 1:
			var from = ant.path[j]
			var to = ant.path[j+1]
			pheromones[from][to] += delta_pheromone
			pheromones[to][from] += delta_pheromone  # Feromona simétrica

func evaporate_pheromones():
	for i in cities.size():
		for j in cities.size():
			pheromones[i][j] *= (1.0 - RHO)
			if pheromones[i][j] < 0.1:  # Valor mínimo
				pheromones[i][j] = 0.1

func _draw():
	# Dibujar ciudades/nodos
	for i in cities.size():
		if i == 0:
			draw_circle(cities[i], 8, Color.GREEN)  # Inicio (verde)
		elif i == cities.size() - 1:
			draw_circle(cities[i], 8, Color.RED)    # Fin (rojo)
		else:
			draw_circle(cities[i], 5, Color.WHITE)  # Intermedios (blanco)
		
		# Mostrar número de nodo
		draw_string(ThemeDB.fallback_font, cities[i] + Vector2(10, -10), str(i), 
				   HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	
	# Dibujar todas las conexiones del grafo con intensidad basada en feromonas
	for i in cities.size():
		for j in cities.size():
			if i != j:
				var pheromone = pheromones[i][j]
				var color = Color(0.5, 0.5, 1.0, clamp(pheromone, 0.1, 1.0))
				draw_line(cities[i], cities[j], color, 1.0)
	
	# Dibujar el mejor camino encontrado
	if best_path.size() > 1:
		for i in best_path.size() - 1:
			var from = cities[best_path[i]]
			var to = cities[best_path[i+1]]
			draw_line(from, to, Color.YELLOW, 3.0)
