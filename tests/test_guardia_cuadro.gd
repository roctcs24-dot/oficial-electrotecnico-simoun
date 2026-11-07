extends RefCounted
## Misiones de Guardia del cuadro principal: maniobras, procedimiento, incidentes y resultados
## sobre la simulación real de generación.

const A := preload("res://tests/ayuda_sim.gd")
const MISIONES := ["gen1_paralelo", "gen2_blackout", "gen3_falla_tierra", "gen4_potencia_inversa"]
const RUTA_PARTIDA := "user://pruebas_guardia_cuadro.json"


func _mision(id: String) -> MisionCuadro:
	return MisionCuadro.new(Contenido.new(), id)


func _opcion_correcta(m: MisionBase) -> int:
	var opciones: Array = m.datos["diagnostico"]["opciones"]
	for i in opciones.size():
		if opciones[i].get("correcta", false):
			return i
	return -1


func _opcion_incorrecta(m: MisionBase) -> int:
	return 1 if _opcion_correcta(m) == 0 else 0


func _respuestas_correctas(m: MisionBase) -> Dictionary:
	var r := {}
	var campos := m.campos_libro()
	for i in campos.size():
		r[i] = int(campos[i]["correcta"])
	return r


func _f_barras(m: MisionCuadro) -> float:
	return m.operador.frecuencia_barras()


## Arranca el entrante, lo deja algo más rápido que las barras y cierra a mano cerca de las
## doce, como haría el jugador mirando el sincronoscopio.
func _sincronizar_a_mano(m: MisionCuadro, id: String) -> bool:
	m.alternar_diesel(id)
	m.avanzar(10.0)
	var g := m.operador.generador(id)
	for _i in 40:
		if g.frecuencia() - _f_barras(m) >= 0.12:
			break
		m.velocidad(id, 1.0)
		m.avanzar(0.5)
	var sy: SimSincronoscopio = m.sim.componente("SY")
	for _i in 2000:
		m.avanzar(SimSimulacion.PASO_S)
		var a: float = sy.estado["angulo"]
		if sy.estado["valido"] and a > -6.0 and a < 0.0:
			m.alternar_interruptor(id)
			return m.operador.interruptor_de(id).cerrado()
	return false


## Con los mandos de velocidad, hasta que los grupos llevan la misma fracción a 50 Hz. Mueve
## un grupo cada vez, el que corrige también la frecuencia: un toque cambia el reparto un 4 %.
func _repartir(m: MisionCuadro, ids: Array) -> bool:
	var a: String = ids[0]
	var b: String = ids[1]
	for _i in 200:
		var ga := m.operador.generador(a)
		var gb := m.operador.generador(b)
		var diferencia: float = ga.estado["p_kw"] / ga.params["p_kw"] - gb.estado["p_kw"] / gb.params["p_kw"]
		var f := _f_barras(m)
		if absf(diferencia) <= 0.03 and absf(f - 50.0) <= 0.08:
			return true
		if absf(diferencia) > 0.03:
			var cargado := a if diferencia > 0.0 else b
			var descargado := b if diferencia > 0.0 else a
			if f > 50.0:
				m.velocidad(cargado, -1.0)
			else:
				m.velocidad(descargado, 1.0)
		elif f < 50.0:
			m.velocidad(a, 1.0)
			m.velocidad(b, 1.0)
		else:
			m.velocidad(a, -1.0)
			m.velocidad(b, -1.0)
		m.avanzar(2.0)
	return false


func _subir_hasta_60(m: MisionCuadro, id: String) -> void:
	for _i in 60:
		if _f_barras(m) >= 49.95:
			return
		m.velocidad(id, 1.0)
		m.avanzar(1.0)


func _esperar_cierre(m: MisionCuadro, id: String) -> bool:
	for _i in 70:
		if m.operador.interruptor_de(id).cerrado():
			return true
		m.avanzar(1.0)
	return false


func _terminar(m: MisionCuadro) -> void:
	m.avanzar(m.tiempo_de_prueba() + 5.0)
	m.firmar(_respuestas_correctas(m))


