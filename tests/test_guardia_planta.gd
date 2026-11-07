extends RefCounted
## Misiones de Guardia de la planta de frío: averías, procedimiento, amoníaco, incidentes y
## resultados sobre la simulación real de la planta.

const A := preload("res://tests/ayuda_sim.gd")
const MISIONES := ["fr1_alta_descarga", "fr2_hielo_evaporador", "fr3_presion_aceite", "fr4_fuga_nh3", "fr5_nivel_botella"]
const RUTA_PARTIDA := "user://pruebas_guardia_planta.json"
## Las pruebas avanzan la planta con pasos de un cuarto de segundo: cambia despacio.
const PASO_S := 0.25


func _mision(id: String) -> MisionPlanta:
	return MisionPlanta.new(Contenido.new(), id)


func _opcion_correcta(m: MisionBase) -> int:
	var opciones: Array = m.datos["diagnostico"]["opciones"]
	for i in opciones.size():
		if opciones[i].get("correcta", false):
			return i
	return -1


func _respuestas_correctas(m: MisionBase) -> Dictionary:
	var r := {}
	var campos := m.campos_libro()
	for i in campos.size():
		r[i] = int(campos[i]["correcta"])
	return r


func _esperar(m: MisionPlanta, segundos: float) -> void:
	m.avanzar(segundos, PASO_S)


func _marcha(m: MisionPlanta) -> void:
	m.pulsar("S1", true)
	_esperar(m, 0.5)
	m.pulsar("S1", false)
	_esperar(m, 3.0)


func _parada(m: MisionPlanta) -> void:
	m.pulsar("S0", true)
	_esperar(m, 0.5)
	m.pulsar("S0", false)
	_esperar(m, 1.0)


## Espera hasta que dispare el presostato, como máximo el tiempo dado.
func _esperar_disparo(m: MisionPlanta, id: String, maximo_s: float) -> bool:
	var p: SimPresostato = m.sim.componente(id)
	var t := 0.0
	while t < maximo_s and m.fin.is_empty():
		if p.estado["disparado"]:
			return true
		_esperar(m, 1.0)
		t += 1.0
	return p.estado["disparado"]


func _terminar(m: MisionPlanta) -> void:
	m.avanzar(m.tiempo_de_prueba() + 10.0, 0.5)
	m.firmar(_respuestas_correctas(m))


# --- Recorridos completos, también usados por la prueba de progresión ---

