extends RefCounted
## Etiquetado de los hilos de los tableros, por potencial: mismo número en un mismo punto
## eléctrico, nombres de fases, motor y tierra, números del tablero que mandan, marcadores en la
## mesa, ficha del hilo tocado y tabla de hilos.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_hilos.json"


func _raiz(tam := Vector2i(960, 432)) -> Raiz:
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


func _mesa(c: Contenido, tablero: String) -> MesaTaller:
	var t := c.tablero(tablero)
	var m := MesaTaller.new(c)
	m.cargar_circuito(c.circuito_datos(t["circuito"]), t["interior"])
	m.hilos = t.get("hilos", {})
	return m


func _cable(m: MesaTaller, a: String, b: String) -> int:
	for i in m.sim.cables.size():
		if m.sim.cables[i] == [a, b]:
			return i
	return -1


## Puntos eléctricos por unión de cables, para comprobar la numeración por otro camino.
func _redes(m: MesaTaller) -> Array:
	var red := {}
	var siguiente := 0
	for c: Array in m.sim.cables:
		var a: int = red.get(c[0], -1)
		var b: int = red.get(c[1], -1)
		if a < 0 and b < 0:
			red[c[0]] = siguiente
			red[c[1]] = siguiente
			siguiente += 1
		elif a < 0:
			red[c[0]] = b
		elif b < 0:
			red[c[1]] = a
		elif a != b:
			for n: String in red:
				if red[n] == b:
					red[n] = a
	var por_cable := []
	for c: Array in m.sim.cables:
		por_cable.append(red[c[0]])
	return por_cable


func test_nombres_del_tablero_de_bombas() -> String:
	var m := _mesa(Contenido.new(), "bombas_mp")
	var n := func(a: String, b: String) -> String: return m.numero_hilo(_cable(m, a, b))
	return A.primero([
		A.cierto(n.call("B.L1", "Q0.1") == "L1" and n.call("B.L3", "Q0.5") == "L3", "la alimentación lleva L1, L2 y L3"),
		A.cierto(n.call("ST.14", "PE.PE") == "PE", "la tierra lleva PE"),
		A.cierto(n.call("Q1.2", "AS1.1") == "1L1" and n.call("Q1.6", "AS1.5") == "1L3", "tras el guardamotor Q1: 1L1 a 1L3"),
		A.cierto(n.call("AS1.2", "M1.U1") == "1U1" and n.call("M1.U1", "M1.W2") == "1U1", "al motor M1 y su puente: 1U1"),
		A.cierto(n.call("AS2.2", "M2.U1") == "2U1", "el motor M2 lleva 2U1"),
		A.cierto(n.call("SM1.14", "KA1.A1") == n.call("KA1.14", "KA1.A1") and n.call("SM1.14", "KA1.A1") != n.call("KA1.A2", "F0.4"), "mando: mismo punto, mismo número; otro punto, otro"),
	])


func test_numeracion_por_potencial_en_todos_los_tableros() -> String:
	var c := Contenido.new()
	var fallos: Array[String] = []
	for archivo: String in DirAccess.get_files_at("res://data/tableros"):
		if not archivo.ends_with(".json"):
			continue
		var id := archivo.get_basename()
		var m := _mesa(c, id)
		var redes := _redes(m)
		var nombre_de_red := {}
		var red_de_nombre := {}
		for i in m.sim.cables.size():
			var numero := m.numero_hilo(i)
			if numero.is_empty():
				fallos.append("%s: cable %d sin número" % [id, i])
				continue
			if nombre_de_red.has(redes[i]) and nombre_de_red[redes[i]] != numero:
				fallos.append("%s: un mismo punto con dos números (%s y %s)" % [id, nombre_de_red[redes[i]], numero])
			nombre_de_red[redes[i]] = numero
			if red_de_nombre.has(numero) and red_de_nombre[numero] != redes[i]:
				fallos.append("%s: el número %s está en dos puntos distintos" % [id, numero])
			red_de_nombre[numero] = redes[i]
	return "; ".join(fallos.slice(0, 6))


func test_los_numeros_del_tablero_mandan() -> String:
	var m := _mesa(Contenido.new(), "bombas_mp")
	m.hilos = {"SM1.14": "21"}
	var a := m.numero_hilo(_cable(m, "SM1.14", "KA1.A1"))
	var b := m.numero_hilo(_cable(m, "KA1.14", "KA1.A1"))
	var otro := m.numero_hilo(_cable(m, "KA1.A2", "F0.4"))
	return A.primero([
		A.cierto(a == "21" and b == "21", "todo el punto toma el número del tablero: %s, %s" % [a, b]),
		A.cierto(otro != "21", "los demás no: %s" % otro),
	])


func test_ficha_tabla_y_etiquetas_en_el_tablero() -> String:
	var fallos: Array[String] = []
	for tam in [Vector2i(960, 432), Vector2i(432, 960)]:
		var raiz := _raiz(tam)
		raiz.ir_a("tablero", {"tablero": "bombas_mp"})
		raiz.pantalla_actual()._alternar_puerta()
		var p = raiz.pantalla_actual()
		var i := _cable(p.mesa, "SM1.14", "KA1.A1")
		p.marcar_hilo(i)
		p = raiz.pantalla_actual()
		var texto := ""
		for e: Label in p.find_children("*", "Label", true, false):
			texto += e.text + "\n"
		if not texto.contains("Hilo %s" % p.mesa.numero_hilo(i)) or not texto.contains("SM1:14") or not texto.contains("KA1:A1"):
			fallos.append("%s: la ficha del hilo no dice su número y sus extremos" % str(tam))
		if p.vista.cable_marcado != i:
			fallos.append("%s: el hilo de la tabla queda marcado en la mesa" % str(tam))
		var boton: Button = p.find_child("BotonEtiquetas", true, false)
		var barra := boton.get_parent() as Control
		if barra.get_combined_minimum_size().x > float(tam.x) - 40.0:
			fallos.append("%s: la barra de la mesa no cabe (%s)" % [str(tam), barra.get_combined_minimum_size().x])
		p.alternar_etiquetas()
		p = raiz.pantalla_actual()
		if p.vista.etiquetas:
			fallos.append("%s: el botón apaga las etiquetas" % str(tam))
		p._elegir_pestana("datos")
		p = raiz.pantalla_actual()
		if p.find_child("Hilo_L1", true, false) == null or p.find_child("Hilo_1U1", true, false) == null:
			fallos.append("%s: la tabla de hilos en Datos" % str(tam))
		raiz.free()
	return "; ".join(fallos)


func test_hilo_en_el_taller_libre() -> String:
	var raiz := _raiz()
	raiz.ir_a("taller")
	var p = raiz.pantalla_actual()
	var mesa: MesaTaller = p.mesa
	var hay_cable := mesa.sim.cables.size() > 0
	var texto := ""
	if hay_cable:
		p.marcar_hilo(0)
		for e: Label in raiz.pantalla_actual().find_children("*", "Label", true, false):
			texto += e.text + "\n"
	raiz.free()
	if not hay_cable:
		return ""
	return A.primero([
		A.cierto(texto.contains("Hilo "), "el Taller muestra el número del hilo tocado"),
		A.cierto(not texto.contains("esquema del tablero"), "en el Taller libre no se habla del esquema del tablero"),
	])
