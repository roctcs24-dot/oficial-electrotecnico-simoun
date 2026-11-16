extends RefCounted
## Atlas de componentes de la Escuela: datos bien formados, lecturas de «Medir» calculadas con
## la simulación, cortes animados coherentes con los modelos, pestañas recorribles y avance.

const A := preload("res://tests/ayuda_sim.gd")
const ESCENA := "res://ui/raiz.tscn"
const RUTA_PARTIDA := "user://pruebas_atlas.json"
const PESTANAS := ["que_es", "funciona", "conexion", "medir", "fallas"]
const ALTO_MIN_BOTON := 48.0


func _crear_raiz() -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load(ESCENA).instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	return raiz


func _ids(c: Contenido) -> Array[String]:
	var lista: Array[String] = []
	for s: Dictionary in c.todos():
		for id: String in s.get("modos", {}).get("aprender", {}).get("atlas", []):
			lista.append(id)
	return lista


func _terminos_fuera(texto: String, glosario: Dictionary) -> String:
	for t in TextoTecnico.terminos(texto):
		if not glosario.has(t):
			return t
	return ""


func test_el_modulo_7_publica_las_etapas_33_a_35() -> String:
	var c := Contenido.new()
	var m := c.sistema(7)
	var esperados := ["contactor", "rele_termico", "guardamotor", "interruptor_automatico", "diferencial", "fusible", "seccionador", "rele_control_fases", "monitor_aislamiento",
		"rele_auxiliar", "temporizador", "pulsador", "selector", "luz_piloto", "seta", "final_carrera", "presostato", "termostato", "interruptor_nivel"]
	return A.primero([
		A.cierto(m.get("estado", "") == "activo", "el módulo 7 debe estar activo"),
		A.cierto(_ids(c) == esperados, "atlas del módulo 7: %s" % str(_ids(c))),
	])


## Cada pieza de un circuito que se abre en el Taller debe tener su dibujo en el cajón.
func _falta_en_el_cajon(c: Contenido, circuito: String) -> String:
	var mesa := MesaTaller.new(c)
	if not mesa.cargar_plantilla(circuito):
		return "no carga"
	for id: String in mesa.piezas:
		if mesa.entrada(mesa.piezas[id]["tipo"]).is_empty():
			return id
	return ""


