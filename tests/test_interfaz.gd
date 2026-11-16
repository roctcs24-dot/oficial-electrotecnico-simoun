extends RefCounted
## Estilo oscuro con color por área: contraste legible, filas con marca y avance, modos sin
## contenido ocultos y la siguiente lección resaltada.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_interfaz.json"


func _raiz() -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	return raiz


func _filas(nodo: Node, lista: Array[FilaMenu]) -> void:
	if nodo is FilaMenu:
		lista.append(nodo)
	for hijo in nodo.get_children():
		_filas(hijo, lista)


func _marcas(nodo: Node) -> int:
	var n := 1 if nodo is MarcaHecho else 0
	for hijo in nodo.get_children():
		n += _marcas(hijo)
	return n


func test_textos_con_contraste_suficiente() -> String:
	var pares := [
		["texto sobre fondo", Tema.TEXTO, Tema.FONDO],
		["texto sobre tarjeta", Tema.TEXTO, Tema.PANEL],
		["nota sobre tarjeta", Tema.TEXTO_SUAVE, Tema.PANEL],
		["nota sobre fondo", Tema.TEXTO_SUAVE, Tema.FONDO],
		["rótulo sobre fondo", Tema.ACENTO, Tema.FONDO],
		["texto de botón", Tema.TEXTO, Tema.BOTON],
	]
	for p: Array in pares:
		var c := Tema.contraste(p[1], p[2])
		if c < 4.5:
			return "%s: contraste %.2f, por debajo de 4,5" % [p[0], c]
	return ""


func test_todos_los_sistemas_tienen_color() -> String:
	for s: Dictionary in Contenido.new().sistemas():
		if not s.has("color"):
			return "el sistema %d no tiene color" % int(s["id"])
		if not Color.html_is_valid(str(s["color"])):
			return "color no válido en el sistema %d: %s" % [int(s["id"]), s["color"]]
	return ""


func test_fila_con_marca_y_avance() -> String:
	var f := FilaMenu.new()
	f.iniciar("Título", "Detalle", "leccion", "3 de 4", true, {"color": Color("2563a8"), "avance": 0.75, "hecho": true})
	var barras := f.find_children("*", "ProgressBar", true, false)
	var barra_bien := barras.size() == 1 and is_equal_approx((barras[0] as ProgressBar).value, 0.75)
	var marca := _marcas(f)
	var alto := f.get_combined_minimum_size().y
	f.free()
	return A.primero([
		A.cierto(barra_bien, "lleva la barra de avance al 75 %"),
		A.cierto(marca == 1, "lleva la marca de hecho"),
		A.cierto(alto >= 48.0, "mide al menos 48 de alto: %.0f" % alto),
	])


func test_sistema_solo_muestra_sus_modos_con_avance() -> String:
	var raiz := _raiz()
	var fallos := []
	for s: Dictionary in raiz.contenido.sistemas():
		raiz.ir_a("sistema", {"id": int(s["id"])})
		var filas: Array[FilaMenu] = []
		_filas(raiz.pantalla_actual(), filas)
		if filas.size() != s["modos"].size():
			fallos.append("sistema %d: %d filas para %d modos" % [int(s["id"]), filas.size(), s["modos"].size()])
		raiz.volver()
	raiz.free()
	return "" if fallos.is_empty() else ", ".join(fallos)


func test_aprender_resalta_la_siguiente_y_marca_las_hechas() -> String:
	var raiz := _raiz()
	var s := raiz.contenido.sistema(3)
	var lecciones: Array = s["modos"]["aprender"]["lecciones"]
	raiz.partida.completar_leccion(lecciones[0], 3, 3)
	raiz.ir_a("aprender", {"id": 3})
	var filas: Array[FilaMenu] = []
	_filas(raiz.pantalla_actual(), filas)
	var segunda_siguiente := filas.size() > 1 and filas[1].siguiente and not filas[0].siguiente
	var marcas := _marcas(filas[0])
	var primera_sin_marca := _marcas(filas[1]) == 0
	raiz.free()
	return A.primero([
		A.cierto(segunda_siguiente, "la segunda lección es la siguiente recomendada"),
		A.cierto(marcas == 1, "la primera, hecha, lleva su marca"),
		A.cierto(primera_sin_marca, "la siguiente no lleva marca"),
	])


func test_avance_cuenta_lecciones_misiones_y_examenes() -> String:
	var p := Partida.new()
	var s := Contenido.new().sistema(3)
	var lecciones: Array = s["modos"]["aprender"]["lecciones"]
	var misiones: Array = s["modos"]["guardia"]["misiones"]
	p.datos["lecciones"][lecciones[0]] = {"aciertos": 1, "total": 1}
	p.datos["misiones"][misiones[0]] = {"completada": true, "estrellas": 3}
	var l := Avance.lecciones(s, p)
	var m := Avance.misiones(s, p)
	var total := Avance.sistema(s, p)
	return A.primero([
		A.cierto(l[0] == 1 and l[1] == lecciones.size(), "lecciones: %s" % str(l)),
		A.cierto(m[0] == 1 and m[1] == misiones.size(), "misiones: %s" % str(m)),
		A.cierto(total[0] == 2, "el sistema suma lo hecho: %s" % str(total)),
		A.cierto(Avance.siguiente_leccion(s, p) == lecciones[1], "la siguiente es la segunda lección"),
	])
