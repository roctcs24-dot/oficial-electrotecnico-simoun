class_name MedallaModulo
extends ControlToque
## Medalla de un módulo de la Escuela, o del rango en el inicio. Tres formas:
##   «tira»: la medalla con el nombre corto debajo, en la tira de arriba en vertical;
##   «fila»: la medalla con el nombre y el avance al lado, en la columna en apaisado;
##   «sola»: solo la medalla, sin toque.

signal pulsada

const LADO_TIRA := Vector2(66, 96)
const ALTO_FILA := 54.0

var forma := "tira"
var nombre := ""
var detalle := ""
var icono := ""
var letra := ""
var color := Tema.ACENTO
var avance := 0.0
var elegida := false
var cerrada := false


func iniciar(p_forma: String, p_nombre: String, p_icono: String, p_color: Color, p_avance: float, opciones := {}) -> void:
	forma = p_forma
	nombre = p_nombre
	icono = p_icono
	color = p_color
	avance = p_avance
	detalle = opciones.get("detalle", "")
	letra = opciones.get("letra", "")
	elegida = opciones.get("elegida", false)
	cerrada = opciones.get("cerrada", false)
	match forma:
		"tira":
			custom_minimum_size = LADO_TIRA
		"fila":
			custom_minimum_size = Vector2(160, ALTO_FILA)
		_:
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			if custom_minimum_size == Vector2.ZERO:
				custom_minimum_size = Vector2(56, 56)
	tooltip_text = nombre if forma != "sola" else ""
	queue_redraw()


func _al_tocar(_punto: Vector2) -> void:
	if forma != "sola":
		pulsada.emit()


func _draw() -> void:
	match forma:
		"tira":
			var r := minf(size.x * 0.34, 22.0)
			var c := Vector2(size.x / 2.0, r * 1.35 + 4.0)
			_medalla(c, r)
			var tam := float(Tema.tam(11))
			while tam > 8.0 and PiezasAri.ancho_texto(nombre, tam) > size.x + 4.0:
				tam -= 0.5
			var tinta := Tema.ACENTO if elegida else (Color("6f7b86") if cerrada else Color("c9d3dc"))
			PiezasAri.texto(self, nombre, size.x / 2.0, c.y + r * 1.25 + tam + 6.0, tam, tinta, Tema.PESO_NEGRITA if elegida else Tema.PESO_FUERTE)
		"fila":
			var caja := Rect2(Vector2(2, 2), size - Vector2(4, 4))
			if elegida:
				for i in 3:
					DibujoAri.borde(self, caja.grow(1.0 + i * 1.5), 10.0 + i * 1.5, Color(Relieve.AMBAR_HALO, 0.18 - i * 0.05), 1.5)
				DibujoAri.degradado(self, caja, 9.0, [Color(1.0, 0.76, 0.23, 0.22), Color(1.0, 0.76, 0.23, 0.06)])
				DibujoAri.borde(self, caja, 9.0, Relieve.AMBAR, 1.2)
			elif _presionado:
				DibujoAri.relleno(self, caja, 9.0, Color(1, 1, 1, 0.06))
			var r := 15.0
			var c := Vector2(10.0 + r * 1.25, size.y / 2.0)
			_medalla(c, r)
			var x := c.x + r * 1.25 + 10.0
			var tam := float(Tema.tam(13))
			var titulo := nombre
			while tam > 9.0 and PiezasAri.ancho_texto(titulo, tam) > size.x - x - 6.0:
				tam -= 0.5
			var tinta := Tema.ACENTO if elegida else (Tema.APAGADO if cerrada else Color.WHITE)
			var nota := float(Tema.tam(11))
			var base := size.y / 2.0 - 2.0 if not detalle.is_empty() else size.y / 2.0 + tam * 0.36
			PiezasAri.texto(self, titulo, x, base, tam, tinta, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
			if not detalle.is_empty():
				PiezasAri.texto(self, detalle, x, base + nota + 4.0, nota, Tema.TEXTO_SUAVE, Tema.PESO_NORMAL, HORIZONTAL_ALIGNMENT_LEFT)
		_:
			var r := minf(size.x, size.y) / 2.0 / 1.3
			_medalla(size / 2.0, r)


func _medalla(c: Vector2, r: float) -> void:
	var base := color.lightened(0.15) if _presionado and forma != "sola" else color
	Relieve.medalla(self, c, r, base, icono, avance, elegida and forma == "tira", cerrada, letra)