func test_datos_del_atlas_bien_formados() -> String:
	var c := Contenido.new()
	var glosario := c.glosario()
	var fallos: Array[String] = []
	for id in _ids(c):
		var a := c.atlas(id)
		if a.is_empty():
			fallos.append("falta data/atlas/%s.json" % id)
			continue
		var ficha := c.ficha(str(a.get("ficha", "")))
		if ficha.is_empty():
			fallos.append("%s: su ficha no existe" % id)
		if not glosario.has(str(a.get("termino", ""))):
			fallos.append("%s: el término de la cabecera no está en el glosario" % id)
		if not FileAccess.file_exists("res://art/iconos/%s.svg" % a.get("icono", "")):
			fallos.append("%s: falta el icono" % id)
		var dibujo: Dictionary = a.get("bornes_dibujo", {})
		var tam: Array = ficha.get("dibujo", {}).get("tamano", [0, 0])
		for b: String in dibujo:
			var p: Array = dibujo[b]
			if p[0] < 0 or p[1] < 0 or p[0] > tam[0] or p[1] > tam[1]:
				fallos.append("%s: el borne %s queda fuera del dibujo" % [id, b])
		# Qué es.
		var que: Dictionary = a.get("que_es", {})
		if que.get("partes", []).size() < 3 or str(que.get("placa", "")).is_empty() or not str(que.get("a_bordo", "")).contains("verificar"):
			fallos.append("%s: «Qué es» incompleto o sin «verificar a bordo»" % id)
		# Funciona.
		var fun: Dictionary = a.get("funciona", {})
		if not FileAccess.file_exists(Animacion.CARPETA % fun.get("animacion", "")):
			fallos.append("%s: falta la animación %s" % [id, fun.get("animacion", "")])
		if fun.get("pasos", []).size() != 3:
			fallos.append("%s: «Funciona» debe tener tres pasos" % id)
		# Conexión.
		var con: Dictionary = a.get("conexion", {})
		if not FileAccess.file_exists(str(con.get("esquema", {}).get("svg", ""))):
			fallos.append("%s: falta el esquema" % id)
		var en_esquema: Dictionary = con.get("bornes_esquema", {})
		for b: String in en_esquema:
			if not con.get("bornes", {}).has(b):
				fallos.append("%s: el borne %s no dice qué le llega" % [id, b])
		for g: Dictionary in con.get("grupos", []):
			for b: String in g["bornes"]:
				if not en_esquema.has(b):
					fallos.append("%s: el grupo %s usa %s, que no está en el esquema" % [id, g["nombre"], b])
		# Medir: siempre con la simulación.
		var med: Dictionary = a.get("medir", {})
		# El botón del Taller es opcional; si está, su circuito debe montarse en la mesa.
		for taller: String in [str(con.get("taller", "")), str(med.get("taller", ""))]:
			if taller.is_empty():
				continue
			var falta := _falta_en_el_cajon(c, taller)
			if not falta.is_empty():
				fallos.append("%s: el circuito %s del Taller falla en %s" % [id, taller, falta])
		for g: Dictionary in med.get("grupos", []):
			if g.get("filas", []).is_empty() or g.get("medida", {}).has("valor"):
				fallos.append("%s: el grupo %s no se mide con la simulación" % [id, g["nombre"]])
			for f: Dictionary in g.get("filas", []):
				if f.get("cambios", {}).has("valor"):
					fallos.append("%s: la fila %s está escrita a mano" % [id, f["estado"]])
		# Fallas.
		var fal: Dictionary = a.get("fallas", {})
		if fal.get("lista", []).size() < 4:
			fallos.append("%s: debe tener al menos cuatro fallas" % id)
		for f: Dictionary in fal.get("lista", []):
			for clave in ["sintoma", "causa", "reparacion"]:
				if str(f.get(clave, "")).is_empty():
					fallos.append("%s: a la falla %s le falta %s" % [id, f.get("nombre", "?"), clave])
			if f.get("mide", []).is_empty():
				fallos.append("%s: la falla %s no dice qué se mide" % [id, f.get("nombre", "?")])
		if fal.get("mantenimiento", []).size() != 3 or not str(fal.get("nota_mantenimiento", "")).contains("verificar"):
			fallos.append("%s: mantenimiento mensual, semestral y anual, con «verificar»" % id)
		if a.get("para_saber_mas", []).is_empty():
			fallos.append("%s: falta Para saber más" % id)
		# Términos del glosario en todos los textos.
		var fuera := _terminos_fuera(JSON.stringify(a), glosario)
		if not fuera.is_empty():
			fallos.append("%s usa un término fuera del glosario: %s" % [id, fuera])
	fallos.append_array(c.errores)
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


func test_medir_del_contactor_sale_de_la_simulacion() -> String:
	var c := Contenido.new()
	var cerrado := _lectura(c, "contactor", "Contactos", "1-2 con la armadura cerrada")
	return A.primero([
		A.cierto(_lectura(c, "contactor", "Bobina A1-A2", "Sana") == "360 Ω", "bobina sana: %s" % _lectura(c, "contactor", "Bobina A1-A2", "Sana")),
		A.cierto(_lectura(c, "contactor", "Bobina A1-A2", "Cortada") == "OL", "bobina cortada debe dar OL"),
		A.cierto(_lectura(c, "contactor", "Bobina A1-A2", "Espiras en corto") == "3 Ω", "espiras en corto: %s" % _lectura(c, "contactor", "Bobina A1-A2", "Espiras en corto")),
		A.cierto(_lectura(c, "contactor", "Contactos", "1-2 en reposo") == "OL", "1-2 en reposo debe dar OL"),
		A.cierto(cerrado == "0,0 Ω", "1-2 cerrado: %s" % cerrado),
		A.cierto(_lectura(c, "contactor", "Contactos", "1-2 en reposo, soldado") == "0,0 Ω", "1-2 soldado debe dar 0 Ω"),
		A.cierto(_lectura(c, "contactor", "Contactos", "13-14 en reposo") == "OL", "13-14 en reposo debe dar OL"),
		A.cierto(_lectura(c, "contactor", "Contactos", "21-22 en reposo") == "0,0 Ω", "21-22 en reposo debe dar 0 Ω"),
		A.cierto(_lectura(c, "contactor", "Tensión de mando", "S1 pulsado") == "110 V", "mando con S1: %s" % _lectura(c, "contactor", "Tensión de mando", "S1 pulsado")),
		A.cierto(_lectura(c, "contactor", "Tensión de mando", "S1 sin pulsar") == "0,0 V", "mando sin S1: %s" % _lectura(c, "contactor", "Tensión de mando", "S1 sin pulsar")),
		A.cierto(_lectura(c, "contactor", "Tensión de mando", "Red de 300 V, S1 pulsado") == "87 V", "mando con la red baja: %s" % _lectura(c, "contactor", "Tensión de mando", "Red de 300 V, S1 pulsado")),
	])