# --- Recorridos completos, también usados por la prueba de progresión ---

func completar(m: MisionCuadro) -> void:
	match m.id():
		"gen1_paralelo":
			_sincronizar_a_mano(m, "G2")
			_repartir(m, ["G1", "G2"])
			m.alternar_carga("C3")
			m.avanzar(3.0)
			_repartir(m, ["G1", "G2"])
			m.diagnosticar(_opcion_correcta(m))
		"gen2_blackout":
			m.dar_paso("aviso")
			m.alternar_carga("C2")
			m.alternar_diesel("G2")
			m.avanzar(10.0)
			m.alternar_interruptor("G2")
			m.avanzar(5.0)
			_subir_hasta_60(m, "G2")
			m.diagnosticar(_opcion_correcta(m))
			m.bloquear("G1")
			m.ejecutar("filtros_g1")
			m.desbloquear("G1")
			m.rearmar("G1")
			m.alternar_diesel("G1")
			m.avanzar(10.0)
			m.sincronizar("G1")
			_esperar_cierre(m, "G1")
			m.alternar_pms()
			m.avanzar(20.0)
			m.alternar_carga("C2")
			m.avanzar(20.0)
			m.alternar_arranque_automatico("GE")
			m.alternar_interruptor_id("QE")
			m.avanzar(1.0)
			m.rearmar_id("QT")
			m.alternar_interruptor_id("QT")
			m.alternar_diesel("GE")
			m.alternar_arranque_automatico("GE")
			m.avanzar(5.0)
		"gen3_falla_tierra":
			m.dar_paso("aviso")
			m.alternar_carga("C3")
			m.avanzar(3.0)
			m.alternar_carga("C3")
			m.alternar_carga("C4")
			m.avanzar(4.0)
			m.bloquear("C4")
			m.verificar("C4")
			m.ejecutar("medir_c4")
			m.diagnosticar(_opcion_correcta(m))
			m.ejecutar("reparar_c4")
			m.ejecutar("medir_c4")
			m.desbloquear("C4")
			m.alternar_carga("C4")
			m.avanzar(3.0)
		"gen4_potencia_inversa":
			m.rearmar("G2")
			m.alternar_diesel("G2")
			m.avanzar(35.0)
			m.diagnosticar(_opcion_correcta(m))
			m.alternar_diesel("G2")
			m.avanzar(5.0)
			m.dar_paso("aviso")
			m.bloquear("G2")
			m.verificar("G2")
			m.ejecutar("cambiar_rele_bajar")
			m.desbloquear("G2")
			m.alternar_diesel("G2")
			m.avanzar(10.0)
			m.sincronizar("G2")
			_esperar_cierre(m, "G2")
			_repartir(m, ["G1", "G2"])
			m.alternar_carga("C2")
			m.avanzar(3.0)
			_repartir(m, ["G1", "G2"])
	_terminar(m)


func test_las_misiones_del_cuadro_estan_bien_formadas() -> String:
	var c := Contenido.new()
	var publicadas: Array = c.sistema(1)["modos"]["guardia"]["misiones"]
	var glosario := c.glosario()
	for id: String in MISIONES:
		if not publicadas.has(id):
			return "falta publicar %s" % id
		var m := _mision(id)
		if m.datos.get("tipo", "") != "cuadro":
			return "%s debe ser del cuadro" % id
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
		for a: Dictionary in m.datos.get("acciones", []):
			if a.has("tema") and not m.comunes["faltas"].has(a["tema"]):
				return "%s: la acción %s usa un tema sin texto" % [id, a["id"]]
		for r: Dictionary in m.datos.get("reglas", []):
			if not m.comunes["faltas"].has(r["falta"]):
				return "%s: la regla usa una falta sin texto: %s" % [id, r["falta"]]
		for tema: String in m.datos.get("eventos", {}).values():
			if not tema.is_empty() and not m.comunes["faltas"].has(tema):
				return "%s: evento con una falta sin texto: %s" % [id, tema]
		if not m.fin.is_empty() or not m.faltas.is_empty():
			return "%s empieza con %s %s" % [id, m.fin, str(m.faltas)]
	return "; ".join(c.errores)


