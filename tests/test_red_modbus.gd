extends RefCounted
## Red Modbus RTU del puesto de alarmas: terminadores, direcciones, velocidad, polaridad,
## cortes, ruido, sistema de alarmas y pantalla local.

const A := preload("res://tests/ayuda_sim.gd")


func _red(averias: Array = []) -> SimRedModbus:
	var red := Contenido.new().red("sala_maquinas")
	var datos: Dictionary = Contenido.new().leer("redes/sala_maquinas.json")
	for id: String in averias:
		for a: Dictionary in datos["averias"]:
			if a["id"] == id:
				for op: Dictionary in a["ops"]:
					red.aplicar(op)
	return red


func _estado(red: SimRedModbus, id: String) -> String:
	return red.estado_de(id)["estado"]


func test_red_sana_todos_comunican() -> String:
	var red := _red()
	red.ciclos(20)
	var todos := true
	for s: Dictionary in red.sondeo:
		if s["estado"] != "ok" or int(s["correctas"]) != 20:
			todos = false
	return A.primero([
		A.cierto(todos, "con la red bien hecha, las 7 direcciones contestan siempre"),
		A.cerca(red.valor(11, 5), 96.0, 2.0, "el maestro lee la temperatura de descarga del MYCOM nº 3"),
		A.cerca(red.valor(1, 0), 84.0, 1.0, "y la del estator del GEN 1, con un decimal"),
		A.cerca(red.ciclo_s, 1.0, 0.9, "una vuelta a la tabla de sondeo tarda menos de 2 s"),
	])


func test_resistencia_entre_a_y_b() -> String:
	var red := _red()
	var dos := red.resistencia_a_b()
	red.ajustar("ES1", "terminacion", false)
	var uno := red.resistencia_a_b()
	red.ajustar("PA", "terminacion", false)
	var ninguno := red.resistencia_a_b()
	return A.primero([
		A.cerca(dos, 57.0, 3.0, "con los dos terminadores, unos 60 Ω"),
		A.cerca(uno, 109.0, 6.0, "con uno solo, unos 120 Ω"),
		A.cierto(ninguno > 1000.0, "sin terminadores, solo los transceptores: más de 1 kΩ"),
	])


func test_sin_terminador_da_errores_intermitentes() -> String:
	var red := _red(["sin_terminador"])
	red.ciclos(40)
	var crc := 0
	var correctas := 0
	for s: Dictionary in red.sondeo:
		crc += int(s["crc"])
		correctas += int(s["correctas"])
	return A.primero([
		A.cierto(red.probabilidad_error() > 0.2, "sin terminador en un extremo, las reflexiones deforman tramas"),
		A.cierto(crc > 20 and correctas > crc, "hay errores de CRC, pero la mayoría de las tramas llegan"),
		A.cierto(_estado(red, "ES1") != "falla" or _estado(red, "AX1") != "falla", "no se cae toda la red"),
	])


func test_direccion_duplicada() -> String:
	var red := _red(["direccion_duplicada"])
	red.ciclos(5)
	var my3 := red.estado_de("MY3")
	var my4 := red.estado_de("MY4")
	return A.primero([
		A.cierto(int(my3["crc"]) == 5 and my3["estado"] == "falla", "los dos MYCOM contestan a la vez a la 11: tramas con el CRC mal"),
		A.cierto(int(my4["sin_respuesta"]) == 5 and my4["estado"] == "falla", "nadie contesta a la 12"),
		A.cierto(_estado(red, "AX1") == "ok", "los demás equipos siguen bien"),
	])


func test_velocidad_polaridad_alimentacion_y_corte() -> String:
	var red := _red(["velocidad_ax2", "invertido_ax3", "sin_alimentacion_es1"])
	red.ciclos(4)
	var r2 := _red(["corte_my4"])
	r2.ciclos(4)
	return A.primero([
		A.cierto(_estado(red, "AX2") == "falla" and int(red.estado_de("AX2")["sin_respuesta"]) == 4, "otra velocidad: el esclavo no entiende y no contesta"),
		A.cierto(_estado(red, "AX3") == "falla", "con A y B invertidos tampoco"),
		A.cierto(_estado(red, "ES1") == "falla", "ni el módulo sin alimentación"),
		A.cierto(_estado(red, "AX1") == "ok" and _estado(red, "MY3") == "ok", "los demás contestan"),
		A.cierto(int(r2.estado_de("MY3")["correctas"]) > 0 and _estado(r2, "MY4") == "falla" and _estado(r2, "ES1") == "falla", "un corte deja sin comunicación a todos los que están detrás"),
		A.cierto(r2.probabilidad_error() > 0.2, "y el tramo que queda termina sin terminador: reflexiones"),
		A.cierto(r2.ciclo_s > red.ciclo_s * 0.5 and r2.ciclo_s > 0.6, "cada equipo que no contesta alarga el ciclo con el tiempo de espera"),
	])