func test_medir_del_termico_y_del_guardamotor() -> String:
	var c := Contenido.new()
	var corrientes: Array[float] = []
	for fase in ["Fase L1 (2/T1)", "Fase L2 (4/T2)", "Fase L3 (6/T3)"]:
		corrientes.append(_lectura(c, "rele_termico", "Corriente por fase", fase).trim_suffix(" A").replace(",", ".").to_float())
	return A.primero([
		A.cierto(_lectura(c, "rele_termico", "Contacto 95-96", "En servicio") == "0,0 Ω", "95-96 en servicio debe dar 0 Ω"),
		A.cierto(_lectura(c, "rele_termico", "Contacto 95-96", "Disparado") == "OL", "95-96 disparado debe dar OL"),
		A.cierto(_lectura(c, "rele_termico", "Contacto 97-98", "Disparado") == "0,0 Ω", "97-98 disparado debe dar 0 Ω"),
		A.cierto(corrientes[0] > 5.0 and corrientes[0] < 29.5, "corriente del motor en marcha por debajo de Ir: %s" % str(corrientes)),
		A.cierto(absf(corrientes[0] - corrientes[1]) < 0.5 and absf(corrientes[0] - corrientes[2]) < 0.5, "fases equilibradas: %s" % str(corrientes)),
		A.cierto(_lectura(c, "guardamotor", "Polos 1-2", "En I") == "0,0 Ω", "polo en I debe dar 0 Ω"),
		A.cierto(_lectura(c, "guardamotor", "Polos 1-2", "En O") == "OL", "polo en O debe dar OL"),
		A.cierto(_lectura(c, "guardamotor", "Polos 1-2", "Disparado") == "OL", "polo disparado debe dar OL"),
		A.cierto(_lectura(c, "guardamotor", "Auxiliares", "13-14 en I") == "0,0 Ω", "13-14 en I debe dar 0 Ω"),
		A.cierto(_lectura(c, "guardamotor", "Auxiliares", "97-98 disparado") == "0,0 Ω", "97-98 disparado debe dar 0 Ω"),
		A.cierto(_lectura(c, "guardamotor", "Aislamiento", "Entre 1 y 3, en O") == "> 999 MΩ", "aislamiento: %s" % _lectura(c, "guardamotor", "Aislamiento", "Entre 1 y 3, en O")),
	])


func test_las_fallas_tienen_lectura() -> String:
	var c := Contenido.new()
	for id in _ids(c):
		for f: Dictionary in c.atlas(id)["fallas"]["lista"]:
			for m: Dictionary in f["mide"]:
				var texto: String = str(m["valor"]) if m.has("valor") else AtlasMedidas.medir(c, m["medida"])["texto"]
				if texto in ["?", "—", ""]:
					return "%s, %s: la lectura «%s» no se pudo calcular" % [id, f["nombre"], m["donde"]]
	return ""


func _animacion(nombre: String, params: Dictionary) -> Animacion:
	var guion: GDScript = load(Animacion.CARPETA % nombre)
	var a: Animacion = guion.new()
	a.iniciar(params, Contenido.new())
	return a


## Segundos simulados hasta el disparo, o INF si no dispara en una hora.
func _tiempo_disparo(nombre: String, veces: float) -> float:
	var a = _animacion(nombre, {"veces": veces})
	var t := 0.0
	while t < 3600.0 and not a.disparado:
		a.avanzar(0.5)
		t += 0.5
	a.free()
	return t if t < 3600.0 else INF


