extends Animacion
## Bornera de la salida de un motor de 15 kW. Se elige el estado del borne 2 (apretado, flojo o
## suelto) y la corriente del motor: un borne flojo de 0,05 Ω deja caer tensión y se calienta con
## P = I² × R, como en la simulación (bornera_servicio). Suelto, el motor queda en dos fases.

const ANCHO := 400.0
const ALTO := 280.0
const R_FLOJO := 0.05
const AMBIENTE := 35.0
## Grados por vatio del borne: valor de enseñanza.
const GRADOS_POR_W := 1.5
const ESTADOS := ["apretado", "flojo", "suelto"]

var estado_borne := "apretado"
var corriente := 24.0
var _botones: Array[Button] = []
var _caida: Label
var _calor: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	for e: String in ESTADOS:
		var b := boton_mando(fila, poner.bind(e))
		b.text = e.capitalize()
		_botones.append(b)
	var i := fila_valor(c, "Corriente del motor")
	i.text = "%d A" % roundi(corriente)
	barra(c, 5.0, 30.0, 1.0, corriente, func(v: float) -> void:
		corriente = v
		i.text = "%d A" % roundi(v)
		_actualizar())
	_caida = fila_valor(c, "Caída en el borne 2")
	_calor = fila_valor(c, "Calor / temperatura")
	_nota = nota_mandos(c)
	_actualizar()


func poner(e: String) -> void:
	estado_borne = e
	_actualizar()


func caida() -> float:
	match estado_borne:
		"flojo":
			return corriente * R_FLOJO
		"suelto":
			return 330.0
	return corriente * 0.001


func calor() -> float:
	return corriente * corriente * R_FLOJO if estado_borne == "flojo" else 0.0


func temperatura() -> float:
	return AMBIENTE + calor() * GRADOS_POR_W


## 1 apretado, 2 flojo, 3 suelto.
func fase() -> int:
	return ESTADOS.find(estado_borne) + 1


func _actualizar() -> void:
	if _nota == null:
		return
	for k in _botones.size():
		_botones[k].modulate = Color(1, 1, 1, 1.0 if ESTADOS[k] == estado_borne else 0.6)
	_caida.text = "%s V" % coma(caida(), 2 if caida() < 1.0 else 1)
	_calor.text = "%d W / %d °C" % [roundi(calor()), roundi(temperatura())]
	match estado_borne:
		"apretado":
			_nota.text = "Apretado al par: casi 0 Ω, la caída es de milivoltios y el borne está a la temperatura del tablero."
		"flojo":
			_nota.text = "Flojo: %s V de caída y %d W de calor en un punto pequeño. El plástico se oscurece y el borne acaba quemado." % [coma(caida()), roundi(calor())]
		_:
			_nota.text = "Suelto: la fase 2 no llega al motor. Gira en dos fases, zumba, la corriente sube y dispara el térmico."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "BORNERA DE SALIDA AL MOTOR", 12, Color("5b6267"))
	l.draw_rect(Rect2(40, 118, 320, 34), Color("b8bec2"))
	var colores := [Color("8a4b1f"), Color("1a1a1a"), Color("8a8f93")]
	for k in 3:
		var x := 110.0 + k * 90.0
		var es_2 := k == 1
		var tono := Color("9aa1a6")
		if es_2 and estado_borne == "flojo":
			tono = tono.lerp(Color("e05a2b"), clampf((temperatura() - AMBIENTE) / 60.0, 0.0, 1.0) * (0.7 + 0.3 * sin(t * 4.0)))
		l.draw_style_box(Tema.caja(tono, 6, 0, 0, Color("5b6267")), Rect2(x - 30, 40, 60, 190))
		l.draw_rect(Rect2(x - 20, 118, 40, 34), Color("f4f5f2"))
		texto(Vector2(x, 135), str(k + 1), 16, Tema.TINTA)
		l.draw_circle(Vector2(x, 70), 12.0, Color("d9dcde"))
		l.draw_circle(Vector2(x, 200), 12.0, Color("d9dcde"))
		var suelto_aqui := es_2 and estado_borne == "suelto"
		l.draw_line(Vector2(x, 20), Vector2(x, 62), colores[k], 7.0)
		if suelto_aqui:
			l.draw_line(Vector2(x + 26, 200), Vector2(x + 30, 262), Tema.TINTA, 7.0)
		else:
			l.draw_line(Vector2(x, 208), Vector2(x, 262), Tema.TINTA, 7.0)
		var giro := 0.25 if es_2 and estado_borne != "apretado" else 0.0
		for y in [70.0, 200.0]:
			var a := giro * TAU + (0.0 if y == 70.0 else 0.0)
			l.draw_line(Vector2(x, y) - Vector2(cos(a), sin(a)) * 8.0, Vector2(x, y) + Vector2(cos(a), sin(a)) * 8.0, Tema.TINTA, 3.0)
	texto(Vector2(372, 70), "A", 13, Tema.TINTA)
	texto(Vector2(372, 200), "B", 13, Tema.TINTA)
	var rotulo := "APRETADO" if fase() == 1 else ("FLOJO: %d °C" % roundi(temperatura()) if fase() == 2 else "SUELTO: MOTOR EN DOS FASES")
	rotulo_estado(Vector2(200, 270), rotulo, Tema.ACIERTO if fase() == 1 else (Tema.ACENTO_FUERTE if fase() == 2 else Tema.FALLO))
	l.draw_set_transform(Vector2.ZERO)
