extends SceneTree
## Ejecutor mínimo de pruebas, sin complementos:
##   godot --headless --path . --script res://tests/run_tests.gd
## Carga cada archivo test_*.gd de tests/ y ejecuta sus métodos test_*. Con la variable
## PRUEBAS_SOLO, solo los archivos cuyo nombre la contiene.
## Una prueba falla si devuelve un motivo o si durante ella hubo cualquier error de script.
## Sale con código 1 si alguna prueba falla.

const CARPETA := "res://tests/"
const RegistroErrores := preload("res://tests/registro_errores.gd")
## Límite de toda la ejecución. Se puede cambiar con la variable LIMITE_PRUEBAS_S.
const LIMITE_S := 300

var _vigilante := Thread.new()
var _terminado := false
var _empezado := false


func _initialize() -> void:
	_vigilante.start(_vigilar)


## Las pruebas corren en el primer fotograma: en _initialize el árbol aún no existe
## y las pruebas de pantallas no podrían añadir nodos.
func _process(_delta: float) -> bool:
	if not _empezado:
		_empezado = true
		_ejecutar()
	return false


func _ejecutar() -> void:
	var registro := RegistroErrores.new()
	OS.add_logger(registro)
	var fallos := 0
	var total := 0
	# PRUEBAS_SOLO=planta ejecuta solo los archivos cuyo nombre contiene «planta».
	var solo := OS.get_environment("PRUEBAS_SOLO")
	for archivo in DirAccess.get_files_at(CARPETA):
		if not (archivo.begins_with("test_") and archivo.ends_with(".gd")):
			continue
		if not solo.is_empty() and not archivo.contains(solo):
			continue
		# Un error aquí no debe impedir llegar a quit(): Godot se quedaría esperando para siempre.
		var guion: GDScript = load(CARPETA + archivo)
		var errores_carga := registro.recoger()
		if guion == null or not guion.can_instantiate() or not errores_carga.is_empty():
			total += 1
			fallos += 1
			printerr("FALLO %s -> el archivo no compila: %s" % [archivo, "; ".join(errores_carga)])
			continue
		var suite: RefCounted = guion.new()
		for metodo in suite.get_method_list():
			var nombre: String = metodo["name"]
			if not nombre.begins_with("test_"):
				continue
			total += 1
			var inicio := Time.get_ticks_msec()
			var resultado: Variant = suite.call(nombre)
			var ms := Time.get_ticks_msec() - inicio
			var errores := registro.recoger()
			var motivo: String = resultado if resultado is String else "no devolvió un resultado"
			if not errores.is_empty():
				motivo = "error de script: %s" % errores[0]
			if motivo.is_empty():
				print("ok    %s::%s (%d ms)" % [archivo, nombre, ms])
			else:
				fallos += 1
				printerr("FALLO %s::%s (%d ms) -> %s" % [archivo, nombre, ms, motivo])
	print("%d pruebas, %d fallos" % [total, fallos])
	OS.remove_logger(registro)
	_terminado = true
	_vigilante.wait_to_finish()
	quit(1 if fallos > 0 or total == 0 else 0)


## Corre en otro hilo: si una prueba entra en un bucle infinito, o si el ejecutor no llega
## a quit(), aborta el proceso con error en vez de dejarlo esperando para siempre.
func _vigilar() -> void:
	var limite := OS.get_environment("LIMITE_PRUEBAS_S").to_int()
	var fin := Time.get_ticks_msec() + (limite if limite > 0 else LIMITE_S) * 1000
	while not _terminado:
		if Time.get_ticks_msec() > fin:
			OS.crash("Las pruebas superaron el tiempo límite: posible cuelgue.")
		OS.delay_msec(200)