func test_corte_del_termico_dispara_como_la_simulacion() -> String:
	var lento := _tiempo_disparo("corte_rele_termico", 1.05)
	var medio := _tiempo_disparo("corte_rele_termico", 1.5)
	var rapido := _tiempo_disparo("corte_rele_termico", 7.2)
	var a = _animacion("corte_rele_termico", {"veces": 7.2})
	a.avanzar(10.0)
	var disparo: bool = a.disparado
	var rearme_caliente: bool = a.rearmar()
	a.avanzar(900.0)
	var rearme_frio: bool = a.rearmar()
	a.free()
	return A.primero([
		A.cierto(lento == INF, "con 1,05 × Ir no debe disparar: %s s" % str(lento)),
		A.cierto(medio > 120.0 and medio < 400.0, "con 1,5 × Ir debe tardar minutos: %s s" % str(medio)),
		A.cierto(rapido > 4.0 and rapido < 9.0, "con 7,2 × Ir unos 6 s: %s s" % str(rapido)),
		A.cierto(disparo and not rearme_caliente, "caliente no debe rearmar"),
		A.cierto(rearme_frio, "frío debe rearmar"),
	])


func test_corte_del_guardamotor() -> String:
	var a = _animacion("corte_guardamotor", {"veces": 1.0})
	a.poner_corriente(14.0)
	var magnetico: bool = a.disparado and a.causa == "magnetico"
	a.poner_corriente(1.0)
	a.accionar(true)
	var sigue: bool = a.disparado
	a.accionar(false)
	a.accionar(true)
	var rearmado: bool = a.cerrado()
	a.free()
	var termico := _tiempo_disparo("corte_guardamotor", 7.2)
	return A.primero([
		A.cierto(magnetico, "por encima de 13 × Ir debe disparar el magnético al instante"),
		A.cierto(not sigue, "tras el disparo, el primer giro lo lleva a O"),
		A.cierto(rearmado, "de O a I debe quedar conectado"),
		A.cierto(termico > 4.0 and termico < 9.0, "térmico a 7,2 × Ir en unos 6 s: %s" % str(termico)),
	])


func test_corte_del_contactor_abre_y_cierra() -> String:
	var a = _animacion("corte_contactor", {"v_bobina": 110})
	var cerrado_al_empezar: bool = a.cerrado()
	a.poner_tension(false)
	for i in 60:
		a._process(0.05)
	var abierto: bool = a.posicion < 0.01 and a.fase() == 3
	a.poner_tension(true)
	a._process(0.05)
	var primer_paso: int = a.fase()
	for i in 60:
		a._process(0.05)
	var cerrado: bool = a.cerrado() and a.fase() == 3
	a.free()
	return A.primero([
		A.cierto(cerrado_al_empezar, "empieza con tensión y cerrado, como la maqueta"),
		A.cierto(abierto, "sin tensión debe abrir"),
		A.cierto(primer_paso == 1, "al dar tensión, primero crece el campo: paso %d" % primer_paso),
		A.cierto(cerrado, "con tensión debe cerrar"),
	])


func _botones_pequenos(nodo: Node, lista: Array[String]) -> void:
	if nodo is Button and nodo.is_visible_in_tree() and nodo.get_combined_minimum_size().y < ALTO_MIN_BOTON:
		lista.append("%s (%d)" % [nodo.text, nodo.get_combined_minimum_size().y])
	for hijo in nodo.get_children():
		_botones_pequenos(hijo, lista)


func test_pestanas_recorribles_en_ambas_orientaciones() -> String:
	var raiz := _crear_raiz()
	var c := raiz.contenido
	var fallos: Array[String] = []
	for vertical in [true, false]:
		raiz.vertical = vertical
		for id in _ids(c):
			var a := c.atlas(id)
			var pasos: Array = []
			for p: String in PESTANAS:
				pasos.append({"id": id, "pestana": p})
			for i in a["medir"]["grupos"].size():
				pasos.append({"id": id, "pestana": "medir", "grupo_medir": i})
			for i in a["fallas"]["lista"].size():
				pasos.append({"id": id, "pestana": "fallas", "falla": i})
			for args: Dictionary in pasos:
				raiz.ir_a("atlas", args)
				var pequenos: Array[String] = []
				_botones_pequenos(raiz.pantalla_actual(), pequenos)
				if not pequenos.is_empty():
					fallos.append("%s %s: botones bajo 48: %s" % [id, args["pestana"], ", ".join(pequenos)])
				raiz.volver()
	var completo := raiz.partida.atlas_completo("contactor")
	raiz.free()
	return A.primero([
		"; ".join(fallos),
		A.cierto(completo, "recorrer las cinco pestañas debe dejar la ficha como vista"),
	])