func completar(m: MisionPlanta) -> void:
	match m.id():
		"fr1_alta_descarga":
			m.rearmar_presostato("PA")
			_marcha(m)
			m.medir_tuberia("agua_mar_entrada")
			_esperar(m, 40.0)
			m.medir_tuberia("agua_mar_salida")
			_esperar_disparo(m, "PA", 120.0)
			m.diagnosticar(_opcion_correcta(m))
			m.alternar_bomba("bomba_agua_mar")
			m.dar_paso("aviso")
			m.bloquear("bomba_agua_mar")
			m.ejecutar("cerrar_agua")
			m.ejecutar("limpiar_condensador")
			m.ejecutar("abrir_agua")
			m.desbloquear("bomba_agua_mar")
			m.alternar_bomba("bomba_agua_mar")
			_esperar(m, 60.0)
			m.rearmar_presostato("PA")
			_marcha(m)
		"fr2_hielo_evaporador":
			_esperar_disparo(m, "PB", 600.0)
			m.ejecutar("medir_densidad")
			m.ejecutar("mirar_evaporador")
			m.diagnosticar(_opcion_correcta(m))
			m.dar_paso("aviso")
			m.dar_paso("epp")
			m.ejecutar("anadir_sal")
			# Parado y con la salmuera circulando, el hielo se funde.
			m.avanzar(400.0, 0.5)
			_marcha(m)
		"fr3_presion_aceite":
			m.rearmar_presostato("PO")
			_marcha(m)
			m.ejecutar("medir_filtro")
			m.ejecutar("mirar_nivel")
			_esperar_disparo(m, "PO", 60.0)
			# El contactor suelta un instante después de abrirse la cadena de seguridades.
			_esperar(m, 2.0)
			m.diagnosticar(_opcion_correcta(m))
			m.dar_paso("aviso")
			m.alternar_guardamotor()
			m.bloquear("Q1")
			m.verificar("Q1")
			m.ejecutar("aislar_filtro")
			m.ejecutar("cambiar_filtro")
			m.ejecutar("abrir_filtro")
			m.desbloquear("Q1")
			m.alternar_guardamotor()
			_esperar(m, 1.0)
			m.rearmar_presostato("PO")
			_marcha(m)
		"fr4_fuga_nh3":
			m.dar_paso("evacuar")
			m.dar_paso("aviso")
			m.alternar_ventilacion()
			_parada(m)
			m.dar_paso("era")
			m.dar_paso("companero")
			m.ejecutar("localizar")
			m.diagnosticar(_opcion_correcta(m))
			m.ejecutar("aislar_compresor")
			m.alternar_guardamotor()
			m.bloquear("Q1")
			m.verificar("Q1")
			m.ejecutar("cambiar_cierre")
			m.ejecutar("abrir_compresor")
			m.desbloquear("Q1")
			m.alternar_guardamotor()
			_esperar(m, 1.0)
			_marcha(m)
			m.avanzar(300.0, 0.5)
		"fr5_nivel_botella":
			m.dar_paso("aviso")
			m.ejecutar("mirar_visor")
			m.ejecutar("comprobar_bobina")
			m.diagnosticar(_opcion_correcta(m))
			m.ejecutar("aislar_solenoide")
			m.alternar_guardamotor()
			m.bloquear("Q1")
			m.verificar("Q1")
			m.ejecutar("cambiar_solenoide")
			m.ejecutar("abrir_solenoide")
			m.ejecutar("trasegar")
			m.desbloquear("Q1")
			m.alternar_guardamotor()
			_esperar(m, 3.0)
			_marcha(m)
	_terminar(m)


func test_las_misiones_de_la_planta_estan_bien_formadas() -> String:
	var c := Contenido.new()
	var publicadas: Array = c.sistema(4)["modos"]["guardia"]["misiones"]
	var glosario := c.glosario()
	for id: String in MISIONES:
		if not publicadas.has(id):
			return "falta publicar %s" % id
		var m := _mision(id)
		if m.datos.get("tipo", "") != "planta":
			return "%s debe ser de la planta" % id
		var correctas := 0
		for o: Dictionary in m.datos["diagnostico"]["opciones"]:
			if o.get("correcta", false):
				correctas += 1
			if o["explicacion"].is_empty():
				return "%s: una opción no explica por qué" % id
		if correctas != 1:
			return "%s debe tener un solo diagnóstico correcto" % id
		for campo: Dictionary in m.campos_libro():
			if int(campo["correcta"]) >= campo["opciones"].size():
				return "%s: campo del libro sin respuesta válida" % id
		for t in TextoTecnico.terminos(m.datos["reporte"]["texto"]):
			if not glosario.has(t):
				return "%s usa un término fuera del glosario: %s" % [id, t]
		if not m.datos["reporte"]["nota"].contains("verificar a bordo"):
			return "%s debe marcar sus valores típicos" % id
		if m.datos.get("para_saber_mas", []).is_empty():
			return "a %s le falta Para saber más" % id
		for o: Dictionary in m.objetivos():
			m.condicion(o)
			if o.get("texto", "").is_empty():
				return "%s: un objetivo no tiene texto" % id
		var temas: Array = m.datos.get("eventos", {}).values() + m.datos.get("repetidos", {}).values()
		for a: Dictionary in m.datos.get("acciones", []):
			if a.has("tema"):
				temas.append(a["tema"])
			for comprobacion: Dictionary in a.get("comprobar", []):
				temas.append(comprobacion["falta"])
				m.condicion(comprobacion)
			for r: Dictionary in a.get("requiere", []):
				m.condicion(r)
				if r.get("si_no", "").is_empty():
					return "%s: la acción %s no explica qué le falta" % [id, a["id"]]
		for tema: String in temas:
			if not m.comunes["faltas"].has(tema):
				return "%s usa una falta sin texto: %s" % [id, tema]
		for b: String in m.bloqueables():
			if b != "Q1" and not m.planta().estado.has(b):
				return "%s: no se puede bloquear %s" % [id, b]
		if not m.fin.is_empty() or not m.faltas.is_empty():
			return "%s empieza con %s %s" % [id, m.fin, str(m.faltas)]
	return "; ".join(c.errores)


