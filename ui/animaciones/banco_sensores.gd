extends Animacion
## Banco de sensores: un PNP en I0.0 y un NPN en I0.1 de un PLC. Se acerca una pieza metálica y
## se cambia el tipo de entradas, con el común 1M al − (PNP) o al + (NPN). Se ve qué LED se
## enciende en cada sensor y en el PLC, y la tensión de cada salida.

const MARRON := Color("8a5a2b")
const AZUL := Color("2a5fb0")
const NEGRO := Color("1b1c1d")
const AMBAR := Color("ffb020")
const VERDE := Color("2fbf5a")

var sim: SimSimulacion
var _boton_pieza: Button
var _boton_entradas: Button


func preparar() -> void:
	lienzo.custom_minimum_size.y = 270.0
	sim = contenido.circuito(params.get("circuito", "banco_sensores"))
	sim.avanzar_tiempo(0.2)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	add_child(fila)
	_boton_pieza = _boton(alternar_pieza)
	fila.add_child(_boton_pieza)
	_boton_entradas = _boton(alternar_entradas)
	fila.add_child(_boton_entradas)
	_actualizar_botones()


func _boton(accion: Callable) -> Button:
	var b := Button.new()
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.y = 48.0
	b.pressed.connect(accion)
	return b


func pieza_delante() -> bool:
	return sim.componente("B1").estado["objeto"]


func plc() -> SimPLC:
	return sim.componente("PLC") as SimPLC


func alternar_pieza() -> void:
	var delante := not pieza_delante()
	for id in ["B1", "B2"]:
		sim.componente(id).estado["objeto"] = delante
	sim.avanzar_tiempo(0.2)
	_actualizar_botones()


## Cambia el tipo de entradas y lleva el común 1M al polo que le corresponde.
func alternar_entradas() -> void:
	var a_npn: bool = plc().params["entradas"] == "pnp"
	plc().params["entradas"] = "npn" if a_npn else "pnp"
	sim.desconectar("PLC.1M", "G1.-" if a_npn else "G1.+")
	sim.conectar("PLC.1M", "G1.+" if a_npn else "G1.-")
	sim.avanzar_tiempo(0.2)
	_actualizar_botones()


func _actualizar_botones() -> void:
	_boton_pieza.text = "Retirar la pieza metálica" if pieza_delante() else "Acercar una pieza metálica"
	var tipo: String = plc().params["entradas"]
	_boton_entradas.text = "Entradas PNP, 1M al −: cambiar a NPN" if tipo == "pnp" else "Entradas NPN, 1M al +: cambiar a PNP"


func _process(delta: float) -> void:
	super(delta)
	if sim != null:
		sim.paso()


