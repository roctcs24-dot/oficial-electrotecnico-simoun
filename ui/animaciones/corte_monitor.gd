extends Animacion
## Monitor de aislamiento sobre la simulación (circuito monitor_red): inyecta una pequeña
## corriente continua entre la red aislada y el casco; solo vuelve a través de los defectos de
## aislamiento, y con ella mide la resistencia de toda la red contra el casco. Por debajo del
## umbral da la alarma, que queda retenida hasta pulsar RESET. TEST simula una falla.

const ANCHO := 408.0
const ALTO := 320.0
const INYECCION := Color("1f8fb0")
## La barra va de 10 kΩ a 1000 MΩ en escala logarítmica: exponente de 10 en MΩ.
const EXP_MIN := -2.0
const EXP_MAX := 3.0
const R_TEST_MOHM := 0.1

var sim: SimSimulacion
var aislamiento_mohm := 50.0
var prueba := false
var lectura := 999.0
var alarma := false
var _espera := 0.0
var _valor: Label
var _nota: Label
var _test: Button


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	aislamiento_mohm = float(params.get("aislamiento_mohm", 50.0))
	sim = contenido.circuito("monitor_red")
	var c := tarjeta_mandos()
	_valor = fila_valor(c, "Aislamiento del consumidor")
	barra(c, EXP_MIN, EXP_MAX, 0.05, log(aislamiento_mohm) / log(10.0), func(v: float) -> void: poner_aislamiento(pow(10.0, v)))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_test = boton_mando(fila, func() -> void: pulsar_test(not prueba))
	boton_mando(fila, reset).text = "RESET"
	_nota = nota_mandos(c)
	_medir()


func umbral() -> float:
	return float(sim.componente("MA").params["alarma_mohm"])


func poner_aislamiento(mohm: float) -> void:
	aislamiento_mohm = mohm
	_medir()


func pulsar_test(pulsado: bool) -> void:
	prueba = pulsado
	_medir()


## La alarma queda retenida: solo se borra si el aislamiento ya está bien.
func reset() -> void:
	_medir()
	alarma = lectura < umbral()
	_actualizar_textos()


func _medir() -> void:
	var c: SimConsumidor = sim.componente("C1")
	var r := R_TEST_MOHM if prueba else aislamiento_mohm
	c.params["fuga_ohm"] = r * 1e6
	lectura = (sim.componente("MA") as SimMonitorAislamiento).medir()
	if lectura < umbral():
		alarma = true
	_actualizar_textos()


## 1 aislamiento bueno, 2 bajando (menos de 10 veces el umbral), 3 alarma.
func fase() -> int:
	if alarma:
		return 3
	return 2 if lectura < umbral() * 10.0 else 1


func _actualizar_textos() -> void:
	if _valor == null:
		return
	_valor.text = _texto_mohm(aislamiento_mohm)
	_test.text = "Soltar TEST" if prueba else "Pulsar TEST"
	if prueba:
		_nota.text = "TEST simula una falla de %s: debe dar la alarma aquí y en el sistema de alarmas." % _texto_mohm(R_TEST_MOHM)
	elif alarma and lectura >= umbral():
		_nota.text = "El aislamiento ya está bien, pero la alarma queda retenida: pulse RESET."
	elif alarma:
		_nota.text = "Alarma: la red tiene un defecto a masa por debajo de %s. Localícelo abriendo salidas una a una; la red sigue en servicio." % _texto_mohm(umbral())
	else:
		_nota.text = "Umbral de alarma: %s (valor típico — verificar a bordo). Baje el aislamiento para ver cómo cae la lectura." % _texto_mohm(umbral())


