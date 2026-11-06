extends RefCounted
## Pantalla de la planta de frío: mandos, lecturas, termómetro, presostatos y avisos sobre la
## simulación real.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_planta.json"


func _raiz(vertical := true, pestana := "esquema") -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.vertical = vertical
	raiz.ir_a("planta", {"id": 4, "pestana": pestana})
	return raiz


func _botones(nodo: Node, lista: Array[String]) -> void:
	if nodo is Button:
		lista.append(nodo.text)
	for hijo in nodo.get_children():
		_botones(hijo, lista)


## Cierra Q1 y mantiene pulsada la marcha, como el jugador.
func _arrancar(p) -> void:
	p._atender_orden(p.operador.alternar_guardamotor)
	p.sim.avanzar_tiempo(0.1)
	p._pulsar("S1", true)
	p.sim.avanzar_tiempo(0.3)
	p._pulsar("S1", false)
	p.sim.avanzar_tiempo(8.0)
	p._comprobar_firma()
	p._actualizar()


func test_el_sistema_4_abre_la_planta() -> String:
	var raiz := _raiz()
	raiz.volver()
	raiz.ir_a("sistema", {"id": 4})
	raiz.pantalla_actual()._abrir_modo("taller")
	var abierta: bool = raiz.pantalla_actual().get_script().resource_path.ends_with("planta.gd")
	raiz.free()
	return A.cierto(abierta, "el Taller del sistema 4 debe abrir la planta")


func test_arranca_el_compresor_desde_los_mandos() -> String:
	var raiz := _raiz(false, "mando")
	var p = raiz.pantalla_actual()
	var textos: Array[String] = []
	_botones(p, textos)
	_arrancar(p)
	var marcha: bool = p._luces["marcha"].encendida
	var corriente: float = p._instrumentos["corriente"].valor
	var gira: bool = p._esquema.en_marcha
	var descarga: float = p._instrumentos["descarga"].valor
	raiz.free()
	return A.primero([
		A.cierto(textos.has("Cerrar el guardamotor Q1") and textos.has("Marcha (S1): mantener"), "deben estar los mandos: %s" % str(textos)),
		A.cierto(marcha, "debe encenderse la luz de marcha"),
		A.cierto(corriente > 20.0, "el amperímetro del motor debe marcar: %.0f A" % corriente),
		A.cierto(gira, "el esquema debe mostrar el flujo"),
		A.cierto(descarga > 9.0, "el manómetro de descarga: %.1f bar" % descarga),
	])


func test_termometro_en_la_descarga() -> String:
	var raiz := _raiz(true, "esquema")
	var p = raiz.pantalla_actual()
	var vacio: String = p._textos["termometro"].text
	_arrancar(p)
	for _i in 60:
		p.sim.paso(1.0)
	p._medir_tuberia("descarga")
	var texto: String = p._textos["termometro"].text
	var marcado: String = p._esquema.punto_marcado
	var tc: float = p.operador.planta().temperatura("condensacion")
	var t_descarga: float = p.operador.planta().temperatura_tuberia("descarga")
	raiz.free()
	return A.primero([
		A.cierto(vacio.begins_with("Toque un punto"), "sin medir, debe explicar cómo: %s" % vacio),
		A.cierto(texto.begins_with("Descarga del compresor:") and texto.ends_with("°C"), "debe mostrar la lectura: %s" % texto),
		A.cierto(marcado == "descarga", "el esquema marca el punto medido"),
		A.cierto(t_descarga > tc + 20.0, "la descarga sale mucho más caliente que la condensación: %.0f y %.0f °C" % [t_descarga, tc]),
	])


