extends SceneTree
## Ejecutor mínimo de pruebas, sin complementos:
##   godot --headless --path . --script res://tests/run_tests.gd
## Carga cada archivo test_*.gd de tests/ y ejecuta sus métodos test_*.
## Una prueba falla si devuelve un motivo o si durante ella hubo cualquier error de script.
## Sale con código 1 si alguna prueba falla.

const CARPETA := "res://tests/"
const RegistroErrores := preload("res://tests/registro_errores.gd")


func _initialize() -> void:
	var registro := RegistroErrores.new()
	OS.add_logger(registro)
	var fallos := 0
	var total := 0
	for archivo in DirAccess.get_files_at(CARPETA):
		if not (archivo.begins_with("test_") and archivo.ends_with(".gd")):
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
	quit(1 if fallos > 0 or total == 0 else 0)
