extends RefCounted
## Misiones de Guardia: procedimiento, consecuencias y resultados sobre la simulación real.

const A := preload("res://tests/ayuda_sim.gd")
const MISIONES := ["g1_no_arranca", "g2_termico_dispara", "g3_bajo_aislamiento"]
const RUTA_PARTIDA := "user://pruebas_guardia.json"


func _mision(id: String, danos := {}) -> MisionGuardia:
	return MisionGuardia.new(Contenido.new(), id, danos)


func _medidor() -> SimMultimetro:
	var m := SimMultimetro.new()
	m.ruido = 0.0
	return m


## Aviso, parada, apertura y candado en todos los aisladores, y verificación completa.
func _bloquear_y_verificar(m: MisionGuardia) -> void:
	m.colocar_epp()
	m.dar_aviso()
	for a in m.aisladores():
		m.accionar_aislador(a, false)
		m.poner_candado(a)
	m.mesa.avanzar(2)
	var medidor := _medidor()
	for p in m.pasos_verificacion():
		m.verificar(p, medidor)


func _quitar_bloqueo_y_energizar(m: MisionGuardia) -> void:
	for a in m.aisladores():
		m.quitar_candado(a)
	m.avisar_energizado()
	for a in m.aisladores():
		m.accionar_aislador(a, true)
	m.mesa.avanzar(2)


func _pulsar_marcha(m: MisionGuardia) -> void:
	m.mesa.sim.componente("S1").estado["presionado"] = true
	m.mesa.avanzar(4)
	m.mesa.sim.componente("S1").estado["presionado"] = false
	m.mesa.avanzar(2)


func _observar(m: MisionGuardia, segundos: float) -> Dictionary:
	m.observar(segundos)
	var resultado := {}
	var vueltas := 0
	while m.observando() and vueltas < 2000:
		resultado = m.procesar_observacion(50)
		vueltas += 1
	return resultado


func _medir_ohm(m: MisionGuardia, a: String, b: String) -> Dictionary:
	var r := _medidor().medir(m.mesa.sim, "ohm", a, b)
	m.registrar_medicion("multimetro", "ohm", a, b, r)
	return r


func _medir_mega(m: MisionGuardia, a: String, b: String) -> Dictionary:
	var meg := SimMegohmetro.new()
	meg.ruido = 0.0
	var r := meg.medir(m.mesa.sim, a, b, 500)
	m.registrar_medicion("megohmetro", "500", a, b, r)
	return r


func _opcion_correcta(m: MisionGuardia) -> int:
	var opciones: Array = m.datos["diagnostico"]["opciones"]
	for i in opciones.size():
		if opciones[i].get("correcta", false):
			return i
	return -1


func _respuestas_correctas(m: MisionGuardia) -> Dictionary:
	var r := {}
	var campos := m.campos_libro()
	for i in campos.size():
		r[i] = int(campos[i]["correcta"])
	return r


func test_las_misiones_estan_bien_formadas() -> String:
	var c := Contenido.new()
	var publicadas: Array = c.sistema(3)["modos"]["guardia"]["misiones"]
	var glosario := c.glosario()
	for id: String in MISIONES:
		if not publicadas.has(id):
			return "falta publicar %s" % id
		var m := _mision(id)
		for p in m.pasos_verificacion():
			for nodo: String in [p["a"], p["b"]]:
				if not m.mesa.bornes(nodo.get_slice(".", 0)).has(MesaTaller.borne_de(nodo)):
					return "%s: el punto %s no existe" % [id, nodo]
		for cable: Array in m.mesa.sim.cables:
			for nodo: String in cable:
				if not m.mesa.bornes(nodo.get_slice(".", 0)).has(MesaTaller.borne_de(nodo)):
					return "%s: el borne %s no está en el dibujo" % [id, nodo]
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
	return "; ".join(c.errores)


