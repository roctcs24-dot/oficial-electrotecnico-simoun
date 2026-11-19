extends RefCounted
## Etapa 46: neumática. Modelo SimNeumatica (fuerza, velocidad con el escape frenado, filtro sucio,
## válvulas 5/2 y 5/3, detectores, posicionador de 4–20 mA, fugas y secador), lecturas del atlas,
## animaciones, módulo 9 ampliado, símbolos ISO 1219 de neumática y su minijuego.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_neumatica.json"
const ATLAS := ["unidad_fr", "secador_frigorifico", "valvula_52", "valvula_53", "cilindro_neumatico", "regulador_caudal", "actuador_cuarto_vuelta", "posicionador"]
const LECCIONES := ["ne1_aire_comprimido", "ne2_tratamiento", "ne3_unidad_frl", "ne4_cilindros", "ne5_valvulas", "ne6_velocidad",
	"ne7_electroneumatica", "ne8_actuadores_posicionadores", "ne9_fugas_seguridad"]


func _raiz(tam := Vector2i(432, 960)) -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.set_anchors_preset(Control.PRESET_TOP_LEFT)
	raiz.size = Vector2(tam)
	raiz._al_cambiar_tamano()
	raiz.reconstruir()
	return raiz


func _cerca(a: float, b: float, tolerancia: float) -> bool:
	return absf(a - b) <= tolerancia


func test_fuerza_velocidad_y_consumo_del_cilindro() -> String:
	var p := SimNeumatica.completar({})
	var a := SimNeumatica.areas(p)
	var avanza := SimNeumatica.resolver({})
	var lento := SimNeumatica.resolver({"reguladores": {"avance": 0.1}})
	var abierto := SimNeumatica.resolver({"reguladores": {"avance": 1.0}})
	var cargado := SimNeumatica.resolver({"cilindro": {"carga": 2000.0}})
	return A.primero([
		A.cierto(_cerca(a.x, 3117.2, 1.0), "área del pistón de 63 mm: %s mm²" % a.x),
		A.cierto(_cerca(avanza["fuerza"], 1683.0, 5.0), "fuerza a 6 bar: %s N" % avanza["fuerza"]),
		A.cierto(avanza["fuerza_retroceso"] < avanza["fuerza"], "al entrar empuja menos: %s" % avanza["fuerza_retroceso"]),
		A.cierto(_cerca(avanza["velocidad"], 180.0, 3.0), "con el regulador al 30 %%, unos 180 mm/s: %s" % avanza["velocidad"]),
		A.cierto(_cerca(lento["velocidad"] * 3.0, avanza["velocidad"], 1.0) and abierto["velocidad"] > 590.0, "la velocidad sigue a la apertura del regulador"),
		A.cierto(_cerca(avanza["consumo"], 8.2, 0.1), "un ciclo de Ø 63 × 200 a 6 bar gasta unos 8,2 NL: %s" % avanza["consumo"]),
		A.cierto(cargado["estado"] == "no_mueve" and cargado["velocidad"] == 0.0, "con más carga que fuerza no se mueve: %s" % cargado["estado"]),
	])


func test_filtro_sucio_hace_caer_la_presion_con_caudal() -> String:
	var limpio := SimNeumatica.resolver({})
	var sucio := SimNeumatica.resolver({"fr": {"filtro_sucio": 1.0}})
	var red_baja := SimNeumatica.resolver({"red": {"presion": 5.5}})
	var parado := SimNeumatica.presion_regulada(SimNeumatica.completar({"fr": {"filtro_sucio": 1.0}}), false)
	return A.primero([
		A.cierto(limpio["P_reg"] == 6.0, "limpio, llega a la regulada: %s" % limpio["P_reg"]),
		A.cierto(sucio["P_reg"] < 5.5 and sucio["dP_filtro"] > 1.5, "colmatado, cae con caudal: %s bar (Δp %s)" % [sucio["P_reg"], sucio["dP_filtro"]]),
		A.cierto(parado == 6.0, "sin caudal el filtro sucio no se nota: %s" % parado),
		A.cierto(red_baja["P_reg"] < 5.5, "con la red baja no llega a la regulada: %s" % red_baja["P_reg"]),
		A.cierto(sucio["velocidad"] < limpio["velocidad"], "con menos presión va algo más lento"),
	])