func test_faltas_e_incidentes_de_la_planta_tienen_texto_y_pregunta() -> String:
	var g: Dictionary = Contenido.new().leer("guardia.json")
	for tipo: String in MisionPlanta.EVENTOS_INCIDENTE.values() + ["arranque_aislado"]:
		var i: Dictionary = g["incidentes"].get(tipo, {})
		for clave in ["cabecera", "titulo", "que_ocurrio", "causa", "como_evitar", "repasar"]:
			if i.get(clave, "").is_empty():
				return "el incidente %s no tiene %s" % [tipo, clave]
		if not g["preguntas"].has("incidente_" + tipo):
			return "el incidente %s no tiene pregunta de repaso" % tipo
	for tipo in ["exposicion_nh3", "abrir_con_presion"]:
		if g["accidentes"].get(tipo, {}).get("como_evitar", "").is_empty():
			return "el accidente %s no tiene texto" % tipo
		if not g["preguntas"].has("accidente_" + tipo):
			return "el accidente %s no tiene pregunta de repaso" % tipo
	for tema in ["ajuste_presostato", "sin_ventilacion", "sin_epp_quimico", "sin_evacuar", "rearme_sin_causa"]:
		if not g["faltas"].has(tema) or not g["preguntas"].has(tema):
			return "la falta %s necesita texto y pregunta" % tema
	return ""


func test_cada_mision_se_completa_sin_faltas() -> String:
	for id: String in MISIONES:
		var m := _mision(id)
		completar(m)
		if m.fin != "completada" or m.estrellas() != 3:
			var pendientes := PackedStringArray()
			for o: Dictionary in m.objetivos():
				if not m.condicion(o):
					pendientes.append(o["texto"])
			return "%s: fin «%s», %d estrellas, faltas %s, diagnóstico %s, prueba %s, sin cumplir: %s" % [id, m.fin, m.estrellas(), str(m.faltas), m.diagnostico_ok, m.prueba_ok, ", ".join(pendientes)]
	return ""


# --- Alta presión de descarga ---

func test_alta_descarga_empieza_disparada_y_vuelve_a_disparar() -> String:
	var m := _mision("fr1_alta_descarga")
	var disparado: bool = m.sim.componente("PA").estado["disparado"]
	var parado := not m.en_marcha()
	var rearme := m.rearmar_presostato("PA")
	_marcha(m)
	var marcha := m.en_marcha()
	var dispara := _esperar_disparo(m, "PA", 180.0)
	return A.primero([
		A.cierto(disparado and parado, "debe empezar parada y con PA disparado"),
		A.cierto(rearme["tipo"] == "hecho", "parada, la descarga es baja y PA rearma: %s" % str(rearme)),
		A.cierto(marcha, "rearmado, el compresor debe arrancar"),
		A.cierto(dispara and not m.en_marcha(), "con el condensador sucio debe volver a disparar"),
		A.cierto(m.faltas.is_empty(), "el primer disparo sirve para ver la avería: %s" % str(m.faltas)),
	])


func test_rearmar_sin_corregir_es_falta() -> String:
	var m := _mision("fr1_alta_descarga")
	for _i in 2:
		_esperar(m, 60.0)
		m.rearmar_presostato("PA")
		_marcha(m)
		_esperar_disparo(m, "PA", 180.0)
	return A.cierto(m.faltas.size() == 1 and m.faltas[0]["tema"] == "rearme_sin_causa", "el segundo disparo debe ser falta: %s" % str(m.faltas))