func test_todas_las_faltas_y_accidentes_tienen_texto() -> String:
	var g: Dictionary = Contenido.new().leer("guardia.json")
	for tema in ["sin_epp", "sin_aviso", "abrir_con_carga", "medir_sin_bloqueo", "energizar_sin_aviso", "bornera_abierta", "sin_remedir", "instrumento_destruido", "fusible_instrumento", "diagnostico_sin_medir", "ajuste_alterado", "prueba_fallida"]:
		if not g["faltas"].has(tema):
			return "falta el texto de %s" % tema
	for tipo: String in g["accidentes"]:
		for clave in ["titulo", "que_ocurrio", "causa", "como_evitar"]:
			if g["accidentes"][tipo].get(clave, "").is_empty():
				return "%s no tiene %s" % [tipo, clave]
	return ""


func test_trabajar_sin_bloqueo_es_un_accidente() -> String:
	var m := _mision("g1_no_arranca")
	var aviso := m.ejecutar("cambiar_k1")
	return A.primero([
		A.cierto(aviso["tipo"] == "accidente", "debe ser un accidente: %s" % aviso["tipo"]),
		A.cierto(m.fin == "accidente", "la misión debe terminar"),
		A.cierto(not m.accidente["causa"].is_empty(), "el informe debe explicar la causa"),
		A.cierto(m.estrellas() == 0, "un accidente no da estrellas"),
		A.cierto(m.mesa.sim.componente("K1").estado["bobina_quemada"], "el trabajo no debe llegar a hacerse"),
	])


func test_bloquear_sin_verificar_tambien_es_accidente() -> String:
	var m := _mision("g1_no_arranca")
	m.dar_aviso()
	m.accionar_aislador("Q1", false)
	m.poner_candado("Q1")
	var aviso := m.ejecutar("cambiar_k1")
	return A.primero([
		A.cierto(aviso["tipo"] == "accidente", "debe ser un accidente: %s" % aviso["tipo"]),
		A.cierto(m.accidente["titulo"].contains("sin verificar"), "debe explicar la verificación: %s" % m.accidente["titulo"]),
	])


func test_verificar_antes_de_bloquear_no_vale() -> String:
	var m := _mision("g1_no_arranca")
	m.accionar_aislador("Q1", false)
	m.mesa.avanzar(2)
	for p in m.pasos_verificacion():
		m.verificar(p, _medidor())
	var sin_candado := m.verificado()
	m.poner_candado("Q1")
	return A.primero([
		A.cierto(not sin_candado, "sin candado no puede estar verificado"),
		A.cierto(not m.verificado(), "colocar el candado obliga a verificar de nuevo"),
	])


func test_la_verificacion_exige_probar_el_instrumento_antes_y_despues() -> String:
	var m := _mision("g1_no_arranca")
	m.dar_aviso()
	m.accionar_aislador("Q1", false)
	m.poner_candado("Q1")
	m.mesa.avanzar(2)
	var pasos := m.pasos_verificacion()
	var medidor := _medidor()
	# Sin la comprobación final.
	for i in pasos.size() - 1:
		m.verificar(pasos[i], medidor)
	var sin_final := m.verificado()
	m.verificar(pasos[-1], medidor)
	var completa := m.verificado()
	return A.primero([
		A.cierto(not sin_final, "falta la comprobación final"),
		A.cierto(completa, "con todo en orden debe valer"),
	])


func test_instrumento_destruido_no_verifica() -> String:
	var m := _mision("g1_no_arranca")
	m.dar_aviso()
	m.accionar_aislador("Q1", false)
	m.poner_candado("Q1")
	m.mesa.avanzar(2)
	var medidor := _medidor()
	medidor.destruido = true
	var aviso := {}
	for p in m.pasos_verificacion():
		aviso = m.verificar(p, medidor)
	return A.primero([
		A.cierto(not m.verificado(), "un instrumento roto no demuestra nada"),
		A.cierto(aviso["titulo"] == "Instrumento averiado", "debe avisar: %s" % aviso["titulo"]),
	])


func test_candado_impide_cerrar_el_aislador() -> String:
	var m := _mision("g1_no_arranca")
	m.accionar_aislador("Q1", false)
	m.poner_candado("Q1")
	var aviso := m.accionar_aislador("Q1", true)
	return A.primero([
		A.cierto(aviso["tipo"] == "aviso", "debe rechazarlo"),
		A.cierto(not m.aislador_cerrado("Q1"), "debe seguir abierto"),
	])