func test_disparo_de_alta_se_explica_y_se_rearma() -> String:
	var raiz := _raiz(false, "mando")
	var p = raiz.pantalla_actual()
	_arrancar(p)
	p._atender_orden(p.operador.alternar_bomba.bind("bomba_agua_mar"))
	for _i in 90:
		p.sim.paso(1.0)
	p._revisar_eventos()
	p._comprobar_firma()
	p._actualizar()
	var aviso: String = p._avisos.get_child(0).get_meta("titulo", "") if p._avisos.get_child_count() > 0 else ""
	var luz: bool = p._luces["PA"].encendida
	var textos: Array[String] = []
	_botones(p, textos)
	var con_presion: Dictionary = p.operador.rearmar_presostato("PA")
	raiz.free()
	return A.primero([
		A.cierto(aviso == "Disparo por alta presión (PA)", "debe explicar el disparo: %s" % aviso),
		A.cierto(luz, "la luz del presostato de alta debe encenderse"),
		A.cierto(textos.has("Rearmar PA") and textos.has("Arrancar la bomba de agua de mar del condensador"), "debe ofrecer el rearme y la bomba: %s" % str(textos)),
		A.cierto(con_presion["titulo"] == "No rearma", "con la presión alta no rearma: %s" % str(con_presion)),
	])


func test_capacidad_en_manual() -> String:
	var raiz := _raiz(false, "mando")
	var p = raiz.pantalla_actual()
	var planta: SimPlantaFrio = p.operador.planta()
	var en_auto: Dictionary = p.operador.capacidad(1.0)
	p._atender_orden(p.operador.alternar_automatico)
	p._atender_orden(p.operador.capacidad.bind(1.0))
	var manual: float = planta.estado["capacidad_manual"]
	raiz.free()
	return A.primero([
		A.cierto(en_auto["titulo"] == "Corredera en automático", "en automático no se mueve a mano"),
		A.cierto(not planta.estado["automatico"], "debe pasar a manual"),
		A.cerca(manual, 0.2, 0.01, "un toque sube un 10 % sobre el mínimo"),
	])


func test_todos_los_eventos_de_la_planta_tienen_explicacion() -> String:
	var c := Contenido.new()
	var textos: Dictionary = c.leer("planta.json")["consecuencias"].duplicate()
	textos.merge(c.leer("taller.json")["consecuencias"])
	for e in ["disparo_presostato_descarga", "disparo_presostato_succion", "disparo_presostato_aceite", "valvula_seguridad", "alarma_nh3", "alarma_nh3_alta", "disparo_rele_termico", "disparo_magnetico", "disparo_termico", "motor_quemado"]:
		if not textos.has(e) or textos[e]["texto"].is_empty():
			return "falta explicar %s" % e
	for punto: String in SimPlantaFrio.TUBERIAS:
		if not c.leer("planta.json")["tuberias"].has(punto):
			return "falta el nombre de la tubería %s" % punto
	return ""


func test_recorre_pestanas_en_ambas_orientaciones() -> String:
	var raiz := _raiz()
	for vertical in [true, false]:
		raiz.vertical = vertical
		raiz.reconstruir()
		var p = raiz.pantalla_actual()
		for id in (["esquema", "mando", "ph", "seguridad"] if vertical else ["mando", "ph", "seguridad"]):
			p._elegir_pestana(id)
			p._actualizar()
	raiz.free()
	return ""


func test_conserva_la_simulacion_al_girar() -> String:
	var raiz := _raiz()
	var p = raiz.pantalla_actual()
	var sim: SimSimulacion = p.sim
	p._atender_orden(p.operador.alternar_guardamotor)
	raiz.vertical = not raiz.vertical
	raiz.reconstruir()
	var igual: bool = raiz.pantalla_actual().sim == sim
	raiz.free()
	return A.cierto(igual and (sim.componente("Q1") as SimGuardamotor).cerrado(), "girar el celular no debe perder la práctica")


func test_diagrama_ph() -> String:
	for t in range(-50, 61, 5):
		if DiagramaPH.h_liquido(t) >= DiagramaPH.h_vapor(t):
			return "a %d °C el líquido debe quedar a la izquierda del vapor" % t
	var d := DiagramaPH.new()
	d.actualizar(-17.0, 31.0, true)
	var bien := d.te == -17.0 and d.en_marcha
	d.free()
	return A.cierto(bien, "el diagrama debe recibir el estado")