func test_subir_el_presostato_de_alta_deja_la_planta_sin_proteccion() -> String:
	var m := _mision("fr1_alta_descarga")
	var aviso := m.ejecutar("subir_alta")
	m.rearmar_presostato("PA")
	_marcha(m)
	var maxima := 0.0
	for _i in 150:
		_esperar(m, 1.0)
		maxima = maxf(maxima, m.planta().presion("descarga"))
	return A.primero([
		A.cierto(aviso["tipo"] == "error" and m.faltas[0]["tema"] == "ajuste_presostato", "subir el corte debe ser falta: %s" % str(m.faltas)),
		A.cierto(m.en_marcha() and maxima > 16.0, "sin el corte de 16 bar el compresor sigue por encima: %.1f bar" % maxima),
		A.cierto(not m.condicion({"c": "param", "id": "PA", "clave": "corte_bar", "max": 16.0}), "la prueba exige restituir el ajuste"),
	])


## La válvula de seguridad es la última protección: si abre, la misión termina en incidente.
func test_apertura_de_la_valvula_de_seguridad_es_incidente() -> String:
	var m := _mision("fr1_alta_descarga")
	m.sim.componente("PLANTA").params["valvula_seguridad_bar"] = 15.0
	m.ejecutar("subir_alta")
	m.rearmar_presostato("PA")
	_marcha(m)
	_esperar(m, 150.0)
	return A.cierto(m.fin == "accidente" and m.accidente["tema"] == "incidente_valvula_seguridad", "fin %s: %s" % [m.fin, str(m.accidente.get("tema", ""))])


func test_limpiar_sin_bloquear_la_bomba_es_accidente() -> String:
	var m := _mision("fr1_alta_descarga")
	m.alternar_bomba("bomba_agua_mar")
	m.ejecutar("cerrar_agua")
	var aviso := m.ejecutar("limpiar_condensador")
	return A.primero([
		A.cierto(aviso["tipo"] == "accidente" and m.fin == "accidente", "debe terminar en accidente: %s" % str(aviso)),
		A.cierto(m.accidente["titulo"].contains("caja de agua"), "el informe debe ser el de la misión: %s" % m.accidente["titulo"]),
	])


func test_cerrar_el_agua_exige_parar_la_bomba() -> String:
	var m := _mision("fr1_alta_descarga")
	var con_bomba := m.ejecutar("cerrar_agua")
	m.alternar_bomba("bomba_agua_mar")
	m.dar_paso("aviso")
	var bloqueo := m.bloquear("bomba_agua_mar")
	var arranque := m.alternar_bomba("bomba_agua_mar")
	return A.primero([
		A.cierto(con_bomba["tipo"] == "aviso" and not m.hechos.has("agua_cerrada"), "con la bomba en marcha no se cierra: %s" % str(con_bomba)),
		A.cierto(bloqueo["tipo"] == "hecho" and m.bloqueado("bomba_agua_mar"), "parada, se bloquea"),
		A.cierto(arranque["tipo"] == "aviso" and not m.planta().estado["bomba_agua_mar"], "bloqueada, no arranca: %s" % str(arranque)),
	])


func test_termometro_queda_en_el_libro() -> String:
	var m := _mision("fr1_alta_descarga")
	m.medir_tuberia("agua_mar_salida")
	m.medir_tuberia("agua_mar_salida")
	m.medir_tuberia("descarga")
	return A.primero([
		A.cierto(m.mediciones.size() == 2, "cada punto se anota una vez, con la última lectura: %s" % str(m.mediciones)),
		A.cierto(m.mediciones[0].ends_with("°C") and m.condicion({"c": "medido", "punto": "agua_mar_salida"}), "debe quedar la lectura: %s" % str(m.mediciones)),
	])


func test_diagnostico_sin_medir_el_agua_es_falta() -> String:
	var m := _mision("fr1_alta_descarga")
	m.diagnosticar(_opcion_correcta(m))
	return A.cierto(m.diagnostico_ok and m.faltas.size() == 1 and m.faltas[0]["tema"] == "diagnostico_sin_medir", "faltas: %s" % str(m.faltas))


# --- Hielo en el evaporador ---

