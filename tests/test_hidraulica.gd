extends RefCounted
## Etapa 45: hidráulica. Modelo SimHidraulica (presiones, caudales, alivio, estranguladora,
## pilotada, bomba gastada, motor y acumulador), lecturas del atlas, prensa de Pascal, animaciones,
## módulo 9 publicado, símbolos ISO 1219 y el minijuego «Símbolos ISO 1219».

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_hidraulica.json"
const ATLAS := ["bomba_engranajes", "bomba_pistones", "cilindro_hidraulico", "motor_hidraulico", "valvula_alivio", "estranguladora", "antirretorno_pilotada", "acumulador"]
const LECCIONES := ["hi1_presion_caudal", "hi2_aceite", "hi3_bombas", "hi4_cilindros_motores", "hi5_valvulas_presion", "hi6_caudal_retencion",
	"hi7_direccionales_esquemas", "hi8_acumuladores", "hi9_diagnostico"]


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


func test_cilindro_presion_de_la_carga_y_alivio_a_tope() -> String:
	var avanza := SimHidraulica.resolver({})
	var area := SimHidraulica.areas(SimHidraulica.completar({})).x
	var de_la_carga := 20.0 * 100.0 / area
	var tope := SimHidraulica.resolver({"actuador": {"a_tope": true}})
	var pegada := SimHidraulica.resolver({"actuador": {"a_tope": true}, "alivio": {"pegada": true}})
	var retro := SimHidraulica.resolver({"direccional": {"posicion": -1}})
	return A.primero([
		A.cierto(_cerca(area, 31.17, 0.05), "área del pistón de 63 mm: %s cm²" % area),
		A.cierto(avanza["estado"] == "avanza" and avanza["P"] > de_la_carga and avanza["P"] < de_la_carga + 3.0, "avanzando, la presión es la de la carga: %s" % avanza["P"]),
		A.cierto(_cerca(avanza["velocidad"], avanza["Q"] * 1000.0 / 60.0 / area * 10.0, 0.01) and avanza["Q_alivio"] < 0.05, "velocidad = caudal ÷ área, sin pasar por el alivio"),
		A.cierto(tope["P"] == 160.0 and tope["Q"] == 0.0 and _cerca(tope["Q_alivio"], SimHidraulica.caudal_bomba(SimHidraulica.completar({}), 160.0), 0.01), "a tope todo por el alivio al tarado: %s" % str(tope)),
		A.cierto(_cerca(tope["calor"], 160.0 * tope["Q_alivio"] / 600.0, 0.01), "el calor es p × Q ÷ 600"),
		A.cierto(pegada["P"] == SimHidraulica.ALIVIO_PEGADO, "alivio pegado: no sube"),
		A.cierto(retro["velocidad"] > avanza["velocidad"] * 1.3, "retrocede más rápido por la sección anular: %s y %s" % [retro["velocidad"], avanza["velocidad"]]),
	])


func test_estranguladora_frena_con_el_alivio_y_multiplica_la_contrapresion() -> String:
	var abierta := SimHidraulica.resolver({"estrangulador": {"presente": true, "apertura": 1.0}})
	var veinte := SimHidraulica.resolver({"estrangulador": {"presente": true, "apertura": 0.2}})
	var diez := SimHidraulica.resolver({"estrangulador": {"presente": true, "apertura": 0.1}})
	var cinco := SimHidraulica.resolver({"estrangulador": {"presente": true, "apertura": 0.05}})
	return A.primero([
		A.cierto(veinte["B"] > abierta["B"] * 5.0, "cerrar sube la contrapresión: %s y %s" % [veinte["B"], abierta["B"]]),
		A.cierto(abierta["Q_alivio"] < 0.05 and veinte["Q_alivio"] < 0.05, "sin llegar al tarado, la bomba fija no frena: todo el caudal va al cilindro"),
		A.cierto(diez["P"] == 160.0 and diez["Q_alivio"] > 5.0 and diez["velocidad"] < abierta["velocidad"] * 0.7, "con el pomo al 10 %% el alivio abre y el cilindro va más lento: %s" % str(diez)),
		A.cierto(cinco["B"] > 130.0, "al 5 %% la contrapresión pasa de 130 bar: %s" % cinco["B"]),
	])