func dibujar() -> void:
	fondo()
	var w := lienzo.size.x
	var arriba := 30.0
	var abajo := 252.0
	var ancho_plc := clampf(w * 0.32, 120.0, 180.0)
	var x_plc := w - ancho_plc - 12.0
	# Fuente y barras de + y −.
	lienzo.draw_rect(Rect2(12.0, 22.0, 56.0, 238.0), Color("c9cdcf"))
	lienzo.draw_rect(Rect2(12.0, 22.0, 56.0, 238.0), Color("6c7276"), false, 1.5)
	texto(Vector2(40.0, 132.0), "24 V", 14)
	texto(Vector2(40.0, 150.0), "DC", 12)
	lienzo.draw_line(Vector2(68.0, arriba), Vector2(x_plc + ancho_plc * 0.5, arriba), MARRON, 3.0)
	lienzo.draw_line(Vector2(68.0, abajo), Vector2(x_plc + ancho_plc * 0.5, abajo), AZUL, 3.0)
	texto(Vector2(80.0, arriba + 12.0), "+", 16, MARRON)
	texto(Vector2(80.0, abajo - 12.0), "−", 18, AZUL)
	# PLC con sus entradas y el común.
	var r_plc := Rect2(x_plc, 60.0, ancho_plc, 170.0)
	lienzo.draw_rect(r_plc, Color("dfe2e1"))
	lienzo.draw_rect(r_plc, Color("6c7276"), false, 1.5)
	texto(Vector2(r_plc.get_center().x, r_plc.position.y + 14.0), "PLC", 14)
	texto(Vector2(r_plc.get_center().x, r_plc.position.y + 32.0), "entradas %s" % plc().params["entradas"].to_upper(), 12)
	var sensores := [["B1", "PNP", "I0.0"], ["B2", "NPN", "I0.1"]]
	# Los dos sensores, uno encima del otro, entre la fuente y el PLC.
	var xs := 68.0 + (x_plc - 68.0) * 0.45
	for i in 2:
		var s: SimSensorProximidad = sim.componente(sensores[i][0])
		var y := 104.0 + 80.0 * i
		_sensor(Vector2(xs, y), s, sensores[i][1])
		var cola := xs + 50.0
		var x_bn := cola + 10.0 + 14.0 * i
		var x_bu := cola + 38.0 + 14.0 * i
		lienzo.draw_polyline(PackedVector2Array([Vector2(cola, y - 6.0), Vector2(x_bn, y - 6.0), Vector2(x_bn, arriba)]), MARRON, 2.5)
		lienzo.draw_polyline(PackedVector2Array([Vector2(cola, y + 6.0), Vector2(x_bu, y + 6.0), Vector2(x_bu, abajo)]), AZUL, 2.5)
		lienzo.draw_line(Vector2(cola, y), Vector2(x_plc, y), NEGRO, 2.5)
		var activa := plc().entrada_activa(i)
		lienzo.draw_circle(Vector2(x_plc + 14.0, y), 6.0, VERDE if activa else VERDE.darkened(0.7))
		texto(Vector2(x_plc + 26.0, y), "%s %s" % [sensores[i][2], "sí" if activa else "no"], 12, Tema.TINTA, false)
		var v := s.tension_dc(sim.solucion, "BK", "BU")
		texto(Vector2(xs - 6.0, y + 30.0), "BK–BU %s V" % TextoTecnico.numero(v, 1), 12)
	# Común 1M al − o al +.
	var a_menos: bool = plc().params["entradas"] == "pnp"
	var x_com := x_plc + ancho_plc * 0.5
	lienzo.draw_line(Vector2(x_com, r_plc.end.y if a_menos else r_plc.position.y), Vector2(x_com, abajo if a_menos else arriba), AZUL if a_menos else MARRON, 2.5)
	texto(Vector2(x_com + 18.0, r_plc.end.y - 10.0 if a_menos else r_plc.position.y + 50.0), "1M", 12)


func _sensor(p: Vector2, s: SimSensorProximidad, tipo: String) -> void:
	# Cuerpo roscado con la cara activa a la izquierda y el LED junto al cable.
	lienzo.draw_rect(Rect2(p + Vector2(-46.0, -14.0), Vector2(8.0, 28.0)), Color("3a6f9a"))
	lienzo.draw_rect(Rect2(p + Vector2(-38.0, -16.0), Vector2(70.0, 32.0)), Color("c9b47a"))
	for k in 7:
		lienzo.draw_line(p + Vector2(-32.0 + 9.0 * k, -15.0), p + Vector2(-35.0 + 9.0 * k, 15.0), Color("8d7a4c"), 1.5)
	lienzo.draw_rect(Rect2(p + Vector2(32.0, -12.0), Vector2(18.0, 24.0)), Color("2b2f32"))
	var activa: bool = s.estado["activa"]
	if activa:
		lienzo.draw_circle(p + Vector2(41.0, -18.0), 9.0, Color(AMBAR, 0.3))
	lienzo.draw_circle(p + Vector2(41.0, -18.0), 5.0, AMBAR if activa else AMBAR.darkened(0.7))
	texto(p + Vector2(-4.0, -30.0), "%s %s" % [s.id, tipo], 13)
	if s.estado["objeto"]:
		# La pieza metálica frente a la cara activa.
		lienzo.draw_rect(Rect2(p + Vector2(-70.0, -18.0), Vector2(16.0, 36.0)), Color("8e9496"))
		lienzo.draw_rect(Rect2(p + Vector2(-70.0, -18.0), Vector2(16.0, 36.0)), Color("4f5559"), false, 1.5)