func test_salmuera_floja_forma_hielo_y_dispara_por_baja() -> String:
	var m := _mision("fr2_hielo_evaporador")
	var marcha := m.en_marcha()
	var dispara := _esperar_disparo(m, "PB", 600.0)
	return A.primero([
		A.cierto(marcha, "debe empezar en marcha"),
		A.cierto(dispara and not m.en_marcha(), "debe disparar por baja"),
		A.cierto(float(m.planta().estado["hielo"]) > 1.0, "debe haber hielo en los tubos: %.2f" % m.planta().estado["hielo"]),
		A.cierto(m.planta().temperatura("salmuera") > -14.0, "la salmuera no llega a la consigna: %.1f °C" % m.planta().temperatura("salmuera")),
	])


func test_sal_sin_proteccion_es_falta() -> String:
	var m := _mision("fr2_hielo_evaporador")
	var aviso := m.ejecutar("anadir_sal")
	return A.primero([
		A.cierto(aviso["tipo"] == "error" and m.faltas[0]["tema"] == "sin_epp_quimico", "falta: %s" % str(m.faltas)),
		A.cierto(float(m.sim.componente("PLANTA").params["congelacion_salmuera"]) <= -20.0, "la sal se añade igualmente"),
	])


func test_sin_corregir_la_salmuera_el_hielo_no_se_funde() -> String:
	var m := _mision("fr2_hielo_evaporador")
	_esperar_disparo(m, "PB", 600.0)
	m.avanzar(400.0, 0.5)
	var hielo: float = m.planta().estado["hielo"]
	return A.cierto(hielo > 0.5, "con la salmuera floja el hielo sigue: %.2f" % hielo)


# --- Presión de aceite ---

func test_filtro_obstruido_dispara_a_los_45_s() -> String:
	var m := _mision("fr3_presion_aceite")
	m.rearmar_presostato("PO")
	_marcha(m)
	var lectura := m.ejecutar("medir_filtro")
	var tras_filtro := m.planta().presion("aceite")
	_esperar(m, 30.0)
	var a_los_30 := m.en_marcha()
	_esperar(m, 20.0)
	return A.primero([
		A.cierto(lectura["tipo"] == "hecho" and lectura["texto"].contains("solo %s bar" % TextoTecnico.numero(tras_filtro, 1)), "debe leer la presión tras el filtro: %s" % lectura["texto"]),
		A.cierto(tras_filtro < 1.0, "tras el filtro queda menos de 1 bar: %.2f" % tras_filtro),
		A.cierto(a_los_30, "dentro del retardo sigue en marcha"),
		A.cierto(not m.en_marcha() and m.sim.componente("PO").estado["disparado"], "pasado el retardo debe disparar PO"),
	])


func test_abrir_el_filtro_sin_aislar_es_accidente() -> String:
	var m := _mision("fr3_presion_aceite")
	m.dar_paso("aviso")
	m.alternar_guardamotor()
	m.bloquear("Q1")
	m.verificar("Q1")
	var aviso := m.ejecutar("cambiar_filtro")
	return A.cierto(aviso["tipo"] == "accidente" and m.accidente["tema"] == "accidente_abrir_con_presion", "debe ser accidente: %s" % str(m.accidente.get("tema", "")))


func test_arrancar_con_el_filtro_aislado_es_incidente() -> String:
	var m := _mision("fr3_presion_aceite")
	m.ejecutar("aislar_filtro")
	m.rearmar_presostato("PO")
	_marcha(m)
	return A.cierto(m.fin == "accidente" and m.accidente["tema"] == "incidente_arranque_aislado", "fin %s: %s" % [m.fin, str(m.accidente.get("tema", ""))])


func test_guardamotor_bloqueado_no_cierra() -> String:
	var m := _mision("fr3_presion_aceite")
	var cerrado_en_marcha := m.bloquear("Q1")
	m.alternar_guardamotor()
	m.dar_paso("aviso")
	m.bloquear("Q1")
	var cierre := m.alternar_guardamotor()
	var verificacion := m.verificar("Q1")
	return A.primero([
		A.cierto(cerrado_en_marcha["tipo"] == "aviso", "con Q1 cerrado no se bloquea: %s" % str(cerrado_en_marcha)),
		A.cierto(cierre["tipo"] == "aviso" and not m.guardamotor().cerrado(), "bloqueado, Q1 no cierra: %s" % str(cierre)),
		A.cierto(verificacion["tipo"] == "hecho" and m.tension_equipo("Q1") < 1.0, "con Q1 abierto el motor no tiene tensión: %.0f V" % m.tension_equipo("Q1")),
	])


