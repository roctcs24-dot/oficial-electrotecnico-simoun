extends RefCounted
## Misiones de Guardia de la red del puesto de alarmas y de la pantalla local del MYCOM.

const A := preload("res://tests/ayuda_sim.gd")
const MISIONES := ["a1_direccion_mycom", "a2_terminador_mal_puesto", "a3_sentina_sin_comunicacion", "a4_descarga_mycom_hmi"]


func _mision(id: String) -> MisionRed:
	return MisionRed.new(Contenido.new(), id)


func _opcion_correcta(m: MisionRed) -> int:
	var opciones: Array = m.datos["diagnostico"]["opciones"]
	for i in opciones.size():
		if opciones[i].get("correcta", false):
			return i
	return -1


func _observar(m: MisionRed) -> Dictionary:
	m.observar(m.tiempo_de_prueba())
	var aviso := {}
	while m.observando():
		aviso = m.procesar_observacion(1000)
	return aviso


func _firmar(m: MisionRed) -> Dictionary:
	var respuestas := {}
	var campos := m.campos_libro()
	for i in campos.size():
		respuestas[i] = int(campos[i]["correcta"])
	return m.firmar(respuestas)


## Lo mismo que hace la pantalla al pulsar «Reconocer» en el puesto.
func _reconocer(m: MisionRed) -> void:
	m.puesto.reconocer()
	m.registrar("reconocer")


func _ajustar(m: MisionRed, equipo: String, clave: String, valor: Variant) -> void:
	m.registrar("ajuste", {"equipo": equipo, "clave": clave, "valor": valor})
	m.red.ajustar(equipo, clave, valor)


## Resuelve cada misión con el procedimiento correcto, como lo haría el jugador.
func resolver(id: String) -> MisionRed:
	var m := _mision(id)
	m.dar_paso("aviso")
	match id:
		"a1_direccion_mycom":
			m.registrar("pestana", {"pestana": "red"})
			m.registrar("seleccionar", {"equipo": "MY4"})
			m.ejecutar("leer_lista")
			m.diagnosticar(_opcion_correcta(m))
			_ajustar(m, "MY4", "direccion", 12)
		"a2_terminador_mal_puesto":
			m.registrar("pestana", {"pestana": "red"})
			m.registrar("medir_ab", {"ohmios": m.red.resistencia_a_b()})
			m.registrar("seleccionar", {"equipo": "MY3"})
			m.diagnosticar(_opcion_correcta(m))
			_ajustar(m, "MY3", "terminacion", false)
			_ajustar(m, "ES1", "terminacion", true)
		"a3_sentina_sin_comunicacion":
			m.dar_paso("ronda")
			m.registrar("pestana", {"pestana": "red"})
			m.registrar("medir_ab", {"ohmios": m.red.resistencia_a_b()})
			m.ejecutar("revisar_caja")
			m.diagnosticar(_opcion_correcta(m))
			m.ejecutar("rehacer_conexion")
			m.ejecutar("achicar")
		"a4_descarga_mycom_hmi":
			m.registrar("pagina_hmi", {"pagina": "tendencia"})
			m.registrar("pagina_hmi", {"pagina": "ajustes"})
			m.ejecutar("comprobar_agua")
			m.diagnosticar(_opcion_correcta(m))
			m.ejecutar("limpiar_filtro")
			m.hmi.nivel_tecnico = true
			m.hmi.cambiar_ajuste("DT-alta", -2)
			m.registrar("ajuste_hmi", {"id": "DT-alta", "pasos": -2})
			m.hmi.nivel_tecnico = false
	# Las alarmas que salen al reparar, como la de sentina, se reconocen después de verlas.
	for _i in 60:
		m.avanzar(0.5)
	_reconocer(m)
	return m


func test_las_cuatro_misiones_se_resuelven_con_tres_estrellas() -> String:
	for id: String in MISIONES:
		var m := resolver(id)
		var aviso := _observar(m)
		if not m.prueba_ok:
			return "%s: prueba no superada: %s" % [id, aviso.get("texto", "")]
		var firma := _firmar(m)
		if m.fin != "completada":
			return "%s: no se pudo firmar: %s" % [id, firma.get("texto", "")]
		if m.estrellas() != 3:
			return "%s: %d estrellas, faltas: %s" % [id, m.estrellas(), str(m.faltas)]
	return ""