static func _texto_mohm(mohm: float) -> String:
	if mohm >= 999.0:
		return "más de 999 MΩ"
	if mohm < 1.0:
		return "%d kΩ" % roundi(mohm * 1000.0)
	return "%s MΩ" % coma(mohm, 1 if mohm < 10.0 else 0)


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(204, 14), "EL MONITOR MIDE LA RED CONTRA EL CASCO", 12, Color("5b6267"))
	# Barras de la red aislada.
	var colores := [Color("8a4b1c"), Color("20242a"), Color("8a949b")]
	for i in 3:
		var y := 40.0 + i * 18.0
		l.draw_line(Vector2(20, y), Vector2(250, y), colores[i], 5.0)
		texto(Vector2(12, y), "L%d" % (i + 1), 11, Tema.TINTA)
	# Consumidor entre L1 y L2 con su defecto a masa.
	l.draw_line(Vector2(70, 40), Vector2(70, 120), colores[0], 3.0)
	l.draw_line(Vector2(100, 58), Vector2(100, 120), colores[1], 3.0)
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 6, 0, 0, Color("5b6267")), Rect2(54, 120, 62, 44))
	texto(Vector2(85, 142), "Consumidor", 10, Tema.TINTA)
	var defecto := clampf(1.0 - (log(maxf(R_TEST_MOHM if prueba else aislamiento_mohm, 0.01)) / log(10.0) - EXP_MIN) / (EXP_MAX - EXP_MIN), 0.0, 1.0)
	var color_defecto := Color("8a949b").lerp(Color("e8462e"), defecto)
	l.draw_line(Vector2(85, 164), Vector2(85, 196), color_defecto, 3.0)
	l.draw_rect(Rect2(77, 196, 16, 36), Color("f1f2f0"))
	l.draw_rect(Rect2(77, 196, 16, 36), color_defecto, false, 2.0)
	texto(Vector2(132, 214), "defecto a masa", 10, Tema.TINTA, false)
	l.draw_line(Vector2(85, 232), Vector2(85, 262), color_defecto, 3.0)
	# Casco.
	l.draw_line(Vector2(20, 262), Vector2(388, 262), Color("5b6267"), 6.0)
	for k in 24:
		l.draw_line(Vector2(24 + k * 16, 266), Vector2(14 + k * 16, 278), Color("5b6267"), 1.5)
	texto(Vector2(204, 292), "Casco (masa)", 11, Tema.TINTA)
	# Monitor con su conexión a la red y al casco.
	var caja := Rect2(262, 70, 128, 150)
	l.draw_line(Vector2(250, 40), Vector2(300, 40), colores[0], 3.0)
	l.draw_line(Vector2(300, 40), Vector2(300, 70), colores[0], 3.0)
	l.draw_line(Vector2(352, 220), Vector2(352, 262), Color("2f6f4a"), 3.0)
	texto(Vector2(372, 242), "PE", 10, Color("2f6f4a"))
	# Corriente de medida: sale por la red, cruza el defecto y vuelve por el casco.
	var intensidad := clampf(defecto, 0.08, 1.0)
	var avance := fmod(t * 40.0, 16.0)
	_trazo(PackedVector2Array([Vector2(296, 70), Vector2(296, 46), Vector2(74, 46), Vector2(74, 124)]), avance, Color(INYECCION, intensidad))
	_trazo(PackedVector2Array([Vector2(89, 166), Vector2(89, 256), Vector2(348, 256), Vector2(348, 220)]), avance, Color(INYECCION, intensidad))
	l.draw_style_box(Tema.caja(Color("e9ebe8"), 8, 0, 0, Color("3b444b")), caja)
	texto(Vector2(326, 84), "MONITOR", 11, Tema.TINTA)
	# Escala analógica: ∞ a la izquierda, 0 a la derecha.
	var c := Vector2(326, 150)
	l.draw_arc(c, 46.0, PI * 1.15, PI * 1.85, 24, Tema.TINTA, 2.0, true)
	var frac := clampf(1.0 - (log(maxf(lectura, 0.01)) / log(10.0) - EXP_MIN) / (EXP_MAX - EXP_MIN), 0.0, 1.0)
	var a := lerpf(PI * 1.15, PI * 1.85, frac)
	l.draw_line(c, c + Vector2(cos(a), sin(a)) * 42.0, Color("c0392b"), 2.5, true)
	texto(c + Vector2(-46, -6), "∞", 12, Tema.TINTA)
	texto(c + Vector2(46, -6), "0", 12, Tema.TINTA)
	texto(Vector2(326, 166), _texto_mohm(lectura), 12, Tema.FALLO if lectura < umbral() else Tema.TINTA)
	l.draw_circle(Vector2(296, 196), 8.0, Color("3fbf5a"))
	texto(Vector2(296, 210), "ON", 9, Tema.TINTA)
	l.draw_circle(Vector2(356, 196), 8.0, Color("e8462e") if alarma else Color("5a1c1c"))
	texto(Vector2(356, 210), "ALARM", 9, Tema.TINTA)
	rotulo_estado(Vector2(326, 236), "ALARMA" if alarma else "AISLAMIENTO BUENO", Color("c0392b") if alarma else Tema.ACIERTO)
	l.draw_set_transform(Vector2.ZERO)


func _trazo(camino: PackedVector2Array, avance: float, color: Color) -> void:
	for k in range(camino.size() - 1):
		var a := camino[k]
		var b := camino[k + 1]
		var largo := a.distance_to(b)
		var s := avance - 16.0
		while s < largo:
			var s0 := maxf(s, 0.0)
			var s1 := minf(s + 8.0, largo)
			if s1 > s0:
				lienzo.draw_line(a.lerp(b, s0 / largo), a.lerp(b, s1 / largo), color, 2.5)
			s += 16.0