func test_candado_exige_aislador_abierto() -> String:
	var m := _mision("g1_no_arranca")
	var aviso := m.poner_candado("Q1")
	return A.primero([
		A.cierto(aviso["tipo"] == "aviso", "no se bloquea un aislador cerrado"),
		A.cierto(not m.bloqueado(), "no debe quedar bloqueado"),
	])


func test_medir_con_tension_sin_epp_es_falta() -> String:
	var m := _mision("g1_no_arranca")
	var r := _medidor().medir(m.mesa.sim, "vac", "B.L1", "B.L2")
	m.registrar_medicion("multimetro", "vac", "B.L1", "B.L2", r)
	m.registrar_medicion("multimetro", "vac", "B.L1", "B.L2", r)
	return A.cierto(m.faltas.size() == 1 and m.faltas[0]["tema"] == "sin_epp", "debe anotarse una vez: %s" % str(m.faltas))


func test_g1_sintoma_y_medicion_de_la_bobina() -> String:
	var m := _mision("g1_no_arranca")
	var luz: bool = m.mesa.sim.componente("H1").estado["encendida"]
	m.mesa.sim.componente("S1").estado["presionado"] = true
	m.mesa.avanzar(4)
	var v := _medidor().medir(m.mesa.sim, "vac", "K1.A1", "K1.A2")
	var cerrado := m.contactor().cerrado()
	m.mesa.sim.componente("S1").estado["presionado"] = false
	m.mesa.avanzar(2)
	_bloquear_y_verificar(m)
	var r := _medir_ohm(m, "K1.A1", "K1.A2")
	var f1 := _medir_ohm(m, "F1.1", "F1.2")
	return A.primero([
		A.cierto(luz, "la luz de mando debe estar encendida"),
		A.cierto(not cerrado, "K1 no debe cerrar"),
		A.cerca(v["valor"], 110.0, 0.1, "con S1 pulsado deben llegar 110 V a la bobina"),
		A.cierto(m.verificado(), "debe poder verificarse"),
		A.cierto(r["fuera_de_rango"], "la bobina abierta debe marcar fuera de rango: %s" % str(r)),
		A.cierto(float(f1["valor"]) < 1.0, "el fusible debe tener continuidad: %s" % str(f1)),
	])


func test_g1_la_averia_no_se_ve_en_el_equipo() -> String:
	var m := _mision("g1_no_arranca")
	return A.primero([
		A.cierto(m.mesa.estado_pieza("K1") == "Abierto", "no debe revelar la avería: %s" % m.mesa.estado_pieza("K1")),
		A.cierto(not m.mesa.danada("K1"), "no debe ofrecer cambiar el repuesto"),
	])


func test_g1_completa_sin_faltas_da_tres_estrellas() -> String:
	var m := _mision("g1_no_arranca")
	_bloquear_y_verificar(m)
	_medir_ohm(m, "K1.A1", "K1.A2")
	var d := m.diagnosticar(_opcion_correcta(m))
	m.ejecutar("cambiar_k1")
	_quitar_bloqueo_y_energizar(m)
	_pulsar_marcha(m)
	var prueba := _observar(m, m.tiempo_de_prueba())
	var firma := m.firmar(_respuestas_correctas(m))
	return A.primero([
		A.cierto(d["tipo"] == "hecho", "el diagnóstico debe confirmarse: %s" % str(d)),
		A.cierto(prueba["titulo"] == "Prueba superada", "debe superar la prueba: %s" % str(prueba)),
		A.cierto(firma["tipo"] == "hecho", "debe poder firmar: %s" % str(firma)),
		A.cierto(m.fin == "completada", "la misión debe terminar"),
		A.cierto(m.faltas.is_empty(), "no debe haber faltas: %s" % str(m.faltas)),
		A.cierto(m.estrellas() == 3, "deben ser 3 estrellas: %d" % m.estrellas()),
	])


func test_g1_sin_reparar_no_supera_la_prueba() -> String:
	var m := _mision("g1_no_arranca")
	_bloquear_y_verificar(m)
	_quitar_bloqueo_y_energizar(m)
	_pulsar_marcha(m)
	var prueba := _observar(m, m.tiempo_de_prueba())
	return A.primero([
		A.cierto(prueba["titulo"] == "Sigue la avería", "no debe pasar: %s" % str(prueba)),
		A.cierto(not m.prueba_ok, "no debe contar como superada"),
		A.cierto(not m.puede_firmar(), "no debe poder firmar"),
	])


