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


func _ids_modulo(c: Contenido, modulo: int) -> Array[String]:
	var lista: Array[String] = []
	lista.assign(c.sistema(modulo).get("modos", {}).get("aprender", {}).get("atlas", []))
	return lista


func _terminos_fuera(texto: String, glosario: Dictionary) -> String:
	for t in TextoTecnico.terminos(texto):
		if not glosario.has(t):
			return t
	return ""


func test_el_modulo_7_publica_las_etapas_33_a_36() -> String:
	var c := Contenido.new()
	var m := c.sistema(7)
	var esperados := ["contactor", "rele_termico", "guardamotor", "interruptor_automatico", "diferencial", "fusible", "seccionador", "rele_control_fases", "monitor_aislamiento",
		"rele_auxiliar", "temporizador", "pulsador", "selector", "luz_piloto", "seta", "final_carrera", "presostato", "termostato", "interruptor_nivel",
		"transformador", "transformador_intensidad", "motor_trifasico", "estrella_triangulo", "arrancador_suave", "variador", "resistencia_caldeo", "condensadores",
		"amperimetro", "voltimetro", "analizador_red", "horometro", "bornera"]
	return A.primero([
		A.cierto(m.get("estado", "") == "activo", "el módulo 7 debe estar activo"),
		A.cierto(_ids_modulo(c, 7) == esperados, "atlas del módulo 7: %s" % str(_ids_modulo(c, 7))),
	])


