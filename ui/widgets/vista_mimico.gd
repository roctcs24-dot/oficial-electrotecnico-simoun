class_name VistaMimico
extends ScrollContainer
## Mímico de un tablero: sus casillas de arrancador en una rejilla que se adapta al ancho, como
## los paneles de un simulador de sala de máquinas. Se desplaza en vertical si no caben. Las
## acciones de cada casilla salen por «accion» para que la pantalla maniobre la simulación.

signal accion(casilla: CasillaAri, que: String, valor: Variant)

const ANCHO_MIN := 100.0
const ANCHO_MAX := 150.0
const SEPARACION := 8.0

var casillas: Array[CasillaAri] = []
var _rejilla: GridContainer


func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_deadzone = Pantalla.ZONA_MUERTA_ARRASTRE
	scroll_started.connect(Pantalla.cancelar_pulsaciones.bind(self))
	_rejilla = GridContainer.new()
	_rejilla.add_theme_constant_override("h_separation", int(SEPARACION))
	_rejilla.add_theme_constant_override("v_separation", int(SEPARACION))
	_rejilla.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_rejilla)
	resized.connect(_repartir)


## Crea las casillas del bloque «mimico» de un tablero, más el megóhmetro si lo lleva.
func preparar(mimico: Dictionary, simulacion: SimSimulacion) -> void:
	var lista: Array = []
	if mimico.has("alimentacion"):
		var a: Dictionary = mimico["alimentacion"].duplicate()
		a["tipo"] = "alimentacion"
		a["titulo"] = a.get("titulo", "ALIM. %s" % a.get("componente", ""))
		lista.append(a)
	lista.append_array(mimico.get("casillas", []))
	if mimico.has("megohmetro"):
		lista.append({"tipo": "megohmetro", "titulo": "MEGÓHMETRO", "franja": "amarillo"})
	for i in lista.size():
		var c := CasillaAri.new()
		c.name = "Casilla%d" % i
		c.datos = lista[i]
		c.sim = simulacion
		c.indice = i
		c.accion.connect(func(casilla: CasillaAri, que: String, valor: Variant) -> void: accion.emit(casilla, que, valor))
		_rejilla.add_child(c)
		casillas.append(c)
	_repartir()


func casilla_megohmetro() -> CasillaAri:
	for c in casillas:
		if c.tipo() == "megohmetro":
			return c
	return null


## Columnas según el ancho: cada casilla entre 100 y 150 de ancho, con su proporción.
func _repartir() -> void:
	if _rejilla == null or casillas.is_empty():
		return
	var ancho := size.x - 2.0
	if ancho < ANCHO_MIN:
		ancho = maxf(get_parent_area_size().x, ANCHO_MIN) if is_inside_tree() else ANCHO_MIN * 3.0
	var columnas := maxi(1, floori((ancho + SEPARACION) / (ANCHO_MIN + SEPARACION)))
	columnas = mini(columnas, casillas.size())
	var w := minf((ancho - SEPARACION * (columnas - 1)) / columnas, ANCHO_MAX)
	_rejilla.columns = columnas
	for c in casillas:
		c.custom_minimum_size = Vector2(floorf(w), floorf(w * CasillaAri.DISENO.y / CasillaAri.DISENO.x))
