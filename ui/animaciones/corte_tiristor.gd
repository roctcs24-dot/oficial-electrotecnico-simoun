extends Animacion
## Tiristor que enclava una sirena de 24 V, como tiristor_servicio: un impulso en la puerta (S1) lo
## dispara y, al soltarlo, sigue conduciendo porque la corriente de la sirena (1 A) supera la de
## mantenimiento. S2, un pulsador NC en serie, corta la corriente y lo apaga.

const ANCHO := 400.0
const ALTO := 260.0
const IMPULSO_S := 0.6

var disparado := false
var cortando := false
var _puerta_s := 0.0
var _corte_s := 0.0
var _estado: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	boton_mando(fila, pulsar_puerta).text = "S1: impulso de puerta"
	boton_mando(fila, cortar).text = "S2: cortar la corriente"
	_estado = fila_valor(c, "Sirena")
	_nota = nota_mandos(c)
	_actualizar()


func pulsar_puerta() -> void:
	_puerta_s = IMPULSO_S
	if not cortando:
		disparado = true
	_actualizar()


func cortar() -> void:
	_corte_s = IMPULSO_S
	cortando = true
	disparado = false
	_actualizar()


func puerta_activa() -> bool:
	return _puerta_s > 0.0


func avanzar(dt: float) -> void:
	_puerta_s = maxf(_puerta_s - dt, 0.0)
	_corte_s = maxf(_corte_s - dt, 0.0)
	cortando = _corte_s > 0.0
	_actualizar()


## 1 bloqueando; 2 disparando con la puerta; 3 enclavado sin puerta.
func fase() -> int:
	if not disparado:
		return 1
	return 2 if puerta_activa() else 3


func _process(delta: float) -> void:
	avanzar(delta)
	super._process(delta)


func _actualizar() -> void:
	if _nota == null:
		return
	_estado.text = "SUENA" if disparado else "callada"
	if disparado and puerta_activa():
		_nota.text = "El impulso de puerta lo dispara: entre A y K queda 1 V y la sirena suena."
	elif disparado:
		_nota.text = "Sin puerta sigue conduciendo: 1 A de sirena supera su corriente de mantenimiento. Está enclavado."
	elif cortando:
		_nota.text = "S2 abre el circuito: la corriente cae a cero y el tiristor se apaga."
	else:
		_nota.text = "Con 24 V entre ánodo y cátodo, bloquea: sin impulso de puerta no conduce."


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(200, 12), "TIRISTOR QUE ENCLAVA UNA ALARMA", 12, Color("5b6267"))
	var tinta := Tema.TINTA
	var vivo := Tema.ACENTO_FUERTE
	var circula := disparado
	var color := vivo if circula else Color("8a949b")
	l.draw_line(Vector2(40, 30), Vector2(340, 30), Color("c0392b"), 3.0)
	texto(Vector2(30, 18), "+24 V", 10, tinta)
	# S2 (NC) y sirena.
	l.draw_line(Vector2(200, 30), Vector2(200, 50), Color("c0392b"), 3.0)
	if cortando:
		l.draw_line(Vector2(200, 70), Vector2(212, 52), tinta, 3.0)
	else:
		l.draw_line(Vector2(200, 70), Vector2(208, 50), tinta, 3.0)
		l.draw_line(Vector2(200, 50), Vector2(208, 50), tinta, 3.0)
	texto(Vector2(236, 60), "S2", 11, tinta)
	l.draw_line(Vector2(200, 70), Vector2(200, 90), color, 3.0)
	l.draw_rect(Rect2(184, 90, 32, 40), Color("ffb3a0") if circula and fmod(t, 0.4) < 0.2 else Color.WHITE)
	l.draw_rect(Rect2(184, 90, 32, 40), tinta, false, 2.5)
	texto(Vector2(252, 110), "sirena", 11, tinta)
	l.draw_line(Vector2(200, 130), Vector2(200, 156), color, 3.0)
	# Tiristor.
	l.draw_colored_polygon(PackedVector2Array([Vector2(184, 156), Vector2(216, 156), Vector2(200, 180)]), vivo if circula else tinta)
	l.draw_line(Vector2(184, 180), Vector2(216, 180), tinta, 3.5)
	l.draw_line(Vector2(208, 180), Vector2(228, 198), vivo if puerta_activa() else tinta, 3.0)
	l.draw_line(Vector2(200, 180), Vector2(200, 230), color, 3.0)
	texto(Vector2(166, 168), "V1", 11, tinta)
	# Puerta: S1 y RG.
	l.draw_line(Vector2(320, 30), Vector2(320, 120), Color("c0392b"), 3.0)
	if puerta_activa():
		l.draw_line(Vector2(320, 120), Vector2(320, 140), vivo, 3.0)
	else:
		l.draw_line(Vector2(320, 140), Vector2(310, 122), tinta, 3.0)
	texto(Vector2(344, 130), "S1", 11, tinta)
	l.draw_line(Vector2(320, 140), Vector2(320, 198), vivo if puerta_activa() else Color("8a949b"), 3.0)
	l.draw_line(Vector2(320, 198), Vector2(228, 198), vivo if puerta_activa() else Color("8a949b"), 3.0)
	texto(Vector2(276, 214), "RG", 10, tinta)
	l.draw_line(Vector2(40, 230), Vector2(340, 230), tinta, 3.0)
	texto(Vector2(30, 242), "0 V", 10, tinta)
	if circula:
		for k in 4:
			var y := 72.0 + fmod(t * 60.0 + k * 40.0, 156.0)
			l.draw_circle(Vector2(200, y), 3.0, vivo)
	var rotulo := "BLOQUEA" if not disparado else ("DISPARANDO" if puerta_activa() else "ENCLAVADO")
	rotulo_estado(Vector2(100, 120), rotulo, Tema.ACIERTO if disparado else Color("5b6267"))
	l.draw_set_transform(Vector2.ZERO)
