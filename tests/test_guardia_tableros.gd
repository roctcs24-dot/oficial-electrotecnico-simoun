extends RefCounted
## Misiones de Guardia frente a un tablero del buque: la falla se ve en el frente y se busca
## midiendo con la puerta abierta.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_guardia_tableros.json"


func _mision(id: String) -> MisionGuardia:
	return MisionGuardia.new(Contenido.new(), id)


func _medidor() -> SimMultimetro:
	var m := SimMultimetro.new()
	m.ruido = 0.0
	return m


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


func _observar(m: MisionGuardia, segundos: float) -> Dictionary:
	m.observar(segundos)
	var resultado := {}
	var vueltas := 0
	while m.observando() and vueltas < 2000:
		resultado = m.procesar_observacion(50)
		vueltas += 1
	return resultado


func _medir_mega(m: MisionGuardia, a: String, b: String) -> Dictionary:
	var meg := SimMegohmetro.new()
	meg.ruido = 0.0
	var r := meg.medir(m.mesa.sim, a, b, 500)
	m.registrar_medicion("megohmetro", "500", a, b, r)
	return r


func _medir_vac(m: MisionGuardia, a: String, b: String) -> Dictionary:
	var r := _medidor().medir(m.mesa.sim, "vac", a, b)
	m.registrar_medicion("multimetro", "vac", a, b, r)
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


func _pulsar(m: MisionGuardia, id: String) -> void:
	m.mesa.sim.componente(id).estado["presionado"] = true
	m.mesa.avanzar(4)
	m.mesa.sim.componente(id).estado["presionado"] = false
	m.mesa.avanzar(2)


func _test_tierra(m: MisionGuardia) -> float:
	m.mesa.sim.componente("ST").estado["presionado"] = true
	m.mesa.avanzar(3)
	var r: float = m.mesa.sim.componente("HT1").estado["relacion"]
	m.mesa.sim.componente("ST").estado["presionado"] = false
	return r


func test_t1_la_lampara_se_apaga_solo_con_la_bomba_1() -> String:
	var m := _mision("t1_tierra_bombas_mp")
	var parada := _test_tierra(m)
	_pulsar(m, "SM1")
	m.mesa.avanzar(60)
	var en_marcha := _test_tierra(m)
	return A.primero([
		A.cierto(parada > 0.5, "con la bomba parada L1 alumbra: %.2f" % parada),
		A.cierto(en_marcha < 0.35, "con la bomba nº 1 en marcha, al pulsar TEST L1 se apaga: %.2f" % en_marcha),
	])


func test_t1_completa() -> String:
	var m := _mision("t1_tierra_bombas_mp")
	_bloquear_y_verificar(m)
	var verificado := m.verificado()
	m.ejecutar("retirar_puentes")
	var u := _medir_mega(m, "M1.U1", "PE.PE")
	for nodo in ["M1.V1", "M1.W1"]:
		_medir_mega(m, nodo, "PE.PE")
	var d := m.diagnosticar(_opcion_correcta(m))
	m.ejecutar("secar_devanado")
	var seco := _medir_mega(m, "M1.U1", "PE.PE")
	m.ejecutar("reponer_puentes")
	_quitar_bloqueo_y_energizar(m)
	_pulsar(m, "SM1")
	m.mesa.avanzar(100)
	var prueba := _observar(m, m.tiempo_de_prueba())
	m.firmar(_respuestas_correctas(m))
	return A.primero([
		A.cierto(verificado, "bloquear Q1 y verificar su salida debe bastar"),
		A.cierto(not u["aceptable"], "el devanado U debe dar bajo: %s" % str(u)),
		A.cierto(d["tipo"] == "hecho", "el diagnóstico debe confirmarse: %s" % str(d)),
		A.cierto(seco["aceptable"], "tras secar debe ser aceptable: %s" % str(seco)),
		A.cierto(prueba["titulo"] == "Prueba superada", "debe superar la prueba: %s" % str(prueba)),
		A.cierto(m.estrellas() == 3, "deben ser 3 estrellas: %d %s" % [m.estrellas(), str(m.faltas)]),
	])


func test_t2_empieza_con_las_dos_fallas_y_falta_una_fase() -> String:
	var m := _mision("t2_hidroforo_sin_fase")
	m.colocar_epp()
	var falla1: bool = m.mesa.sim.componente("HF1").estado["encendida"]
	var falla2: bool = m.mesa.sim.componente("HF2").estado["encendida"]
	var sana := _medir_vac(m, "Q0.2", "Q0.4")
	var sin_fase := _medir_vac(m, "Q0.4", "Q0.6")
	return A.primero([
		A.cierto(falla1 and falla2, "las dos luces de FALLA TERMICA deben empezar encendidas"),
		A.cerca(float(sana["valor"]), 380.0, 0.05, "entre L1 y L2 hay 380 V"),
		A.cierto(float(sin_fase["valor"]) < 300.0, "con el polo quemado falta tensión hacia L3: %.0f V" % float(sin_fase["valor"])),
	])


func test_t2_completa() -> String:
	var m := _mision("t2_hidroforo_sin_fase")
	m.colocar_epp()
	_medir_vac(m, "Q0.2", "Q0.6")
	_medir_vac(m, "Q0.4", "Q0.6")
	var d := m.diagnosticar(_opcion_correcta(m))
	_bloquear_y_verificar(m)
	var verificado := m.verificado()
	m.ejecutar("cambiar_q0")
	_quitar_bloqueo_y_energizar(m)
	for f in ["F1", "F2"]:
		(m.mesa.sim.componente(f) as SimReleTermico).rearmar()
	(m.mesa.sim.componente("SM") as SimSelector).poner("MAN")
	m.mesa.avanzar(100)
	var prueba := _observar(m, m.tiempo_de_prueba())
	m.firmar(_respuestas_correctas(m))
	return A.primero([
		A.cierto(d["tipo"] == "hecho", "el diagnóstico debe confirmarse: %s" % str(d)),
		A.cierto(verificado, "bloquear la alimentación del cuadro y verificar la entrada de Q0"),
		A.cierto(prueba["titulo"] == "Prueba superada", "debe superar la prueba: %s" % str(prueba)),
		A.cierto(m.estrellas() == 3, "deben ser 3 estrellas: %d %s" % [m.estrellas(), str(m.faltas)]),
	])


func test_t2_cambiar_q0_sin_bloquear_el_cuadro_es_accidente() -> String:
	var m := _mision("t2_hidroforo_sin_fase")
	m.colocar_epp()
	m.dar_aviso()
	var q0: SimSeccionador = m.mesa.sim.componente("Q0")
	q0.accionar(false)
	m.ejecutar("cambiar_q0")
	return A.cierto(m.fin == "accidente", "con la entrada de Q0 en tensión, cambiarlo es accidente: %s" % m.fin)


func test_pantalla_de_mision_muestra_el_frente() -> String:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.ir_a("mision", {"id": "t2_hidroforo_sin_fase"})
	var p = raiz.pantalla_actual()
	var con_frente: bool = p.frente != null and p.frente.visible
	p._alternar_puerta()
	var abierta: bool = p._caja_mesa.visible
	raiz.free()
	return A.primero([
		A.cierto(con_frente, "la misión empieza frente al tablero"),
		A.cierto(abierta, "al abrir la puerta se ve la mesa para medir"),
	])