func test_valvulas_52_y_53() -> String:
	var m := func(v: Dictionary) -> int: return SimNeumatica.mando(SimNeumatica.completar({"valvula": v}))
	var centro := SimNeumatica.resolver({"valvula": {"tipo": "53", "y1": false, "y2": false}})
	var quemada := SimNeumatica.resolver({"valvula": {"y1": true, "bobina_quemada": true}})
	var fuga := SimNeumatica.resolver({"valvula": {"y1": false, "fuga_corredera": true}})
	return A.primero([
		A.cierto(m.call({"y1": true}) == 1 and m.call({"y1": false}) == -1, "5/2: con Y1 avanza y sin ella vuelve por muelle"),
		A.cierto(m.call({"y1": true, "bobina_quemada": true}) == -1, "con la bobina quemada no cambia"),
		A.cierto(m.call({"tipo": "53", "y1": false, "y2": false}) == 0 and m.call({"tipo": "53", "y1": true, "y2": true}) == 0, "5/3: sin bobinas o con las dos, centro"),
		A.cierto(m.call({"tipo": "53", "y2": true, "y1": false}) == -1, "5/3: con Y2 retrocede"),
		A.cierto(centro["estado"] == "parado" and centro["P_B"] > centro["P_A"], "en el centro cerrado el aire queda encerrado y la cámara anular a más presión: %s y %s" % [centro["P_A"], centro["P_B"]]),
		A.cierto(quemada["P_A"] == 0.0, "con la bobina quemada la boca 4 no recibe aire"),
		A.cierto(fuga["fuga_escape"] > 0.0, "con la corredera gastada sopla el escape"),
	])


func test_detectores_magneticos() -> String:
	var fuera := SimNeumatica.resolver({"valvula": {"y1": true}})
	var dentro := SimNeumatica.resolver({"valvula": {"y1": false}})
	var sin_iman := SimNeumatica.resolver({"valvula": {"y1": true}, "cilindro": {"sin_iman": true}})
	return A.primero([
		A.cierto(fuera["B2"] == 24.0 and fuera["B1"] == 0.0, "vástago fuera: B2 a 24 V"),
		A.cierto(dentro["B1"] == 24.0 and dentro["B2"] == 0.0, "vástago dentro: B1 a 24 V"),
		A.cierto(sin_iman["B2"] == 0.0, "sin imán o con el detector movido no hay señal"),
		A.cierto(fuera["Y1"] == 24.0 and dentro["Y1"] == 0.0, "tensión en la bobina según el mando"),
	])


func test_posicionador_4_20_mA() -> String:
	var pos := func(x: Dictionary) -> Dictionary: return SimNeumatica.posicionador({"posicionador": x})
	var cerrada: Dictionary = pos.call({"senal": 4.0})
	var media: Dictionary = pos.call({"senal": 12.0})
	var abierta: Dictionary = pos.call({"senal": 20.0})
	var sin_aire: Dictionary = pos.call({"senal": 12.0, "sin_aire": true})
	var sin_lazo: Dictionary = pos.call({"senal": 0.0})
	var membrana: Dictionary = pos.call({"senal": 20.0, "membrana_fuga": true})
	var invertido: Dictionary = pos.call({"senal": 4.0, "invertido": true})
	return A.primero([
		A.cierto(cerrada["posicion"] == 0.0 and media["posicion"] == 50.0 and abierta["posicion"] == 100.0, "4, 12 y 20 mA: 0, 50 y 100 %"),
		A.cierto(_cerca(media["P_salida"], 2.5, 0.01) and _cerca(abierta["P_salida"], 4.0, 0.01), "salida dentro del muelle de 1 a 4 bar: %s y %s" % [media["P_salida"], abierta["P_salida"]]),
		A.cierto(sin_aire["posicion"] == 0.0 and sin_aire["P_salida"] == 0.0, "sin aire, el muelle cierra"),
		A.cierto(sin_lazo["posicion"] == 0.0, "sin señal, posición de falla"),
		A.cierto(membrana["posicion"] == SimNeumatica.MEMBRANA_MAX, "con fuga se queda corta: %s" % membrana["posicion"]),
		A.cierto(invertido["posicion"] == 100.0, "acción invertida: 4 mA abre"),
	])


func test_fugas_y_secador() -> String:
	var uno := SimNeumatica.red({"fuga": {"diametro": 1.0}})
	var dos := SimNeumatica.red({"fuga": {"diametro": 2.0}})
	var tres := SimNeumatica.red({"fuga": {"diametro": 3.0}})
	var sano := SimNeumatica.red({})
	var averiado := SimNeumatica.red({"secador": {"averiado": true}})
	return A.primero([
		A.cierto(_cerca(dos["fuga_Q"], uno["fuga_Q"] * 4.0, 0.01), "el caudal crece con el diámetro al cuadrado"),
		A.cierto(tres["fuga_Q"] > 600.0 and tres["fuga_Q"] < 700.0 and tres["fuga_kW"] > 3.5, "3 mm a 7 bar: unos 650 NL/min y 4 kW: %s y %s" % [tres["fuga_Q"], tres["fuga_kW"]]),
		A.cierto(sano["rocio"] == 3.0 and averiado["rocio"] == 30.0, "secador sano a +3 °C; averiado, el ambiente"),
	])