func test_repuesto_innecesario_es_falta() -> String:
	var m := _mision("g1_no_arranca")
	_bloquear_y_verificar(m)
	var aviso := m.ejecutar("cambiar_f1")
	return A.primero([
		A.cierto(aviso["tipo"] == "error", "debe explicar el error"),
		A.cierto(m.faltas.size() == 1, "debe anotarse: %s" % str(m.faltas)),
		A.cierto(m.mesa.sim.componente("K1").estado["bobina_quemada"], "la avería debe seguir"),
	])


func test_diagnostico_incorrecto_y_sin_medir() -> String:
	var m := _mision("g1_no_arranca")
	var correcta := _opcion_correcta(m)
	var mal := m.diagnosticar((correcta + 1) % 4)
	var confirmado_mal := m.diagnostico_ok
	var sin_medir := m.diagnosticar(correcta)
	return A.primero([
		A.cierto(mal["tipo"] == "error" and not confirmado_mal, "uno incorrecto no debe confirmarse"),
		A.cierto(sin_medir["tipo"] == "error", "sin mediciones debe avisar"),
		A.cierto(m.diagnostico_ok, "acertar confirma la causa aunque cueste una falta"),
		A.cierto(m.faltas.size() == 2, "son dos faltas: %s" % str(m.faltas)),
	])


func test_g2_dispara_a_los_pocos_minutos() -> String:
	var m := _mision("g2_termico_dispara")
	_pulsar_marcha(m)
	m.mesa.avanzar(100)
	var i := m.corrientes()
	var inicio := m.mesa.sim.tiempo
	_observar(m, 600.0)
	var tiempo := m.mesa.sim.tiempo - inicio
	return A.primero([
		A.cerca(i[0], 34.7, 0.05, "debe consumir más que la nominal"),
		A.cerca(i[0], i[1], 0.02, "las fases deben ser iguales"),
		A.cierto(tiempo > 180.0 and tiempo < 330.0, "debe disparar entre 3 y 5,5 min: %.0f s" % tiempo),
		A.cierto(m.rele().estado["disparado"], "debe disparar el relé"),
		A.cierto(not m.contactor().cerrado(), "K1 debe soltar"),
		A.cierto(not m.motor().quemado(), "la protección debe salvar el motor"),
		A.cierto(m.faltas.is_empty(), "comprobar el síntoma antes de bloquear no es falta: %s" % str(m.faltas)),
	])


func test_g2_subir_el_ajuste_termina_quemando_el_motor() -> String:
	var m := _mision("g2_termico_dispara")
	m.rele().params["ajuste_a"] = 45.0
	_pulsar_marcha(m)
	m.mesa.avanzar(100)
	_observar(m, m.tiempo_de_prueba())
	var temas := []
	for f: Dictionary in m.faltas:
		temas.append(f["tema"])
	return A.primero([
		A.cierto(m.motor().quemado(), "el motor debe quemarse: %.0f °C" % m.motor().temperatura()),
		A.cierto(temas.has("ajuste_alterado"), "debe anotarse la falta: %s" % str(temas)),
		A.cierto(not m.prueba_ok, "no debe superar la prueba"),
		A.cierto(m.danos().has("M1"), "el daño debe quedar anotado"),
	])


func test_g2_completa_con_rodamiento() -> String:
	var m := _mision("g2_termico_dispara")
	_bloquear_y_verificar(m)
	var aislamiento := _medir_mega(m, "M1.U1", "PE1.PE")
	var sin_girar := m.ejecutar("cambiar_rodamiento")
	m.ejecutar("girar_eje")
	var d := m.diagnosticar(_opcion_correcta(m))
	m.ejecutar("cambiar_rodamiento")
	_quitar_bloqueo_y_energizar(m)
	_pulsar_marcha(m)
	m.mesa.avanzar(100)
	var i := m.corriente_maxima()
	var prueba := _observar(m, m.tiempo_de_prueba())
	m.firmar(_respuestas_correctas(m))
	return A.primero([
		A.cierto(aislamiento["aceptable"], "el aislamiento debe ser bueno"),
		A.cierto(sin_girar["tipo"] == "aviso", "antes hay que girar el eje"),
		A.cierto(d["tipo"] == "hecho", "el diagnóstico debe confirmarse: %s" % str(d)),
		A.cierto(i < 25.0, "la corriente debe bajar de la nominal: %.1f" % i),
		A.cierto(prueba["titulo"] == "Prueba superada", "debe superar la prueba: %s" % str(prueba)),
		A.cierto(m.estrellas() == 3, "deben ser 3 estrellas: %d %s" % [m.estrellas(), str(m.faltas)]),
	])