func test_el_modulo_8_publica_la_electronica_i_y_ii() -> String:
	var c := Contenido.new()
	var m := c.sistema(8)
	var esperados := ["resistor", "potenciometro", "termistor", "varistor", "condensador_electrico", "diodo", "diodo_zener", "led", "puente_rectificador",
		"transistor", "mosfet", "tiristor", "triac", "optoacoplador", "rele_estado_solido", "regulador", "fuente_conmutada", "operacional", "puerta_logica"]
	var en_sistema_6: Array = c.sistema(6)["modos"]["aprender"]["fichas"]
	var faltan := esperados.filter(func(id: String) -> bool: return not en_sistema_6.has(id))
	return A.primero([
		A.cierto(m.get("estado", "") == "activo", "el módulo 8 debe estar activo"),
		A.cierto(_ids_modulo(c, 8) == esperados, "atlas del módulo 8: %s" % str(_ids_modulo(c, 8))),
		A.cierto(faltan.is_empty(), "las fichas de electrónica deben publicarse en el sistema 6: faltan %s" % str(faltan)),
		A.cierto(Avance.atlas(m, Partida.new("user://pruebas_atlas_8.json")) == [0, 19], "avance del módulo 8 al empezar"),
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
			# Los grupos y las fallas, solo en vertical: en horizontal basta con las cinco pestañas,
			# y así la batería, que corre en un solo fotograma, no agota los recursos.
			if vertical:
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
				# Las pruebas corren en un solo fotograma: sin liberarlas aquí, las cientos de
				# pantallas recorridas esperarían todas al final y agotarían la memoria.
				var vista := raiz.pantalla_actual()
				raiz.volver()
				if is_instance_valid(vista):
					vista.free()
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
		# 9 lecciones, 32 piezas del atlas y, desde la 5.1.0, el examen de la Escuela I.
		A.cierto(antes == [0, 42], "al empezar: %s" % str(antes)),
		A.cierto(despues == [1, 42], "tras ver las cinco pestañas: %s" % str(despues)),
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


func test_medir_de_potencia_y_medida() -> String:
	var c := Contenido.new()
	return A.primero([
		A.cierto(_lectura(c, "transformador", "Devanados", "1U-1V, columna U cortada") == "0,6 Ω", "columna cortada: triple resistencia"),
		A.cierto(_lectura(c, "transformador_intensidad", "Corriente", "Cable de S1") == "3,8 A", "TI: 76 A en la barra son 3,8 A"),
		A.cierto(_lectura(c, "transformador_intensidad", "Tensión S1-S2", "Amperímetro abierto").trim_suffix(" V").to_int() > 500, "TI abierto: cientos de voltios"),
		A.cierto(_lectura(c, "estrella_triangulo", "Tensión por devanado", "En estrella") == "219 V", "estrella: 220 V por devanado"),
		A.cierto(_lectura(c, "arrancador_suave", "Pantalla", "Estado a los 15 s") == "BYPASS", "arrancador suave en bypass a los 15 s"),
		A.cierto(absi(_lectura(c, "variador", "Bus y salida", "U-V a 25 Hz").trim_suffix(" V").to_int() - 190) <= 2, "variador: V/f a 25 Hz, %s" % _lectura(c, "variador", "Bus y salida", "U-V a 25 Hz")),
		A.cierto(_lectura(c, "variador", "Pantalla", "Frecuencia, consigna 25 Hz") == "25 Hz", "variador: 25 Hz en pantalla"),
		A.cierto(_lectura(c, "resistencia_caldeo", "Resistencia", "Sana") == "529 Ω", "caldeo: V²/P"),
		A.cierto(_lectura(c, "resistencia_caldeo", "En servicio", "Motor en marcha") == "0,0 V", "caldeo apagado en marcha"),
		A.cierto(_lectura(c, "condensadores", "Analizador", "FP con batería") == "0,97 ind", "compensado a 0,97"),
		A.cierto(_lectura(c, "amperimetro", "Aguja", "Aguja") == _lectura(c, "amperimetro", "Aguja", "Pinza en la barra"), "amperímetro y pinza coinciden"),
		A.cierto(_lectura(c, "analizador_red", "Pantalla", "FP") == "0,80 ind", "analizador: FP 0,80"),
		A.cierto(_lectura(c, "horometro", "Tensión", "Bomba en marcha") == "110 V", "horómetro con tensión en marcha"),
		A.cierto(_lectura(c, "bornera", "Caída en servicio", "Borne 2 flojo") == "1,2 V", "borne flojo: 1,2 V"),
	])


func test_cortes_de_potencia_y_medida() -> String:
	var ti = _animacion("corte_ti", {})
	ti.poner_amperimetro(false)
	var peligro: bool = ti.fase() == 3 and ti.tension_secundario() > 500.0
	ti.poner_puente(true)
	var seguro: bool = ti.fase() == 2 and ti.lectura() == 0.0
	ti.free()
	var vf = _animacion("corte_variador", {})
	vf.consigna = 25.0
	vf.poner_marcha(true)
	for _i in 40:
		vf.avanzar(0.1)
	var a_25: bool = is_equal_approx(vf.f, 25.0) and vf.fase() == 3 and is_equal_approx(vf.tension_salida(), 190.0)
	var red_menor: bool = vf.corriente_red() < vf.corriente_motor()
	vf.free()
	var ca = _animacion("corte_caldeo", {})
	var calienta: bool = ca.calentando() and not ca.condensa()
	ca.cortar(true)
	var condensa: bool = ca.condensa()
	ca.poner_marcha(true)
	var apagada: bool = not ca.calentando() and ca.fase() == 3
	ca.free()
	var co = _animacion("corte_compensacion", {"tipo": "compensacion"})
	var fp_con: float = co.fp()
	co.conectar(false)
	var fp_sin: float = co.fp()
	co.free()
	var ap = _animacion("corte_aparato", {"tipo": "horometro"})
	ap.poner_marcha(true)
	ap.poner_60_hz(true)
	var atrasa: bool = ap.ritmo() < 1.0 and ap.fase() == 3
	ap.free()
	var bo = _animacion("corte_bornera", {})
	bo.poner("flojo")
	var flojo: bool = absf(bo.caida() - 1.2) < 0.01 and bo.temperatura() > 70.0
	bo.free()
	return A.primero([
		A.cierto(peligro and seguro, "TI: abierto es peligroso; con el puente, seguro"),
		A.cierto(a_25 and red_menor, "variador: rampa hasta 25 Hz con 190 V y menos corriente de red"),
		A.cierto(calienta and condensa and apagada, "caldeo: calienta parado, condensa si se corta, se apaga en marcha"),
		A.cierto(fp_con > 0.95 and fp_sin < 0.8, "compensación: %.2f con batería y %.2f sin ella" % [fp_con, fp_sin]),
		A.cierto(atrasa, "horómetro de 60 Hz atrasa"),
		A.cierto(flojo, "borne flojo: 1,2 V y más de 70 °C"),
	])


func test_medir_de_electronica() -> String:
	var c := Contenido.new()
	return A.primero([
		A.cierto(_lectura(c, "resistor", "Valor", "Sana") == "4,7 kΩ", "resistencia: %s" % _lectura(c, "resistor", "Valor", "Sana")),
		A.cierto(_lectura(c, "resistor", "En la tarjeta", "Con R2 en paralelo") == "3,2 kΩ", "en la tarjeta marca menos"),
		A.cierto(_lectura(c, "resistor", "En servicio", "R1 cortada") == "24 V", "R1 cortada: toda la tensión"),
		A.cierto(_lectura(c, "potenciometro", "En servicio", "A la mitad") == "5,0 V", "cursor a la mitad: 5 V"),
		A.cierto(_lectura(c, "potenciometro", "Cursor", "Girado un cuarto") == "2,5 kΩ", "un cuarto: 2,5 kΩ"),
		A.cierto(_lectura(c, "termistor", "NTC", "A 25 °C") == "10,0 kΩ", "NTC a 25 °C: %s" % _lectura(c, "termistor", "NTC", "A 25 °C")),
		A.cierto(_lectura(c, "termistor", "NTC", "A 60 °C") == "2,5 kΩ", "NTC a 60 °C"),
		A.cierto(_lectura(c, "termistor", "PTC del motor", "Motor frío, 25 °C") == "298 Ω", "PTC en frío: %s" % _lectura(c, "termistor", "PTC del motor", "Motor frío, 25 °C")),
		A.cierto(_lectura(c, "termistor", "PTC del motor", "A 135 °C") == "4,5 kΩ", "PTC pasada la TNF"),
		A.cierto(_lectura(c, "termistor", "En servicio", "A 25 °C") == "2,5 V", "divisor de la NTC"),
		A.cierto(_lectura(c, "varistor", "Fuga", "Sano") == "OL", "varistor sano: OL"),
		A.cierto(_lectura(c, "varistor", "En servicio", "En corto") == "0,0 V", "varistor en corto: F1 fundido"),
		A.cierto(_lectura(c, "varistor", "Corriente de fuga", "Degradado") == "4,6 mA", "fuga del degradado"),
		A.cierto(_lectura(c, "condensador_electrico", "Capacidad", "Sano") == "20,0 µF", "capacidad: %s" % _lectura(c, "condensador_electrico", "Capacidad", "Sano")),
		A.cierto(_lectura(c, "condensador_electrico", "Capacidad", "Seco") == "10,0 µF", "seco: la mitad"),
		A.cierto(_lectura(c, "condensador_electrico", "Capacidad", "En corto") == "OL", "en corto: fuera de escala"),
		A.cierto(_lectura(c, "condensador_electrico", "En servicio", "Sano") == "1,4 A", "20 µF a 230 V: 1,4 A"),
		A.cierto(_lectura(c, "diodo", "Prueba de diodo", "Sano") == "0,7 V", "diodo en directa"),
		A.cierto(_lectura(c, "diodo", "Al revés", "Sano") == "OL", "diodo al revés"),
		A.cierto(_lectura(c, "diodo", "En servicio", "Al revés") == "-24,0 V", "diodo montado al revés: %s" % _lectura(c, "diodo", "En servicio", "Al revés")),
		A.cierto(_lectura(c, "diodo_zener", "En servicio", "Sano") == "12,1 V", "Zener regula: %s" % _lectura(c, "diodo_zener", "En servicio", "Sano")),
		A.cierto(_lectura(c, "diodo_zener", "En servicio", "Abierto") == "16,3 V", "Zener abierto: divisor"),
		A.cierto(_lectura(c, "diodo_zener", "Al revés", "Sano") == "OL", "el multímetro no llega a 12 V"),
		A.cierto(_lectura(c, "led", "Corriente", "Con R1 de 1,1 kΩ") == "19,7 mA", "LED: %s" % _lectura(c, "led", "Corriente", "Con R1 de 1,1 kΩ")),
		A.cierto(_lectura(c, "led", "Prueba de diodo", "Sano") == "1,9 V", "LED en prueba de diodo"),
		A.cierto(_lectura(c, "puente_rectificador", "Diodos", "− → +, dos diodos") == "1,4 V", "dos diodos en serie"),
		A.cierto(_lectura(c, "puente_rectificador", "Diodos", "+ → ~") == "OL", "el puente bloquea al revés"),
		A.cierto(_lectura(c, "puente_rectificador", "Salida", "Con filtro") == "32 V", "puente con filtro: %s" % _lectura(c, "puente_rectificador", "Salida", "Con filtro")),
		A.cierto(_lectura(c, "puente_rectificador", "Salida", "Filtro seco") == "20 V", "sin filtro: 20 V"),
		A.cierto(_lectura(c, "puente_rectificador", "Salida", "Un diodo abierto, sin filtro") == "10,0 V", "media onda: la mitad"),
		A.cierto(_lectura(c, "puente_rectificador", "Entrada", "Un diodo en corto") == "0,0 V", "diodo en corto: F1 fundido"),
	])


func test_cortes_de_electronica() -> String:
	var r = _animacion("corte_resistor", {})
	r.elegir(2)
	r.poner_tension(24.0)
	var holgada: bool = not r.se_quema() and r.fase() == 2 and absf(r.corriente() - 24.0 / 4700.0) < 1e-6
	r.elegir(0)
	var quema: bool = r.se_quema() and r.fase() == 3
	r.free()
	var p = _animacion("corte_potenciometro", {})
	p.poner_posicion(0.5)
	var mitad: bool = is_equal_approx(p.tension_cursor(), 5.0) and is_equal_approx(p.frecuencia(), 25.0)
	p.gastar(true)
	var tiron: bool = p.tension_cursor() == 0.0 and p.fase() == 2
	p.free()
	var t = _animacion("corte_termistor", {})
	var ntc_25: bool = absf(t.resistencia() - 10000.0) < 1.0 and absf(t.tension_sonda() - 2.5) < 0.01
	t.elegir_tipo("ptc")
	t.poner_temperatura(135.0)
	var dispara: bool = t.disparado and t.fase() == 3
	t.poner_temperatura(128.0)
	var sigue: bool = t.disparado
	t.poner_temperatura(100.0)
	var rearma: bool = not t.disparado
	t.free()
	var v = _animacion("corte_varistor", {})
	var recorta: bool = is_equal_approx(v.pico(), SimVaristor.new("x").params["v_recorte"])
	for _i in 4:
		v.pico()
	var en_corto: bool = v.en_corto and v.fusible_fundido and v.tension_fuente() == 0.0 and v.fase() == 3
	v.cambiar_todo()
	v.poner_abierto(true)
	var sin_proteccion: bool = v.pico() > 1500.0 and v.fuente_danada
	v.free()
	var cd = _animacion("corte_condensador", {})
	cd.avanzar(5.0 * cd.tau())
	var lleno: bool = cd.vc > 23.8
	cd.poner_tension(false)
	cd.avanzar(10.0)
	var guarda: bool = cd.vc > 23.0 and cd.fase() == 2
	cd.descargar()
	cd.avanzar(5.0 * cd.tau())
	var descargado: bool = cd.vc < 0.2 and cd.fase() == 3
	cd.free()
	var d = _animacion("corte_diodo", {})
	var directa: bool = is_equal_approx(d.tension_diodo(), 0.7) and d.corriente() > 0.09
	d.girar()
	var inversa: bool = d.corriente() == 0.0 and is_equal_approx(d.tension_diodo(), 24.0)
	d.free()
	var z = _animacion("corte_zener", {})
	z.poner_entrada(24.0)
	var regula: bool = z.conduce() and absf(z.salida() - 12.07) < 0.05
	z.poner_entrada(10.0)
	var sigue_entrada: bool = not z.conduce() and absf(z.salida() - 10.0 * 1000.0 / 1470.0) < 0.01
	z.free()
	var led = _animacion("corte_led", {})
	var luce: bool = led.luce() and absf(led.corriente() - 22.1 / 1120.0) < 1e-4
	led.elegir(3)
	var funde: bool = led.fundido and led.fase() == 3
	led.elegir(1)
	var sigue_fundido: bool = led.fundido
	led.cambiar()
	led.girar()
	var al_reves: bool = not led.luce() and not led.fundido
	led.free()
	var pu = _animacion("corte_puente", {})
	var con_filtro: bool = absf(pu.tension_media() - (24.0 * 1.414 - 1.4)) < 0.01
	pu.poner_filtro(false)
	var sin_filtro: bool = absf(pu.tension_media() - (24.0 * 0.9 - 1.4)) < 0.01
	pu.abrir_diodo(true)
	var media_onda: bool = absf(pu.tension_media() - (24.0 * 0.45 - 0.7)) < 0.01
	pu.free()
	return A.primero([
		A.cierto(holgada and quema, "resistencia: 4,7 kΩ holgada a 24 V y 470 Ω se quema"),
		A.cierto(mitad and tiron, "potenciómetro: 5 V a la mitad y tirón en la pista gastada"),
		A.cierto(ntc_25 and dispara and sigue and rearma, "termistor: NTC de 10 kΩ y PTC con disparo, histéresis y rearme"),
		A.cierto(recorta and en_corto and sin_proteccion, "varistor: recorta, se agota en corto y reventado no protege"),
		A.cierto(lleno and guarda and descargado, "condensador: se carga en 5τ, guarda la carga y se descarga"),
		A.cierto(directa and inversa, "diodo: 0,7 V en directa y bloquea al revés"),
		A.cierto(regula and sigue_entrada, "Zener: regula a 12 V y por debajo sigue a la entrada"),
		A.cierto(luce and funde and sigue_fundido and al_reves, "LED: luce con 1,1 kΩ, se funde sin resistencia y al revés no luce"),
		A.cierto(con_filtro and sin_filtro and media_onda, "puente: 32 V con filtro, 20 V sin él y media onda"),
	])


func test_medir_de_electronica_ii() -> String:
	var c := Contenido.new()
	return A.primero([
		A.cierto(_lectura(c, "transistor", "En servicio", "Con orden (S1)") == "0,2 V", "transistor saturado: %s" % _lectura(c, "transistor", "En servicio", "Con orden (S1)")),
		A.cierto(_lectura(c, "transistor", "En servicio", "RB de 470 kΩ") == "21 V", "sin saturar: %s" % _lectura(c, "transistor", "En servicio", "RB de 470 kΩ")),
		A.cierto(_lectura(c, "transistor", "Diodos", "C → E") == "OL", "C-E: OL"),
		A.cierto(_lectura(c, "mosfet", "Prueba de diodo", "S → D, diodo interno") == "0,5 V", "diodo interno del MOSFET"),
		A.cierto(_lectura(c, "mosfet", "Puerta", "Perforada") == "10 Ω", "puerta perforada"),
		A.cierto(_lectura(c, "tiristor", "Sirena", "Soltado S1") == "23 V", "tiristor enclavado: %s" % _lectura(c, "tiristor", "Sirena", "Soltado S1")),
		A.cierto(_lectura(c, "tiristor", "Sirena", "Pulsando S2") == "0,0 V", "S2 lo apaga"),
		A.cierto(_lectura(c, "triac", "En servicio", "Con puerta (S1)") == "229 V", "triac conduce: %s" % _lectura(c, "triac", "En servicio", "Con puerta (S1)")),
		A.cierto(_lectura(c, "triac", "En servicio", "RG de 1 kΩ") == "0,0 V", "poca puerta: no conduce"),
		A.cierto(_lectura(c, "triac", "Óhmetro", "A1-A2") == "OL" and _lectura(c, "triac", "Óhmetro", "A1-A2 en corto") == "0,0 Ω", "triac: A1-A2 con el óhmetro"),
		A.cierto(_lectura(c, "optoacoplador", "Aislamiento", "Sano") == "> 999 MΩ", "aislamiento del optoacoplador"),
		A.cierto(_lectura(c, "optoacoplador", "En servicio", "Entrada activa (S1)") == "0,2 V", "salida activa"),
		A.cierto(_lectura(c, "rele_estado_solido", "Sin carga", "Relé sano, apagado") == "229 V", "tensión fantasma: %s" % _lectura(c, "rele_estado_solido", "Sin carga", "Relé sano, apagado")),
		A.cierto(_lectura(c, "rele_estado_solido", "En servicio", "Sin orden") == "1,3 V", "fuga con carga: %s" % _lectura(c, "rele_estado_solido", "En servicio", "Sin orden")),
		A.cierto(_lectura(c, "regulador", "Salida", "Normal") == "12,0 V", "regulador: %s" % _lectura(c, "regulador", "Salida", "Normal")),
		A.cierto(_lectura(c, "regulador", "Calor", "Sin disipador, a los 12 s") == "0,0 V", "corte térmico sin disipador"),
		A.cierto(_lectura(c, "regulador", "Salida", "En corto IN-OUT") == "24 V", "regulador en corto"),
		A.cierto(_lectura(c, "fuente_conmutada", "Salida", "Degradada") == "19,2 V", "fuente degradada"),
		A.cierto(_lectura(c, "fuente_conmutada", "Salida", "Corto en la salida") == "0,0 V", "protección de la fuente"),
		A.cierto(_lectura(c, "operacional", "Salida", "Sonda a 70 °C") == "10,1 V", "alarma: %s" % _lectura(c, "operacional", "Salida", "Sonda a 70 °C")),
		A.cierto(_lectura(c, "operacional", "Salida", "70 °C, sonda abierta") == "0,0 V", "sonda abierta: sin alarma"),
		A.cierto(_lectura(c, "puerta_logica", "Tabla de verdad", "A = 1, B = 1") == "4,6 V", "AND con las dos a 1: %s" % _lectura(c, "puerta_logica", "Tabla de verdad", "A = 1, B = 1")),
		A.cierto(_lectura(c, "puerta_logica", "Tabla de verdad", "A = 1, B = 0") == "0,0 V", "AND con una a 0"),
		A.cierto(_lectura(c, "puerta_logica", "Otras puertas", "XOR (4070)") == "4,6 V", "XOR distintas"),
		A.cierto(_lectura(c, "puerta_logica", "Entrada al aire", "Salida Y con B = 1") == "2,4 V", "salida indefinida"),
	])


func test_cortes_de_electronica_ii() -> String:
	var q = _animacion("corte_transistor", {})
	q.poner_orden(true)
	var satura: bool = q.saturado() and q.rele_entra() and is_equal_approx(q.vce(), 0.2)
	q.elegir_rb(1)
	var no_satura: bool = not q.saturado() and not q.rele_entra() and q.vce() > 5.0
	q.elegir_rb(0)
	q.poner_supresor(false)
	q.poner_orden(false)
	var perforado: bool = q.quemado and q.fase() == 3
	q.free()
	var m = _animacion("corte_mosfet", {})
	m.poner_vgs(10.0)
	var pleno: bool = m.nivel() == 2 and m.potencia() < 0.5 and not m.quemado
	m.poner_vgs(5.0)
	var medias: bool = m.quemado and m.fase() == 3
	m.free()
	var tr = _animacion("corte_tiristor", {})
	tr.pulsar_puerta()
	var dispara: bool = tr.disparado and tr.fase() == 2
	tr.avanzar(1.0)
	var enclava: bool = tr.disparado and tr.fase() == 3
	tr.cortar()
	var apaga: bool = not tr.disparado
	tr.free()
	var tc = _animacion("corte_triac", {})
	tc.poner_puerta(true)
	tc.avanzar(0.1)
	var conduce: bool = tc.conduce
	tc.poner_puerta(false)
	var espera: bool = tc.conduce and tc.fase() == 3
	tc.avanzar(1.0)
	var apagado: bool = not tc.conduce
	tc.free()
	var ok = _animacion("corte_optoacoplador", {})
	ok.poner_entrada(true)
	var baja: bool = is_equal_approx(ok.salida(), 0.2)
	ok.pico()
	var aislado: bool = not ok.danada
	ok.unir(true)
	ok.pico()
	var danada: bool = ok.danada
	ok.free()
	var s = _animacion("corte_ssr", {})
	var fuga: bool = s.tension_salida() < 2.0
	s.quitar_carga(true)
	var fantasma: bool = s.tension_salida() > 220.0 and s.fase() == 3
	s.free()
	var r = _animacion("corte_regulador", {})
	var regula: bool = is_equal_approx(r.salida(), 12.0) and absf(r.potencia() - 6.0) < 0.01
	r.poner_disipador(false)
	for _i in 120:
		r.avanzar(0.1)
	var corta: bool = r.corte and r.salida() == 0.0
	r.poner_entrada(13.0)
	r.poner_disipador(true)
	for _i in 600:
		r.avanzar(0.1)
	var baja_entrada: bool = not r.corte and is_equal_approx(r.salida(), 11.0)
	r.free()
	var f = _animacion("corte_fuente", {})
	var servicio: bool = f.salida() > 23.9 and f.fase() == 2
	f.elegir_carga(2)
	f.avanzar(0.2)
	var protege: bool = f.protegida and f.salida() == 0.0
	f.avanzar(2.0)
	var reintenta: bool = not f.protegida
	f.free()
	var op = _animacion("corte_operacional", {})
	var sin_alarma: bool = not op.alarma()
	op.poner_temperatura(70.0)
	var alarma: bool = op.alarma()
	op.abrir_sonda(true)
	var sonda: bool = not op.alarma()
	op.free()
	var p = _animacion("corte_puertas", {})
	p.poner(1, 1)
	var and_11: bool = p.salida() == 1
	p.elegir_tipo("nand")
	var nand_11: bool = p.salida() == 0
	p.elegir_tipo("not")
	p.poner(0, 0)
	var not_0: bool = p.salida() == 1
	p.al_aire(true)
	var indefinida: bool = p.salida() == -1 and p.fase() == 3
	p.free()
	return A.primero([
		A.cierto(satura and no_satura and perforado, "transistor: satura con 10 kΩ, no con 100 kΩ, y sin supresor se perfora"),
		A.cierto(pleno and medias, "MOSFET: pleno con 10 V y se quema a medias"),
		A.cierto(dispara and enclava and apaga, "tiristor: dispara, se enclava y S2 lo apaga"),
		A.cierto(conduce and espera and apagado, "triac: conduce con puerta y se apaga en el paso por cero"),
		A.cierto(baja and aislado and danada, "optoacoplador: aísla, salvo con los comunes unidos"),
		A.cierto(fuga and fantasma, "relé de estado sólido: fuga y tensión fantasma"),
		A.cierto(regula and corta and baja_entrada, "regulador: 12 V, corte térmico y entrada baja"),
		A.cierto(servicio and protege and reintenta, "fuente: 24 V, protección y reintento"),
		A.cierto(sin_alarma and alarma and sonda, "operacional: alarma con calor y sin ella con la sonda abierta"),
		A.cierto(and_11 and nand_11 and not_0 and indefinida, "puertas: AND, NAND, NOT y entrada al aire"),
	])