func test_tocar_un_borne_lo_ilumina_en_esquema_y_dibujo() -> String:
	var raiz := _crear_raiz()
	raiz.ir_a("atlas", {"id": "contactor", "pestana": "conexion"})
	var p = raiz.pantalla_actual()
	var grupo_inicial: Array = p.esquema.resaltados.keys()
	p.tocar_borne("13")
	var en_esquema: Array = p.esquema.resaltados.keys()
	var en_dibujo: Array = p.dibujo_conexion.resaltados.keys()
	var texto: String = p._texto_borne.text
	p.elegir_grupo(1)
	var potencia: int = p.dibujo_conexion.resaltados.size()
	raiz.free()
	return A.primero([
		A.cierto(grupo_inicial == ["A1", "A2"], "al abrir se ilumina la bobina: %s" % str(grupo_inicial)),
		A.cierto(en_esquema == ["13"] and en_dibujo == ["13"], "13 en esquema %s y dibujo %s" % [str(en_esquema), str(en_dibujo)]),
		A.cierto(texto.contains("S0"), "debe decir qué llega al 13: %s" % texto),
		A.cierto(potencia == 6, "el grupo de potencia ilumina seis bornes en el dibujo: %d" % potencia),
	])


func test_avance_del_modulo_y_mantenimiento_guardado() -> String:
	var raiz := _crear_raiz()
	var m := raiz.contenido.sistema(7)
	var antes := Avance.sistema(m, raiz.partida)
	for p: String in PESTANAS:
		raiz.partida.marcar_pestana_atlas("rele_termico", p)
	var despues := Avance.sistema(m, raiz.partida)
	raiz.partida.marcar_tarea_atlas("contactor", 1, true)
	raiz.free()
	var guardada := Partida.new(RUTA_PARTIDA)
	guardada.cargar()
	return A.primero([
		A.cierto(antes == [0, 19], "al empezar: %s" % str(antes)),
		A.cierto(despues == [1, 19], "tras ver las cinco pestañas: %s" % str(despues)),
		A.cierto(guardada.tarea_atlas_hecha("contactor", 1), "la tarea marcada debe quedar guardada"),
		A.cierto(guardada.atlas_completo("rele_termico"), "la ficha vista debe quedar guardada"),
	])


func test_medir_de_la_proteccion() -> String:
	var c := Contenido.new()
	var falta_l3 := _lectura(c, "rele_control_fases", "Tensiones de entrada", "L2-L3, falta L3").trim_suffix(" V").to_float()
	return A.primero([
		A.cierto(_lectura(c, "interruptor_automatico", "Tensión de salida", "En OFF") == "0,0 V", "interruptor en OFF sin tensión aguas abajo"),
		A.cierto(_lectura(c, "interruptor_automatico", "Tensión de salida", "Cortocircuito en el alumbrado") == "0,0 V", "con un corto debe disparar"),
		A.cierto(_lectura(c, "diferencial", "Fuga", "Fuga de 20 kΩ") == "11,4 mA", "fuga de 20 kΩ: %s" % _lectura(c, "diferencial", "Fuga", "Fuga de 20 kΩ")),
		A.cierto(_lectura(c, "diferencial", "Fuga", "Red aislada, fuga de 5 kΩ") == "0,0 mA", "en la red aislada no hay fuga que medir"),
		A.cierto(_lectura(c, "diferencial", "Tensión en la toma", "Fuga de 5 kΩ") == "0,0 V", "con 46 mA debe disparar"),
		A.cierto(_lectura(c, "diferencial", "Tensión en la toma", "Pulsando T") == "0,0 V", "T debe disparar"),
		A.cierto(_lectura(c, "fusible", "En servicio", "Fundido") == "110 V", "fusible fundido en servicio: toda la tensión"),
		A.cierto(_lectura(c, "fusible", "Cartucho", "Fundido") == "OL", "cartucho fundido: OL"),
		A.cierto(_lectura(c, "seccionador", "Ausencia de tensión", "Entradas 1-3, en 0") == "380 V", "las entradas siguen con tensión en 0"),
		A.cierto(_lectura(c, "seccionador", "Ausencia de tensión", "Salidas 2-4, en 0") == "0,0 V", "las salidas sin tensión en 0"),
		A.cierto(_lectura(c, "rele_control_fases", "Luz de red correcta", "Red correcta") == "110 V", "red correcta: la luz encendida"),
		A.cierto(_lectura(c, "rele_control_fases", "Luz de red correcta", "Falta L3") == "0,0 V", "falta de fase: suelta"),
		A.cierto(_lectura(c, "rele_control_fases", "Luz de red correcta", "Secuencia inversa") == "0,0 V", "secuencia inversa: suelta"),
		A.cierto(falta_l3 > 150.0 and falta_l3 < 230.0, "sin L3, entre L2 y L3 queda media tensión: %s" % str(falta_l3)),
		A.cierto(_lectura(c, "monitor_aislamiento", "Lectura del monitor", "Red sana") == "> 999 MΩ", "red sana: %s" % _lectura(c, "monitor_aislamiento", "Lectura del monitor", "Red sana")),
		A.cierto(_lectura(c, "monitor_aislamiento", "Lectura del monitor", "Defecto de 500 kΩ") == "0,5 MΩ", "defecto de 500 kΩ: %s" % _lectura(c, "monitor_aislamiento", "Lectura del monitor", "Defecto de 500 kΩ")),
	])