func test_g3_bloquear_solo_la_potencia_es_accidente() -> String:
	var m := _mision("g3_bajo_aislamiento")
	m.dar_aviso()
	m.accionar_aislador("Q1", false)
	m.poner_candado("Q1")
	var aviso := m.ejecutar("retirar_puentes")
	return A.primero([
		A.cierto(aviso["tipo"] == "accidente", "debe ser un accidente: %s" % aviso["tipo"]),
		A.cierto(m.accidente["causa"].contains("Q2"), "debe explicar la segunda alimentación: %s" % m.accidente["causa"]),
	])


func test_g3_la_verificacion_encuentra_el_mando_energizado() -> String:
	var m := _mision("g3_bajo_aislamiento")
	m.accionar_aislador("Q1", false)
	m.mesa.avanzar(2)
	var aviso := {}
	for p in m.pasos_verificacion():
		if p["a"] == "T1.X1":
			aviso = m.verificar(p, _medidor())
	return A.cierto(aviso.get("titulo", "").begins_with("Hay tensión"), "debe detectar 110 V: %s" % str(aviso))


func test_g3_monitor_sigue_al_motor() -> String:
	var m := _mision("g3_bajo_aislamiento")
	var parado := m.monitor_mohm()
	_pulsar_marcha(m)
	var en_marcha := m.monitor_mohm()
	return A.primero([
		A.cierto(parado > 1.0, "parado no debe haber alarma: %.1f" % parado),
		A.cierto(en_marcha < 1.0, "en marcha debe dar alarma: %.1f" % en_marcha),
	])


func test_g3_con_puentes_no_se_distingue_el_devanado() -> String:
	var m := _mision("g3_bajo_aislamiento")
	_bloquear_y_verificar(m)
	var con_puentes := _medir_mega(m, "M1.V1", "PE1.PE")
	m.ejecutar("retirar_puentes")
	var u := _medir_mega(m, "M1.U1", "PE1.PE")
	var v := _medir_mega(m, "M1.V1", "PE1.PE")
	return A.primero([
		A.cierto(float(con_puentes["mohm"]) < 1.0, "con puentes, V se ve baja por el devanado U: %.2f" % con_puentes["mohm"]),
		A.cierto(float(u["mohm"]) < 1.0, "U debe estar baja: %.2f" % u["mohm"]),
		A.cierto(float(v["mohm"]) > 20.0, "V debe estar sana sin puentes: %.2f" % v["mohm"]),
	])


func test_g3_no_se_quita_el_candado_con_la_bornera_abierta() -> String:
	var m := _mision("g3_bajo_aislamiento")
	_bloquear_y_verificar(m)
	m.ejecutar("retirar_puentes")
	var aviso := m.quitar_candado("Q1")
	return A.primero([
		A.cierto(aviso["tipo"] == "error", "debe rechazarlo"),
		A.cierto(m.tiene_candado("Q1"), "el candado debe seguir"),
	])


func test_g3_completa() -> String:
	var m := _mision("g3_bajo_aislamiento")
	_bloquear_y_verificar(m)
	m.ejecutar("retirar_puentes")
	for nodo in ["M1.U1", "M1.V1", "M1.W1"]:
		_medir_mega(m, nodo, "PE1.PE")
	var d := m.diagnosticar(_opcion_correcta(m))
	m.ejecutar("secar_devanado")
	var seco := _medir_mega(m, "M1.U1", "PE1.PE")
	m.ejecutar("reponer_puentes")
	_quitar_bloqueo_y_energizar(m)
	_pulsar_marcha(m)
	m.mesa.avanzar(100)
	var monitor := m.monitor_mohm()
	var prueba := _observar(m, m.tiempo_de_prueba())
	m.firmar(_respuestas_correctas(m))
	return A.primero([
		A.cierto(d["tipo"] == "hecho", "el diagnóstico debe confirmarse: %s" % str(d)),
		A.cierto(seco["aceptable"], "tras secar debe ser aceptable: %s" % str(seco)),
		A.cierto(monitor > 1.0, "el monitor debe salir de alarma: %.1f" % monitor),
		A.cierto(m.motor().rpm() > 1700.0, "con los puentes repuestos debe funcionar: %.0f" % m.motor().rpm()),
		A.cierto(prueba["titulo"] == "Prueba superada", "debe superar la prueba: %s" % str(prueba)),
		A.cierto(m.estrellas() == 3, "deben ser 3 estrellas: %d %s" % [m.estrellas(), str(m.faltas)]),
	])


