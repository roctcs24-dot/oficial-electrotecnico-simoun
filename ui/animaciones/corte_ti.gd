extends Animacion
## Transformador de intensidad de 100/5 A con su amperímetro y la bornera con puente. Se elige la
## corriente de la barra y se cierra el puente o se quita el amperímetro: con el secundario abierto
## la tensión entre S1 y S2 sube a cientos de voltios, como en la simulación (reactancia
## magnetizante de 200 Ω).

const ANCHO := 420.0
const ALTO := 290.0
const RELACION := 20.0
const X_MAGNETIZANTE := 200.0
const CARGA_OHM := 0.25

var corriente := 76.0
var puente := false
var con_amperimetro := true
var _valor: Label
var _tension: Label
var _boton_puente: Button
var _boton_aparato: Button
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	_valor = fila_valor(c, "Corriente en la barra")
	barra(c, 0.0, 120.0, 2.0, corriente, func(v: float) -> void:
		corriente = v
		_actualizar())
	_tension = fila_valor(c, "Tensión S1-S2")
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_boton_puente = boton_mando(fila, func() -> void: poner_puente(not puente))
	_boton_aparato = boton_mando(fila, func() -> void: poner_amperimetro(not con_amperimetro))
	_nota = nota_mandos(c)
	_actualizar()


func poner_puente(si: bool) -> void:
	puente = si
	_actualizar()


func poner_amperimetro(si: bool) -> void:
	con_amperimetro = si
	_actualizar()


func abierto() -> bool:
	return not puente and not con_amperimetro


func corriente_secundario() -> float:
	return corriente / RELACION


## Lo que marca el amperímetro, en amperios del primario.
func lectura() -> float:
	return corriente if con_amperimetro and not puente else 0.0


func tension_secundario() -> float:
	if puente:
		return 0.0
	if not con_amperimetro:
		return corriente_secundario() * X_MAGNETIZANTE
	return corriente_secundario() * CARGA_OHM


## 2 con el secundario cerrado; 3 abierto, con la tensión peligrosa.
func fase() -> int:
	return 3 if abierto() and corriente > 0.0 else 2


func _actualizar() -> void:
	if _nota == null:
		return
	_valor.text = "%d A" % roundi(corriente)
	_tension.text = "%s V" % coma(tension_secundario(), 1 if tension_secundario() < 10.0 else 0)
	_boton_puente.text = "Abrir el puente" if puente else "Cerrar el puente"
	_boton_aparato.text = "Poner el amperímetro" if not con_amperimetro else "Quitar el amperímetro"
	if abierto():
		_nota.text = "¡Secundario abierto! Toda la corriente del TI busca camino: la tensión sube y el aislamiento se rompe. Cierre el puente antes de quitar el aparato."
	elif puente:
		_nota.text = "El puente cortocircuita el secundario: el TI trabaja seguro y el amperímetro se puede quitar. Marca cero."
	else:
		_nota.text = "El secundario da %s A a través del amperímetro, que marca %d A en su escala." % [coma(corriente_secundario(), 2), roundi(lectura())]


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(210, 12), "TRANSFORMADOR DE INTENSIDAD 100/5 A", 12, Color("5b6267"))
	# Barra del primario y núcleo.
	var c := Vector2(130, 100)
	l.draw_circle(c, 62.0, Color("3a3f44"))
	l.draw_circle(c, 30.0, Tema.PAPEL)
	var cobre := Color("c27a45")
	l.draw_rect(Rect2(10, 92, 240, 16), cobre)
	texto(Vector2(22, 80), "P1", 11, Tema.TINTA)
	texto(Vector2(238, 80), "P2", 11, Tema.TINTA)
	# Flujo animado alrededor del núcleo.
	var paso := fmod(t * (0.5 + corriente / 60.0), 1.0)
	for k in 8:
		var a := TAU * (k / 8.0 + paso)
		l.draw_circle(c + Vector2(cos(a), sin(a)) * 46.0, 3.0, Color("ffd166") if corriente > 0.0 else Color("6c7276"))
	# Secundario hasta la bornera y el amperímetro.
	var color_sec := Tema.FALLO if abierto() and corriente > 0.0 else Color("2f7fd0")
	l.draw_line(Vector2(116, 162), Vector2(116, 200), color_sec, 3.0)
	l.draw_line(Vector2(144, 162), Vector2(144, 200), color_sec, 3.0)
	texto(Vector2(102, 176), "S1", 10, Tema.TINTA)
	texto(Vector2(160, 176), "S2", 10, Tema.TINTA)
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 4, 0, 0, Color("5b6267")), Rect2(100, 200, 60, 30))
	if puente:
		l.draw_line(Vector2(116, 215), Vector2(144, 215), Color("c0392b"), 4.0)
	texto(Vector2(130, 244), "bornera", 10, Tema.TINTA)
	# Amperímetro.
	var m := Vector2(330, 120)
	if con_amperimetro:
		l.draw_line(Vector2(116, 230), Vector2(116, 262), color_sec, 3.0)
		l.draw_line(Vector2(116, 262), Vector2(m.x - 20, 262), color_sec, 3.0)
		l.draw_line(Vector2(144, 230), Vector2(144, 250), color_sec, 3.0)
		l.draw_line(Vector2(144, 250), Vector2(m.x + 20, 250), color_sec, 3.0)
		l.draw_line(Vector2(m.x - 20, 262), Vector2(m.x - 20, 190), color_sec, 3.0)
		l.draw_line(Vector2(m.x + 20, 250), Vector2(m.x + 20, 190), color_sec, 3.0)
		l.draw_style_box(Tema.caja(Color("2a2e32"), 6, 0, 0), Rect2(m.x - 70, m.y - 70, 140, 120))
		l.draw_style_box(Tema.caja(Color("f4f5f2"), 3, 0, 0), Rect2(m.x - 62, m.y - 62, 124, 104))
		l.draw_arc(m + Vector2(0, 26), 70.0, -PI * 0.78, -PI * 0.22, 24, Tema.TINTA, 2.0)
		var angulo := lerpf(-PI * 0.78, -PI * 0.22, clampf(lectura() / 100.0, 0.0, 1.2))
		l.draw_line(m + Vector2(0, 26), m + Vector2(0, 26) + Vector2(cos(angulo), sin(angulo)) * 64.0, Color("c0392b"), 3.0)
		texto(m + Vector2(-50, -46), "0", 10, Tema.TINTA)
		texto(m + Vector2(50, -46), "100", 10, Tema.TINTA)
		texto(m + Vector2(0, 2), "A", 16, Tema.TINTA)
	else:
		texto(m, "amperímetro quitado", 12, Color("5b6267"))
	var rotulo := "PELIGRO: %d V EN S1-S2" % roundi(tension_secundario()) if fase() == 3 else ("PUENTE CERRADO" if puente else "MIDIENDO: %d A" % roundi(lectura()))
	rotulo_estado(Vector2(316, 222), rotulo, Tema.FALLO if fase() == 3 else (Color("5b6267") if puente else Tema.ACIERTO))
	l.draw_set_transform(Vector2.ZERO)
