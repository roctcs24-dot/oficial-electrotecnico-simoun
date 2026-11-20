extends RefCounted
## Código de colores de los cables (5.4.0): fases marrón, negro y gris; neutro azul claro; tierra
## verde-amarillo; mando en alterna rojo; continua azul oscuro y su 0 V con raya blanca; los hilos
## propios del sensor; el naranja que fija el tablero; la ficha del hilo y la leyenda en Datos.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_colores.json"


func _mesa_libre() -> Array:
	var m := MesaTaller.new(Contenido.new())
	var ids := {}
	for k: String in ["fuente_trifasica", "guardamotor", "motor_380", "masa", "fuente_dc", "sensor_pnp", "plc",
			"rele_110", "interruptor_automatico", "consumidor_alumbrado", "transformador_230", "pulsador_na", "contactor", "rele_control_fases"]:
		ids[k] = m.agregar(k, Vector2(ids.size() * 400.0, 0.0))
	return [m, ids]


func _de(m: MesaTaller, a: String, b: String) -> String:
	m.conectar(a, b)
	return m.conductor_cable(m.sim.cables.size() - 1)


func test_conductor_segun_sus_bornes() -> String:
	var r := _mesa_libre()
	var m: MesaTaller = r[0]
	var id: Dictionary = r[1]
	var casos := [
		[id["fuente_trifasica"] + ".L1", id["guardamotor"] + ".1", "L1"],
		[id["guardamotor"] + ".4", id["contactor"] + ".3", "L2"],
		[id["contactor"] + ".6", id["motor_380"] + ".W1", "L3"],
		[id["fuente_trifasica"] + ".L2", id["rele_control_fases"] + ".L2", "L2"],
		[id["motor_380"] + ".U2", id["contactor"] + ".2", "L1"],
		[id["consumidor_alumbrado"] + ".PE", id["masa"] + ".PE", "PE"],
		[id["interruptor_automatico"] + ".2", id["consumidor_alumbrado"] + ".A", "L1"],
		[id["interruptor_automatico"] + ".4", id["consumidor_alumbrado"] + ".B", "L2"],
		[id["transformador_230"] + ".X1", id["fuente_dc"] + ".L", "CA"],
		[id["transformador_230"] + ".X2", id["fuente_dc"] + ".N", "N"],
		[id["pulsador_na"] + ".14", id["contactor"] + ".A1", "CA"],
		[id["fuente_dc"] + ".+", id["plc"] + ".L+", "CC"],
		[id["fuente_dc"] + ".-", id["plc"] + ".M", "0V"],
		[id["sensor_pnp"] + ".BN", id["plc"] + ".I0.1", "BN"],
		[id["sensor_pnp"] + ".BK", id["plc"] + ".I0.0", "BK"],
		[id["sensor_pnp"] + ".BU", id["fuente_dc"] + ".-", "BU"],
		[id["plc"] + ".Q0.0", id["rele_110"] + ".A1", "CA"],
	]
	var fallos: Array[String] = []
	for c: Array in casos:
		var obtenido := _de(m, c[0], c[1])
		if obtenido != c[2]:
			fallos.append("%s–%s: %s y no %s" % [c[0], c[1], obtenido, c[2]])
	return "; ".join(fallos)


func test_rayas_del_pe_y_del_0v() -> String:
	var r := _mesa_libre()
	var m: MesaTaller = r[0]
	var id: Dictionary = r[1]
	_de(m, id["consumidor_alumbrado"] + ".PE", id["masa"] + ".PE")
	_de(m, id["fuente_dc"] + ".-", id["plc"] + ".M")
	_de(m, id["fuente_dc"] + ".+", id["plc"] + ".L+")
	return A.primero([
		A.cierto(m.color_cable(0) == MesaTaller.CONDUCTORES["PE"]["color"] and m.raya_cable(0) == MesaTaller.CONDUCTORES["PE"]["raya"], "el PE es amarillo con raya verde"),
		A.cierto(m.raya_cable(1).is_equal_approx(Color("e2e5e0")), "el 0 V lleva raya blanca"),
		A.cierto(m.raya_cable(2).a == 0.0, "el +24 V no lleva raya"),
		A.cierto(m.cable_de_potencia(0) and not m.cable_de_potencia(2), "el PE lleva puntera de potencia y el +24 V de mando"),
	])