func test_pilotada_sostiene_la_carga_sin_deriva() -> String:
	var corredera := SimHidraulica.resolver({"direccional": {"posicion": 0}})
	var pilotada := SimHidraulica.resolver({"direccional": {"posicion": 0}, "pilotada": {"presente": true}})
	var danada := SimHidraulica.resolver({"direccional": {"posicion": 0}, "pilotada": {"presente": true, "asiento_danado": true}})
	return A.primero([
		A.cierto(corredera["deriva"] > 0.0, "solo con la corredera, la carga baja"),
		A.cierto(pilotada["deriva"] == 0.0, "con la pilotada sana no baja"),
		A.cierto(danada["deriva"] > corredera["deriva"], "con el asiento dañado baja más"),
		A.cierto(_cerca(pilotada["A"], 20.0 * 100.0 / SimHidraulica.areas(SimHidraulica.completar({})).x, 0.01), "la presión que sostiene es la carga entre el área"),
	])


func test_bomba_caudal_teorico_y_desgaste() -> String:
	var nueva := SimHidraulica.completar({})
	var gastada := SimHidraulica.completar({"bomba": {"desgaste": 1.0}})
	var q0 := SimHidraulica.caudal_bomba(nueva, 0.0)
	var q160 := SimHidraulica.caudal_bomba(nueva, 160.0)
	var g160 := SimHidraulica.caudal_bomba(gastada, 160.0)
	var lenta := SimHidraulica.resolver({"bomba": {"desgaste": 1.0}, "actuador": {"carga": 45.0}})
	return A.primero([
		A.cierto(_cerca(q0, 20.0 * 1450.0 / 1000.0, 0.01), "caudal teórico = cilindrada × rpm: %s" % q0),
		A.cierto(q160 / q0 > 0.94 and q160 / q0 < 0.96, "la nueva pierde un 5 %% a 160 bar: %s" % (q160 / q0)),
		A.cierto(g160 / q0 < 0.8 and SimHidraulica.caudal_bomba(gastada, 0.0) == q0, "la gastada pierde más de un 20 %% con presión y nada a 0 bar"),
		A.cierto(lenta["velocidad"] < SimHidraulica.resolver({"actuador": {"carga": 45.0}})["velocidad"] * 0.8, "con la bomba gastada el cilindro cargado va lento"),
		A.cierto(SimHidraulica.resolver({"bomba": {"aspiracion_obstruida": true}})["S"] < -0.5, "aspiración obstruida: depresión de cavitación"),
	])


func test_motor_hidraulico_rpm_par_y_drenaje() -> String:
	var m := SimHidraulica.resolver({"actuador": {"tipo": "motor", "par": 150.0}})
	var gastado := SimHidraulica.resolver({"actuador": {"tipo": "motor", "par": 150.0, "desgaste": 1.0}})
	var duro := SimHidraulica.resolver({"actuador": {"tipo": "motor", "par": 300.0}})
	return A.primero([
		A.cierto(_cerca(m["P"] - SimHidraulica.RETORNO, 20.0 * PI * 150.0 / 100.0, 0.01), "Δp = 20π × par ÷ cilindrada: %s" % m["P"]),
		A.cierto(_cerca(m["rpm"], (m["Q"] - m["drenaje"]) * 1000.0 / 100.0, 0.5), "rpm = caudal útil ÷ cilindrada: %s" % m["rpm"]),
		A.cierto(gastado["drenaje"] > m["drenaje"] * 10.0 and gastado["rpm"] < m["rpm"], "gastado: el drenaje se multiplica y pierde vueltas"),
		A.cierto(duro["estado"] == "atascado" and duro["P"] == 160.0, "si el par pide más que el tarado, se para"),
	])


