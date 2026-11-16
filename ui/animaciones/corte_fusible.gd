extends Animacion
## Corte de un cartucho de fusible: la corriente calienta el elemento, más en sus
## estrechamientos; con sobrecorriente acumula energía hasta fundirse en uno de ellos, y la arena
## apaga el arco. Mismo modelo que SimFusible: por encima de 1,25 × In acumula (I/In)² · t y funde
## al llegar a energia_fusion; por debajo se enfría. Simplificado para enseñar: la curva real
## de cada fusible está en su catálogo.
## Parámetros: i_nominal (A), energia_fusion y veces (corriente inicial en × In).

const ANCHO := 408.0
const ALTO := 300.0
const UMBRAL := 1.25
const ACELERACION := 10.0
const NOTCHES := [150.0, 204.0, 258.0]

var veces := 1.0
var energia := 0.0
var fundido := false
var reloj := 0.0
var _arco := 0.0
var _valor: Label
var _nota: Label
var _cambio: Button


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	veces = float(params.get("veces", 1.0))
	var c := tarjeta_mandos()
	_valor = fila_valor(c, "Corriente del circuito")
	barra(c, 0.0, 20.0, 0.1, veces, poner_corriente)
	_nota = nota_mandos(c)
	_cambio = boton_mando(c, cambiar_cartucho)
	_cambio.text = "Cambiar el cartucho (sin tensión)"
	_actualizar_textos()


func i_nominal() -> float:
	return float(params.get("i_nominal", 2.0))


func energia_fusion() -> float:
	return float(params.get("energia_fusion", 50.0))


func poner_corriente(v: float) -> void:
	veces = v
	_actualizar_textos()


func corriente() -> float:
	return 0.0 if fundido else veces * i_nominal()


func cambiar_cartucho() -> void:
	fundido = false
	energia = 0.0
	reloj = 0.0
	_actualizar_textos()


## Igual que SimFusible.avanzar.
func avanzar(segundos: float) -> void:
	var resto := segundos
	while resto > 0.0:
		var dt := minf(resto, 0.05)
		resto -= dt
		if fundido:
			continue
		reloj += dt
		if veces > UMBRAL:
			energia += veces * veces * dt
		else:
			energia = maxf(0.0, energia - dt)
		if energia >= energia_fusion():
			fundido = true
			_arco = 0.6
			_actualizar_textos()


func acelerado() -> bool:
	return veces < 3.0


## 1 normal, 2 calentándose hacia la fusión, 3 fundido.
func fase() -> int:
	if fundido:
		return 3
	return 2 if veces > UMBRAL else 1


func _process(delta: float) -> void:
	avanzar(delta * (ACELERACION if acelerado() else 1.0))
	_arco = maxf(_arco - delta, 0.0)
	super(delta)


func _actualizar_textos() -> void:
	if _valor == null:
		return
	_valor.text = "%s × In · %s A" % [coma(veces), coma(veces * i_nominal())]
	if fundido:
		_nota.text = "Fundido: el circuito quedó abierto. Antes de cambiarlo, busque la causa y abra el portafusible sin tensión."
	elif veces > UMBRAL:
		var t := energia_fusion() / (veces * veces)
		_nota.text = "Por encima de 1,25 × In se funde: a %s × In, en unos %s s. Cuanta más corriente, antes." % [coma(veces), coma(t, 1)]
	else:
		_nota.text = "In = %s A. Hasta 1,25 × In aguanta sin fundirse. Valores del modelo del juego: la curva real está en el catálogo." % coma(i_nominal())


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(204, 14), "CORTE DE UN CARTUCHO DE FUSIBLE", 12, Color("5b6267"))
	# Casquillos y cuerpo cerámico.
	l.draw_style_box(Tema.caja(Color("aeb3b6"), 6, 0, 0, Color("5b6267")), Rect2(30, 92, 56, 116))
	l.draw_style_box(Tema.caja(Color("aeb3b6"), 6, 0, 0, Color("5b6267")), Rect2(322, 92, 56, 116))
	l.draw_style_box(Tema.caja(Color("f1eee4"), 4, 0, 0, Color("8f8a7c")), Rect2(80, 100, 248, 100))
	# Arena de cuarzo.
	for j in 140:
		var x := 86.0 + fmod(j * 37.0, 236.0)
		var y := 106.0 + fmod(j * 53.0, 88.0)
		l.draw_circle(Vector2(x, y), 1.4, Color("d2c9ad"))
	# Elemento con estrechamientos. El color sube con el calor acumulado.
	var calor := clampf(energia / energia_fusion(), 0.0, 1.0)
	var corriente_rel := clampf(corriente() / i_nominal() / 3.0, 0.0, 1.0)
	var color := Color("c08a3e").lerp(Color("ff7a1a"), maxf(calor, corriente_rel * 0.4)).lerp(Color("fff1b0"), calor * calor)
	var y0 := 150.0
	var x := 80.0
	for n in NOTCHES:
		_tramo(Vector2(x, y0), Vector2(n - 6, y0), 12.0, color)
		x = n + 6
	_tramo(Vector2(x, y0), Vector2(328, y0), 12.0, color)
	for i in NOTCHES.size():
		var n: float = NOTCHES[i]
		if fundido and i == 1:
			# Se funde en el estrechamiento central: queda un hueco con gotas y arena vitrificada.
			l.draw_circle(Vector2(n - 8, y0), 5.0, Color("8a6a3a"))
			l.draw_circle(Vector2(n + 8, y0), 5.0, Color("8a6a3a"))
			l.draw_circle(Vector2(n, y0), 11.0, Color("b8b2a0", 0.8))
		else:
			_tramo(Vector2(n - 6, y0), Vector2(n + 6, y0), 4.0, color.lerp(Color("fff7d6"), calor))
	if _arco > 0.0:
		l.draw_circle(Vector2(NOTCHES[1], y0), 16.0 * _arco + 4.0, Color("ffe066", minf(_arco * 1.6, 1.0)))
	texto(Vector2(58, 76), "1", 13, Tema.TINTA)
	texto(Vector2(350, 76), "2", 13, Tema.TINTA)
	texto(Vector2(204, 224), "Elemento de plata con estrechamientos, en arena de cuarzo", 11, Tema.TINTA)
	# Indicador de fusión.
	l.draw_circle(Vector2(204, 92), 7.0, Color("c0392b") if fundido else Color("d9d4c4"))
	texto(Vector2(204, 74), "indicador", 10, Color("5b6267"))
	# Estado y reloj.
	rotulo_estado(Vector2(204, 260), "FUNDIDO: CIRCUITO ABIERTO" if fundido else ("CALENTÁNDOSE" if veces > UMBRAL else "CONDUCE"), Color("c0392b") if fundido else (Color("c26a1a") if veces > UMBRAL else Tema.ACIERTO))
	texto_derecha(Vector2(398, 290), "Tiempo: %s s%s" % [coma(reloj, 1), "  (reloj × %d)" % int(ACELERACION) if acelerado() else ""], 11)
	l.draw_set_transform(Vector2.ZERO)


func _tramo(a: Vector2, b: Vector2, grosor: float, color: Color) -> void:
	lienzo.draw_line(a, b, color, grosor)
