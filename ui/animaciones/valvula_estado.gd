extends Animacion
## Una válvula del catálogo (params «tipo») que se maniobra: con un deslizador la abre o la
## cierra; la de tres vías elige la salida y la retención, el sentido del flujo. Debajo dice cómo
## está y cómo se sabe, con el texto del catálogo.

const ALTO := 220.0

var dibujo: DibujoValvula
var _estado: Label
var _nota: Label
var _datos := {}


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	var tipo := str(params.get("tipo", "bola"))
	dibujo = DibujoValvula.new()
	dibujo.tipo = tipo
	dibujo.flujo = true
	dibujo.apertura = float(params.get("apertura", 1.0))
	dibujo.set_anchors_preset(Control.PRESET_FULL_RECT)
	lienzo.add_child(dibujo)
	if contenido != null:
		for v: Dictionary in contenido.leer("catalogos/valvulas.json").get("valvulas", []):
			if v["dibujo"] == tipo:
				_datos = v
	var c := tarjeta_mandos()
	match tipo:
		"tres_vias":
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			c.add_child(fila)
			var b_b := boton_mando(fila, poner_via.bind("b"))
			b_b.text = "De A a B"
			var b_c := boton_mando(fila, poner_via.bind("c"))
			b_c.text = "De A a C"
		"retencion":
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			c.add_child(fila)
			var b_b := boton_mando(fila, poner_via.bind("b"))
			b_b.text = "Flujo en el sentido de la flecha"
			var b_c := boton_mando(fila, poner_via.bind("c"))
			b_c.text = "Flujo al revés"
		_:
			var ap := fila_valor(c, "Apertura")
			barra(c, 0.0, 100.0, 5.0, dibujo.apertura * 100.0, func(v: float) -> void:
				dibujo.apertura = v / 100.0
				ap.text = "%d %%" % roundi(v)
				_actualizar())
			ap.text = "%d %%" % roundi(dibujo.apertura * 100.0)
	_estado = fila_valor(c, "Estado")
	_nota = nota_mandos(c)
	_actualizar()


func poner_via(v: String) -> void:
	dibujo.via = v
	_actualizar()


## «abierta», «cerrada», «a medio abrir», «de A a B», «de A a C», «pasa» o «asienta».
func estado() -> String:
	match dibujo.tipo:
		"tres_vias":
			return "de A a B" if dibujo.via == "b" else "de A a C"
		"retencion":
			return "deja pasar" if dibujo.via == "b" else "asienta y no deja volver"
	if dibujo.apertura >= 0.97:
		return "abierta"
	return "cerrada" if dibujo.apertura <= 0.03 else "a medio abrir"


func _actualizar() -> void:
	if _nota == null:
		return
	_estado.text = estado()
	_nota.text = str(_datos.get("como_saber", ""))


func dibujar() -> void:
	DibujoAri.degradado(lienzo, Rect2(Vector2.ZERO, lienzo.size), 10.0, [Color("26313c"), Color("141b22")])