func test_acumulador_ley_de_boyle() -> String:
	var sano := SimHidraulica.acumulador({})
	var perdido := SimHidraulica.acumulador({"acumulador": {"perdida_gas": 0.7}})
	var esperado := 10.0 * 91.0 * (1.0 / 101.0 - 1.0 / 161.0)
	return A.primero([
		A.cierto(_cerca(sano["volumen_util"], esperado, 0.001) and sano["gas"] == 90.0, "volumen útil entre 100 y 160 bar: %s" % sano["volumen_util"]),
		A.cierto(_cerca(perdido["gas"], 27.0, 0.01) and perdido["volumen_util"] < sano["volumen_util"] * 0.35, "con la precarga perdida entrega mucho menos: %s" % perdido["volumen_util"]),
	])


func test_prensa_de_pascal() -> String:
	var prensa := load("res://ui/animaciones/prensa_hidraulica.gd")
	var p: float = prensa.presion_bar(200.0, 20.0)
	var f: float = prensa.fuerza_n(p, 100.0)
	return A.primero([
		A.cierto(_cerca(p, 6.366, 0.01), "200 N sobre 20 mm: %s bar" % p),
		A.cierto(_cerca(f, 5000.0, 0.5), "la misma presión sobre 100 mm da 25 veces la fuerza: %s N" % f),
		A.cierto(_cerca(prensa.fuerza_n(100.0, 79.79), 50000.0, 50.0), "100 bar sobre 50 cm² son 50 kN, como en la lección"),
	])


func _lectura(c: Contenido, id: String, grupo: String, estado: String) -> String:
	for g: Dictionary in c.atlas(id)["medir"]["grupos"]:
		if g["nombre"] != grupo:
			continue
		for f: Dictionary in g["filas"]:
			if f["estado"] == estado:
				return AtlasMedidas.medir(c, AtlasMedidas.combinar(g["medida"], f.get("cambios", {})))["texto"]
	return "(no existe %s / %s)" % [grupo, estado]


func test_lecturas_del_atlas_salen_del_modelo() -> String:
	var c := Contenido.new()
	return A.primero([
		A.cierto(_lectura(c, "valvula_alivio", "Tarado", "Tarado correcto") == "160 bar", "tarado: %s" % _lectura(c, "valvula_alivio", "Tarado", "Tarado correcto")),
		A.cierto(_lectura(c, "valvula_alivio", "Tarado", "Pegada abierta") == "15,0 bar", "alivio pegado: %s" % _lectura(c, "valvula_alivio", "Tarado", "Pegada abierta")),
		A.cierto(_lectura(c, "bomba_engranajes", "Caudal a presión", "Bomba nueva a 0 bar") == "29 L/min", "caudal a 0 bar: %s" % _lectura(c, "bomba_engranajes", "Caudal a presión", "Bomba nueva a 0 bar")),
		A.cierto(_lectura(c, "bomba_engranajes", "Aspiración", "Filtro de aspiración obstruido") == "-0,6 bar", "aspiración: %s" % _lectura(c, "bomba_engranajes", "Aspiración", "Filtro de aspiración obstruido")),
		A.cierto(_lectura(c, "antirretorno_pilotada", "Deriva de la carga", "Con pilotada sana") == "0,0 mm/min", "deriva: %s" % _lectura(c, "antirretorno_pilotada", "Deriva de la carga", "Con pilotada sana")),
		A.cierto(_lectura(c, "acumulador", "Precarga del gas", "Vejiga que pierde gas") == "27 bar", "precarga perdida: %s" % _lectura(c, "acumulador", "Precarga del gas", "Vejiga que pierde gas")),
		A.cierto(_lectura(c, "cilindro_hidraulico", "Fuga de la junta del pistón", "Junta gastada") == "8,0 L/min", "fuga de la junta: %s" % _lectura(c, "cilindro_hidraulico", "Fuga de la junta del pistón", "Junta gastada")),
	])


