class_name VisorFicha
extends PanelContainer
## Visor de las fichas: un hueco oscuro con luz de foco en el centro y un tornillo en cada
## esquina, donde va el dibujo grande del equipo, la animación o el esquema en su papel.

const RADIO := 14.0

## Rótulo grabado abajo a la izquierda, como «TOQUE UN NÚMERO»; vacío, sin rótulo.
var rotulo := "":
	set(valor):
		rotulo = valor
		queue_redraw()


func _init(margen := 10.0) -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", Relieve.estilo_hueco(margen, RADIO))


func _draw() -> void:
	var r := Rect2(Vector2(1.5, 1.5), size - Vector2(3, 3))
	if r.size.x <= 4.0 or r.size.y <= 4.0:
		return
	var puntos := DibujoAri.contorno(r, RADIO - 1.5)
	var uvs := PackedVector2Array()
	var colores := PackedColorArray()
	for p in puntos:
		uvs.append((p - r.position) / r.size)
		colores.append(Color.WHITE)
	draw_polygon(puntos, colores, uvs, Relieve.foco())
	# Sombra interior arriba: la luz viene de encima y el canto del hueco la tapa.
	for i in 4:
		var franja := Rect2(r.position + Vector2(0, i * 1.5), Vector2(r.size.x, r.size.y - i * 1.5))
		DibujoAri.borde(self, franja.grow(-float(i)), RADIO - 1.5 - i, Color(0, 0, 0, 0.32 - i * 0.07), 1.5)
	DibujoAri.borde(self, Rect2(Vector2.ZERO, size), RADIO, Relieve.HUECO_BORDE, 1.0)
	for p: Vector2 in [Vector2(9, 9), Vector2(size.x - 9.0, 9), Vector2(9, size.y - 9.0), size - Vector2(9, 9)]:
		PiezasAri.tornillo(self, p, 2.8)
	if not rotulo.is_empty():
		var tam := float(Tema.tam(10))
		PiezasAri.texto(self, rotulo, 20.0, size.y - 10.0, tam, Color(Tema.ACENTO, 0.7), Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