func test_atlas_neumatico_sale_del_modelo() -> String:
	var c := Contenido.new()
	var fallos: Array[String] = []
	for id: String in ATLAS:
		var a := c.atlas(id)
		if a.is_empty():
			fallos.append("falta el atlas %s" % id)
			continue
		var ficha := c.ficha(id)
		if not FileAccess.file_exists(str(ficha.get("simbolos", {}).get("iso", {}).get("svg", ""))):
			fallos.append("%s sin símbolo ISO" % id)
		if not ResourceLoader.exists("res://art/realista/equipos/%s.webp" % id):
			fallos.append("%s sin dibujo realista" % id)
		for g: Dictionary in a["medir"]["grupos"]:
			if not g["medida"].has("neumatica"):
				fallos.append("%s: %s no sale del modelo neumático" % [id, g["nombre"]])
			if not g["instrumento"] in VistaMedida.DE_FLUIDOS and g["instrumento"] != "multimetro":
				fallos.append("%s: instrumento raro %s" % [id, g["instrumento"]])
	return "; ".join(fallos)


## Lectura de la fila de un grupo, por el nombre del estado.
func _lectura(c: Contenido, id: String, grupo: String, estado: String) -> String:
	for g: Dictionary in c.atlas(id)["medir"]["grupos"]:
		if g["nombre"] != grupo:
			continue
		for f: Dictionary in g["filas"]:
			if f["estado"] == estado:
				return AtlasMedidas.medir(c, AtlasMedidas.combinar(g["medida"], f.get("cambios", {})))["texto"]
	return "(no existe %s / %s)" % [grupo, estado]


func test_lecturas_del_atlas() -> String:
	var c := Contenido.new()
	var pares := [
		[_lectura(c, "unidad_fr", "Presión regulada", "Cartucho limpio, red a 7 bar"), "6,0 bar"],
		[_lectura(c, "secador_frigorifico", "Punto de rocío", "Secador en marcha"), "3,0 °C"],
		[_lectura(c, "valvula_52", "Tensión en la bobina", "El PLC manda avance"), "24 V"],
		[_lectura(c, "cilindro_neumatico", "Velocidad", "Regulador al 30 %"), "180 mm/s"],
		[_lectura(c, "posicionador", "Señal del lazo", "Regulador pide 50 %"), "12,0 mA"],
		[_lectura(c, "posicionador", "Posición", "12 mA"), "50 %"],
		[_lectura(c, "actuador_cuarto_vuelta", "Presión para abrir", "Al 50 % (12 mA)"), "2,5 bar"],
	]
	var fallos: Array[String] = []
	for par: Array in pares:
		if par[0] != par[1]:
			fallos.append("%s en lugar de %s" % [par[0], par[1]])
	return "; ".join(fallos)


func test_modulo_9_con_neumatica() -> String:
	var c := Contenido.new()
	var m := c.sistema(9)
	var aprender: Dictionary = m["modos"]["aprender"]
	var lecciones: Array = aprender["lecciones"]
	var atlas: Array = aprender["atlas"]
	return A.primero([
		A.cierto(lecciones.slice(lecciones.size() - LECCIONES.size()) == LECCIONES, "lecciones de neumática al final del módulo 9"),
		A.cierto(atlas.slice(atlas.size() - ATLAS.size()) == ATLAS, "atlas de neumática al final"),
		A.cierto(m["modos"]["examen"]["minijuegos"].has(JuegoIso1219.REGISTRO_NEUMATICA), "minijuego de símbolos de neumática"),
		A.cierto(int(m["etapa"]) == 46, "módulo 9 en la etapa 46"),
	])


func test_simbolos_de_neumatica() -> String:
	var c := Contenido.new()
	var neu := JuegoIso1219.leer(c, "neumatica")
	var hid := JuegoIso1219.leer(c, "hidraulica")
	var fallos: Array[String] = []
	var piezas := 0
	for s: Dictionary in neu:
		if not FileAccess.file_exists(str(s["svg"])):
			fallos.append("%s sin SVG" % s["id"])
		if not str(s.get("pieza", "")).is_empty():
			piezas += 1
			if c.ficha(s["pieza"]).is_empty():
				fallos.append("%s: su pieza no tiene ficha" % s["id"])
	var ids := {}
	for s: Dictionary in JuegoIso1219.leer(c):
		if ids.has(s["id"]):
			fallos.append("id repetido %s" % s["id"])
		ids[s["id"]] = true
	return A.primero([
		A.cierto(neu.size() >= 14, "símbolos de neumática: %d" % neu.size()),
		A.cierto(hid.size() == 18, "los de hidráulica siguen siendo 18: %d" % hid.size()),
		A.cierto(piezas >= JuegoIso1219.RONDAS_PIEZA, "piezas dibujadas para las rondas de pieza: %d" % piezas),
		"; ".join(fallos),
	])


