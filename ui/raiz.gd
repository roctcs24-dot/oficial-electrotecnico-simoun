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
## Pantallas de Guardia y Taller, que se muestran dentro del marco de simulador.
const PANTALLAS_ARI := [
	"tableros", "guardia", "cuadro", "planta", "plc", "red_alarmas", "tablero", "taller",
	"mision", "mision_cuadro", "mision_planta", "mision_red", "indice_paneles", "leyenda",
]
## Margen alrededor de las pantallas sin marco.
const MARGEN_BASE := 12.0

var contenido := Contenido.new()
var partida: Partida
var ruta_partida := Partida.RUTA
## Disposición en una columna. Si se fija desde fuera (las pruebas lo hacen para recorrer las
## dos orientaciones), se respeta hasta el próximo cambio real de tamaño.
var vertical := false:
	set(valor):
		vertical = valor
		_vertical_fijado = true
var _vertical_fijado := false
## Pantalla en vertical (o apaisada pero estrecha): el marco pone los accesos en una tira.
var retrato := false
var paneles: Paneles
var eventos := EventosBuque.new()
## Marco de simulador de la pantalla actual, si la pantalla lo usa.
var marco: MarcoAri
## Panel derecho del marco plegado, para dar todo el ancho al tablero.
var marco_plegado := false
var _pila: Array[Dictionary] = []
var _actual: Pantalla
var _zona: MarginContainer
var _margen := Vector4.ZERO


func _ready() -> void:
	partida = Partida.new(ruta_partida)
	partida.cargar()
	Tema.escala_texto = float(partida.datos["ajustes"].get("tamano_texto", 1.0))
	theme = Tema.crear()
	paneles = Paneles.new(contenido)
	var fondo := ColorRect.new()
	fondo.color = Tema.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_zona = MarginContainer.new()
	_zona.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_zona)
	_ajustar_escala()
	resized.connect(_al_cambiar_tamano)
	ir_a("inicio")
	# La bienvenida sale la primera vez en la partida real; las partidas de prueba no la ven.
	if ruta_partida == Partida.RUTA and not partida.datos["ajustes"].get("bienvenida_vista", false):
		ir_a("bienvenida")


func ir_a(nombre: String, argumentos := {}) -> void:
	_pila.append({"nombre": nombre, "args": argumentos})
	reconstruir()


func volver() -> void:
	if _pila.size() > 1:
		_pila.pop_back()
		reconstruir()


## Cambia el tamaño del texto de todo el juego y lo guarda en la partida.
func aplicar_tamano_texto(escala: float) -> void:
	partida.datos["ajustes"]["tamano_texto"] = escala
	partida.guardar()
	Tema.escala_texto = escala
	theme = Tema.crear()
	reconstruir()


## Una sección de la barra de navegación empieza una pila nueva.
func ir_a_seccion(nombre: String) -> void:
	_pila = [{"nombre": nombre, "args": {}}]
	reconstruir()


## Abre un panel del índice. Si ya está abierta su pantalla con los mismos datos, solo cambia
## de pestaña y conserva la simulación; si la pantalla actual es otro panel, lo sustituye para
## que «Volver» no recorra todos los paneles vistos.
func ir_a_panel(codigo: String) -> void:
	var p := paneles.panel(codigo)
	if not Paneles.disponible(p):
		return
	var nuevos: Dictionary = p.get("args", {}).duplicate(true)
	nuevos["panel"] = codigo
	var entrada: Dictionary = _pila.back()
	if entrada["nombre"] == p["pantalla"] and _mismos_datos(entrada["args"], nuevos):
		entrada["args"].merge(nuevos, true)
		reconstruir()
		return
	var actual := paneles.codigo_de(entrada["nombre"], entrada["args"])
	if not actual.is_empty() and _pila.size() > 1:
		_pila.pop_back()
	ir_a(p["pantalla"], nuevos)


static func _mismos_datos(actuales: Dictionary, nuevos: Dictionary) -> bool:
	for clave: String in nuevos:
		if clave in ["pestana", "panel"]:
			continue
		if str(actuales.get(clave, "")) != str(nuevos[clave]):
			return false
	# El banco libre no lleva plantilla: no es el mismo banco que el de sensores.
	if nuevos.size() <= 1 and actuales.has("plantilla"):
		return false
	return true


func args_actuales() -> Dictionary:
	return _pila.back()["args"] if not _pila.is_empty() else {}


static func usa_marco(nombre: String) -> bool:
	return nombre in PANTALLAS_ARI


## Ancho que tiene la pantalla para su contenido, descontando márgenes y el marco.
func ancho_contenido() -> float:
	var ancho := size.x - _margen.x - _margen.z
	if usa_marco(nombre_actual()):
		return MarcoAri.ancho_util(ancho, retrato, marco_plegado)
	return ancho


## 1 en las pantallas de la barra de navegación; más, al entrar en ellas.
func nivel() -> int:
	return _pila.size()


func nombre_actual() -> String:
	return _pila.back()["nombre"] if not _pila.is_empty() else ""


func es_seccion() -> bool:
	return _pila.size() == 1 and BarraNavegacion.SECCIONES.any(func(s: Array) -> bool: return s[0] == nombre_actual())


func pantalla_actual() -> Pantalla:
	return _actual


## Rehace la pantalla de arriba de la pila, que vuelve a leer el progreso guardado.
func reconstruir() -> void:
	if marco != null:
		_zona.remove_child(marco)
		marco.queue_free()
		marco = null
	elif _actual != null:
		_zona.remove_child(_actual)
		_actual.queue_free()
	_actual = null
	var entrada: Dictionary = _pila.back()
	_ajustar_margenes()
	retrato = MarcoAri.es_retrato(size)
	if not _vertical_fijado:
		vertical = _calcular_vertical()
		_vertical_fijado = false
	var guion: GDScript = load(CARPETA_PANTALLAS % entrada["nombre"])
	_actual = guion.new()
	if usa_marco(entrada["nombre"]):
		marco = MarcoAri.new()
		_zona.add_child(marco)
		marco.preparar(self)
		marco.cuerpo.add_child(_actual)
	else:
		_zona.add_child(_actual)
	_actual.iniciar(self, entrada["args"])
	if marco != null:
		marco.montar(_actual)


func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _pila.size() > 1:
			volver()
		elif nombre_actual() != "inicio":
			ir_a_seccion("inicio")
		else:
			get_tree().quit()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		volver()
		accept_event()


func _al_cambiar_tamano() -> void:
	_ajustar_escala()
	_ajustar_margenes()
	if _pila.is_empty():
		return
	var en_retrato := MarcoAri.es_retrato(size)
	var ahora := _calcular_vertical()
	if ahora != vertical or (marco != null and en_retrato != retrato):
		vertical = ahora
		_vertical_fijado = false
		retrato = en_retrato
		reconstruir.call_deferred()


## Dentro del marco cuenta el ancho que le queda a la pantalla: con el panel derecho abierto
## en un celular apaisado, la pantalla usa su disposición en una columna.
func _calcular_vertical() -> bool:
	if not _pila.is_empty() and usa_marco(nombre_actual()):
		return MarcoAri.es_retrato(size) or ancho_contenido() < ANCHO_MIN_HORIZONTAL - MARGEN_BASE * 2.0
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
	var base := 0.0 if not _pila.is_empty() and usa_marco(nombre_actual()) else MARGEN_BASE
	var margen := Vector4(base, base, base, base)
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
	_margen = margen