func test_otro_equipo_en_la_direccion_da_excepcion() -> String:
	var red := _red()
	red.ajustar("MY4", "alimentado", false)
	red.ajustar("AX4", "direccion", 12)
	red.ciclos(4)
	return A.primero([
		A.cierto(int(red.estado_de("MY4")["excepciones"]) == 4, "el AX4 contesta en la 12, pero no tiene 7 registros: excepción 02"),
		A.cierto(_estado(red, "AX4") == "falla", "y su propia dirección, la 4, se queda sin respuesta"),
	])


func test_ciclo_de_una_alarma() -> String:
	var red := _red()
	var pa := SimSistemaAlarmas.desde_red(red)
	var paso := func(segundos: float) -> void:
		for _i in int(segundos / 0.5):
			red.avanzar(0.5)
			pa.actualizar(0.5)
	paso.call(5.0)
	var tranquilo := pa.activas() == 0 and not pa.bocina
	red.aplicar({"op": "valor", "equipo": "MY3", "registro": 5, "valor": 135.0})
	paso.call(2.0)
	var con_retardo := pa.estado("MY3-DT-alta") == "normal"
	paso.call(6.0)
	var activa := pa.estado("MY3-DT-alta") == "activa" and pa.bocina
	pa.silenciar()
	var silenciada := not pa.bocina and pa.estado("MY3-DT-alta") == "activa"
	pa.reconocer()
	var reconocida := pa.estado("MY3-DT-alta") == "reconocida"
	red.aplicar({"op": "valor", "equipo": "MY3", "registro": 5, "valor": 95.0})
	paso.call(3.0)
	return A.primero([
		A.cierto(tranquilo, "con todo normal no hay alarmas"),
		A.cierto(con_retardo, "la alarma espera su retardo de 5 s"),
		A.cierto(activa, "pasado el retardo, alarma activa y bocina"),
		A.cierto(silenciada, "silenciar apaga la bocina, pero no reconoce"),
		A.cierto(reconocida, "reconocer la deja fija"),
		A.cierto(pa.estado("MY3-DT-alta") == "normal", "al volver el valor, se borra"),
		A.cierto(pa.historial.size() == 3, "el historial guarda alarma, reconocida y normal"),
	])


func test_retorno_sin_reconocer_y_extension() -> String:
	var red := _red(["sentina"])
	var pa := SimSistemaAlarmas.desde_red(red)
	for _i in 30:
		red.avanzar(0.5)
		pa.actualizar(0.5)
	red.aplicar({"op": "valor", "equipo": "ES1", "registro": 0, "valor": 0})
	for _i in 4:
		red.avanzar(0.5)
		pa.actualizar(0.5)
	var retorno := pa.estado("LSH-SM-digital") == "retorno"
	red.aplicar({"op": "valor", "equipo": "ES1", "registro": 0, "valor": 1})
	for _i in 400:
		red.avanzar(0.5)
		pa.actualizar(0.5)
	return A.primero([
		A.cierto(retorno, "si la sentina se vacía antes de reconocer, queda en retorno"),
		A.cierto(pa.extension, "una alarma sin reconocer más de 3 minutos se extiende a los camarotes"),
	])


func test_falla_de_comunicacion_es_una_alarma_y_congela_los_valores() -> String:
	var red := _red(["corte_my4", "descarga_my3"])
	var pa := SimSistemaAlarmas.desde_red(red)
	for _i in 20:
		red.avanzar(0.5)
		pa.actualizar(0.5)
	return A.primero([
		A.cierto(pa.estado("MY4-COM") == "activa", "falla de comunicación con el MYCOM nº 4"),
		A.cierto(pa.estado("ES1-COM") == "activa", "y con el módulo de E/S, detrás del corte"),
		A.cierto(is_nan(red.valor(12, 5)), "sin comunicación, el maestro no da valores del MYCOM nº 4"),
		A.cierto(pa.estado("MY4-DT-alta") == "normal", "ni alarma de proceso falsa"),
	])


func test_pantalla_local_comunica_aunque_falle_la_red() -> String:
	var red := _red(["corte_my4", "sin_terminador"])
	var hmi := SimPantallaHMI.new(red)
	hmi.avanzar(3.0)
	var con_valores := not is_nan(hmi.valor(5))
	var rechazo := hmi.cambiar_ajuste("DT-alta", 1)
	hmi.nivel_tecnico = true
	var fuera := hmi.cambiar_ajuste("DT-alta", 3)
	var dentro := hmi.cambiar_ajuste("DT-alta", -1)
	red.aplicar({"op": "hmi", "valor": true})
	return A.primero([
		A.cierto(con_valores, "la pantalla Omron lee su controlador por su propio cable"),
		A.cierto(hmi.tendencia[0].size() == 4, "guarda una muestra al empezar y otra por segundo para la tendencia"),
		A.cierto(rechazo != "", "sin nivel de técnico no se cambian los ajustes"),
		A.cierto(fuera != "", "ni por encima del máximo que admite el equipo"),
		A.cierto(dentro == "" and is_equal_approx(hmi.alarmas.punto("DT-alta")["limite"], 125.0), "dentro de los límites, el nuevo valor pasa a la alarma local"),
		A.cierto(is_nan(hmi.valor(5)) and not hmi.comunica(), "con su cable suelto, la pantalla da ####"),
	])
