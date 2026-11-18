class_name FotoPieza
extends Control
## Foto de una pieza tomada a bordo, enmarcada con bisel: llena el espacio (recortando los bordes
## y centrada en el halo), con un halo ámbar que late sobre la pieza que importa, el rótulo arriba,
## el crédito abajo y, si se pide, la lámpara del estado (abierta o cerrada).

const AMBAR := Color("ffc23a")
const BORDE := Color("10141a")

var textura: Texture2D:
	set(v):
		textura = v
		queue_redraw()
var halo := Rect2():
	set(v):
		halo = v
		set_process(halo.has_area())
		queue_redraw()
var rotulo := ""
var credito := ""
## Partes numeradas (fracciones de la foto): se pintan como monedas ámbar 1, 2, 3…
var partes: Array[Vector2] = []
## Con «entera», la foto se ve completa (con bandas oscuras) en lugar de llenar el espacio: así no
## se pierde ninguna parte numerada.
var entera := false
## «abierta», «cerrada» o vacío: con estado se pinta la lámpara arriba a la derecha.
var estado := ""
var _tiempo := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	custom_minimum_size = Vector2(160, 140)
	set_process(false)


static func desde(foto: Dictionary, nota_credito := "", con_estado := false) -> FotoPieza:
	var f := FotoPieza.new()
	f.name = "Foto_%s" % foto.get("id", "")
	f.textura = FotosPiezas.textura(foto)
	f.halo = FotosPiezas.halo_relativo(foto)
	f.rotulo = str(foto.get("rotulo", ""))
	f.partes = FotosPiezas.partes_relativas(foto)
	f.entera = not f.partes.is_empty()
	f.credito = nota_credito
	if con_estado:
		f.estado = str(foto.get("estado", ""))
	return f


func _process(delta: float) -> void:
	_tiempo += delta
	queue_redraw()


## Parte de la textura que se ve: llena el control y se centra en el halo si lo hay.
func region_visible() -> Rect2:
	if textura == null or size.x <= 0.0 or size.y <= 0.0:
		return Rect2()
	var t := textura.get_size()
	if entera:
		return Rect2(Vector2.ZERO, t)
	var escala := maxf(size.x / t.x, size.y / t.y)
	var ver := size / escala
	var centro := t / 2.0
	if halo.has_area():
		centro = (halo.position + halo.size / 2.0) * t
	var origen := (centro - ver / 2.0).clamp(Vector2.ZERO, t - ver)
	return Rect2(origen, ver)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var s := clampf(size.x / 420.0, 0.75, 1.4)
	draw_rect(r.grow(2.0), Color(0, 0, 0, 0.55))
	if textura == null:
		draw_rect(r, Color("1b232c"))
	else:
		var region := region_visible()
		if entera:
			draw_rect(r, Color("0b0f13"))
			r = destino()
		draw_texture_rect_region(textura, r, region)
		if halo.has_area():
			_halo(region)
		for i in partes.size():
			_parte(region, partes[i], i + 1)
	# Viñeta y bisel: arriba más claro, abajo y a los lados más oscuro.
	for i in 6:
		var a := 0.07 * (6 - i) / 6.0
		draw_rect(Rect2(i * 3.0, i * 3.0, size.x - i * 6.0, size.y - i * 6.0), Color(0, 0, 0, a), false, 3.0)
	draw_line(Vector2(2, 2), Vector2(size.x - 2, 2), Color(1, 1, 1, 0.18), 1.5)
	draw_rect(r, BORDE, false, 3.0)
	draw_rect(r.grow(-2.5), Color("3a4048"), false, 1.0)
	if not rotulo.is_empty():
		_chapa(Vector2(10, 10) * s, rotulo.to_upper(), 10.0 * s, true)
	if not credito.is_empty():
		_chapa(Vector2(10 * s, size.y - 26 * s), credito.to_upper(), 8.5 * s, false)
	if estado in ["abierta", "cerrada"]:
		var texto := estado.to_upper()
		var ancho := PiezasAri.ancho_texto(texto, 10.0 * s) + 34 * s
		var donde := Vector2(size.x - ancho - 10 * s, 10 * s)
		_chapa(donde, texto, 10.0 * s, true, 18 * s)
		Relieve.lampara_estado(self, donde + Vector2(13 * s, 11 * s), 5.5 * s, "completo" if estado == "abierta" else "averia")


func _halo(region: Rect2) -> void:
	var t := textura.get_size()
	var escala := destino().size.x / region.size.x
	var centro := punto_en_control(region, halo.position + halo.size / 2.0)
	var radios := halo.size * t * escala / 2.0 + Vector2(6, 6)
	var puntos := PackedVector2Array()
	for i in 73:
		var a := TAU * i / 72.0
		puntos.append(centro + Vector2(cos(a) * radios.x, sin(a) * radios.y))
	var latido := 0.75 + 0.25 * sin(_tiempo * 3.2)
	draw_polyline(puntos, Color(1.0, 0.69, 0.0, 0.18 * latido), 11.0, true)
	draw_polyline(puntos, Color(1.0, 0.69, 0.0, 0.35 * latido), 6.0, true)
	draw_polyline(puntos, AMBAR, 3.0, true)


## Punto de la foto (fracción) en coordenadas del control.
func punto_en_control(region: Rect2, fraccion: Vector2) -> Vector2:
	var d := destino()
	return d.position + (fraccion * textura.get_size() - region.position) * (d.size.x / region.size.x)


## Rectángulo del control donde se pinta la foto: todo, o centrada y entera si «entera».
func destino() -> Rect2:
	if not entera or textura == null:
		return Rect2(Vector2.ZERO, size)
	var t := textura.get_size()
	var k := minf(size.x / t.x, size.y / t.y)
	return Rect2((size - t * k) / 2.0, t * k)


func _parte(region: Rect2, fraccion: Vector2, n: int) -> void:
	var c := punto_en_control(region, fraccion)
	var r := clampf(size.x / 34.0, 9.0, 14.0)
	c = c.clamp(Vector2(r + 3, r + 3), size - Vector2(r + 3, r + 3))
	Relieve.halo(self, c, r * 1.9, Color("ffb000"), 0.8)
	draw_circle(c + Vector2(0, 2), r + 2.5, Color(0, 0, 0, 0.55))
	draw_circle(c, r + 2.0, BORDE)
	PiezasAri._disco(self, c, r, Color("fff3c4"), Color("d99614"), Vector2(-0.3, -0.35), 8)
	PiezasAri.texto(self, str(n), c.x, c.y + r * 0.42, r * 1.15, Color("2a1a00"))


func _chapa(pos: Vector2, texto: String, tam: float, fuerte: bool, sangria := 0.0) -> void:
	var ancho := PiezasAri.ancho_texto(texto, tam) + tam * 1.4 + sangria
	var caja := StyleBoxFlat.new()
	caja.set_corner_radius_all(4)
	caja.bg_color = Color("1f252c") if fuerte else Color(0.04, 0.055, 0.07, 0.75)
	caja.border_color = Color(1, 1, 1, 0.14)
	caja.set_border_width_all(1)
	caja.shadow_color = Color(0, 0, 0, 0.5)
	caja.shadow_size = 3
	caja.shadow_offset = Vector2(0, 2)
	var r := Rect2(pos, Vector2(ancho, tam * 2.0))
	draw_style_box(caja, r)
	PiezasAri.texto(self, texto, pos.x + tam * 0.7 + sangria, pos.y + tam * 1.38, tam, Tema.TEXTO if fuerte else Color("e8edf2"), Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
