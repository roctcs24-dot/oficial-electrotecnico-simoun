extends RefCounted
## Misiones de Guardia del sistema 6 en el panel local de la máquina principal.

const A := preload("res://tests/ayuda_sim.gd")
const MISIONES := ["m1_mp_no_queda_lista", "m2_mp_parada_cop"]
const G := preload("res://tests/test_guardia_tableros.gd")
const D := preload("res://tests/test_guardia_distribucion.gd")


func _medir(m: MisionGuardia, modo: String, a: String, b: String) -> Dictionary:
	var medidor := SimMultimetro.new()
	medidor.ruido = 0.0
	var r := medidor.medir(m.mesa.sim, modo, a, b)
	m.registrar_medicion("multimetro", modo, a, b, r)
	return r


## Prelubrica, gira el selector a START, lo suelta y deja el motor al ralentí.
func _arrancar(m: MisionGuardia) -> void:
	m.mesa.sim.avanzar_tiempo(10.0)
	var s: SimSelector = m.mesa.sim.componente("SRS")
	s.poner("START")
	m.mesa.avanzar(4)
	s.soltar()
	m.mesa.sim.avanzar_tiempo(15.0)


## Resuelve la misión como el jugador y la deja lista para la prueba en servicio.
func resolver(id: String) -> MisionGuardia:
	var g = G.new()
	var d = D.new()
	var m := MisionGuardia.new(Contenido.new(), id)
	m.datos["bloqueo"] = ["Q0"]
	m.colocar_epp()
	if id == "m1_mp_no_queda_lista":
		m.mesa.sim.avanzar_tiempo(10.0)
		_medir(m, "vdc", "MP.PA1", "Q0.4")
		_medir(m, "vdc", "MP.PA2", "Q0.4")
		m.diagnosticar(g._opcion_correcta(m))
		d._bloquear(m, g)
		m.ejecutar("cerrar_aire")
		m.ejecutar("cambiar_presostato")
		m.ejecutar("abrir_aire")
		m.mesa.sim.avanzar_tiempo(1.0)
		_medir(m, "ohm", "MP.PA1", "MP.PA2")
	else:
		_arrancar(m)
		m.mesa.sim.avanzar_tiempo(30.0)
		_medir(m, "vdc", "MP.CP1", "Q0.4")
		_medir(m, "vdc", "MP.CP2", "Q0.4")
		m.diagnosticar(g._opcion_correcta(m))
		d._bloquear(m, g)
		m.ejecutar("revisar_carter")
		m.ejecutar("cambiar_cop")
		m.mesa.sim.avanzar_tiempo(1.0)
		_medir(m, "ohm", "MP.CP1", "MP.CP2")
	d._energizar(m)
	if id == "m2_mp_parada_cop":
		# Con la cadena ya cerrada, RESET ALARM repone la parada retenida.
		g._pulsar(m, "RA")
	_arrancar(m)
	return m


func test_las_dos_misiones_se_resuelven_con_tres_estrellas() -> String:
	var g = G.new()
	for id: String in MISIONES:
		var m := resolver(id)
		var aviso: Dictionary = g._observar(m, m.tiempo_de_prueba())
		if not m.prueba_ok:
			return "%s: prueba no superada: %s" % [id, aviso.get("texto", "")]
		m.firmar(g._respuestas_correctas(m))
		if m.fin != "completada" or m.estrellas() != 3:
			return "%s: %s, %d estrellas, %s" % [id, m.fin, m.estrellas(), str(m.faltas)]
	return ""


func test_sin_reparar_la_prueba_falla() -> String:
	var g = G.new()
	for id: String in MISIONES:
		var m := MisionGuardia.new(Contenido.new(), id)
		_arrancar(m)
		g._observar(m, m.tiempo_de_prueba())
		if m.prueba_ok:
			return "%s: la prueba pasa sin reparar" % id
	return ""


func test_el_presostato_no_se_cambia_con_la_linea_de_aire_en_presion() -> String:
	var g = G.new()
	var d = D.new()
	var m := MisionGuardia.new(Contenido.new(), "m1_mp_no_queda_lista")
	m.datos["bloqueo"] = ["Q0"]
	d._bloquear(m, g)
	var aviso := m.ejecutar("cambiar_presostato")
	return A.primero([
		A.cierto(aviso["tipo"] == "aviso", "sin cerrar el aire, la misión lo impide: %s" % aviso),
		A.cierto(m.mesa.sim.componente("MP").params["averia"] == "presostato_aire", "el presostato sigue averiado"),
	])


func test_tocar_el_cop_sin_revisar_el_carter_no_se_puede() -> String:
	var g = G.new()
	var d = D.new()
	var m := MisionGuardia.new(Contenido.new(), "m2_mp_parada_cop")
	m.datos["bloqueo"] = ["Q0"]
	d._bloquear(m, g)
	var aviso := m.ejecutar("cambiar_cop")
	var puente := m.ejecutar("puentear_cp")
	return A.primero([
		A.cierto(aviso["tipo"] == "aviso", "sin revisar el cárter no se toca el COP: %s" % aviso),
		A.cierto(puente["tipo"] == "error", "puentear la protección es un error"),
		A.cierto(m.faltas.any(func(f: Dictionary) -> bool: return f["tema"] == "puente_seguridad"), "queda anotada la falta"),
	])
