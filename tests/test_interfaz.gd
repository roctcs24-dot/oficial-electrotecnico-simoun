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


func _barras(nodo: Node) -> int:
	var n := 1 if nodo is BarraNavegacion else 0
	for hijo in nodo.get_children():
		n += _barras(hijo)
	return n


func test_ruta_recomienda_la_primera_leccion_pendiente() -> String:
	var c := Contenido.new()
	var p := Partida.new("user://pruebas_ruta.json")
	var primera := Ruta.siguiente(c, p)
	var s0: Array = c.sistema(0)["modos"]["aprender"]["lecciones"]
	for id: String in s0:
		p.datos["lecciones"][id] = {"aciertos": 1, "total": 1}
	var tras_sistema_0 := Ruta.siguiente(c, p)
	return A.primero([
		A.cierto(primera["sistema"] == 0 and primera["numero"] == 1, "empieza por la primera lección del sistema 0: %s" % str(primera)),
		A.cierto(tras_sistema_0["sistema"] == 1 and tras_sistema_0["numero"] == 1, "hecho el sistema 0, sigue el 1: %s" % str(tras_sistema_0)),
	])


func test_barra_solo_en_las_secciones_y_atajo_al_inicio() -> String:
	var raiz := _raiz()
	var en_inicio := _barras(raiz.pantalla_actual())
	var es_inicio := raiz.nombre_actual() == "inicio"
	raiz.ir_a("sistema", {"id": 3})
	var en_sistema := _barras(raiz.pantalla_actual())
	raiz.ir_a("aprender", {"id": 3})
	var atajo := raiz.pantalla_actual().find_children("*", "Button", true, false).any(func(b: Node) -> bool: return (b as Button).tooltip_text == "Inicio")
	raiz.ir_a_seccion("progreso")
	var en_progreso := _barras(raiz.pantalla_actual())
	var nivel := raiz.nivel()
	raiz._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	var vuelve_al_inicio := raiz.nombre_actual() == "inicio"
	raiz.free()
	return A.primero([
		A.cierto(es_inicio and en_inicio == 1, "el juego abre en el inicio con su barra"),
		A.cierto(en_sistema == 0, "dentro de un sistema no hay barra"),
		A.cierto(atajo, "en el tercer nivel hay un atajo al inicio"),
		A.cierto(en_progreso == 1 and nivel == 1, "cada sección empieza una pila nueva con su barra"),
		A.cierto(vuelve_al_inicio, "atrás en una sección vuelve al inicio"),
	])


func test_zona_del_plano_alcanzable_con_el_dedo() -> String:
	var plano := PlanoInteractivo.new()
	var c := Contenido.new()
	plano.sistemas = c.sistemas()
	plano.cargar(c.plano())
	plano.size = Vector2(380, 170)
	var fallos := []
	for s: Dictionary in plano.sistemas:
		var r := plano._rect_zona(s)
		# A 20 puntos del borde de la zona, el dedo todavía la alcanza.
		var punto := Vector2(r.get_center().x, r.position.y - 20.0)
		var tocado := plano.zona_en(punto)
		if tocado == -1:
			fallos.append(int(s["id"]))
	plano.free()
	return "" if fallos.is_empty() else "zonas sin margen táctil: %s" % str(fallos)


func test_escuela_y_panol_en_la_barra() -> String:
	var raiz := _raiz()
	var nombres := []
	for s: Array in BarraNavegacion.SECCIONES:
		nombres.append(s[0])
	raiz.ir_a_seccion("escuela")
	var filas_escuela: Array[FilaMenu] = []
	_filas(raiz.pantalla_actual(), filas_escuela)
	raiz.ir_a_seccion("panol")
	var filas_panol: Array[FilaMenu] = []
	_filas(raiz.pantalla_actual(), filas_panol)
	filas_panol[0].pulsada.emit()
	var fichas := raiz.nombre_actual() == "fichas_equipos"
	var filas_fichas: Array[FilaMenu] = []
	_filas(raiz.pantalla_actual(), filas_fichas)
	var modulos := raiz.contenido.modulos_escuela().size()
	raiz.free()
	return A.primero([
		A.cierto(nombres == ["inicio", "escuela", "plano_barco", "panol", "progreso"], "secciones: %s" % str(nombres)),
		A.cierto(filas_escuela.size() == modulos + 1, "la Escuela lista los fundamentos y %d módulos: %d filas" % [modulos, filas_escuela.size()]),
		A.cierto(fichas and filas_fichas.size() >= 30, "el Pañol abre las fichas de equipos: %d" % filas_fichas.size()),
	])


func test_modulos_de_la_escuela_con_id_color_e_icono() -> String:
	var c := Contenido.new()
	var ids := []
	for m: Dictionary in c.modulos_escuela():
		ids.append(int(m["id"]))
		if not ResourceLoader.exists("res://art/iconos/%s.svg" % m.get("icono", "")) and not FileAccess.file_exists("res://art/iconos/%s.svg" % m.get("icono", "")):
			return "el módulo %d no tiene icono" % int(m["id"])
		if c.sistema(int(m["id"])).is_empty():
			return "contenido.sistema() no encuentra el módulo %d" % int(m["id"])
	return A.cierto(ids == [7, 8, 9, 10, 11], "módulos 7 a 11: %s" % str(ids))


func test_partida_antigua_recibe_ajustes_y_la_prueba_no_ve_la_bienvenida() -> String:
	var p := Partida.new("user://pruebas_ajustes.json")
	var antigua := Partida.datos_nuevos()
	antigua.erase("ajustes")
	var motivo := p.desde_texto(JSON.stringify(antigua))
	var raiz := _raiz()
	var en_inicio := raiz.nombre_actual() == "inicio"
	raiz.free()
	return A.primero([
		A.cierto(motivo.is_empty(), "una partida sin ajustes se carga: %s" % motivo),
		A.cierto(p.datos["ajustes"]["bienvenida_vista"] == false and is_equal_approx(p.datos["ajustes"]["tamano_texto"], 1.0), "recibe los ajustes por defecto"),
		A.cierto(en_inicio, "en las pruebas el juego abre en el inicio, sin bienvenida"),
	])


func test_bienvenida_se_recorre_y_queda_vista() -> String:
	var raiz := _raiz()
	raiz.ir_a("bienvenida")
	var p = raiz.pantalla_actual()
	p._ir(1)
	p = raiz.pantalla_actual()
	p._ir(2)
	raiz.pantalla_actual().terminar()
	var vista: bool = raiz.partida.datos["ajustes"]["bienvenida_vista"]
	var vuelve := raiz.nombre_actual() == "inicio"
	raiz.free()
	return A.primero([
		A.cierto(vista, "al terminar queda marcada como vista"),
		A.cierto(vuelve, "y vuelve al inicio"),
	])


func test_tamano_de_texto_cambia_el_tema_y_se_guarda() -> String:
	var raiz := _raiz()
	var normal := raiz.theme.default_font_size
	raiz.aplicar_tamano_texto(1.3)
	var grande := raiz.theme.default_font_size
	var guardado: float = raiz.partida.datos["ajustes"]["tamano_texto"]
	raiz.aplicar_tamano_texto(1.0)
	raiz.free()
	return A.primero([
		A.cierto(grande > normal, "la letra crece: %d → %d" % [normal, grande]),
		A.cierto(is_equal_approx(guardado, 1.3), "el tamaño queda en la partida"),
		A.cierto(is_equal_approx(Tema.escala_texto, 1.0), "se puede volver al normal"),
	])
