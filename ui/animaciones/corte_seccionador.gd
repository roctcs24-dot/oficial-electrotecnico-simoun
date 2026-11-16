extends Animacion
## Corte de un interruptor seccionador de tres polos con SimSeccionador: el mando gira los
## puentes de doble ruptura; en 0 queda una separación visible. El 13-14 abre antes que los
## polos para soltar el mando. En 0 se puede poner el candado, y con él no se puede cerrar.
## Las entradas 1, 3 y 5 siguen con tensión aunque esté en 0.

const ANCHO := 408.0
const ALTO := 320.0
const POLOS := [50.0, 130.0, 210.0]
const VIVO := Color("e8462e")

var q: SimSeccionador
## 0 abierto, 1 cerrado: giro de los puentes.
var giro := 0.0
var _aviso := 0.0
var _mando: Button
var _candado: Button
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	q = SimSeccionador.new("Q0")
	q.estado["cerrado"] = bool(params.get("cerrado", true))
	giro = 1.0 if q.cerrado() else 0.0
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_mando = boton_mando(fila, func() -> void: accionar(not q.cerrado()))
	_candado = boton_mando(fila, func() -> void: poner_candado(not q.estado["candado"]))
	_nota = nota_mandos(c)
	_actualizar_textos()


func accionar(cerrar: bool) -> bool:
	var hecho := q.accionar(cerrar)
	if not hecho:
		_aviso = 2.5
	_actualizar_textos()
	return hecho


func poner_candado(poner: bool) -> bool:
	var hecho := q.poner_candado(poner)
	if not hecho:
		_aviso = 2.5
	_actualizar_textos()
	return hecho


## 1 en servicio, 2 abierto sin bloquear, 3 abierto con candado.
func fase() -> int:
	if q.cerrado():
		return 1
	return 3 if q.estado["candado"] else 2


func _process(delta: float) -> void:
	giro = move_toward(giro, 1.0 if q.cerrado() else 0.0, delta * 3.0)
	if _aviso > 0.0:
		_aviso -= delta
		if _aviso <= 0.0:
			_actualizar_textos()
	super(delta)


func _actualizar_textos() -> void:
	if _mando == null:
		return
	_mando.text = "Girar a 0 (abrir)" if q.cerrado() else "Girar a I (cerrar)"
	_candado.text = "Quitar candado y tarjeta" if q.estado["candado"] else "Poner candado y tarjeta"
	if _aviso > 0.0:
		_nota.text = "No se puede: con el candado puesto no gira a I, y el candado solo entra en 0." if q.estado["candado"] else "El candado solo entra con el mando en 0 (abierto)."
	elif q.cerrado():
		_nota.text = "En I: los puentes unen 1-2, 3-4 y 5-6 y el tablero recibe la red."
	elif q.estado["candado"]:
		_nota.text = "Bloqueado en 0 con su candado y tarjeta. Aun así, verifique la ausencia de tensión aguas abajo antes de tocar."
	else:
		_nota.text = "En 0 los polos están separados, pero 1, 3 y 5 siguen con tensión. Ponga el candado para trabajar."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(204, 14), "CORTE DEL INTERRUPTOR SECCIONADOR", 12, Color("5b6267"))
	var arriba := ["1", "3", "5"]
	var abajo := ["2", "4", "6"]
	# El 13-14 abre antes que los polos: va un poco por delante en el giro.
	var aux_cerrado := giro > 0.75
	for i in 3:
		var x: float = POLOS[i]
		# Entradas: siempre con tensión.
		l.draw_line(Vector2(x, 34), Vector2(x, 96), VIVO, 6.0)
		texto(Vector2(x - 16, 44), arriba[i], 12, Tema.TINTA)
		# Salidas: con tensión solo si el polo está cerrado.
		var salida := VIVO if giro > 0.98 else Color("6e7a83")
		l.draw_line(Vector2(x, 184), Vector2(x, 250), salida, 6.0)
		texto(Vector2(x - 16, 246), abajo[i], 12, Tema.TINTA)
		# Contactos fijos.
		l.draw_rect(Rect2(x - 10, 96, 20, 6), Color("d8a24a"))
		l.draw_rect(Rect2(x - 10, 178, 20, 6), Color("d8a24a"))
		# Puente giratorio de doble ruptura: vertical cerrado, horizontal abierto.
		var centro := Vector2(x, 140)
		# Abierto queda inclinado: se ven los tres puentes separados de sus contactos.
		var angulo := lerpf(PI * 0.4, 0.0, giro)
		var d := Vector2(sin(angulo), cos(angulo)) * 38.0
		l.draw_line(centro - d, centro + d, Color("b26a1e"), 8.0, true)
		l.draw_circle(centro, 7.0, Color("3b444b"))
	# Eje común.
	l.draw_line(Vector2(28, 140), Vector2(234, 140), Color("8a949b", 0.6), 3.0)
	texto(Vector2(130, 270), "Entradas 1-3-5 siempre con tensión", 11, VIVO)
	texto(Vector2(130, 288), "Salidas 2-4-6 con tensión solo en I", 11, Color("5b6267"))
	# Auxiliar 13-14.
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 8, 0, 0, Color("5b6267")), Rect2(256, 34, 142, 70))
	texto(Vector2(266, 52), "13-14 (abre antes)", 11, Tema.TINTA, false)
	l.draw_line(Vector2(266, 80), Vector2(292, 80), Tema.TINTA, 3.0)
	l.draw_line(Vector2(318, 80), Vector2(356, 80), Tema.TINTA, 3.0)
	l.draw_line(Vector2(292, 80), Vector2(320, 80) if aux_cerrado else Vector2(316, 68), Tema.TINTA, 3.0, true)
	texto(Vector2(266, 96), "cerrado" if aux_cerrado else "abierto: el mando suelta", 10, Tema.ACIERTO if aux_cerrado else Tema.FALLO, false)
	# Mando rotativo con su candado.
	var c := Vector2(327, 176)
	l.draw_circle(c, 40.0, Color("c0392b"))
	l.draw_circle(c, 30.0, Color("e2a52a"))
	var a := lerpf(-PI / 2.0, 0.0, giro)
	l.draw_line(c - Vector2(cos(a), sin(a)) * 26.0, c + Vector2(cos(a), sin(a)) * 26.0, Color("8a1d12"), 12.0, true)
	texto(c + Vector2(-50, -36), "0", 14, Tema.TINTA)
	texto(c + Vector2(50, -36), "I", 14, Tema.TINTA)
	if q.estado["candado"]:
		l.draw_arc(c + Vector2(0, 46), 9.0, PI, TAU, 12, Color("3b444b"), 4.0, true)
		l.draw_rect(Rect2(c.x - 13, c.y + 46, 26, 22), Color("e2b23a"))
		l.draw_rect(Rect2(c.x + 16, c.y + 46, 44, 30), Color("c0392b"))
		texto(Vector2(c.x + 38, c.y + 56), "NO", 10, Color.WHITE)
		texto(Vector2(c.x + 38, c.y + 68), "OPERAR", 8, Color.WHITE)
	var rotulo := "EN SERVICIO (I)" if q.cerrado() else ("BLOQUEADO EN 0" if q.estado["candado"] else "ABIERTO (0)")
	rotulo_estado(Vector2(327, 300), rotulo, Tema.ACIERTO if q.cerrado() else (Color("c0392b") if q.estado["candado"] else Color("5b6267")))
	l.draw_set_transform(Vector2.ZERO)