func test_cortes_de_la_proteccion() -> String:
	var d = _animacion("corte_diferencial", {"fuga_ma": 12})
	d.avanzar(0.5)
	var con_12: bool = not d.disparado()
	d.poner_fuga(45.0)
	d.avanzar(0.5)
	var con_45: bool = d.disparado()
	d.accionar(false)
	d.poner_fuga(45.0)
	d.poner_tierra(false)
	d.accionar(true)
	d.avanzar(0.5)
	var aislada: bool = not d.disparado()
	d.poner_tierra(true)
	d.poner_fuga(0.0)
	d.probar()
	var prueba: bool = d.disparado()
	d.free()
	var f = _animacion("corte_fusible", {"veces": 2.0})
	var t := 0.0
	while not f.fundido and t < 60.0:
		f.avanzar(0.5)
		t += 0.5
	f.free()
	var aguanta = _animacion("corte_fusible", {"veces": 1.2})
	aguanta.avanzar(3600.0)
	var sin_fundir: bool = not aguanta.fundido
	aguanta.free()
	var s = _animacion("corte_seccionador", {"cerrado": true})
	var candado_cerrado: bool = s.poner_candado(true)
	s.accionar(false)
	var candado_abierto: bool = s.poner_candado(true)
	var cierra_con_candado: bool = s.accionar(true)
	s.free()
	var r = _animacion("corte_rele_fases", {})
	var activo_al_empezar: bool = r.activado()
	r.quitar_fase(true)
	r.avanzar(1.0)
	var suelta: bool = not r.activado()
	r.quitar_fase(false)
	r.invertir(true)
	r.avanzar(1.0)
	var inversa: bool = not r.activado()
	r.free()
	var mon = _animacion("corte_monitor", {"aislamiento_mohm": 50})
	var sin_alarma: bool = not mon.alarma
	mon.poner_aislamiento(0.4)
	var alarma: bool = mon.alarma
	mon.poner_aislamiento(50.0)
	var retenida: bool = mon.alarma
	mon.reset()
	var borrada: bool = not mon.alarma
	mon.free()
	return A.primero([
		A.cierto(con_12 and con_45, "diferencial: 12 mA no dispara y 45 mA sí"),
		A.cierto(aislada, "en la red aislada la fuga no lo dispara"),
		A.cierto(prueba, "T debe disparar"),
		A.cierto(t > 10.0 and t < 15.0, "fusible a 2 × In: unos 12,5 s, y fue %s s" % str(t)),
		A.cierto(sin_fundir, "a 1,2 × In no debe fundirse"),
		A.cierto(not candado_cerrado and candado_abierto and not cierra_con_candado, "el candado solo en 0, y con él no cierra"),
		A.cierto(activo_al_empezar and suelta and inversa, "relé de fases: activo con la red bien, suelta sin L3 y con secuencia inversa"),
		A.cierto(sin_alarma and alarma and retenida and borrada, "monitor: alarma bajo 1 MΩ, retenida hasta RESET"),
	])


