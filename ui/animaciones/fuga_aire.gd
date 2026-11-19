extends Animacion
## Fuga de aire comprimido: un agujero en la red de 7 bar sopla un chorro que no se ve pero se
## oye. Se mueve el diámetro equivalente del agujero y se ven el caudal perdido, la potencia del
## compresor que se gasta en él y la energía de un año entero, con SimNeumatica.red.
## Parámetros: "diametro" (mm), "presion" (bar).

const ANCHO := 440.0
const ALTO := 200.0

var diametro := 1.0
var presion := 7.0
var resultado := {}
var _caudal: Label
var _potencia: Label
var _anual: Label


func preparar() -> void:
	diametro = float(params.get("diametro", diametro))
	presion = float(params.get("presion", presion))
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var v := fila_valor(c, "Agujero equivalente")
	barra(c, 0.0, 6.0, 0.5, diametro, func(n: float) -> void:
		diametro = n
		v.text = "%s mm" % coma(n, 1))
	v.text = "%s mm" % coma(diametro, 1)
	_caudal = fila_valor(c, "Aire perdido")
	_potencia = fila_valor(c, "Compresor gastado en la fuga")
	_anual = fila_valor(c, "En un año, día y noche")


func resolver() -> Dictionary:
	resultado = SimNeumatica.red({"red": {"presion": presion}, "fuga": {"diametro": diametro}})
	return resultado


func fase() -> int:
	if diametro < 0.5:
		return 1
	return 2 if diametro < 3.0 else 3


func _process(delta: float) -> void:
	resolver()
	if _caudal != null:
		_caudal.text = "%d NL/min" % roundi(resultado.get("fuga_Q", 0.0))
		_potencia.text = "%s kW" % coma(resultado.get("fuga_kW", 0.0), 1)
		_anual.text = "%d kWh" % roundi(float(resultado.get("fuga_kW", 0.0)) * 8760.0)
	super(delta)


func dibujar() -> void:
	diseno(ANCHO, ALTO)
	var l := lienzo
	var fuente := get_theme_default_font()
	DibujoAri.degradado(l, Rect2(0, 0, ANCHO, ALTO), 10.0, DibujoNeumatico.FONDO)
	# Tubería de la red con un racor flojo en el centro.
	DibujoNeumatico.tubo(l, PackedVector2Array([Vector2(10, 120), Vector2(430, 120)]), "presion", t * 30.0, 14.0)
	var racor := Rect2(190, 104, 60, 32)
	DibujoHidraulico.pieza(l, racor, 4.0)
	DibujoNeumatico.manometro(l, fuente, Vector2(70, 70), 20.0, presion, 10.0)
	l.draw_line(Vector2(70, 92), Vector2(70, 112), Color("aab4bb"), 4.0)
	# El chorro: conos que se abren y se desvanecen, más grandes cuanto mayor el agujero.
	var fuerza := clampf(diametro / 6.0, 0.0, 1.0)
	if diametro > 0.0:
		for k in 6:
			var fase := fposmod(t * 2.2 + k / 6.0, 1.0)
			var p := Vector2(220, 104) + Vector2(0, -fase * (30.0 + 60.0 * fuerza))
			l.draw_circle(p, 3.0 + fase * (6.0 + 18.0 * fuerza), Color(1, 1, 1, 0.4 * (1.0 - fase)))
		# Ondas de sonido: la fuga se oye.
		for k in 3:
			var radio := 20.0 + fposmod(t * 30.0 + k * 14.0, 42.0)
			l.draw_arc(Vector2(220, 100), radio, -PI * 0.85, -PI * 0.15, 16, Color(1, 0.85, 0.5, 0.35 * (1.0 - (radio - 20.0) / 42.0)), 1.5, true)
	DibujoHidraulico.rotulo(l, fuente, Vector2(330, 60), "%d NL/min · %s kW" % [roundi(resultado.get("fuga_Q", 0.0)), coma(resultado.get("fuga_kW", 0.0), 1)], 11, Color("ffd08a"))
	texto(Vector2(220, 160), "agujero de %s mm" % coma(diametro, 1), 10, Color("cfd8df"))
	texto(Vector2(330, 178), "valores típicos — verificar a bordo", 9, Color("8a96a0"))