func test_faltas_e_incidentes_del_cuadro_tienen_texto() -> String:
	var g: Dictionary = Contenido.new().leer("guardia.json")
	for tema: String in MisionCuadro.EVENTOS_FALTA.values():
		if not g["faltas"].has(tema):
			return "falta el texto de %s" % tema
	for tipo: String in MisionCuadro.EVENTOS_INCIDENTE.values() + ["blackout"]:
		var i: Dictionary = g["incidentes"].get(tipo, {})
		for clave in ["cabecera", "titulo", "que_ocurrio", "causa", "como_evitar", "repasar"]:
			if i.get(clave, "").is_empty():
				return "el incidente %s no tiene %s" % [tipo, clave]
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
			return "%s: fin «%s», %d estrellas, faltas %s, prueba %s, sin cumplir: %s" % [id, m.fin, m.estrellas(), str(m.faltas), m.prueba_ok, ", ".join(pendientes)]
	return ""


# --- Paralelo ---

func test_paralelo_empieza_con_g1_solo() -> String:
	var m := _mision("gen1_paralelo")
	return A.primero([
		A.cierto(m.operador.interruptor_de("G1").cerrado() and not m.operador.interruptor_de("G2").cerrado(), "G1 solo en barras"),
		A.cerca(_f_barras(m), 50.0, 0.003, "frecuencia inicial"),
		A.cerca(m.operador.generador("G1").estado["p_kw"], 360.0, 0.05, "carga de G1, con el cuadro de emergencia"),
		A.cierto(not m.operador.pms().automatico(), "PMS en manual"),
	])


func test_paralelo_sin_sincronizador_automatico() -> String:
	var m := _mision("gen1_paralelo")
	m.alternar_diesel("G2")
	m.avanzar(10.0)
	var aviso := m.sincronizar("G2")
	return A.cierto(aviso["tipo"] == "aviso" and aviso["texto"].contains("a mano"), "debe pedir sincronizar a mano: %s" % str(aviso))


func test_paralelo_cierre_fuera_de_fase_es_incidente() -> String:
	var m := _mision("gen1_paralelo")
	m.alternar_diesel("G2")
	m.avanzar(10.0)
	m.velocidad("G2", 2.0)
	var sy: SimSincronoscopio = m.sim.componente("SY")
	for _i in 2000:
		m.avanzar(SimSimulacion.PASO_S)
		if sy.estado["valido"] and absf(sy.estado["angulo"]) > 150.0:
			break
	var aviso := m.alternar_interruptor("G2")
	return A.primero([
		A.cierto(m.fin == "accidente", "debe terminar la misión"),
		A.cierto(aviso["tipo"] == "accidente", "el mando debe informar el incidente: %s" % str(aviso)),
		A.cierto(m.accidente.get("tema", "") == "incidente_fuera_de_fase", "tema: %s" % m.accidente.get("tema", "")),
		A.cierto(m.accidente.get("cabecera", "") == "Informe de incidente", "debe ser un informe de incidente"),
	])


func test_paralelo_conectar_sin_reserva_dispara_el_preferente() -> String:
	var m := _mision("gen1_paralelo")
	m.alternar_carga("C3")
	m.avanzar(10.0)
	var temas := m.faltas.map(func(f: Dictionary) -> String: return f["tema"])
	return A.primero([
		A.cierto(temas.has("disparo_preferente"), "debe anotar la falta: %s" % str(temas)),
		A.cierto(not m.operador.carga("C3").estado["conectada"] and not m.operador.carga("C2").estado["conectada"], "deben salir las no esenciales"),
		A.cierto(m.operador.carga("C1").estado["conectada"], "la esencial sigue"),
		A.cierto(m.fin.is_empty(), "no es un blackout"),
		A.cierto(not m.avisos_pendientes.is_empty(), "la pantalla debe mostrar la falta"),
	])