func test_g3_sin_medir_tras_secar_es_falta() -> String:
	var m := _mision("g3_bajo_aislamiento")
	_bloquear_y_verificar(m)
	m.ejecutar("retirar_puentes")
	m.ejecutar("secar_devanado")
	m.ejecutar("reponer_puentes")
	m.quitar_candado("Q1")
	var temas := []
	for f: Dictionary in m.faltas:
		temas.append(f["tema"])
	return A.cierto(temas.has("sin_remedir"), "debe anotarse: %s" % str(temas))


func test_libro_con_dato_incorrecto_no_se_firma() -> String:
	var m := _mision("g1_no_arranca")
	var antes := m.firmar({})
	m.diagnostico_ok = true
	m.prueba_ok = true
	var respuestas := _respuestas_correctas(m)
	respuestas[0] = (int(respuestas[0]) + 1) % m.campos_libro()[0]["opciones"].size()
	var mal := m.firmar(respuestas)
	var incompleto := m.firmar({})
	return A.primero([
		A.cierto(antes["tipo"] == "aviso", "sin prueba no se firma"),
		A.cierto(mal["tipo"] == "error", "un dato incorrecto debe explicarse"),
		A.cierto(incompleto["tipo"] == "aviso", "debe pedir los datos que faltan"),
		A.cierto(m.fin.is_empty(), "no debe terminar"),
	])


func test_estrellas_por_faltas_y_pistas() -> String:
	var m := _mision("g1_no_arranca")
	m.fin = "completada"
	var sin_nada := m.estrellas()
	m.siguiente_pista()
	var con_pista := m.estrellas()
	for tema in ["sin_epp", "sin_aviso", "abrir_con_carga"]:
		m._falta(tema)
	return A.primero([
		A.cierto(sin_nada == 3, "sin faltas: %d" % sin_nada),
		A.cierto(con_pista == 2, "una pista baja a 2: %d" % con_pista),
		A.cierto(m.estrellas() == 1, "tres faltas bajan a 1: %d" % m.estrellas()),
	])


func test_equipo_danado_sigue_danado_hasta_el_repuesto() -> String:
	var m := _mision("g2_termico_dispara", {"M1": {"quemado": true}})
	var danado := m.motor().quemado()
	var visible := m.mesa.danada("M1")
	var sin_bloqueo := m.cambiar_repuesto("M1")
	var n := _mision("g2_termico_dispara", {"M1": {"quemado": true}})
	_bloquear_y_verificar(n)
	n.cambiar_repuesto("M1")
	return A.primero([
		A.cierto(danado and visible, "el motor quemado debe seguir quemado y verse"),
		A.cierto(sin_bloqueo["tipo"] == "accidente", "cambiarlo sin bloquear es un accidente"),
		A.cierto(not n.motor().quemado(), "con el repuesto debe quedar sano"),
		A.cierto(n.danos().is_empty(), "no debe quedar daño anotado: %s" % str(n.danos())),
	])


func test_paso_rapido_coincide_con_el_normal() -> String:
	var lento := _mision("g2_termico_dispara")
	var rapido := _mision("g2_termico_dispara")
	for m: MisionGuardia in [lento, rapido]:
		_pulsar_marcha(m)
		m.mesa.avanzar(100)
	lento.mesa.sim.avanzar_tiempo(60.0)
	for _i in 60:
		rapido.mesa.sim.paso(1.0)
	return A.primero([
		A.cerca(rapido.motor().rpm(), lento.motor().rpm(), 0.005, "velocidad"),
		A.cerca(rapido.motor().temperatura(), lento.motor().temperatura(), 0.005, "temperatura"),
		A.cerca(rapido.rele().estado["memoria"][0], lento.rele().estado["memoria"][0], 0.005, "memoria térmica"),
	])


