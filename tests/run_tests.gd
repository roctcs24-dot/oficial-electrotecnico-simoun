extends SceneTree
## Ejecutor mínimo de pruebas, sin complementos:
##   godot --headless --path . --script res://tests/run_tests.gd
## Carga cada archivo test_*.gd de tests/ y ejecuta sus métodos test_*.
## Sale con código 1 si alguna prueba falla.

const CARPETA := "res://tests/"


func _initialize() -> void:
	var fallos := 0
	var total := 0
	for archivo in DirAccess.get_files_at(CARPETA):
		if not (archivo.begins_with("test_") and archivo.ends_with(".gd")):
			continue
		var suite: RefCounted = load(CARPETA + archivo).new()
		for metodo in suite.get_method_list():
			var nombre: String = metodo["name"]
			if not nombre.begins_with("test_"):
				continue
			total += 1
			var error: String = suite.call(nombre)
			if error.is_empty():
				print("ok    %s::%s" % [archivo, nombre])
			else:
				fallos += 1
				printerr("FALLO %s::%s -> %s" % [archivo, nombre, error])
	print("%d pruebas, %d fallos" % [total, fallos])
	quit(1 if fallos > 0 or total == 0 else 0)