func test_abrir_el_unico_grupo_es_blackout() -> String:
	var m := _mision("gen1_paralelo")
	m.alternar_interruptor("G1")
	m.avanzar(1.0)
	return A.primero([
		A.cierto(m.fin == "accidente", "debe terminar en incidente"),
		A.cierto(m.accidente.get("tema", "") == "incidente_blackout", "tema: %s" % m.accidente.get("tema", "")),
	])


func test_paralelo_sin_repartir_no_supera_la_prueba() -> String:
	var m := _mision("gen1_paralelo")
	_sincronizar_a_mano(m, "G2")
	m.avanzar(5.0)
	m.avanzar(m.tiempo_de_prueba() + 5.0)
	return A.cierto(not m.prueba_ok, "sin conectar C3 ni repartir no debe pasar")


# --- Blackout ---

func test_blackout_empieza_sin_tension() -> String:
	var m := _mision("gen2_blackout")
	var g1 := m.operador.generador("G1")
	var aviso := m.alternar_diesel("G1")
	var g3 := m.alternar_diesel("G3")
	return A.primero([
		A.cierto(m.operador.tension_barras() < 10.0, "barras sin tensión: %.0f V" % m.operador.tension_barras()),
		A.cierto(m.operador.interruptor_de("G1").estado["causa"] == "disparo_minima_tension", "Q1 disparado por mínima tensión: %s" % m.operador.interruptor_de("G1").estado["causa"]),
		A.cierto(not g1.en_marcha() and aviso["texto"].contains("combustible"), "G1 no arranca por su alarma: %s" % aviso["texto"]),
		A.cierto(g3["texto"].contains("bloqueado"), "G3 está bloqueado: %s" % g3["texto"]),
		A.cierto(m.fin.is_empty(), "el blackout inicial no termina la misión"),
	])


func test_blackout_cerrar_con_toda_la_carga_es_falta() -> String:
	var m := _mision("gen2_blackout")
	m.alternar_diesel("G2")
	m.avanzar(10.0)
	m.alternar_interruptor("G2")
	m.avanzar(1.0)
	var temas := m.faltas.map(func(f: Dictionary) -> String: return f["tema"])
	return A.primero([
		A.cierto(m.operador.interruptor_de("G2").cerrado(), "debe cerrar sobre las barras muertas"),
		A.cierto(temas.has("restablecer_con_toda_la_carga"), "debe anotar la falta: %s" % str(temas)),
	])


func test_blackout_mecanico_sin_bloqueo_es_accidente() -> String:
	var m := _mision("gen2_blackout")
	m.diagnosticar(_opcion_correcta(m))
	m.ejecutar("filtros_g1")
	return A.primero([
		A.cierto(m.fin == "accidente", "debe terminar en accidente"),
		A.cierto(m.accidente["titulo"].contains("mantenimiento"), "con el texto de la misión: %s" % m.accidente["titulo"]),
		A.cierto(m.accidente["tema"] == "accidente_sin_bloqueo", "tema: %s" % m.accidente["tema"]),
	])


func test_bloquear_sin_aviso_es_falta() -> String:
	var m := _mision("gen2_blackout")
	var aviso := m.bloquear("G1")
	return A.primero([
		A.cierto(aviso["tipo"] == "error", "debe avisar de la falta"),
		A.cierto(m.bloqueado("G1") and m.operador.generador("G1").estado["bloqueado"], "el bloqueo se coloca igual"),
	])


func test_un_grupo_bloqueado_no_arranca_ni_lo_usa_el_pms() -> String:
	var m := _mision("gen2_blackout")
	m.dar_paso("aviso")
	m.alternar_pms()
	m.avanzar(15.0)
	return A.primero([
		A.cierto(not m.operador.generador("G3").en_marcha(), "el PMS no debe arrancar G3, bloqueado"),
		A.cierto(not m.operador.generador("G1").en_marcha(), "ni G1, parado por alarma"),
		A.cierto(m.operador.generador("G2").en_marcha(), "debe arrancar G2"),
	])


