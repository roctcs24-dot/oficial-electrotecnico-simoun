class_name InstrumentoAguja
extends Control
## Instrumento analógico con aspecto real. Dos estilos:
## - "cuadro": voltímetro, amperímetro, vatímetro o frecuencímetro de cuadro, en marco cuadrado
##   de baquelita con escala de 240° y el símbolo de la unidad impreso en la esfera.
## - "manometro": manómetro o termómetro de esfera en caja redonda de acero, escala de 270° y
##   toma inferior; en bar lleva además la escala interior en psi, como los de la planta de frío.
## Encima va el rótulo grabado y debajo la lectura en cifras, para leer sin errores de paralaje.
## Desde zona_roja la escala se pinta en rojo, como en los instrumentos reales.

const APERTURA_CUADRO := 240.0
const APERTURA_MANOMETRO := 270.0
const PSI_POR_BAR := 14.5038
const PLACA := Color("202427")
const TEXTO_PLACA := Color("e9ebe8")
const ALTO_ROTULO := 18.0
const ALTO_LECTURA := 22.0

var titulo := ""
var unidad := ""
var minimo := 0.0
var maximo := 100.0
var zona_roja := INF
var decimales := 0
## "cuadro" o "manometro". configurar() lo elige por la unidad.
var estilo := "cuadro"
var valor := 0.0:
	set(nuevo):
		if not is_equal_approx(nuevo, valor):
			valor = nuevo
			queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(132.0, 172.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func configurar(p_titulo: String, p_unidad: String, p_minimo: float, p_maximo: float, p_zona_roja := INF, p_decimales := 0) -> InstrumentoAguja:
	titulo = p_titulo
	unidad = p_unidad
	minimo = p_minimo
	maximo = p_maximo
	zona_roja = p_zona_roja
	decimales = p_decimales
	estilo = "manometro" if unidad in ["bar", "psi", "kPa", "°C"] else "cuadro"
	return self


func _draw() -> void:
	var fuente := get_theme_default_font()
	_placa(fuente, Rect2(Vector2.ZERO, Vector2(size.x, ALTO_ROTULO)), titulo, 12)
	var zona := Rect2(Vector2(0.0, ALTO_ROTULO + 4.0), Vector2(size.x, size.y - ALTO_ROTULO - ALTO_LECTURA - 8.0))
	if estilo == "manometro":
		_manometro(fuente, zona)
	else:
		_cuadro(fuente, zona)
	var lectura := "%s %s" % [TextoTecnico.numero(valor, decimales), unidad]
	_placa(fuente, Rect2(Vector2(size.x * 0.1, size.y - ALTO_LECTURA), Vector2(size.x * 0.8, ALTO_LECTURA)), lectura, 15)


func _placa(fuente: Font, r: Rect2, texto: String, tam: int) -> void:
	draw_rect(r, PLACA)
	draw_line(r.position, Vector2(r.end.x, r.position.y), PLACA.lightened(0.25), 1.0)
	draw_line(Vector2(r.position.x, r.end.y), r.end, PLACA.darkened(0.6), 1.0)
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	draw_string(fuente, Vector2(r.get_center().x - ancho / 2.0, r.get_center().y + tam * 0.36), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, TEXTO_PLACA)


func _cuadro(fuente: Font, zona: Rect2) -> void:
	var lado := minf(zona.size.x, zona.size.y)
	var marco := Rect2(Vector2(zona.get_center().x - lado / 2.0, zona.position.y), Vector2(lado, lado))
	var cara := DibujoInstrumentos.marco_cuadrado(self, marco)
	var h := cara.size.y
	var centro := Vector2(cara.get_center().x, cara.position.y + h * 0.5)
	var radio := h * 0.4
	var tam := clampi(int(radio * 0.24), 9, 14)
	DibujoInstrumentos.escala(self, fuente, centro, radio, minimo, maximo, APERTURA_CUADRO, zona_roja, DibujoInstrumentos.TINTA, tam)
	var t_unidad := clampi(int(h * 0.15), 11, 22)
	var ancho := fuente.get_string_size(unidad, HORIZONTAL_ALIGNMENT_LEFT, -1, t_unidad).x
	draw_string(fuente, Vector2(centro.x - ancho / 2.0, cara.end.y - h * 0.1), unidad, HORIZONTAL_ALIGNMENT_LEFT, -1, t_unidad, DibujoInstrumentos.TINTA)
	var a := DibujoInstrumentos.angulo_escala(valor, minimo, maximo, APERTURA_CUADRO)
	DibujoInstrumentos.aguja(self, centro, a, radio * 0.98, Color("15171a"))
	DibujoInstrumentos.reflejo(self, cara.get_center(), h * 0.5)


func _manometro(fuente: Font, zona: Rect2) -> void:
	var r := minf(zona.size.x, zona.size.y - 8.0) / 2.0
	var centro := Vector2(zona.get_center().x, zona.position.y + r)
	DibujoInstrumentos.toma_inferior(self, centro, r)
	var esfera := DibujoInstrumentos.caja_redonda(self, centro, r)
	var radio := esfera * 0.9
	var tam := clampi(int(esfera * 0.2), 8, 13)
	DibujoInstrumentos.escala(self, fuente, centro, radio, minimo, maximo, APERTURA_MANOMETRO, zona_roja, DibujoInstrumentos.TINTA, tam)
	var t_unidad := clampi(int(esfera * 0.2), 9, 14)
	# La escala interior en psi solo se dibuja si la esfera es lo bastante grande para leerla.
	if unidad == "bar" and esfera >= 55.0:
		DibujoInstrumentos.escala_secundaria(self, fuente, centro, esfera * 0.42, minimo, maximo, PSI_POR_BAR,
			APERTURA_MANOMETRO, DibujoInstrumentos.ROJO, maxi(tam - 3, 7))
		_centrado(fuente, "psi", centro + Vector2(0.0, esfera * 0.72), maxi(t_unidad - 3, 7), DibujoInstrumentos.ROJO)
	_centrado(fuente, unidad, centro + Vector2(0.0, esfera * 0.5), t_unidad, DibujoInstrumentos.TINTA)
	var a := DibujoInstrumentos.angulo_escala(valor, minimo, maximo, APERTURA_MANOMETRO)
	DibujoInstrumentos.aguja(self, centro, a, radio * 0.96, Color("15171a"))
	DibujoInstrumentos.reflejo(self, centro, esfera)


func _centrado(fuente: Font, texto: String, p: Vector2, tam: int, color: Color) -> void:
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	draw_string(fuente, Vector2(p.x - ancho / 2.0, p.y + tam * 0.36), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)
