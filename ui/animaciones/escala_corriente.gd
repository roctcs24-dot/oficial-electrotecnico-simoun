extends Animacion
## Escala logarítmica de efectos de la corriente en el cuerpo. Los textos vienen del JSON.

const MA_MIN := 0.3
const MA_MAX := 1000.0
const SEPARACION_ROTULOS := 26.0
const SEPARACION_FILAS := 14.0

var _ma := 380.0
var _etiqueta: Label
var _efecto: Label


## Efecto del mayor nivel alcanzado. niveles va de menor a mayor y ma_consulta en mA.
static func efecto_de(niveles: Array, ma_consulta: float) -> String:
	var resultado: String = niveles[0]["texto"]
	for n: Dictionary in niveles:
		if ma_consulta >= float(n["ma"]):
			resultado = n["texto"]
	return resultado


func preparar() -> void:
	lienzo.custom_minimum_size.y = 120.0
	_ma = params.get("inicial", 380.0)
	var inicio := (log(_ma) - log(MA_MIN)) / (log(MA_MAX) - log(MA_MIN))
	_etiqueta = deslizador(0.0, 1.0, 0.002, inicio, _al_cambiar)
	_efecto = Label.new()
	_efecto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_efecto.custom_minimum_size.y = 100.0
	add_child(_efecto)
	_actualizar()


func _al_cambiar(valor: float) -> void:
	_ma = exp(log(MA_MIN) + valor * (log(MA_MAX) - log(MA_MIN)))
	_actualizar()


func _actualizar() -> void:
	var decimales := 1 if _ma < 10.0 else 0
	_etiqueta.text = "%s mA" % TextoTecnico.numero(_ma, decimales)
	_efecto.text = efecto_de(params["niveles"], _ma)


func _x(area: Rect2, ma: float) -> float:
	return area.position.x + area.size.x * (log(ma) - log(MA_MIN)) / (log(MA_MAX) - log(MA_MIN))


func dibujar() -> void:
	fondo()
	var area := Rect2(16.0, 48.0, lienzo.size.x - 32.0, 26.0)
	var pasos := 48
	for n in pasos:
		var f := float(n) / pasos
		var color := Color("2f9e57").lerp(Color("f2a93b"), f * 2.0) if f < 0.5 else Color("f2a93b").lerp(Color("c9231b"), (f - 0.5) * 2.0)
		lienzo.draw_rect(Rect2(area.position.x + f * area.size.x, area.position.y, area.size.x / pasos + 1.0, area.size.y), color)
	var x_previa := -INF
	var abajo := false
	for n: Dictionary in params["niveles"]:
		var x := _x(area, n["ma"])
		# Dos valores cercanos no caben en la misma línea en un celular.
		abajo = not abajo and x - x_previa < SEPARACION_ROTULOS
		x_previa = x
		var y := area.end.y + (SEPARACION_FILAS + 15.0 if abajo else 15.0)
		lienzo.draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y + 5.0), Tema.TINTA, 2.0)
		texto(Vector2(x, y), TextoTecnico.numero(n["ma"], 1 if float(n["ma"]) < 1.0 else 0), 13)
	var cursor := _x(area, _ma)
	flecha(Vector2(cursor, area.position.y - 30.0), Vector2(cursor, area.position.y - 2.0), Tema.TINTA, 4.0)
	var fijo := clampf(cursor, 60.0, lienzo.size.x - 60.0)
	texto(Vector2(fijo, 12.0), "%s mA" % TextoTecnico.numero(_ma, 1 if _ma < 10.0 else 0), 15)
