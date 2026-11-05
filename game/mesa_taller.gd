class_name MesaTaller
extends RefCounted
## Banco de pruebas libre: piezas con posición, cables y simulación. No depende de la
## interfaz, así se puede probar sin pantalla.

const CARPETA := "user://circuitos/"
const AUTOGUARDADO := "user://taller_ultimo.json"
const COLUMNAS_PLANTILLA := 4
const SEPARACION_PLANTILLA := Vector2(540.0, 640.0)
const CURVA_CABLE := 0.12
const PUNTOS_CABLE := 12
## Colores de IEC 60445 para potencia; los cables de mando van en rojo.
const COLOR_FASE := {"1": Color("7a4a24"), "2": Color("7a4a24"), "3": Color("17181a"), "4": Color("17181a"), "5": Color("8a8f93"), "6": Color("8a8f93"),
	"L1": Color("7a4a24"), "L2": Color("17181a"), "L3": Color("8a8f93"), "U1": Color("7a4a24"), "V1": Color("17181a"), "W1": Color("8a8f93")}
const COLOR_MANDO := Color("b02a22")

var contenido: Contenido
var sim := SimSimulacion.new()
## id -> {tipo, x, y}, donde tipo es el id en el catálogo de data/taller.json.
var piezas := {}
var _eventos_vistos := 0


func _init(contenido_juego: Contenido) -> void:
	contenido = contenido_juego


func catalogo() -> Array:
	return contenido.leer("taller.json").get("componentes", [])


func entrada(id_catalogo: String) -> Dictionary:
	for e: Dictionary in catalogo():
		if e["id"] == id_catalogo:
			return e
	return {}


## Dibujo de una entrada: el suyo, o el de la ficha del equipo si la indica.
func dibujo(id_catalogo: String) -> Dictionary:
	var e := entrada(id_catalogo)
	if e.has("ficha"):
		return contenido.ficha(e["ficha"]).get("dibujo", {})
	return e


func agregar(id_catalogo: String, posicion: Vector2) -> String:
	var e := entrada(id_catalogo)
	var id := _id_libre(e["prefijo"])
	var clase: GDScript = SimSimulacion.tipos()[e["tipo"]]
	sim.agregar(clase.new(id, e.get("params", {}).duplicate(true)))
	piezas[id] = {"tipo": id_catalogo, "x": posicion.x, "y": posicion.y}
	return id


func _id_libre(prefijo: String) -> String:
	var n := 1
	while piezas.has("%s%d" % [prefijo, n]):
		n += 1
	return "%s%d" % [prefijo, n]


func quitar(id: String) -> void:
	piezas.erase(id)
	sim.componentes.erase(id)
	var prefijo := id + "."
	sim.cables = sim.cables.filter(func(c: Array) -> bool:
		return not (c[0].begins_with(prefijo) or c[1].begins_with(prefijo)))


## Devuelve false si no tiene sentido: un borne consigo mismo o un cable repetido.
func conectar(a: String, b: String) -> bool:
	if a == b or a.is_empty() or b.is_empty():
		return false
	for c: Array in sim.cables:
		if (c[0] == a and c[1] == b) or (c[0] == b and c[1] == a):
			return false
	sim.conectar(a, b)
	return true


func quitar_cable(indice: int) -> void:
	sim.cables.remove_at(indice)


func bornes(id: String) -> Dictionary:
	return entrada(piezas[id]["tipo"])["bornes"]


func posicion_pieza(id: String) -> Vector2:
	return Vector2(piezas[id]["x"], piezas[id]["y"])


func mover(id: String, posicion: Vector2) -> void:
	piezas[id]["x"] = posicion.x
	piezas[id]["y"] = posicion.y


func tamano_pieza(id: String) -> Vector2:
	var t: Array = dibujo(piezas[id]["tipo"])["tamano"]
	return Vector2(t[0], t[1])


