extends Pantalla
## Colores de tubería (data/tuberias.json): cada servicio con un tramo de tubo pintado de su color
## ISO 14726, su nombre y el nombre del color. Debajo, el aviso de verificar el código del buque.

const COLOR := Color("2e9e6a")

var filas: Array[Control] = []


func construir() -> void:
	var datos := raiz.contenido.leer("tuberias.json")
	var cabecera := CabeceraFicha.new()
	cabecera.iniciar(raiz, "Colores de tubería", "Pañol · ISO 14726: qué lleva cada línea", COLOR, "valvulas")
	add_child(cabecera)
	var desplazable := _desplazable()
	add_child(desplazable)
	var columna := _columna(10)
	desplazable.add_child(_ancho_lectura(columna))
	var placa := PiezasLeccion.placa(14.0, 10.0)
	columna.add_child(placa)
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 4)
	lista.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(lista)
	lista.add_child(PiezasLeccion.rotulo("Servicio · color ISO 14726"))
	var rejilla := GridContainer.new()
	rejilla.columns = 1 if raiz.vertical else 2
	rejilla.add_theme_constant_override("h_separation", 18)
	rejilla.add_theme_constant_override("v_separation", 4)
	lista.add_child(rejilla)
	filas.clear()
	var colores: Dictionary = datos.get("colores", {})
	for id: String in colores:
		var c: Dictionary = colores[id]
		var fila := HBoxContainer.new()
		fila.name = "Color_%s" % id
		fila.add_theme_constant_override("separation", 12)
		fila.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tubo := TramoColor.new()
		tubo.colores = [Color(str(c["claro"])), Color(str(c["color"])), Color(str(c["oscuro"]))]
		fila.add_child(tubo)
		var textos := VBoxContainer.new()
		textos.add_theme_constant_override("separation", 0)
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		textos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		textos.add_child(PiezasLeccion.etiqueta(str(c["nombre"]), 15, Tema.TEXTO, Tema.PESO_NEGRITA))
		textos.add_child(PiezasLeccion.etiqueta(str(c["iso"]), 12, Tema.TEXTO_SUAVE))
		fila.add_child(textos)
		rejilla.add_child(fila)
		filas.append(fila)
	var aviso := PiezasLeccion.placa(14.0, 10.0)
	aviso.name = "Aviso"
	columna.add_child(aviso)
	var t := VBoxContainer.new()
	aviso.add_child(t)
	t.add_child(PiezasLeccion.rotulo("A bordo del Vía Simoun"))
	t.add_child(PiezasLeccion.etiqueta(str(datos.get("nota", "")), 13, Tema.TEXTO_SUAVE))


## Tramo corto de tubo pintado, con su sombra y su brillo.
class TramoColor:
	extends Control

	var colores: Array = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(84, 40)

	func _draw() -> void:
		var r := Rect2(2, size.y / 2.0 - 9.0, size.x - 4.0, 18.0)
		DibujoAri.relleno(self, Rect2(r.position + Vector2(0, 4), r.size), 9.0, Color(0, 0, 0, 0.45))
		DibujoAri.relleno(self, r.grow(1.5), 10.0, Color("0a0d10"))
		DibujoAri.degradado(self, r, 9.0, colores)
		DibujoAri.relleno(self, Rect2(r.position + Vector2(6, 3), Vector2(r.size.x - 12.0, 3.0)), 1.5, Color(1, 1, 1, 0.35))
