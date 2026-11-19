extends RefCounted
## Cables con aspecto real (5.3.0): salen rectos del borne alejándose del aparato, los ordenados
## doblan con esquinas redondeadas (o en S si casi no hay desvío) y el cuerpo del cable se recorta
## donde van la puntera y su cuello.

const A := preload("res://tests/ayuda_sim.gd")


func _mesa_bombas() -> MesaTaller:
	var c := Contenido.new()
	var t := c.tablero("bombas_mp")
	var m := MesaTaller.new(c)
	m.cargar_circuito(c.circuito_datos(t["circuito"]), t["interior"])
	return m


func _cable(m: MesaTaller, a: String, b: String) -> int:
	for i in m.sim.cables.size():
		if m.sim.cables[i] == [a, b]:
			return i
	return -1


func test_el_cable_sale_del_borne_alejandose_del_aparato() -> String:
	var m := _mesa_bombas()
	return A.primero([
		A.cierto(m.salida_borne("KA1.A1") == Vector2.UP, "A1, arriba del relé, sale hacia arriba: %s" % m.salida_borne("KA1.A1")),
		A.cierto(m.salida_borne("KA1.14") == Vector2.DOWN, "14, abajo del relé, sale hacia abajo: %s" % m.salida_borne("KA1.14")),
	])


func test_tramo_recto_a_la_salida_de_cada_borne() -> String:
	var m := _mesa_bombas()
	var fallos: Array[String] = []
	for i in m.sim.cables.size():
		var p := m.puntos_cable(i)
		for extremo in 2:
			var nodo: String = m.sim.cables[i][extremo]
			var borne := p[0] if extremo == 0 else p[-1]
			var siguiente := p[1] if extremo == 0 else p[-2]
			var dir := (siguiente - borne).normalized()
			if borne.distance_to(siguiente) > 1.0 and dir.dot(m.salida_borne(nodo)) < 0.999:
				fallos.append("%s: sale torcido (%s)" % [nodo, dir])
	return "; ".join(fallos.slice(0, 4))


func test_ordenados_sin_esquinas_vivas() -> String:
	var m := _mesa_bombas()
	m.ordenar_cables()
	var vista := VistaMesa.new()
	vista.mesa = m
	var peor := 0.0
	var en := ""
	for i in m.sim.cables.size():
		var p := vista.trazado_cable(i)
		for k in range(1, p.size() - 1):
			var a := p[k] - p[k - 1]
			var b := p[k + 1] - p[k]
			if a.length() < 0.01 or b.length() < 0.01:
				continue
			var giro := absf(a.angle_to(b))
			if giro > peor:
				peor = giro
				en = str(m.sim.cables[i])
	vista.free()
	return A.cierto(rad_to_deg(peor) < 31.0, "el giro más brusco es de %.0f° en %s" % [rad_to_deg(peor), en])


func test_desvio_en_s_cuando_casi_estan_alineados() -> String:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(0, 100), Vector2(10, 100), Vector2(10, 200)])
	var r := VistaMesa.redondear(p, 12.0)
	var m := _mesa_bombas()
	var vista := VistaMesa.new()
	vista.mesa = m
	# Un cable ordenado entre dos bornes casi alineados: se corre SM1 hasta 10 de KA1.A1.
	var i := _cable(m, "SM1.14", "KA1.A1")
	var corrimiento := m.posicion_borne("KA1.A1").x + 10.0 - m.posicion_borne("SM1.14").x
	m.mover("SM1", m.posicion_pieza("SM1") + Vector2(corrimiento, 0.0))
	m.fijar_estilo_cable(i, "angulos")
	var s := vista.trazado_cable(i)
	vista.free()
	var x_min := INF
	var x_max := -INF
	for q in s:
		x_min = minf(x_min, q.x)
		x_max = maxf(x_max, q.x)
	return A.primero([
		A.cierto(r[0] == p[0] and r[-1] == p[-1], "el redondeo conserva los extremos"),
		A.cierto(s.size() == 11, "el desvío corto se dibuja en S: %d puntos" % s.size()),
		A.cierto(x_max - x_min <= absf(m.posicion_borne("SM1.14").x - m.posicion_borne("KA1.A1").x) + 0.01, "la S no se sale del desvío"),
	])


func test_el_cuerpo_se_recorta_para_la_puntera() -> String:
	var p := PackedVector2Array([Vector2(0, 0), Vector2(0, 100), Vector2(100, 100)])
	var r := VistaMesa._recortar(p, VistaMesa.RECORTE_CABLE)
	var largo := VistaMesa._largo(r)
	return A.primero([
		A.cerca(largo, 200.0 - 2.0 * VistaMesa.RECORTE_CABLE, 0.01, "el cable pierde la puntera en cada extremo"),
		A.cierto(r[0] == Vector2(0, VistaMesa.RECORTE_CABLE), "empieza donde acaba el cuello: %s" % r[0]),
		A.cierto(r[-1] == Vector2(100.0 - VistaMesa.RECORTE_CABLE, 100), "y termina igual en el otro extremo: %s" % r[-1]),
	])
