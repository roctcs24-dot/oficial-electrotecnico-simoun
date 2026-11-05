extends RefCounted
## Las pantallas se construyen sin errores en ambas orientaciones y con botones de tamaño táctil.

const A := preload("res://tests/ayuda_sim.gd")
const ESCENA := "res://ui/raiz.tscn"
const ALTO_MIN_BOTON := 48.0
const RUTA_PARTIDA := "user://pruebas_pantallas.json"


func _crear_raiz() -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load(ESCENA).instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	return raiz


func _botones_pequenos(nodo: Node, lista: Array[String]) -> void:
	if nodo is Button and nodo.get_combined_minimum_size().y < ALTO_MIN_BOTON:
		lista.append("%s (%d)" % [nodo.text, nodo.get_combined_minimum_size().y])
	for hijo in nodo.get_children():
		_botones_pequenos(hijo, lista)


func _recorrer(raiz: Raiz) -> String:
	var pasos := [
		["sistema", {"id": 3}],
		["aprender", {"id": 3}],
		["ficha", {"id": "contactor"}],
		["ficha", {"id": "contactor", "vista": "simbolos"}],
		["aprender", {"id": 0}],
		["glosario", {}],
	]
	for id: String in raiz.contenido.sistema(0)["modos"]["aprender"]["lecciones"]:
		for n in raiz.contenido.leccion(id)["paginas"].size():
			pasos.append(["leccion", {"id": id, "sistema": 0, "pagina": n, "respuestas": {}}])
	for vertical in [false, true]:
		raiz.vertical = vertical
		raiz.reconstruir()
		for p: Array in pasos:
			raiz.ir_a(p[0], p[1])
			var pequenos: Array[String] = []
			_botones_pequenos(raiz, pequenos)
			if not pequenos.is_empty():
				return "botones bajo %d en %s: %s" % [int(ALTO_MIN_BOTON), p[0], ", ".join(pequenos)]
			raiz.volver()
	return ""


func test_recorrido_en_ambas_orientaciones() -> String:
	var raiz := _crear_raiz()
	var motivo := _recorrer(raiz)
	raiz.free()
	return motivo


func test_volver_no_sale_de_la_primera_pantalla() -> String:
	var raiz := _crear_raiz()
	raiz.volver()
	var sigue := raiz.pantalla_actual() != null
	raiz.free()
	return A.cierto(sigue, "volver en el plano debe dejar el plano")


func test_abrir_una_ficha_queda_guardado() -> String:
	var raiz := _crear_raiz()
	raiz.ir_a("ficha", {"id": "contactor"})
	raiz.free()
	var p := Partida.new(RUTA_PARTIDA)
	p.cargar()
	return A.cierto(p.ficha_vista("contactor"), "debe recordar la ficha vista")


func test_el_banco_usa_la_simulacion() -> String:
	var raiz := _crear_raiz()
	raiz.ir_a("ficha", {"id": "contactor"})
	var ficha = raiz.pantalla_actual()
	var k: SimContactor = ficha._sim.componente("K1")
	var reposo := k.cerrado()
	ficha.pulsar_banco(true)
	var pulsado := k.cerrado()
	ficha.pulsar_banco(true)
	var luz: bool = ficha._luz.encendida
	ficha.pulsar_banco(false)
	ficha.pulsar_banco(false)
	var soltado := k.cerrado()
	ficha.pulsar_banco(false)
	var luz_soltado: bool = ficha._luz.encendida
	raiz.free()
	return A.primero([
		A.cierto(not reposo, "en reposo debe estar abierto"),
		A.cierto(pulsado, "con S1 pulsado debe cerrar"),
		A.cierto(luz, "la luz debe encender por el contacto 13-14"),
		A.cierto(not soltado, "al soltar debe abrir"),
		A.cierto(not luz_soltado, "al soltar debe apagarse la luz"),
	])
