extends Animacion
## Rectificador de un cargador de 24 V AC, 50 Hz, visto en un osciloscopio: media onda con un
## diodo, puente de cuatro diodos y puente con condensador de filtro. La carga toma 1 A y el
## condensador es de 4700 µF (valores típicos — verificar a bordo).
## Pico: V × √2 menos 0,7 V por diodo en el camino (uno en media onda, dos en el puente).
## Rizado con filtro: ΔV = I ÷ (f_rizado × C), con f_rizado = 100 Hz en el puente.

const ANCHO := 420.0
const ALTO := 230.0
const V_AC := 24.0
const F_RED := 50.0
const I_CARGA := 1.0
const C_FILTRO := 4700e-6
const DIODO := 0.7
const MODOS := ["media", "puente", "filtro"]
const NOMBRES := {"media": "Media onda", "puente": "Puente", "filtro": "Con filtro"}

var modo := "filtro"
var _botones: Array[Button] = []
var _media: Label
var _rizado: Label
var _nota: Label


static func pico(v_ac: float, diodos: int) -> float:
	return v_ac * sqrt(2.0) - DIODO * diodos


## Rizado pico a pico con condensador.
static func rizado_filtro(i: float, f_rizado: float, c: float) -> float:
	return i / (f_rizado * c)


## Tensión media en la carga y rizado pico a pico de cada montaje.
static func lectura(m: String) -> Array[float]:
	match m:
		"media":
			var vp1 := pico(V_AC, 1)
			return [vp1 / PI, vp1]
		"puente":
			var vp2 := pico(V_AC, 2)
			return [2.0 * vp2 / PI, vp2]
	var vp := pico(V_AC, 2)
	var dv := rizado_filtro(I_CARGA, 2.0 * F_RED, C_FILTRO)
	return [vp - dv / 2.0, dv]


## Tensión con filtro en la fase x (en ciclos de la red): la onda del puente o, entre picos, la
## descarga en recta del condensador desde el último pico (dv por cada medio ciclo).
static func filtrada(x: float, vp: float, dv: float) -> float:
	var u := fposmod(2.0 * x, 1.0)
	var onda := sin(PI * u) * vp
	var desde_pico := u - 0.5 if u >= 0.5 else u + 0.5
	return maxf(onda, vp - dv * desde_pico)


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	for m: String in MODOS:
		var b := boton_mando(fila, poner_modo.bind(m))
		b.text = NOMBRES[m]
		_botones.append(b)
	_media = fila_valor(c, "Tensión media en la carga")
	_rizado = fila_valor(c, "Rizado (pico a pico)")
	_nota = nota_mandos(c)
	_actualizar()


func poner_modo(m: String) -> void:
	modo = m
	_actualizar()


func _actualizar() -> void:
	if _nota == null:
		return
	for k in MODOS.size():
		_botones[k].modulate = Color(1, 1, 1, 1.0 if MODOS[k] == modo else 0.55)
	var r := lectura(modo)
	_media.text = "%s V" % coma(r[0])
	_rizado.text = "%s V" % coma(r[1])
	match modo:
		"media":
			_nota.text = "Un solo diodo deja pasar medio ciclo: la carga recibe pulsos separados."
		"puente":
			_nota.text = "El puente da la vuelta al semiciclo negativo: dos pulsos por ciclo, pero la tensión sigue bajando a cero."
		_:
			_nota.text = "El condensador se carga en cada pico y alimenta la carga entre picos. Si se seca, vuelve el rizado."


## Tensión de la salida en la fase x (en ciclos de la red), según el montaje.
func salida_en(x: float) -> float:
	var s := sin(x * TAU)
	match modo:
		"media":
			return maxf(s, 0.0) * pico(V_AC, 1)
		"puente":
			return absf(s) * pico(V_AC, 2)
	return filtrada(x, pico(V_AC, 2), rizado_filtro(I_CARGA, 2.0 * F_RED, C_FILTRO))


func dibujar() -> void:
	diseno(ANCHO, ALTO)
	var l := lienzo
	var pantalla := Rect2(8, 8, 404, 214)
	l.draw_style_box(Tema.caja(Color("06140d"), 8, 0, 0, Color("1b2833")), pantalla)
	for i in range(1, 10):
		var x := pantalla.position.x + pantalla.size.x * i / 10.0
		l.draw_line(Vector2(x, pantalla.position.y), Vector2(x, pantalla.end.y), Color("1d3b2a"), 1.6 if i == 5 else 0.8)
	for i in range(1, 8):
		var y := pantalla.position.y + pantalla.size.y * i / 8.0
		l.draw_line(Vector2(pantalla.position.x, y), Vector2(pantalla.end.x, y), Color("1d3b2a"), 1.6 if i == 4 else 0.8)
	texto(Vector2(16, 22), "10 V/div · 5 ms/div", 11, Color("7dffab"), false)
	texto_derecha(Vector2(404, 22), "— entrada AC", 11, Color("ffc23a"))
	var cero := pantalla.position.y + pantalla.size.y * 0.5
	# 10 V por división (8 divisiones en el alto de la pantalla).
	var k := pantalla.size.y / 8.0 / 10.0
	var ciclos := 2.5
	var desplazamiento := fmod(t * 0.4, 1.0)
	var entrada := PackedVector2Array()
	var salida := PackedVector2Array()
	for i in 301:
		var x := float(i) / 300.0 * ciclos
		var px := pantalla.position.x + 4.0 + (pantalla.size.x - 8.0) * float(i) / 300.0
		var fase := x + desplazamiento
		entrada.append(Vector2(px, cero - sin(fase * TAU) * V_AC * sqrt(2.0) * k))
		salida.append(Vector2(px, cero - salida_en(fase) * k))
	for i in range(0, entrada.size() - 1, 2):
		l.draw_line(entrada[i], entrada[i + 1], Color(1.0, 0.76, 0.23, 0.6), 1.5)
	l.draw_polyline(salida, Color(0.27, 1.0, 0.51, 0.35), 6.0, true)
	l.draw_polyline(salida, Color("7dffab"), 2.4, true)
	l.draw_line(Vector2(pantalla.position.x, cero), Vector2(pantalla.end.x, cero), Color(0.49, 1.0, 0.67, 0.35), 1.0)
	texto(Vector2(16, cero - 8), "0 V", 10, Color("7dffab"), false)
	l.draw_set_transform(Vector2.ZERO)
