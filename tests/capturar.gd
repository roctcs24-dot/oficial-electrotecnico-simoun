extends SceneTree
## Guarda imágenes de las pantallas tal como las dibuja el juego, para revisarlas:
##   godot --path . --script res://tests/capturar.gd -- <carpeta de salida>
## No usa --headless porque necesita dibujar. Se excluye de las versiones exportadas.

const TAMANOS := [Vector2i(1280, 720), Vector2i(432, 960), Vector2i(960, 432)]

var _empezado := false


func _process(_delta: float) -> bool:
	if not _empezado:
		_empezado = true
		_capturar()
	return false


func _capturar() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var carpeta: String = argumentos[0] if argumentos.size() > 0 else OS.get_user_data_dir()
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = "user://pruebas_capturas.json"
	root.add_child(raiz)
	for tam: Vector2i in TAMANOS:
		root.size = tam
		await _esperar()
		await _guardar(carpeta, "plano", tam)
		raiz.ir_a("sistema", {"id": 3})
		await _guardar(carpeta, "sistema", tam)
		raiz.volver()
		raiz.ir_a("ficha", {"id": "contactor"})
		await _guardar(carpeta, "ficha", tam)
		raiz.pantalla_actual().pulsar_banco(true)
		await _guardar(carpeta, "ficha_pulsado", tam)
		raiz.pantalla_actual().pulsar_banco(false)
		raiz.volver()
		raiz.ir_a("ficha", {"id": "contactor", "vista": "simbolos"})
		await _guardar(carpeta, "simbolos", tam)
		raiz.volver()
	quit()


func _esperar() -> void:
	for _i in 12:
		await process_frame


func _guardar(carpeta: String, nombre: String, tam: Vector2i) -> void:
	await _esperar()
	await RenderingServer.frame_post_draw
	var ruta := carpeta.path_join("%s_%dx%d.png" % [nombre, tam.x, tam.y])
	root.get_texture().get_image().save_png(ruta)
	print(ruta)
