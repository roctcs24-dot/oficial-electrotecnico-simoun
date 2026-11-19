extends Animacion
## Acumulador de vejiga cortado: la vejiga lleva nitrógeno a la presión de precarga; al entrar
## aceite, el gas se comprime (Boyle: p·V constante, en presiones absolutas) y guarda energía.
## Con la bomba parada sigue habiendo presión: hay que descargarlo antes de abrir el circuito.
## Parámetros: "volumen" (L), "precarga" (bar), "p_max" (bar), "caudal" de la bomba (L/min).

const ANCHO := 420.0
const ALTO := 220.0

var volumen := 10.0
var precarga := 90.0
var p_max := 160.0
var caudal := 20.0
var perdida_gas := false
## Litros de aceite dentro.
var aceite := 0.0
## "carga", "consumo", "descarga" o "".
var accion := ""
var _botones := {}
var _presion: Label
var _volumen: Label
var _util: Label
var _boton_gas: Button


func preparar() -> void:
	volumen = float(params.get("volumen", volumen))
	precarga = float(params.get("precarga", precarga))
	p_max = float(params.get("p_max", p_max))
	caudal = float(params.get("caudal", caudal))
	lienzo.custom_minimum_size.y = ALTO
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	for clave in ["carga", "consumo", "descarga"]:
		_botones[clave] = boton_mando(fila, _pulsar.bind(clave))
	_presion = fila_valor(c, "Manómetro del aceite")
	_volumen = fila_valor(c, "Aceite dentro")
	_util = fila_valor(c, "Volumen útil entre 100 y %d bar" % roundi(p_max))
	_boton_gas = boton_mando(c, func() -> void:
		perdida_gas = not perdida_gas
		aceite = minf(aceite, volumen * 0.95)
		_actualizar())
	_actualizar()


func _pulsar(clave: String) -> void:
	accion = "" if accion == clave else clave
	_actualizar()


## Precarga real del gas (bar).
func gas() -> float:
	return precarga * (0.3 if perdida_gas else 1.0)


## Presión del aceite (bar) con «litros» de aceite dentro.
func presion(litros: float) -> float:
	if litros <= 0.0:
		return 0.0
	return (gas() + 1.0) * volumen / maxf(volumen - litros, 0.05) - 1.0


## Litros de aceite dentro a una presión dada.
func litros_a(p: float) -> float:
	if p <= gas():
		return 0.0
	return volumen * (1.0 - (gas() + 1.0) / (p + 1.0))


func _actualizar() -> void:
	_botones["carga"].text = "Bomba en marcha" if accion != "carga" else "Parar la bomba"
	_botones["consumo"].text = "Mover el cilindro" if accion != "consumo" else "Parar el cilindro"
	_botones["descarga"].text = "Abrir la descarga" if accion != "descarga" else "Cerrar la descarga"
	_boton_gas.text = "Recargar el nitrógeno" if perdida_gas else "Perder nitrógeno (vejiga con fuga)"
	var util := SimHidraulica.acumulador({"acumulador": {"volumen": volumen, "precarga": precarga, "perdida_gas": 0.7 if perdida_gas else 0.0, "p_max": p_max}})
	_util.text = "%s L" % coma(util["volumen_util"], 1)


func fase() -> int:
	if aceite <= 0.01:
		return 1
	return 3 if accion == "descarga" else 2


func _process(delta: float) -> void:
	match accion:
		"carga":
			aceite = minf(aceite + caudal / 60.0 * delta * 2.0, litros_a(p_max))
		"consumo":
			aceite = maxf(aceite - 12.0 / 60.0 * delta * 2.0, 0.0)
		"descarga":
			aceite = maxf(aceite - 30.0 / 60.0 * delta * 2.0, 0.0)
	if _presion != null:
		_presion.text = "%d bar" % roundi(presion(aceite))
		_volumen.text = "%s L" % coma(aceite, 1)
	super(delta)


func dibujar() -> void:
	diseno(ANCHO, ALTO)
	var l := lienzo
	var fuente := get_theme_default_font()
	DibujoAri.degradado(l, Rect2(0, 0, ANCHO, ALTO), 10.0, DibujoHidraulico.FONDO)
	# Botella cortada.
	var botella := Rect2(150, 18, 92, 170)
	DibujoHidraulico.pieza(l, botella.grow(6.0), 40.0, DibujoHidraulico.PINTURA)
	DibujoAri.relleno(l, botella, 36.0, Color("1a1f24"))
	var lleno := clampf(aceite / volumen, 0.0, 0.97)
	var alto_aceite := botella.size.y * lleno
	# Aceite abajo y vejiga de gas arriba, que se encoge.
	if alto_aceite > 0.5:
		DibujoAri.degradado(l, Rect2(botella.position.x, botella.end.y - alto_aceite, botella.size.x, alto_aceite), 30.0, [Color("f0c15a"), DibujoHidraulico.ACEITE, Color("8a5a12")])
	var vejiga := Rect2(botella.position.x + 6, botella.position.y + 6, botella.size.x - 12, botella.size.y - alto_aceite - 10)
	if vejiga.size.y > 4.0:
		DibujoAri.degradado(l, vejiga, 30.0, [Color("ffe08a"), Color("d9b24a"), Color("8a6a1a")])
		texto(vejiga.get_center(), "N₂", 16, Color("3a2a00"))
		texto(vejiga.get_center() + Vector2(0, 18), "%d bar" % roundi(maxf(presion(aceite), gas())), 11, Color("3a2a00"))
	# Válvula de gas arriba y conexión de aceite abajo.
	DibujoHidraulico.pieza(l, Rect2(botella.get_center().x - 9, 4, 18, 14), 3.0)
	DibujoHidraulico.pieza(l, Rect2(botella.get_center().x - 12, botella.end.y + 6, 24, 12), 3.0)
	var hay_caudal := accion != "" and (accion == "carga" or aceite > 0.0)
	var papel := "presion" if accion == "carga" else ("retorno" if accion == "descarga" and aceite > 0.0 else ("trabajo" if accion == "consumo" and aceite > 0.0 else ""))
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(196, 200), Vector2(196, 208), Vector2(330, 208), Vector2(330, 150)]), papel, t * 40.0 * (1.0 if accion == "carga" else -1.0) if hay_caudal else -1.0)
	DibujoHidraulico.tubo(l, PackedVector2Array([Vector2(196, 208), Vector2(60, 208), Vector2(60, 150)]), "presion" if accion == "carga" else "", t * 40.0 if accion == "carga" else -1.0)
	DibujoHidraulico.bomba(l, Vector2(60, 128), t * 6.0 if accion == "carga" else 0.0, 0.8)
	DibujoHidraulico.manometro(l, fuente, Vector2(330, 120), 26.0, presion(aceite), 250.0)
	texto(Vector2(60, 98), "bomba", 10, Color("cfd8df"))
	texto(Vector2(84, 40), "precarga %d bar" % roundi(gas()), 11, Color("ffd08a"))
	if accion != "carga" and presion(aceite) > 5.0:
		DibujoHidraulico.rotulo(l, fuente, Vector2(330, 172), "BOMBA PARADA Y CON PRESIÓN", 10, Color("ff7a5a"))