func test_blackout_arranca_el_generador_de_emergencia() -> String:
	var m := _mision("gen2_blackout")
	var ge := m.generador("GE")
	var v_be := m.tension_emergencia()
	var qt := m.interruptor("QT")
	var cerrar_qt := m.alternar_interruptor_id("QT")
	return A.primero([
		A.cierto(ge.en_marcha() and m.interruptor("QE").cerrado(), "GE en marcha y QE cerrado al empezar"),
		A.cerca(v_be, 380.0, 0.05, "el cuadro de emergencia con tensión"),
		A.cierto(qt.estado["causa"] == "disparo_minima_tension", "el enlace abrió por mínima tensión: %s" % qt.estado["causa"]),
		A.cierto(cerrar_qt["tipo"] == "aviso" and not qt.cerrado(), "disparado y enclavado, el enlace no cierra"),
	])


func test_en_servicio_normal_la_emergencia_espera() -> String:
	for id: String in ["gen1_paralelo", "gen3_falla_tierra", "gen4_potencia_inversa"]:
		var m := _mision(id)
		m.avanzar(5.0)
		if not m.interruptor("QT").cerrado() or m.interruptor("QE").cerrado() or m.generador("GE").en_marcha():
			return "%s: el cuadro de emergencia debe estar alimentado desde el principal" % id
		if not m.generador("GE").params["arranque_automatico"]:
			return "%s: GE debe quedar en automático" % id
		if m.tension_emergencia() < 340.0:
			return "%s: barras de emergencia sin tensión" % id
	return ""


func test_blackout_provocado_tambien_arranca_la_emergencia() -> String:
	var m := _mision("gen1_paralelo")
	m.alternar_interruptor("G1")
	m.avanzar(1.0)
	m.sim.avanzar_tiempo(24.0)
	return A.primero([
		A.cierto(m.fin == "accidente", "el blackout termina la misión"),
		A.cierto(m.generador("GE").en_marcha() and m.interruptor("QE").cerrado(), "la emergencia toma el cuadro de emergencia"),
	])


# --- Falla a tierra ---

func test_falla_a_tierra_se_ve_en_monitor_y_lamparas() -> String:
	var m := _mision("gen3_falla_tierra")
	var v := m.operador.tensiones_a_tierra()
	var mohm: float = m.sim.componente("MA").estado["mohm"]
	m.alternar_carga("C4")
	m.avanzar(3.0)
	var sin_c4: float = m.sim.componente("MA").estado["mohm"]
	var v_sin_c4 := m.operador.tensiones_a_tierra()
	return A.primero([
		A.cierto(mohm < 0.1, "el monitor debe marcar menos de 0,1 MΩ: %.3f" % mohm),
		A.cierto(v[2] < 30.0, "la lámpara de L3 apagada: %.0f V" % v[2]),
		A.cerca(v[0], 380.0, 0.05, "L1 a tierra con la falla"),
		A.cerca(v[1], 380.0, 0.05, "L2 a tierra con la falla"),
		A.cierto(sin_c4 > 10.0, "al abrir C4 el monitor vuelve a normal: %.1f" % sin_c4),
		A.cerca(v_sin_c4[2], 219.4, 0.05, "sin la falla, cada fase a 219 V del casco"),
	])


func test_cortar_una_esencial_sin_aviso_es_falta() -> String:
	var m := _mision("gen3_falla_tierra")
	var aviso := m.alternar_carga("C1")
	var n := _mision("gen3_falla_tierra")
	n.dar_paso("aviso")
	var con_aviso := n.alternar_carga("C1")
	var no_esencial := _mision("gen3_falla_tierra").alternar_carga("C3")
	return A.primero([
		A.cierto(aviso["tipo"] == "error" and m.faltas[0]["tema"] == "cortar_esencial_sin_aviso", "sin aviso es falta: %s" % str(aviso)),
		A.cierto(not m.operador.carga("C1").estado["conectada"], "la salida se abre igual"),
		A.cierto(con_aviso["tipo"] == "hecho" and n.faltas.is_empty(), "con aviso no es falta"),
		A.cierto(no_esencial["tipo"] == "hecho", "una no esencial no necesita aviso"),
	])