# --- Fuga de amoníaco ---

func test_fuga_empieza_con_aviso_de_amoniaco() -> String:
	var m := _mision("fr4_fuga_nh3")
	var p := m.planta()
	return A.primero([
		A.cierto(m.en_marcha(), "el compresor sigue en marcha"),
		A.cierto(p.estado["alarma"] == "aviso", "debe estar el aviso: %s, %.0f ppm" % [p.estado["alarma"], p.estado["ppm_sala"]]),
	])


func test_entrar_sin_equipo_de_respiracion_es_accidente() -> String:
	var m := _mision("fr4_fuga_nh3")
	m.dar_paso("evacuar")
	var aviso := m.ejecutar("localizar")
	return A.cierto(aviso["tipo"] == "accidente" and m.accidente["tema"] == "accidente_exposicion_nh3", "debe ser accidente: %s" % str(m.accidente.get("tema", "")))


func test_verificar_en_la_sala_tambien_exige_el_equipo() -> String:
	var m := _mision("fr4_fuga_nh3")
	_parada(m)
	m.dar_paso("aviso")
	m.alternar_guardamotor()
	m.bloquear("Q1")
	m.verificar("Q1")
	return A.cierto(m.accidente.get("tema", "") == "accidente_exposicion_nh3", "fin %s %s" % [m.fin, str(m.accidente.get("tema", ""))])


func test_buscar_la_fuga_sin_ventilar_ni_evacuar_son_faltas() -> String:
	var m := _mision("fr4_fuga_nh3")
	m.dar_paso("era")
	m.dar_paso("companero")
	m.ejecutar("localizar")
	var temas := []
	for f: Dictionary in m.faltas:
		temas.append(f["tema"])
	return A.cierto(m.fin.is_empty() and temas.has("sin_ventilacion") and temas.has("sin_evacuar"), "faltas: %s" % str(temas))


func test_sin_reparar_la_ventilacion_no_baja_del_aviso() -> String:
	var m := _mision("fr4_fuga_nh3")
	m.alternar_ventilacion()
	m.avanzar(900.0, 0.5)
	var ppm: float = m.planta().estado["ppm_sala"]
	return A.cierto(ppm > 25.0 and ppm < 150.0, "con la fuga, la ventilación la contiene pero no la elimina: %.0f ppm" % ppm)


# --- Nivel alto en la botella ---

func test_botella_llena_para_el_compresor_y_no_deja_arrancar() -> String:
	var m := _mision("fr5_nivel_botella")
	var ls: SimPresostato = m.sim.componente("LS")
	_marcha(m)
	var arranca := m.en_marcha()
	var lectura := m.ejecutar("mirar_visor")
	return A.primero([
		A.cierto(ls.estado["disparado"] and not arranca, "con la botella llena el interruptor de nivel no deja arrancar"),
		A.cierto(lectura["texto"].contains("un 8"), "el visor debe dar el nivel alto: %s" % lectura["texto"]),
		A.cierto(not m.planta().estado["solenoide_nivel"], "la luz de la solenoide indica la orden de cerrar"),
	])


func test_trasegar_sin_reparar_vuelve_a_llenar_la_botella() -> String:
	var m := _mision("fr5_nivel_botella")
	m.ejecutar("trasegar")
	_esperar(m, 3.0)
	_marcha(m)
	var arranca := m.en_marcha()
	_esperar(m, 300.0)
	return A.primero([
		A.cierto(arranca, "con el nivel corregido el compresor arranca"),
		A.cierto(not m.en_marcha() and m.sim.componente("LS").estado["disparado"], "con la solenoide pegada la botella se vuelve a llenar y para"),
	])