func test_modulo_9_publicado_con_atlas_y_lecciones() -> String:
	var c := Contenido.new()
	var m := c.sistema(9)
	var aprender: Dictionary = m.get("modos", {}).get("aprender", {})
	var fallos: Array[String] = []
	for id: String in ATLAS:
		var ficha := c.ficha(id)
		if not ficha.get("simbolos", {}).has("iso"):
			fallos.append("%s sin símbolo ISO 1219" % id)
		elif not FileAccess.file_exists(ficha["simbolos"]["iso"]["svg"]):
			fallos.append("%s: falta el SVG del símbolo" % id)
		var a := c.atlas(id)
		for g: Dictionary in a["medir"]["grupos"]:
			if not g["medida"].has("hidraulica"):
				fallos.append("%s: %s no sale del modelo hidráulico" % [id, g["nombre"]])
	return A.primero([
		A.cierto(m.get("estado", "") == "activo", "el módulo 9 debe estar activo"),
		# Desde la etapa 46 el módulo sigue con la neumática: la hidráulica va primero.
		A.cierto(aprender.get("lecciones", []).slice(0, LECCIONES.size()) == LECCIONES, "lecciones del módulo 9: %s" % str(aprender.get("lecciones", []))),
		A.cierto(aprender.get("atlas", []).slice(0, ATLAS.size()) == ATLAS, "atlas del módulo 9: %s" % str(aprender.get("atlas", []))),
		A.cierto(m["modos"].get("examen", {}).get("minijuegos", []).has("simbolos_iso1219"), "minijuego del módulo 9"),
		"; ".join(fallos),
	])


func test_simbolos_iso1219_bien_formados() -> String:
	var c := Contenido.new()
	var lista := JuegoIso1219.leer(c, "hidraulica")
	var fallos: Array[String] = []
	var piezas := 0
	for s: Dictionary in lista:
		if VistaSvg.rasterizar(s["svg"], 0.5) == null:
			fallos.append("no se dibuja %s" % s["id"])
		if str(s.get("explicacion", "")).is_empty() or str(s.get("en", "")).is_empty():
			fallos.append("%s sin explicación o sin término inglés" % s["id"])
		if not str(s.get("pieza", "")).is_empty():
			piezas += 1
			if c.ficha(s["pieza"]).is_empty():
				fallos.append("%s: la pieza %s no tiene ficha" % [s["id"], s["pieza"]])
	return A.primero([A.cierto(lista.size() >= 18, "símbolos: %d" % lista.size()), A.cierto(piezas == 8, "una pieza dibujada por cada ficha del atlas: %d" % piezas), "; ".join(fallos)])


func test_rondas_del_minijuego() -> String:
	var lista := JuegoIso1219.leer(Contenido.new())
	var azar := RandomNumberGenerator.new()
	azar.seed = 45
	var rondas := JuegoIso1219.crear_rondas(lista, 10, azar)
	var fallos: Array[String] = []
	var de_pieza := 0
	for r: Dictionary in rondas:
		if r["opciones"].size() != 4:
			fallos.append("%s: %d opciones" % [r["id"], r["opciones"].size()])
		var distintas := {}
		for o in r["opciones"]:
			distintas[o] = true
		if distintas.size() != 4:
			fallos.append("%s: opciones repetidas" % r["id"])
		if r["tipo"] == "pieza":
			de_pieza += 1
			if r["opciones"][r["correcta"]] != r["id"]:
				fallos.append("%s: la correcta no es su símbolo" % r["id"])
		elif r["opciones"][r["correcta"]] != JuegoIso1219.simbolo(lista, r["id"])["nombre"]:
			fallos.append("%s: la correcta no es su nombre" % r["id"])
	return A.primero([A.cierto(rondas.size() == 10, "diez rondas"), A.cierto(de_pieza == JuegoIso1219.RONDAS_PIEZA, "rondas de pieza: %d" % de_pieza), "; ".join(fallos)])