func test_megometro_sin_bloqueo_es_falta() -> String:
	var m := _mision("gen3_falla_tierra")
	m.alternar_carga("C4")
	var aviso := m.ejecutar("medir_c4")
	return A.primero([
		A.cierto(aviso["tipo"] == "error" and m.faltas[0]["tema"] == "medir_sin_bloqueo", "debe ser falta: %s" % str(aviso)),
		A.cierto(m.mediciones.is_empty(), "no debe dar lectura"),
	])


func test_lectura_del_megometro_y_remedicion() -> String:
	var m := _mision("gen3_falla_tierra")
	m.dar_paso("aviso")
	m.alternar_carga("C4")
	m.bloquear("C4")
	var conectar := m.alternar_carga("C4")
	m.verificar("C4")
	var antes := m.ejecutar("medir_c4")
	m.ejecutar("reparar_c4")
	var sin_medir := m.desbloquear("C4")
	return A.primero([
		A.cierto(conectar["titulo"] == "Salida bloqueada", "con candado no se conecta: %s" % str(conectar)),
		A.cierto(antes["texto"].contains("0,08 MΩ"), "lectura con la falla: %s" % antes["texto"]),
		A.cierto(sin_medir["tipo"] == "error" and m.faltas.back()["tema"] == "sin_remedir", "quitar el candado sin medir es falta"),
	])


func test_diagnostico_sin_pruebas_es_falta() -> String:
	var m := _mision("gen3_falla_tierra")
	var aviso := m.diagnosticar(_opcion_correcta(m))
	var n := _mision("gen3_falla_tierra")
	var mal := n.diagnosticar(_opcion_incorrecta(n))
	return A.primero([
		A.cierto(m.diagnostico_ok and aviso["tipo"] == "error" and m.faltas[0]["tema"] == "diagnostico_sin_medir", "acierto sin pruebas: %s" % str(m.faltas)),
		A.cierto(not n.diagnostico_ok and mal["tipo"] == "error" and n.faltas[0]["tema"] == "diagnostico_gen3_falla_tierra", "error de diagnóstico"),
	])


# --- Potencia inversa ---

func test_deriva_se_ve_con_el_grupo_aislado() -> String:
	var m := _mision("gen4_potencia_inversa")
	var g := m.operador.generador("G2")
	m.rearmar("G2")
	m.alternar_diesel("G2")
	m.avanzar(12.0)
	var f1 := g.frecuencia()
	m.avanzar(30.0)
	var f2 := g.frecuencia()
	return A.primero([
		A.cierto(f1 - f2 > 0.4, "la frecuencia de G2 debe bajar sola: %.2f → %.2f Hz" % [f1, f2]),
		A.cierto(m.evidencias_completas(), "la observación debe contar como prueba"),
	])


func test_sin_reparar_vuelve_a_disparar() -> String:
	var m := _mision("gen4_potencia_inversa")
	m.rearmar("G2")
	m.alternar_diesel("G2")
	m.avanzar(10.0)
	m.sincronizar("G2")
	_esperar_cierre(m, "G2")
	m.velocidad("G2", 3.0)
	m.avanzar(150.0)
	var temas := m.faltas.map(func(f: Dictionary) -> String: return f["tema"])
	return A.primero([
		A.cierto(temas.has("repetir_disparo"), "debe anotar el disparo repetido: %s" % str(temas)),
		A.cierto(not temas.has("potencia_inversa"), "con el tema de la misión, no el común"),
		A.cierto(not m.prueba_ok, "no debe superar la prueba"),
		A.cierto(m.fin.is_empty(), "G1 sigue en barras: no hay blackout"),
	])


func test_subir_la_proteccion_es_falta_y_no_pasa_la_prueba() -> String:
	var m := _mision("gen4_potencia_inversa")
	var aviso := m.ejecutar("subir_inversa")
	var cumple: bool = m.condicion({"c": "param", "id": "Q2", "clave": "potencia_inversa_pct", "max": 8.0})
	m.ejecutar("restituir_inversa")
	var restituido: bool = m.condicion({"c": "param", "id": "Q2", "clave": "potencia_inversa_pct", "max": 8.0})
	return A.primero([
		A.cierto(aviso["tipo"] == "error" and m.faltas[0]["tema"] == "ajuste_proteccion_generador", "debe ser falta: %s" % str(m.faltas)),
		A.cierto(not cumple, "con el 20 % no se cumple el objetivo"),
		A.cierto(restituido, "al restituir vuelve a cumplirse"),
	])