## Posición en la mesa de un nodo "K1.A1".
func posicion_borne(nodo: String) -> Vector2:
	var partes := nodo.split(".")
	var b: Array = bornes(partes[0])[partes[1]]
	return posicion_pieza(partes[0]) + Vector2(b[0], b[1])


## Borne más cercano dentro del radio, o "".
func borne_en(punto: Vector2, radio: float) -> String:
	var mejor := ""
	var distancia := radio
	for id: String in piezas:
		for b: String in bornes(id):
			var nodo := "%s.%s" % [id, b]
			var d := posicion_borne(nodo).distance_to(punto)
			if d <= distancia:
				distancia = d
				mejor = nodo
	return mejor


## La pieza dibujada más arriba bajo el punto, o "".
func pieza_en(punto: Vector2) -> String:
	var encontrada := ""
	for id: String in piezas:
		if Rect2(posicion_pieza(id), tamano_pieza(id)).has_point(punto):
			encontrada = id
	return encontrada


func puntos_cable(indice: int) -> PackedVector2Array:
	var c: Array = sim.cables[indice]
	var a := posicion_borne(c[0])
	var b := posicion_borne(c[1])
	var control := (a + b) / 2.0 + Vector2(0.0, a.distance_to(b) * CURVA_CABLE)
	var puntos := PackedVector2Array()
	for i in PUNTOS_CABLE + 1:
		var t := float(i) / PUNTOS_CABLE
		puntos.append(a.lerp(control, t).lerp(control.lerp(b, t), t))
	return puntos


## Cable más cercano al punto, o -1.
func cable_en(punto: Vector2, tolerancia: float) -> int:
	var mejor := -1
	var distancia := tolerancia
	for i in sim.cables.size():
		var p := puntos_cable(i)
		for j in p.size() - 1:
			var d := Geometry2D.get_closest_point_to_segment(punto, p[j], p[j + 1]).distance_to(punto)
			if d <= distancia:
				distancia = d
				mejor = i
	return mejor


func color_cable(indice: int) -> Color:
	var c: Array = sim.cables[indice]
	for nodo: String in c:
		var borne := nodo.get_slice(".", 1)
		var es_potencia: bool = entrada(piezas[nodo.get_slice(".", 0)]["tipo"]).get("potencia", false)
		if es_potencia and COLOR_FASE.has(borne):
			return COLOR_FASE[borne]
	return COLOR_MANDO


func a_dict() -> Dictionary:
	return {"piezas": piezas.duplicate(true), "circuito": sim.a_dict()}


## Devuelve false si los datos no se pueden interpretar; entonces la mesa no cambia.
func desde_dict(datos: Variant) -> bool:
	if not datos is Dictionary or not datos.has("piezas") or not datos.has("circuito"):
		return false
	for pieza: Dictionary in datos["piezas"].values():
		if entrada(pieza.get("tipo", "")).is_empty():
			return false
	piezas = datos["piezas"].duplicate(true)
	sim = SimSimulacion.desde_dict(datos["circuito"])
	_eventos_vistos = 0
	return true


func vaciar() -> void:
	piezas = {}
	sim = SimSimulacion.new()
	_eventos_vistos = 0


func _ruta(nombre: String) -> String:
	return CARPETA + nombre.validate_filename() + ".json"


func guardar(nombre: String) -> bool:
	if nombre.strip_edges().is_empty():
		return false
	DirAccess.make_dir_recursive_absolute(CARPETA)
	return _escribir(_ruta(nombre))


func _escribir(ruta: String) -> bool:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(a_dict(), "\t"))
	f.close()
	return true


func cargar(nombre: String) -> bool:
	return _leer(_ruta(nombre))


func _leer(ruta: String) -> bool:
	if not FileAccess.file_exists(ruta):
		return false
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(ruta)) != OK:
		return false
	return desde_dict(json.data)


func autoguardar() -> void:
	_escribir(AUTOGUARDADO)