func test_minijuego_de_neumatica_registra_aparte() -> String:
	var raiz := _raiz()
	raiz.ir_a("simbolos_iso1219", {"registro": JuegoIso1219.REGISTRO_NEUMATICA})
	var vista = raiz.pantalla_actual()
	var total: int = vista.args["items"].size()
	var solo_neumatica := true
	var neu := JuegoIso1219.leer(raiz.contenido, "neumatica").map(func(s: Dictionary) -> String: return s["id"])
	for i in total:
		vista = raiz.pantalla_actual()
		if not neu.has(vista.args["items"][i]["id"]):
			solo_neumatica = false
		vista.resolver_bien()
		vista = raiz.pantalla_actual()
		vista.avanzar()
	var neumatica := int(raiz.partida.datos["minijuegos"].get(JuegoIso1219.REGISTRO_NEUMATICA, {}).get("estrellas", 0))
	var hidraulica := int(raiz.partida.datos["minijuegos"].get(JuegoIso1219.REGISTRO, {}).get("estrellas", 0))
	raiz.free()
	return A.primero([
		A.cierto(total == 10, "diez rondas"),
		A.cierto(solo_neumatica, "solo salen símbolos de neumática"),
		A.cierto(neumatica == 3 and hidraulica == 0, "las estrellas van al registro de neumática: %d y %d" % [neumatica, hidraulica]),
	])


func test_animaciones_neumaticas() -> String:
	var c := Contenido.new()
	var circuito = load(Animacion.CARPETA % "circuito_neumatico").new()
	circuito.iniciar({"foco": "cilindro", "apertura": 0.5}, c)
	var reposo: int = circuito.fase()
	circuito.y1 = true
	circuito._process(0.05)
	var moviendo: int = circuito.fase()
	for i in 200:
		circuito._process(0.05)
	var final: int = circuito.fase()
	var b2: bool = circuito.b2()
	circuito.free()
	var corte = load(Animacion.CARPETA % "valvula_corte").new()
	corte.iniciar({}, c)
	var corte_reposo: int = corte.fase()
	corte.y1 = true
	var corte_y1: int = corte.fase()
	corte.bobina_quemada = true
	var corte_quemada: int = corte.fase()
	corte.manual = true
	var corte_manual: int = corte.fase()
	corte.free()
	var lazo = load(Animacion.CARPETA % "posicionador_lazo").new()
	lazo.iniciar({"senal": 20.0}, c)
	for i in 100:
		lazo._process(0.05)
	var giro_abierta: float = lazo.giro
	lazo.sin_aire = true
	lazo._process(0.05)
	var fase_sin_aire: int = lazo.fase()
	lazo.free()
	var fuga = load(Animacion.CARPETA % "fuga_aire").new()
	fuga.iniciar({"diametro": 4.0}, c)
	fuga._process(0.05)
	var fase_fuga: int = fuga.fase()
	fuga.free()
	return A.primero([
		A.cierto(reposo == 1 and moviendo == 2 and final == 3 and b2, "cilindro: reposo, avanza y llega con B2: %d %d %d" % [reposo, moviendo, final]),
		A.cierto(corte_reposo == 1 and corte_y1 == 2 and corte_quemada == 3 and corte_manual == 2, "válvula cortada: %d %d %d %d" % [corte_reposo, corte_y1, corte_quemada, corte_manual]),
		A.cierto(_cerca(giro_abierta, 1.0, 0.01), "con 20 mA la mariposa abre del todo: %s" % giro_abierta),
		A.cierto(fase_sin_aire == 3, "sin aire, en falla"),
		A.cierto(fase_fuga == 3, "una fuga de 4 mm es grave"),
	])


func test_lecciones_y_atlas_en_ambas_orientaciones() -> String:
	var fallos: Array[String] = []
	for tam in [Vector2i(432, 960), Vector2i(960, 432)]:
		var raiz := _raiz(tam)
		for id: String in LECCIONES:
			raiz.ir_a("leccion", {"id": id})
			if raiz.nombre_actual() != "leccion":
				fallos.append("%s no abre" % id)
			raiz.volver()
		for id: String in ATLAS:
			raiz.ir_a("atlas", {"id": id, "pestana": "medir"})
			if raiz.pantalla_actual().find_children("*", "VistaMedida", true, false).is_empty():
				fallos.append("%s: «Medir» sin instrumento" % id)
			raiz.volver()
		raiz.free()
	return "; ".join(fallos)