func test_verificar_un_grupo_que_gira_encuentra_tension() -> String:
	var m := _mision("gen4_potencia_inversa")
	m.dar_paso("aviso")
	m.rearmar("G2")
	m.alternar_diesel("G2")
	m.avanzar(10.0)
	var en_marcha := m.bloquear("G2")
	m.alternar_diesel("G2")
	m.avanzar(5.0)
	m.bloquear("G2")
	var verificado := m.verificar("G2")
	return A.primero([
		A.cierto(en_marcha["tipo"] == "aviso" and not m.bloqueos.is_empty(), "no se bloquea en marcha, sí parado"),
		A.cierto(verificado["tipo"] == "hecho" and m.verificado("G2"), "parado, la verificación vale: %s" % str(verificado)),
	])


func test_diagnostico_incorrecto_queda_anotado() -> String:
	var m := _mision("gen4_potencia_inversa")
	m.diagnosticar(_opcion_incorrecta(m))
	return A.cierto(m.faltas.size() == 1 and m.faltas[0]["tema"] == "diagnostico_gen4_potencia_inversa", "faltas: %s" % str(m.faltas))


# --- Pantalla ---

func _raiz(id: String) -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.ir_a("mision_cuadro", {"id": id})
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


func test_guardia_del_sistema_1_abre_la_mision_del_cuadro() -> String:
	var raiz := _raiz("gen1_paralelo")
	raiz.volver()
	raiz.ir_a("guardia", {"id": 1})
	var filas: Array[FilaMenu] = []
	_filas(raiz.pantalla_actual(), filas)
	filas[0].pulsada.emit()
	var abierta: bool = raiz.pantalla_actual().get_script().resource_path.ends_with("mision_cuadro.gd")
	raiz.free()
	return A.primero([
		A.cierto(filas.size() == MISIONES.size(), "deben listarse las misiones: %d" % filas.size()),
		A.cierto(abierta, "debe abrir la pantalla de misión del cuadro"),
	])


func test_pantalla_recorre_las_pestanas_en_ambas_orientaciones() -> String:
	for id: String in MISIONES:
		var raiz := _raiz(id)
		for vertical in [true, false]:
			raiz.vertical = vertical
			raiz.reconstruir()
			var p = raiz.pantalla_actual()
			for pestana in (["mision", "barras", "G1", "G2", "G3"] if vertical else ["mision", "G1", "G2", "G3"]):
				p._elegir_pestana(pestana)
				p._actualizar()
		raiz.free()
	return ""


func test_pantalla_muestra_el_procedimiento_y_los_objetivos() -> String:
	var raiz := _raiz("gen3_falla_tierra")
	var p = raiz.pantalla_actual()
	var textos: Array[String] = []
	_botones(p, textos)
	p._actualizar()
	var marcas: int = p._panel.marcas_objetivos.size()
	var primera: String = p._panel.marcas_objetivos[0].text
	p._panel.dar_paso("aviso")
	p._alternar_carga("C4")
	p._panel.bloquear("C4")
	var despues: Array[String] = []
	_botones(raiz.pantalla_actual(), despues)
	if raiz.vertical:
		p._elegir_pestana("barras")
	var barras: Array[String] = []
	_botones(raiz.pantalla_actual(), barras)
	raiz.free()
	return A.primero([
		A.cierto(textos.has("Avisar al puente y al jefe de máquinas de la búsqueda de la falla"), "debe estar el aviso"),
		A.cierto(textos.has("Bloquear C4 (alumbrado y reflectores de cubierta) con candado y tarjeta"), "debe poder bloquear C4: %s" % str(textos)),
		A.cierto(marcas == 8 and primera.begins_with("✓"), "objetivos con su marca: %d, %s" % [marcas, primera]),
		A.cierto(despues.has("Verificar ausencia de tensión en C4"), "bloqueada, debe ofrecer la verificación"),
		A.cierto(not textos.has("Reiniciar la práctica"), "en una misión no se reinicia la práctica"),
		A.cierto(barras.has("Abrir el enlace QT") and barras.has("GE en automático: pasar a manual"), "debe estar el cuadro de emergencia: %s" % str(barras)),
	])