func test_puentear_el_nivel_alto_es_falta() -> String:
	var m := _mision("fr5_nivel_botella")
	var aviso := m.ejecutar("puentear_nivel")
	_marcha(m)
	return A.primero([
		A.cierto(aviso["tipo"] == "error" and m.faltas[0]["tema"] == "ajuste_presostato", "debe ser falta: %s" % str(m.faltas)),
		A.cierto(m.en_marcha(), "puenteado, el compresor arranca con la botella llena"),
		A.cierto(not m.condicion({"c": "estado", "id": "LS", "clave": "puenteado", "valor": false}), "la prueba exige quitar el puente"),
	])


# --- Vilter: etapas y cabezas ---

func test_vilter_arranca_descargado_y_carga_por_etapas() -> String:
	var m := _mision("fr3_presion_aceite")
	var p := m.planta()
	p.params["obstruccion_filtro_aceite"] = 0.0
	m.rearmar_presostato("PO")
	_marcha(m)
	var al_arrancar: float = p.estado["capacidad"]
	var maxima := 0.0
	var corriente := 0.0
	for _i in 600:
		_esperar(m, 1.0)
		maxima = maxf(maxima, p.estado["capacidad"])
		corriente = maxf(corriente, m.corriente_motor())
	var motor: SimMotorTrifasico = m.sim.componente("M1")
	return A.primero([
		A.cierto(p.piston(), "la misión de aceite es con el Vilter de pistón"),
		A.cierto(is_equal_approx(al_arrancar, SimPlantaFrio.ETAPA_BASE), "arranca con la etapa base: %.2f" % al_arrancar),
		A.cierto(maxima >= SimPlantaFrio.ETAPA_75, "en automático debe cargar una etapa: %.2f" % maxima),
		A.cierto(corriente < float(motor.params["i_delta"]) * 1.05, "el automático no sobrecarga el motor: %.0f A" % corriente),
	])


func test_vilter_sin_agua_en_las_cabezas_da_alarma() -> String:
	var m := _mision("fr3_presion_aceite")
	var p := m.planta()
	p.params["obstruccion_filtro_aceite"] = 0.0
	p.estado["bomba_cabezas"] = false
	m.rearmar_presostato("PO")
	_marcha(m)
	_esperar(m, 300.0)
	return A.primero([
		A.cierto(m.sim.hubo_evento("alta_temperatura_cabezas"), "debe dar la alarma de cabezas"),
		A.cierto(p.temperatura_tuberia("descarga") > 150.0, "la descarga sale muy caliente: %.0f °C" % p.temperatura_tuberia("descarga")),
	])


# --- Pantalla ---

func _raiz(id: String) -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.ir_a("mision_planta", {"id": id})
	return raiz


func _botones(nodo: Node, lista: Array[String]) -> void:
	if nodo is Button:
		lista.append(nodo.text)
	for hijo in nodo.get_children():
		_botones(hijo, lista)


func _filas(nodo: Node, lista: Array[FilaMenu]) -> void:
	if nodo is FilaMenu:
		lista.append(nodo)
	for hijo in nodo.get_children():
		_filas(hijo, lista)


func test_guardia_del_sistema_4_abre_la_mision_de_la_planta() -> String:
	var raiz := _raiz("fr1_alta_descarga")
	raiz.volver()
	raiz.ir_a("guardia", {"id": 4})
	var filas: Array[FilaMenu] = []
	_filas(raiz.pantalla_actual(), filas)
	filas[0].pulsada.emit()
	var abierta: bool = raiz.pantalla_actual().get_script().resource_path.ends_with("mision_planta.gd")
	raiz.free()
	return A.primero([
		A.cierto(filas.size() == MISIONES.size(), "deben listarse las misiones: %d" % filas.size()),
		A.cierto(abierta, "debe abrir la pantalla de misión de la planta"),
	])


func test_pantalla_recorre_las_pestanas_en_ambas_orientaciones() -> String:
	for id: String in MISIONES:
		var raiz := _raiz(id)
		for vertical in [true, false]:
			raiz.vertical = vertical
			raiz.reconstruir()
			var p = raiz.pantalla_actual()
			for pestana in (["mision", "esquema", "mando", "ph", "seguridad"] if vertical else ["mision", "mando", "ph", "seguridad"]):
				p._elegir_pestana(pestana)
				p._actualizar()
		raiz.free()
	return ""


