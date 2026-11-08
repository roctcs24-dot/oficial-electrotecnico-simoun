extends RefCounted
## Misiones de Guardia del sistema 2 en el tablero de 110 V de habitabilidad: cortocircuito,
## fase a masa y sobrecarga en los circuitos de distribución.

const A := preload("res://tests/ayuda_sim.gd")
const MISIONES := ["h1_corto_alumbrado", "h2_tierra_tomas", "h3_sobrecarga_cocina"]
const G := preload("res://tests/test_guardia_tableros.gd")


func _mision(id: String) -> MisionGuardia:
	return MisionGuardia.new(Contenido.new(), id)


func _medir_ohm(m: MisionGuardia, a: String, b: String) -> Dictionary:
	var medidor := SimMultimetro.new()
	medidor.ruido = 0.0
	var r := medidor.medir(m.mesa.sim, "ohm", a, b)
	m.registrar_medicion("multimetro", "ohm", a, b, r)
	return r


## Bloquea solo el interruptor del circuito con la falla, como en el procedimiento real.
func _bloquear(m: MisionGuardia, g: Variant) -> void:
	m.colocar_epp()
	m.dar_aviso()
	for a: String in m.datos["bloqueo"]:
		m.accionar_aislador(a, false)
		m.poner_candado(a)
	m.mesa.avanzar(2)
	var medidor := SimMultimetro.new()
	medidor.ruido = 0.0
	for p in m.pasos_verificacion():
		m.verificar(p, medidor)


func _energizar(m: MisionGuardia) -> void:
	for a: String in m.datos["bloqueo"]:
		m.quitar_candado(a)
	m.avisar_energizado()
	for a in m.aisladores():
		m.accionar_aislador(a, true)
	m.mesa.avanzar(2)


## Resuelve la misión como el jugador. Devuelve la misión lista para la prueba en servicio.
func resolver(id: String) -> MisionGuardia:
	var g = G.new()
	var m := _mision(id)
	match id:
		"h1_corto_alumbrado":
			_bloquear(m, g)
			_medir_ohm(m, "F1.2", "F1.4")
			m.ejecutar("revisar_luminarias")
			m.diagnosticar(g._opcion_correcta(m))
			m.ejecutar("cambiar_portalamparas")
			_medir_ohm(m, "F1.2", "F1.4")
		"h2_tierra_tomas":
			_bloquear(m, g)
			g._medir_mega(m, "F2.2", "PE.PE")
			m.ejecutar("revisar_tomas")
			m.diagnosticar(g._opcion_correcta(m))
			m.ejecutar("secar_toma")
			g._medir_mega(m, "F2.2", "PE.PE")
		"h3_sobrecarga_cocina":
			_bloquear(m, g)
			_medir_ohm(m, "F3.2", "F3.4")
			m.ejecutar("revisar_cocina")
			m.diagnosticar(g._opcion_correcta(m))
			m.ejecutar("retirar_estufa")
			_medir_ohm(m, "F3.2", "F3.4")
	_energizar(m)
	return m


func test_las_misiones_estan_bien_formadas() -> String:
	var c := Contenido.new()
	var publicadas: Array = c.sistema(2)["modos"]["guardia"]["misiones"]
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
		if not m.datos["reporte"]["nota"].contains("verificar a bordo"):
			return "%s debe marcar sus valores típicos" % id
	return "; ".join(c.errores)


func test_las_tres_misiones_se_resuelven_con_tres_estrellas() -> String:
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


func test_h1_el_corto_dispara_al_rearmar_y_se_mide() -> String:
	var m := _mision("h1_corto_alumbrado")
	m.dar_aviso()
	m.avisar_energizado()
	m.accionar_aislador("F1", true)
	m.mesa.avanzar(2)
	var disparo: bool = m.mesa.sim.componente("F1").estado["disparado"]
	var g = G.new()
	_bloquear(m, g)
	var r := _medir_ohm(m, "F1.2", "F1.4")
	return A.primero([
		A.cierto(disparo, "F1 vuelve a disparar al rearmarlo"),
		A.cierto(float(r["valor"]) < 1.0, "casi 0 Ω entre las salidas de F1: %s" % r["valor"]),
	])


func test_h2_abrir_f2_iguala_las_lamparas_de_tierra() -> String:
	var m := _mision("h2_tierra_tomas")
	m.dar_aviso()
	var sim := m.mesa.sim
	sim.componente("ST").estado["presionado"] = true
	m.mesa.avanzar(3)
	var s_con_falla: float = sim.componente("HT2").estado["relacion"]
	var r_con_falla: float = sim.componente("HT1").estado["relacion"]
	m.accionar_aislador("F1", false)
	m.mesa.avanzar(3)
	var s_sin_f1: float = sim.componente("HT2").estado["relacion"]
	m.accionar_aislador("F2", false)
	m.mesa.avanzar(3)
	var s_sin_f2: float = sim.componente("HT2").estado["relacion"]
	var r_sin_f2: float = sim.componente("HT1").estado["relacion"]
	return A.primero([
		A.cierto(s_con_falla < 0.3 and r_con_falla > 0.8, "con TEST pulsado, S casi apagada y R brillante: %s / %s" % [s_con_falla, r_con_falla]),
		A.cierto(s_sin_f1 < 0.3, "abrir F1 no cambia nada"),
		A.cierto(absf(s_sin_f2 - r_sin_f2) < 0.1, "abrir F2 iguala las lámparas: %s / %s" % [s_sin_f2, r_sin_f2]),
	])


func test_h3_sin_reparar_la_prueba_falla_por_el_termico() -> String:
	var g = G.new()
	var m := _mision("h3_sobrecarga_cocina")
	m.dar_aviso()
	m.avisar_energizado()
	m.accionar_aislador("F3", true)
	m.mesa.avanzar(2)
	var aviso: Dictionary = g._observar(m, m.tiempo_de_prueba())
	return A.primero([
		A.cierto(not m.prueba_ok, "con la estufa conectada la prueba no pasa"),
		A.cierto(m.mesa.sim.componente("F3").estado["disparado"], "F3 dispara por el térmico durante la observación"),
		A.cierto(String(aviso.get("texto", "")).contains("F3"), "el aviso lo dice: %s" % aviso.get("texto", "")),
	])