func test_pantalla_incidente_muestra_el_informe_y_no_suma() -> String:
	var raiz := _raiz("gen1_paralelo")
	var p = raiz.pantalla_actual()
	p._alternar_acb("G1")
	p._avanzar(20)
	raiz.reconstruir()
	var q = raiz.pantalla_actual()
	var fin: String = q.mision.fin
	var datos: Dictionary = raiz.partida.datos["misiones"].get("gen1_paralelo", {})
	var errores: Dictionary = raiz.partida.datos["errores"]
	var puntos: int = raiz.partida.datos["puntos"]
	q._repetir()
	var nueva = raiz.pantalla_actual()
	var reinicia: bool = nueva.mision.fin.is_empty()
	raiz.free()
	return A.primero([
		A.cierto(fin == "accidente", "debe terminar en incidente"),
		A.cierto(int(datos.get("accidentes", 0)) == 1, "debe contar el incidente: %s" % str(datos)),
		A.cierto(errores.has("incidente_blackout"), "debe quedar para repasar: %s" % str(errores.keys())),
		A.cierto(puntos == 0, "no debe sumar puntos: %d" % puntos),
		A.cierto(reinicia, "repetir debe empezar de nuevo"),
	])


func test_pantalla_conserva_la_mision_al_girar() -> String:
	var raiz := _raiz("gen2_blackout")
	var p = raiz.pantalla_actual()
	var m: MisionCuadro = p.mision
	p._panel.dar_paso("aviso")
	raiz.vertical = not raiz.vertical
	raiz.reconstruir()
	var igual: bool = raiz.pantalla_actual().mision == m and raiz.pantalla_actual().sim == m.sim
	raiz.free()
	return A.primero([
		A.cierto(igual, "girar el celular no debe perder la misión"),
		A.cierto(m.hechos.has("aviso"), "debe conservar lo hecho"),
	])


func test_pantalla_firma_y_registra_la_mision() -> String:
	var raiz := _raiz("gen4_potencia_inversa")
	var p = raiz.pantalla_actual()
	var m: MisionCuadro = p.mision
	m.diagnostico_ok = true
	m.prueba_ok = true
	p.args["respuestas"] = _respuestas_correctas(m)
	p._panel.firmar()
	raiz.reconstruir()
	var q = raiz.pantalla_actual()
	var completada: bool = q.mision.fin == "completada"
	var datos: Dictionary = raiz.partida.datos["misiones"].get("gen4_potencia_inversa", {})
	var puntos: int = raiz.partida.datos["puntos"]
	raiz.free()
	return A.primero([
		A.cierto(completada, "debe mostrar el resultado"),
		A.cierto(int(datos.get("estrellas", 0)) == 3, "debe guardar las estrellas: %s" % str(datos)),
		A.cierto(puntos == Partida.PUNTOS_MISION + 3 * Partida.PUNTOS_ESTRELLA, "puntos: %d" % puntos),
	])


func test_pantalla_observa_con_el_tiempo_acelerado() -> String:
	var raiz := _raiz("gen3_falla_tierra")
	var p = raiz.pantalla_actual()
	p._panel.observar()
	var observando: bool = p.mision.observando()
	var inicio: float = p.mision.sim.tiempo
	for _i in 400:
		if not p.mision.observando():
			break
		p._avanzar(1)
	var avanzado: float = p.mision.sim.tiempo - inicio
	var terminado: bool = not p.mision.observando()
	var aviso: int = p._avisos.get_child_count()
	raiz.free()
	return A.primero([
		A.cierto(observando, "debe empezar a observar"),
		A.cierto(terminado and avanzado >= 9.9, "debe avanzar el tiempo de la prueba: %.1f s" % avanzado),
		A.cierto(aviso > 0, "debe decir por qué no se superó"),
	])
