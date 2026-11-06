class_name Raiz
extends Control
## Contenedor del juego: tema, escala, margen seguro y pila de pantallas.

const CARPETA_PANTALLAS := "res://ui/screens/%s.gd"
## La interfaz se mide en puntos independientes de la densidad, para que un botón de 48
## mida lo mismo en un celular que en un monitor.
const DPI_BASE_MOVIL := 160.0
const DPI_BASE_PC := 96.0
const LADO_CORTO_MIN := 360.0
const LADO_CORTO_MAX := 600.0
## Una tableta con una densidad creíble puede pasar de 600 puntos de lado corto. Por debajo de
## DPI_CREIBLE se supone una densidad mal informada y se mantiene el límite de un celular.
const LADO_CORTO_MAX_TABLETA := 900.0
const DPI_CREIBLE := 200.0
const ANCHO_MIN_HORIZONTAL := 720.0

var contenido := Contenido.new()
var partida: Partida
var ruta_partida := Partida.RUTA
var vertical := false
var _pila: Array[Dictionary] = []
var _actual: Pantalla
var _zona: MarginContainer


func _ready() -> void:
	theme = Tema.crear()
	partida = Partida.new(ruta_partida)
	partida.cargar()
	var fondo := ColorRect.new()
	fondo.color = Tema.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_zona = MarginContainer.new()
	_zona.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_zona)
	_ajustar_escala()
	_ajustar_margenes()
	vertical = _calcular_vertical()
	resized.connect(_al_cambiar_tamano)
	ir_a("plano_barco")


func ir_a(nombre: String, argumentos := {}) -> void:
	_pila.append({"nombre": nombre, "args": argumentos})
	reconstruir()


func volver() -> void:
	if _pila.size() > 1:
		_pila.pop_back()
		reconstruir()


func pantalla_actual() -> Pantalla:
	return _actual


## Rehace la pantalla de arriba de la pila, que vuelve a leer el progreso guardado.
func reconstruir() -> void:
	if _actual != null:
		_zona.remove_child(_actual)
		_actual.queue_free()
	var entrada: Dictionary = _pila.back()
	var guion: GDScript = load(CARPETA_PANTALLAS % entrada["nombre"])
	_actual = guion.new()
	_zona.add_child(_actual)
	_actual.iniciar(self, entrada["args"])


func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _pila.size() > 1:
			volver()
		else:
			get_tree().quit()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		volver()
		accept_event()


func _al_cambiar_tamano() -> void:
	_ajustar_escala()
	_ajustar_margenes()
	var ahora := _calcular_vertical()
	if ahora != vertical:
		vertical = ahora
		reconstruir.call_deferred()


func _calcular_vertical() -> bool:
	return size.x < size.y or size.x < ANCHO_MIN_HORIZONTAL


func _ajustar_escala() -> void:
	var ventana := get_window()
	var movil := OS.has_feature("mobile")
	var dpi := float(DisplayServer.screen_get_dpi())
	var escala := dpi / (DPI_BASE_MOVIL if movil else DPI_BASE_PC)
	if movil:
		# Algunos celulares informan mal su densidad: el tamaño físico pone los límites.
		var lado_corto := float(mini(ventana.size.x, ventana.size.y))
		escala = clampf(escala, lado_corto / lado_corto_maximo(dpi), lado_corto / LADO_CORTO_MIN)
	escala = maxf(escala, 1.0)
	if not is_equal_approx(ventana.content_scale_factor, escala):
		ventana.content_scale_factor = escala


static func lado_corto_maximo(dpi: float) -> float:
	return LADO_CORTO_MAX_TABLETA if dpi >= DPI_CREIBLE else LADO_CORTO_MAX


func _ajustar_margenes() -> void:
	var margen := Vector4(12.0, 12.0, 12.0, 12.0)
	if OS.has_feature("mobile"):
		var ventana := get_window()
		var seguro := DisplayServer.get_display_safe_area()
		var factor := ventana.content_scale_factor
		margen.x += seguro.position.x / factor
		margen.y += seguro.position.y / factor
		margen.z += maxf(ventana.size.x - seguro.end.x, 0.0) / factor
		margen.w += maxf(ventana.size.y - seguro.end.y, 0.0) / factor
	_zona.add_theme_constant_override("margin_left", int(margen.x))
	_zona.add_theme_constant_override("margin_top", int(margen.y))
	_zona.add_theme_constant_override("margin_right", int(margen.z))
	_zona.add_theme_constant_override("margin_bottom", int(margen.w))