func test_minijuego_completo_da_tres_estrellas() -> String:
	var raiz := _raiz()
	raiz.ir_a("simbolos_iso1219", {})
	var vista = raiz.pantalla_actual()
	var total: int = vista.args["items"].size()
	var con_opciones := false
	for i in total:
		vista = raiz.pantalla_actual()
		if vista.args["items"][i]["tipo"] == "pieza" and vista.opciones.size() == 4:
			con_opciones = true
		vista.resolver_bien()
		vista = raiz.pantalla_actual()
		vista.avanzar()
	var estrellas := int(raiz.partida.datos["minijuegos"].get(JuegoIso1219.REGISTRO, {}).get("estrellas", 0))
	var final_ok: bool = raiz.pantalla_actual().find_child("PlacaCalificacion", true, false) != null
	raiz.free()
	return A.primero([A.cierto(con_opciones, "las rondas de pieza muestran cuatro símbolos"), A.cierto(estrellas == 3, "todo bien: 3 estrellas (%d)" % estrellas), A.cierto(final_ok, "pantalla de resultado")])


func test_animaciones_responden_al_modelo() -> String:
	var c := Contenido.new()
	var circuito = load(Animacion.CARPETA % "circuito_hidraulico").new()
	circuito.iniciar({"foco": "alivio"}, c)
	var en_centro: int = circuito.fase()
	circuito._mandar(1)
	circuito._process(0.05)
	var moviendo: int = circuito.fase()
	for i in 200:
		circuito._process(0.05)
	var a_tope: int = circuito.fase()
	var p_tope: float = circuito.resultado["P"]
	circuito.free()
	var bomba = load(Animacion.CARPETA % "corte_bomba").new()
	bomba.iniciar({"tipo": "pistones"}, c)
	var q_lleno: float = bomba.caudal_real()
	bomba.plato = 0.0
	var q_recto: float = bomba.caudal_real()
	bomba.free()
	var acu = load(Animacion.CARPETA % "acumulador_vejiga").new()
	acu.iniciar({}, c)
	acu._pulsar("carga")
	for i in 400:
		acu._process(0.05)
	var cargado: float = acu.presion(acu.aceite)
	acu._pulsar("descarga")
	for i in 400:
		acu._process(0.05)
	var descargado: float = acu.presion(acu.aceite)
	acu.free()
	return A.primero([
		A.cierto(en_centro == 1 and moviendo == 2 and a_tope == 3, "fases del circuito: %d %d %d" % [en_centro, moviendo, a_tope]),
		A.cierto(p_tope == 160.0, "a tope el manómetro marca el tarado: %s" % p_tope),
		A.cierto(q_lleno > 60.0 and q_recto == 0.0, "con el plato recto la bomba de pistones no da caudal: %s y %s" % [q_lleno, q_recto]),
		A.cierto(_cerca(cargado, 160.0, 1.0) and descargado == 0.0, "el acumulador carga hasta 160 bar y descarga a cero: %s y %s" % [cargado, descargado]),
	])


func test_lecciones_y_atlas_en_ambas_orientaciones() -> String:
	var fallos: Array[String] = []
	for tam in [Vector2i(432, 960), Vector2i(960, 432)]:
		var raiz := _raiz(tam)
		for id: String in LECCIONES:
			raiz.ir_a("leccion", {"id": id})
			if raiz.nombre_actual() != "leccion":
				fallos.append("%s no abre" % id)
			var vista := raiz.pantalla_actual()
			raiz.volver()
			if is_instance_valid(vista):
				vista.free()
		for id: String in ["valvula_alivio", "acumulador"]:
			raiz.ir_a("atlas", {"id": id, "pestana": "medir"})
			var medida := raiz.pantalla_actual().find_children("*", "VistaMedida", true, false)
			if medida.is_empty() or not (medida[0] as VistaMedida).instrumento in VistaMedida.DE_FLUIDOS:
				fallos.append("%s: «Medir» sin instrumento de fluidos" % id)
			raiz.ir_a("atlas", {"id": id, "pestana": "que_es"})
			raiz.volver()
			raiz.volver()
		raiz.free()
	return "; ".join(fallos)