func test_medir_del_mando() -> String:
	var c := Contenido.new()
	return A.primero([
		A.cierto(_lectura(c, "rele_auxiliar", "Bobina", "Sana") == "4,4 kΩ", "bobina del relé: %s" % _lectura(c, "rele_auxiliar", "Bobina", "Sana")),
		A.cierto(_lectura(c, "temporizador", "Salida con el tiempo", "A la conexión, a los 2 s") == "0,0 V", "a los 2 s aún cuenta"),
		A.cierto(_lectura(c, "temporizador", "Salida con el tiempo", "A la conexión, a los 7 s") == "110 V", "a los 7 s ya conmutó"),
		A.cierto(_lectura(c, "temporizador", "Salida con el tiempo", "A la desconexión, 2 s tras quitar la orden") == "110 V", "a la desconexión sigue 2 s después"),
		A.cierto(_lectura(c, "temporizador", "Salida con el tiempo", "A la desconexión, a los 7 s") == "0,0 V", "a la desconexión vuelve a los 7 s"),
		A.cierto(_lectura(c, "pulsador", "Con tensión", "Sin pulsar") == "110 V", "pulsador abierto: toda la tensión"),
		A.cierto(_lectura(c, "seta", "Con tensión", "Pulsada") == "110 V", "seta pulsada: toda la tensión entre 11 y 12"),
		A.cierto(_lectura(c, "selector", "Tabla de contactos", "13-14 en MAN") == "0,0 Ω", "13-14 cierra en MAN"),
		A.cierto(_lectura(c, "selector", "Tabla de contactos", "13-14 en OFF") == "OL", "13-14 abierto en OFF"),
		A.cierto(_lectura(c, "termostato", "Contacto 1-4", "Bulbo a −10 °C") == "0,0 Ω", "termostato pide frío a −10 °C"),
		A.cierto(_lectura(c, "termostato", "Contacto 1-4", "−10 °C, capilar roto") == "OL", "capilar roto: no pide"),
		A.cierto(_lectura(c, "final_carrera", "Contactos", "21-22 accionado") == "OL", "final de carrera accionado abre 21-22"),
		A.cierto(_lectura(c, "luz_piloto", "Sin tensión", "Fundida") == "OL", "luz fundida: OL"),
	])


func test_cortes_del_mando() -> String:
	var p = _animacion("corte_mando", {"tipo": "presostato", "minimo": 0, "maximo": 25, "corte": 16, "diferencial": 2, "inicial": 12})
	p.poner_valor(17.0)
	var dispara: bool = p.accionado
	p.poner_valor(15.0)
	var no_rearma: bool = not p.rearmar()
	p.poner_valor(13.0)
	var rearma: bool = p.rearmar()
	p.free()
	var t = _animacion("corte_mando", {"tipo": "termostato", "minimo": -30, "maximo": 0, "corte": -18, "diferencial": 2, "inicial": -20})
	t.poner_valor(-18.0)
	var pide: bool = t.accionado
	t.poner_valor(-19.0)
	var sigue: bool = t.accionado
	t.poner_valor(-20.5)
	var para: bool = not t.accionado
	t.free()
	var b = _animacion("corte_mando", {"tipo": "pulsador", "contactos": [{"bornes": "13-14", "tipo": "NA"}]})
	b.pulsar()
	var cerrado_pulsado: bool = b.cerrado({"bornes": "13-14", "tipo": "NA"})
	b.avanzar(1.5)
	var vuelve: bool = not b.accionado
	b.free()
	var k = _animacion("corte_temporizador", {"modo": "on_delay", "retardo_s": 5})
	k.poner_tension(true)
	k.avanzar(3.0)
	var antes: bool = not k.conmutado
	k.avanzar(3.0)
	var despues: bool = k.conmutado
	k.free()
	var h = _animacion("corte_piloto", {})
	h.fundir(true)
	var fundida: bool = h.fase() == 2 and not h.encendida()
	h.free()
	return A.primero([
		A.cierto(dispara and no_rearma and rearma, "presostato: dispara, no rearma en el diferencial y rearma por debajo"),
		A.cierto(pide and sigue and para, "termostato: pide a la consigna, sigue en el diferencial y para debajo"),
		A.cierto(cerrado_pulsado and vuelve, "pulsador: cierra al pulsar y vuelve por resorte"),
		A.cierto(antes and despues, "temporizador: conmuta pasados 5 s"),
		A.cierto(fundida, "luz fundida con tensión: no enciende"),
	])