func test_al_empezar_ya_hay_alarmas_en_el_puesto() -> String:
	var a1 := _mision("a1_direccion_mycom")
	var a3 := _mision("a3_sentina_sin_comunicacion")
	var a4 := _mision("a4_descarga_mycom_hmi")
	return A.primero([
		A.cierto(a1.puesto.estado("MY3-COM") == "activa" and a1.puesto.estado("MY4-COM") == "activa", "a1: falla de comunicación con los dos MYCOM"),
		A.cierto(a3.puesto.estado("ES1-COM") == "activa", "a3: falla de comunicación con el módulo de E/S"),
		A.cierto(a3.puesto.estado("LSH-SM-digital") == "normal", "a3: la alarma de sentina no puede llegar"),
		A.cierto(a4.puesto.estado("MY3-DT-alta") == "activa", "a4: el puesto da alta temperatura de descarga"),
		A.cierto(a4.hmi.alarmas.estado("DT-alta") == "normal", "a4: la pantalla local, con el límite subido, calla"),
	])


func test_tocar_un_equipo_que_comunica_es_falta() -> String:
	var m := _mision("a1_direccion_mycom")
	_ajustar(m, "AX1", "baudios", 9600)
	var falta := false
	for f: Dictionary in m.faltas:
		if f["tema"] == "ajuste_red_innecesario":
			falta = true
	m.avanzar(3.0)
	return A.primero([
		A.cierto(falta, "cambiar la velocidad del AX4 del GEN 1, que comunicaba, es falta"),
		A.cierto(m.red.estado_de("AX1")["estado"] == "falla", "y además lo deja sin comunicación"),
	])


func test_sin_el_aviso_la_prueba_lleva_falta() -> String:
	var m := resolver("a3_sentina_sin_comunicacion")
	var sin_aviso := _mision("a3_sentina_sin_comunicacion")
	sin_aviso.registrar("pestana", {"pestana": "red"})
	sin_aviso.registrar("medir_ab", {"ohmios": sin_aviso.red.resistencia_a_b()})
	sin_aviso.ejecutar("revisar_caja")
	sin_aviso.ejecutar("rehacer_conexion")
	_observar(sin_aviso)
	var falta := false
	for f: Dictionary in sin_aviso.faltas:
		if f["tema"] == "sin_aviso_alarmas":
			falta = true
	return A.primero([
		A.cierto(m.faltas.is_empty(), "con el aviso y la ronda no hay faltas"),
		A.cierto(falta, "observar sin haber hecho la ronda es falta"),
		A.cierto(not sin_aviso.prueba_ok, "y sin achicar, la sentina da alarma y la prueba no pasa"),
	])


func test_la_medida_entre_a_y_b_queda_en_el_libro() -> String:
	var m := _mision("a3_sentina_sin_comunicacion")
	m.registrar("medir_ab", {"ohmios": m.red.resistencia_a_b()})
	return A.primero([
		A.cerca(m.red.resistencia_a_b(), 113.0, 5.0, "con el cable cortado solo queda el terminador del puesto"),
		A.cierto(m.mediciones[-1].contains("%s Ω" % TextoTecnico.numero(m.red.resistencia_a_b(), 0)), "la lectura queda anotada: %s" % m.mediciones[-1]),
	])


func test_subir_el_limite_local_es_falta() -> String:
	var m := _mision("a4_descarga_mycom_hmi")
	m.hmi.nivel_tecnico = true
	m.hmi.cambiar_ajuste("DT-alta", -1)
	m.registrar("ajuste_hmi", {"id": "DT-alta", "pasos": -1})
	var sin_falta := m.faltas.is_empty()
	m.hmi.cambiar_ajuste("DT-alta", 1)
	m.registrar("ajuste_hmi", {"id": "DT-alta", "pasos": 1})
	return A.primero([
		A.cierto(sin_falta, "bajarlo hacia el valor del fabricante no es falta"),
		A.cierto(not m.faltas.is_empty() and m.faltas[0]["tema"] == "limite_alarma_alterado", "subirlo sí"),
	])