func test_masa_permite_medir_contra_tierra_en_el_taller() -> String:
	var mesa := MesaTaller.new(Contenido.new())
	mesa.agregar("motor_440", Vector2.ZERO)
	mesa.agregar("masa", Vector2(600.0, 0.0))
	mesa.sim.componente("M1").params["aislamiento_mohm"] = [2.0, 300.0, 300.0]
	mesa.avanzar(1)
	var meg := SimMegohmetro.new()
	meg.ruido = 0.0
	var r := meg.medir(mesa.sim, "M1.U1", "PE1.PE", 500)
	return A.cerca(r["mohm"], 2.0, 0.1, "aislamiento del devanado contra la masa")


func test_registrar_mision_en_la_partida() -> String:
	var p := Partida.new(RUTA_PARTIDA)
	var accidente := p.registrar_mision("x", 0, false)
	var primera := p.registrar_mision("x", 2, true)
	var peor := p.registrar_mision("x", 1, true)
	var mejor := p.registrar_mision("x", 3, true)
	var d: Dictionary = p.datos["misiones"]["x"]
	return A.primero([
		A.cierto(accidente == 0, "un accidente no suma: %d" % accidente),
		A.cierto(primera == Partida.PUNTOS_MISION + 2 * Partida.PUNTOS_ESTRELLA, "primera: %d" % primera),
		A.cierto(peor == 0, "repetir peor no suma: %d" % peor),
		A.cierto(mejor == Partida.PUNTOS_ESTRELLA, "la estrella nueva suma: %d" % mejor),
		A.cierto(int(d["estrellas"]) == 3 and int(d["intentos"]) == 4 and int(d["accidentes"]) == 1, "datos: %s" % str(d)),
	])


func _raiz(id: String) -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.ir_a("mision", {"id": id})
	return raiz


func _recorrer_pestanas(p) -> void:
	for pestana: String in ["reporte", "proceso", "pieza", "medir", "libro"]:
		p._elegir_pestana(pestana)


func test_pantalla_recorre_las_pestanas_en_ambas_orientaciones() -> String:
	for id: String in MISIONES:
		var raiz := _raiz(id)
		for vertical in [false, true]:
			raiz.vertical = vertical
			raiz.reconstruir()
			var p = raiz.pantalla_actual()
			_recorrer_pestanas(p)
			p._al_tocar_pieza("M1")
			p._al_tocar_pieza("F2")
			p._al_tocar_pieza("Q1")
		raiz.free()
	return ""


## En un celular de 360 de ancho deben caber las cinco pestañas sin cortar el texto.
func test_las_pestanas_caben_en_vertical() -> String:
	var raiz := _raiz("g1_no_arranca")
	raiz.vertical = true
	raiz.reconstruir()
	var p = raiz.pantalla_actual()
	var margenes := 24.0
	var ancho: float = (360.0 - margenes - 4.0 * (p.PESTANAS.size() - 1)) / p.PESTANAS.size()
	var motivo := ""
	for clave: String in p._botones_pestana:
		var b: Button = p._botones_pestana[clave]
		var caja := b.get_theme_stylebox("normal")
		var disponible: float = ancho - caja.content_margin_left - caja.content_margin_right
		var texto := b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
		if texto > disponible:
			motivo = "%s mide %.0f y solo hay %.0f" % [b.text, texto, disponible]
	raiz.free()
	return motivo


func test_avisos_se_muestran_de_uno_en_uno() -> String:
	var raiz := _raiz("g1_no_arranca")
	var p = raiz.pantalla_actual()
	p._mostrar_aviso("Uno", "Primero")
	p._mostrar_aviso("Dos", "Segundo")
	p._mostrar_aviso("Dos", "Repetido")
	var visibles: int = p._avisos.get_child_count()
	var en_cola: int = p._cola_avisos.size()
	p._cerrar_aviso(p._avisos.get_child(0))
	var siguiente: String = p._avisos.get_child(0).get_meta("titulo")
	raiz.free()
	return A.primero([
		A.cierto(visibles == 1, "debe verse uno: %d" % visibles),
		A.cierto(en_cola == 1, "el repetido no debe encolarse: %d" % en_cola),
		A.cierto(siguiente == "Dos", "al cerrar debe aparecer el siguiente: %s" % siguiente),
	])


