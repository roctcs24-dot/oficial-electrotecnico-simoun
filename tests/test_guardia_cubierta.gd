extends RefCounted
## Misiones de Guardia del sistema 5 en el mando del power block.

const A := preload("res://tests/ayuda_sim.gd")
const MISIONES := ["p1_power_block_no_vira", "p2_mando_se_apaga"]
const G := preload("res://tests/test_guardia_tableros.gd")
const D := preload("res://tests/test_guardia_distribucion.gd")


## Resuelve la misión como el jugador y la deja lista para la prueba en servicio.
func resolver(id: String) -> MisionGuardia:
	var g = G.new()
	var d = D.new()
	var m := MisionGuardia.new(Contenido.new(), id)
	var bobina := "Y1" if id == "p1_power_block_no_vira" else "Y2"
	m.datos["bloqueo"] = ["Q0"]
	d._bloquear(m, g)
	d._medir_ohm(m, "PB.%sA" % bobina, "PB.%sB" % bobina)
	m.diagnosticar(g._opcion_correcta(m))
	m.ejecutar("parar_central")
	m.ejecutar("cambiar_%s" % bobina.to_lower())
	d._medir_ohm(m, "PB.%sA" % bobina, "PB.%sB" % bobina)
	m.ejecutar("arrancar_central")
	d._energizar(m)
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
		g._observar(m, m.tiempo_de_prueba())
		if m.prueba_ok:
			return "%s: la prueba pasa sin reparar" % id
	return ""


func test_cambiar_la_bobina_sin_parar_la_central_no_se_puede() -> String:
	var g = G.new()
	var d = D.new()
	var m := MisionGuardia.new(Contenido.new(), "p1_power_block_no_vira")
	m.datos["bloqueo"] = ["Q0"]
	d._bloquear(m, g)
	var aviso := m.ejecutar("cambiar_y1")
	return A.primero([
		A.cierto(aviso["tipo"] == "aviso", "sin parar la central, la misión lo impide: %s" % aviso),
		A.cierto(m.mesa.sim.componente("PB").params["averia_y1"] == "abierta", "la bobina sigue cortada"),
	])