func recuperar_autoguardado() -> bool:
	return _leer(AUTOGUARDADO)


func borrar(nombre: String) -> void:
	if FileAccess.file_exists(_ruta(nombre)):
		DirAccess.remove_absolute(_ruta(nombre))


func circuitos_guardados() -> Array[String]:
	var lista: Array[String] = []
	if DirAccess.dir_exists_absolute(CARPETA):
		for f in DirAccess.get_files_at(CARPETA):
			if f.ends_with(".json"):
				lista.append(f.get_basename())
	lista.sort()
	return lista


## Coloca una plantilla de data/circuitos en la mesa, en filas.
func cargar_plantilla(nombre: String) -> bool:
	var plantilla := contenido.circuito(nombre)
	if plantilla == null:
		return false
	piezas = {}
	sim = plantilla
	_eventos_vistos = 0
	var n := 0
	for c: SimComponente in sim.componentes.values():
		var fila := n / COLUMNAS_PLANTILLA
		var columna := n % COLUMNAS_PLANTILLA
		piezas[c.id] = {"tipo": _catalogo_de(c), "x": columna * SEPARACION_PLANTILLA.x, "y": fila * SEPARACION_PLANTILLA.y}
		n += 1
	return true


func _catalogo_de(c: SimComponente) -> String:
	match c.tipo():
		"pulsador":
			return "pulsador_na" if c.params["contacto"] == "NA" else "pulsador_nc"
		"motor_trifasico":
			return "motor_254" if is_equal_approx(c.params["v_delta"], 254.0) else "motor_440"
	return c.tipo()


func avanzar(pasos: int) -> void:
	for _i in pasos:
		sim.paso()


## Eventos ocurridos desde la última consulta.
func eventos_nuevos() -> Array:
	var nuevos := sim.eventos.slice(_eventos_vistos)
	_eventos_vistos = sim.eventos.size()
	return nuevos


func danada(id: String) -> bool:
	var e: Dictionary = sim.componente(id).estado
	return e.get("quemado", false) or e.get("soldado", false) or e.get("bobina_quemada", false) \
		or e.get("fundido", false) or e.get("quemada", false)


func reparar(id: String) -> void:
	var c := sim.componente(id)
	var presionado: bool = c.estado.get("presionado", false)
	c.reemplazar()
	if c.estado.has("presionado"):
		c.estado["presionado"] = presionado


func estado_pieza(id: String) -> String:
	var c := sim.componente(id)
	var e: Dictionary = c.estado
	match c.tipo():
		"fuente_trifasica":
			if e["disparada"]:
				return "Interruptor disparado"
			return "Con tensión" if e["activa"] else "Sin tensión"
		"contactor":
			if e["soldado"]:
				return "Contactos soldados"
			if e["bobina_quemada"]:
				return "Bobina quemada"
			return "Cerrado" if e["energizada"] else "Abierto"
		"rele_termico":
			return "Disparado" if e["disparado"] else "Normal"
		"guardamotor":
			if e["disparado"]:
				return "Disparado"
			return "Cerrado" if e["encendido"] else "Abierto"
		"motor_trifasico":
			if e["quemado"]:
				return "Quemado"
			return "%s rpm · %s °C" % [TextoTecnico.numero(absf(e["rpm"]), 0), TextoTecnico.numero(e["temperatura"], 0)]
		"lampara":
			if e["quemada"]:
				return "Quemada"
			return "Encendida" if e["encendida"] else "Apagada"
		"fusible":
			return "Fundido" if e["fundido"] else "Normal"
		"pulsador":
			return "Pulsado" if e["presionado"] else "En reposo"
		"temporizador":
			return "Conmutado" if e["conmutado"] else ("Contando" if e["bobina"] else "En reposo")
		"transformador_mando":
			return "440 / 110 V"
		"resistencia":
			return "%s Ω" % TextoTecnico.numero(c.params.get("ohm", 0.0), 0)
	return ""