func test_pantalla_accidente_muestra_el_informe_y_no_suma() -> String:
	var raiz := _raiz("g1_no_arranca")
	var p = raiz.pantalla_actual()
	p._ejecutar("cambiar_k1")
	raiz.reconstruir()
	var q = raiz.pantalla_actual()
	var informe: bool = q.vista == null and q.mision.fin == "accidente"
	var datos: Dictionary = raiz.partida.datos["misiones"]["g1_no_arranca"]
	var puntos: int = raiz.partida.datos["puntos"]
	q._repetir()
	var nueva = raiz.pantalla_actual()
	var reinicia: bool = nueva.mision.fin.is_empty() and nueva.vista != null
	raiz.free()
	return A.primero([
		A.cierto(informe, "debe mostrar el informe"),
		A.cierto(int(datos["accidentes"]) == 1, "debe contar el accidente"),
		A.cierto(puntos == 0, "no debe sumar puntos: %d" % puntos),
		A.cierto(reinicia, "repetir debe empezar de nuevo"),
	])


func test_pantalla_conserva_la_mision_al_girar() -> String:
	var raiz := _raiz("g1_no_arranca")
	var p = raiz.pantalla_actual()
	var m: MisionGuardia = p.mision
	m.colocar_epp()
	raiz.vertical = not raiz.vertical
	raiz.reconstruir()
	var igual: bool = raiz.pantalla_actual().mision == m
	raiz.free()
	return A.primero([
		A.cierto(igual, "girar el celular no debe perder la misión"),
		A.cierto(m.hechos.has("epp"), "debe conservar lo hecho"),
	])


func test_pantalla_firma_y_registra_la_mision() -> String:
	var raiz := _raiz("g1_no_arranca")
	var p = raiz.pantalla_actual()
	var m: MisionGuardia = p.mision
	m.diagnostico_ok = true
	m.prueba_ok = true
	p.args["respuestas"] = _respuestas_correctas(m)
	p._firmar()
	raiz.reconstruir()
	var q = raiz.pantalla_actual()
	var resultado: bool = q.vista == null and q.mision.fin == "completada"
	var datos: Dictionary = raiz.partida.datos["misiones"].get("g1_no_arranca", {})
	var puntos: int = raiz.partida.datos["puntos"]
	raiz.free()
	return A.primero([
		A.cierto(resultado, "debe mostrar el resultado"),
		A.cierto(int(datos.get("estrellas", 0)) == 3, "debe guardar las estrellas: %s" % str(datos)),
		A.cierto(puntos == Partida.PUNTOS_MISION + 3 * Partida.PUNTOS_ESTRELLA, "puntos: %d" % puntos),
	])


func test_pinza_con_corriente_sin_epp_es_falta() -> String:
	var m := _mision("g2_termico_dispara")
	_pulsar_marcha(m)
	m.mesa.avanzar(60)
	var r := SimPinza.new().medir(m.mesa.sim, [0])
	m.registrar_medicion("pinza", "a", m.mesa.sim.cables[0][0], m.mesa.sim.cables[0][1], r)
	var temas := m.faltas.map(func(f: Dictionary) -> String: return f["tema"])
	var n := _mision("g2_termico_dispara")
	n.colocar_epp()
	_pulsar_marcha(n)
	n.mesa.avanzar(60)
	n.registrar_medicion("pinza", "a", n.mesa.sim.cables[0][0], n.mesa.sim.cables[0][1], SimPinza.new().medir(n.mesa.sim, [0]))
	return A.primero([
		A.cierto(float(r["valor"]) > 1.0, "el motor debe tener corriente: %.1f A" % r["valor"]),
		A.cierto(temas.has("sin_epp"), "sin EPP debe ser falta: %s" % str(temas)),
		A.cierto(n.faltas.is_empty(), "con EPP no hay falta: %s" % str(n.faltas)),
	])