func test_pantalla_muestra_el_procedimiento_y_los_objetivos() -> String:
	var raiz := _raiz("fr4_fuga_nh3")
	var p = raiz.pantalla_actual()
	var textos: Array[String] = []
	_botones(p, textos)
	p._actualizar()
	var marcas: int = p._panel.marcas_objetivos.size()
	p._elegir_pestana("mando")
	var mando: Array[String] = []
	_botones(raiz.pantalla_actual(), mando)
	raiz.free()
	return A.primero([
		A.cierto(textos.has("Ponerse el equipo de respiración autónomo y el traje de protección"), "debe estar el equipo de respiración: %s" % str(textos)),
		A.cierto(textos.has("Bloquear el guardamotor Q1 del compresor con candado y tarjeta"), "debe poder bloquear Q1: %s" % str(textos)),
		A.cierto(marcas == 6, "objetivos con su marca: %d" % marcas),
		A.cierto(not mando.has("Reiniciar la práctica"), "en una misión no se reinicia la práctica"),
		A.cierto(mando.has("Marcha (S1): mantener"), "deben estar los mandos del compresor: %s" % str(mando)),
	])


func test_pantalla_termometro_anota_y_accidente_muestra_el_informe() -> String:
	var raiz := _raiz("fr4_fuga_nh3")
	raiz.vertical = true
	raiz.reconstruir()
	var p = raiz.pantalla_actual()
	p._elegir_pestana("esquema")
	p._medir_tuberia("descarga")
	var anotada: int = p.mision.mediciones.size()
	p._panel.ejecutar("localizar")
	raiz.reconstruir()
	var q = raiz.pantalla_actual()
	var fin: String = q.mision.fin
	var errores: Dictionary = raiz.partida.datos["errores"]
	var puntos: int = raiz.partida.datos["puntos"]
	raiz.free()
	return A.primero([
		A.cierto(anotada == 1, "el termómetro debe anotar en el libro: %d" % anotada),
		A.cierto(fin == "accidente", "entrar sin equipo debe terminar en accidente"),
		A.cierto(errores.has("accidente_exposicion_nh3"), "debe quedar para repasar: %s" % str(errores.keys())),
		A.cierto(puntos == 0, "no debe sumar puntos: %d" % puntos),
	])


func test_pantalla_observa_con_el_tiempo_acelerado() -> String:
	var raiz := _raiz("fr3_presion_aceite")
	var p = raiz.pantalla_actual()
	p._panel.observar()
	var observando: bool = p.mision.observando()
	var inicio: float = p.mision.sim.tiempo
	for _i in 2000:
		if not p.mision.observando():
			break
		p._avanzar(1, SimSimulacion.PASO_S)
	var avanzado: float = p.mision.sim.tiempo - inicio
	var aviso: int = p._avisos.get_child_count()
	raiz.free()
	return A.primero([
		A.cierto(observando, "debe empezar a observar"),
		A.cierto(avanzado >= 299.0, "debe avanzar el tiempo de la prueba: %.1f s" % avanzado),
		A.cierto(aviso > 0, "debe decir por qué no se superó"),
	])


func test_pantalla_firma_y_registra_la_mision() -> String:
	var raiz := _raiz("fr2_hielo_evaporador")
	var p = raiz.pantalla_actual()
	var m: MisionPlanta = p.mision
	m.diagnostico_ok = true
	m.prueba_ok = true
	p.args["respuestas"] = _respuestas_correctas(m)
	p._panel.firmar()
	raiz.reconstruir()
	var completada: bool = raiz.pantalla_actual().mision.fin == "completada"
	var datos: Dictionary = raiz.partida.datos["misiones"].get("fr2_hielo_evaporador", {})
	raiz.free()
	return A.primero([
		A.cierto(completada, "debe mostrar el resultado"),
		A.cierto(int(datos.get("estrellas", 0)) == 3, "debe guardar las estrellas: %s" % str(datos)),
	])