func test_el_tablero_fija_el_naranja() -> String:
	var c := Contenido.new()
	var t := c.tablero("bombas_mp")
	var m := MesaTaller.new(c)
	m.cargar_circuito(c.circuito_datos(t["circuito"]), t["interior"])
	var i := -1
	for k in m.sim.cables.size():
		if m.sim.cables[k] == ["SM1.14", "KA1.A1"]:
			i = k
	var antes := m.conductor_cable(i)
	m.colores = {"KA1.A1": "naranja"}
	var por_nodo := m.conductor_cable(i)
	var mismos_puntos := m.cables_del_hilo(i).all(func(k: int) -> bool: return m.conductor_cable(k) == "EXT")
	m.colores = {m.numero_hilo(i): "naranja"}
	var por_numero := m.conductor_cable(i)
	m.colores = {"KA1.A1": "magenta"}
	var desconocido := m.conductor_cable(i)
	return A.primero([
		A.cierto(antes == "CA", "sin fijar, el mando del tablero es rojo: %s" % antes),
		A.cierto(por_nodo == "EXT" and mismos_puntos, "fijado por un nodo, todo el punto va en naranja"),
		A.cierto(por_numero == "EXT", "también se fija por el número de hilo"),
		A.cierto(desconocido == "CA", "un color que no existe se ignora"),
	])


func test_todos_los_tableros_tienen_colores_validos() -> String:
	var c := Contenido.new()
	var fallos: Array[String] = []
	for archivo: String in DirAccess.get_files_at("res://data/tableros"):
		var t := c.tablero(archivo.get_basename())
		var m := MesaTaller.new(c)
		m.cargar_circuito(c.circuito_datos(t["circuito"]), t["interior"])
		m.hilos = t.get("hilos", {})
		m.colores = t.get("colores", {})
		var hay_fase := false
		for i in m.sim.cables.size():
			var k := m.conductor_cable(i)
			if not MesaTaller.CONDUCTORES.has(k):
				fallos.append("%s: conductor %s" % [archivo, k])
			hay_fase = hay_fase or k in ["L1", "L2", "L3"]
		if not hay_fase:
			fallos.append("%s: ningún cable de fase" % archivo)
	return "; ".join(fallos.slice(0, 5))


func _raiz(tam: Vector2i) -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.set_anchors_preset(Control.PRESET_TOP_LEFT)
	raiz.size = Vector2(tam)
	raiz._al_cambiar_tamano()
	raiz.reconstruir()
	return raiz


func test_ficha_del_hilo_y_leyenda_en_datos() -> String:
	var fallos: Array[String] = []
	for tam in [Vector2i(960, 432), Vector2i(432, 960)]:
		var raiz := _raiz(tam)
		raiz.ir_a("tablero", {"tablero": "bombas_mp"})
		raiz.pantalla_actual()._alternar_puerta()
		var p = raiz.pantalla_actual()
		var i := -1
		for k in p.mesa.sim.cables.size():
			if p.mesa.conductor_cable(k) == "L1":
				i = k
				break
		p.marcar_hilo(i)
		p = raiz.pantalla_actual()
		if p.find_child("Conductor_L1", true, false) == null:
			fallos.append("%s: la ficha del hilo muestra su conductor" % str(tam))
		p._elegir_pestana("datos")
		p = raiz.pantalla_actual()
		for k: String in MesaTaller.LEYENDA_CONDUCTORES:
			var fila: Control = p.find_child("Conductor_%s" % k, true, false)
			if fila == null:
				fallos.append("%s: falta %s en la leyenda" % [str(tam), k])
			elif fila.get_combined_minimum_size().x > float(tam.x):
				fallos.append("%s: la fila %s no cabe" % [str(tam), k])
		raiz.free()
	return "; ".join(fallos)
