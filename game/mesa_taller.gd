class_name MesaTaller
extends RefCounted
## Banco de pruebas libre: piezas con posición, cables y simulación. No depende de la
## interfaz, así se puede probar sin pantalla.

const CARPETA := "user://circuitos/"
const AUTOGUARDADO := "user://taller_ultimo.json"
const COLUMNAS_PLANTILLA := 4
const SEPARACION_PLANTILLA := Vector2(540.0, 640.0)
const CURVA_CABLE := 0.12
const PUNTOS_CABLE := 20
## Cuánto sale recto el cable del borne antes de curvarse, en proporción a su largo y con topes.
const SALIDA_CABLE := 0.35
const SALIDA_MIN := 30.0
const SALIDA_MAX := 120.0
## Tramo recto del cable al salir del borne (puntera, cuello y manguito), en unidades de mesa.
const TRAMO_RECTO := 50.0
const CANALES_CABLE := 9
const SEPARACION_CANALES := 22.0
## Código de colores de los conductores (IEC 60445 y, en el mando, IEC 60204-1). Cada uno con su
## color, la raya longitudinal del aislante (transparente si no tiene) y su nombre.
const CONDUCTORES := {
	"L1": {"color": Color("7a4a24"), "nombre": "L1 · fase 1", "color_nombre": "marrón"},
	"L2": {"color": Color("17181a"), "nombre": "L2 · fase 2", "color_nombre": "negro"},
	"L3": {"color": Color("8a8f93"), "nombre": "L3 · fase 3", "color_nombre": "gris"},
	"N": {"color": Color("4f9fd8"), "nombre": "N · neutro", "color_nombre": "azul claro"},
	"PE": {"color": Color("d9b81c"), "raya": Color("2f8f34"), "nombre": "PE · tierra de protección", "color_nombre": "verde-amarillo"},
	"CA": {"color": Color("b02a22"), "nombre": "Mando en alterna", "color_nombre": "rojo"},
	"CC": {"color": Color("2747a8"), "nombre": "Mando en continua (+24 V)", "color_nombre": "azul oscuro"},
	"0V": {"color": Color("2747a8"), "raya": Color("e2e5e0"), "nombre": "0 V de continua", "color_nombre": "azul con raya blanca"},
	"EXT": {"color": Color("e36d14"), "nombre": "Enclavamiento con tensión externa", "color_nombre": "naranja"},
	"BN": {"color": Color("7a4a24"), "nombre": "BN · positivo del sensor", "color_nombre": "marrón, del cable del sensor"},
	"BU": {"color": Color("2a6cb8"), "nombre": "BU · 0 V del sensor", "color_nombre": "azul, del cable del sensor"},
	"BK": {"color": Color("17181a"), "nombre": "BK · salida del sensor", "color_nombre": "negro, del cable del sensor"},
}
## Orden de la leyenda.
const LEYENDA_CONDUCTORES := ["L1", "L2", "L3", "N", "PE", "CA", "CC", "0V", "EXT"]
## Bornes de fase de los aparatos de potencia (1-2, 3-4, 5-6) y del motor y las barras.
const FASE_BORNE := {"1": "L1", "2": "L1", "3": "L2", "4": "L2", "5": "L3", "6": "L3", "U1": "L1", "V1": "L2", "W1": "L3"}
## Nombres de color que admite «colores» en el JSON del tablero, además de las claves de CONDUCTORES.
const COLOR_A_CONDUCTOR := {"naranja": "EXT", "rojo": "CA", "azul_oscuro": "CC", "azul_claro": "N", "verde_amarillo": "PE"}
## Piezas que cambiaron de nombre al pasar la red a 380 V: los circuitos guardados antes se
## siguen abriendo.
const RENOMBRADOS := {"motor_440": "motor_380", "motor_254": "motor_220"}

var contenido: Contenido
var sim := SimSimulacion.new()
## id -> {tipo, x, y}, donde tipo es el id en el catálogo de data/taller.json.
var piezas := {}
## "a|b" -> ruta del cable. Solo es presentación: la simulación no la usa.
var rutas := {}
## En una misión, averías que no se ven a simple vista: hay que encontrarlas midiendo.
var ocultas := {}
var _eventos_vistos := 0


func _init(contenido_juego: Contenido) -> void:
	contenido = contenido_juego


func catalogo() -> Array:
	return contenido.leer("taller.json").get("componentes", [])


func entrada(id_catalogo: String) -> Dictionary:
	id_catalogo = RENOMBRADOS.get(id_catalogo, id_catalogo)
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
	var params: Dictionary = e.get("params", {}).duplicate(true)
	if params.has("programa_de"):
		# Un PLC del cajón llega con su programa de prueba cargado.
		var programa := contenido.plc(params["programa_de"])
		params["programa"] = programa.get("programa", [])
		params["etiquetas"] = programa.get("etiquetas", {})
	sim.agregar(clase.new(id, params))
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
	rutas.erase(_clave_cable(indice))
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


## Posición en la mesa de un nodo "K1.A1". El borne puede llevar puntos, como "PLC.I0.0":
## solo el primero separa la pieza del borne.
func posicion_borne(nodo: String) -> Vector2:
	var id := nodo.get_slice(".", 0)
	var b: Array = bornes(id)[borne_de(nodo)]
	return posicion_pieza(id) + Vector2(b[0], b[1])


static func borne_de(nodo: String) -> String:
	return nodo.substr(nodo.find(".") + 1)


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


func _clave_cable(indice: int) -> String:
	var c: Array = sim.cables[indice]
	return "%s|%s" % [c[0], c[1]]


## La ruta de un cable: estilo (curva, angulos o recta) y desplazamiento respecto al punto
## medio entre sus bornes, para que siga al cable cuando se mueven las piezas.
func ruta_cable(indice: int) -> Dictionary:
	return rutas.get(_clave_cable(indice), {"estilo": "curva", "dx": 0.0, "dy": 0.0})


func fijar_estilo_cable(indice: int, estilo: String) -> void:
	var r := ruta_cable(indice).duplicate()
	r["estilo"] = estilo
	rutas[_clave_cable(indice)] = r


## Punto del que se arrastra un cable para acomodarlo. Una recta no tiene ninguno.
func mango_cable(indice: int) -> Vector2:
	var r := ruta_cable(indice)
	var c: Array = sim.cables[indice]
	var a := posicion_borne(c[0])
	var b := posicion_borne(c[1])
	var medio := (a + b) / 2.0
	match r["estilo"]:
		"curva":
			var p := puntos_cable(indice)
			return p[p.size() / 2]
		"angulos":
			return Vector2(medio.x, medio.y + r["dy"])
	return medio


func tiene_mango(indice: int) -> bool:
	return ruta_cable(indice)["estilo"] != "recta"


func mover_mango(indice: int, punto: Vector2) -> void:
	var r := ruta_cable(indice).duplicate()
	var c: Array = sim.cables[indice]
	var a := posicion_borne(c[0])
	var b := posicion_borne(c[1])
	var medio := (a + b) / 2.0
	if r["estilo"] == "curva":
		# El punto medio de la curva (t = 0,5) pesa 1/16 los extremos, 4/16 los controles de salida
		# y 6/16 el control del medio (medio + desvío + caída).
		var k := _controles_curva(c)
		var fijo: Vector2 = (k[0] + k[3] + (k[1] + k[2]) * 4.0) / 16.0
		var d: Vector2 = (punto - fijo) / 0.375 - (k[0] + k[3]) / 2.0 - _caida(k[0], k[3])
		r["dx"] = d.x
		r["dy"] = d.y
	else:
		r["dy"] = punto.y - medio.y
	rutas[_clave_cable(indice)] = r


## Pasa todos los cables a ángulos rectos, cada uno en su propio canal para que no se
## tapen entre sí. Llamarlo de nuevo con todos ordenados los devuelve a curvas.
func ordenar_cables() -> void:
	var todos_ordenados := not sim.cables.is_empty()
	for i in sim.cables.size():
		if ruta_cable(i)["estilo"] != "angulos":
			todos_ordenados = false
	if todos_ordenados:
		rutas = {}
		return
	for i in sim.cables.size():
		var canal := (i % CANALES_CABLE) - CANALES_CABLE / 2
		rutas[_clave_cable(i)] = {"estilo": "angulos", "dx": 0.0, "dy": float(canal) * SEPARACION_CANALES}


func puntos_cable(indice: int) -> PackedVector2Array:
	var c: Array = sim.cables[indice]
	var a := posicion_borne(c[0])
	var b := posicion_borne(c[1])
	var r := ruta_cable(indice)
	var medio := (a + b) / 2.0
	match r["estilo"]:
		"recta":
			return PackedVector2Array([a, b])
		"angulos":
			var y: float = medio.y + r["dy"]
			return PackedVector2Array([a, Vector2(a.x, y), Vector2(b.x, y), b])
	# El cable sale recto de cada borne, alejándose del aparato, y luego sigue una curva de grado 4.
	# El desvío y la caída van solo en el control del medio: no tuercen la salida.
	var k := _controles_curva(c)
	var a2: Vector2 = k[0]
	var c1: Vector2 = k[1]
	var c3: Vector2 = k[2]
	var b2: Vector2 = k[3]
	var c2 := (a2 + b2) / 2.0 + Vector2(r["dx"], r["dy"]) + _caida(a2, b2)
	var puntos := PackedVector2Array([a])
	for i in PUNTOS_CABLE + 1:
		# Puntos más juntos cerca de los extremos, donde el cable se dobla; t = 0,5 en el medio.
		var t := (1.0 - cos(PI * i / PUNTOS_CABLE)) / 2.0
		var u := 1.0 - t
		puntos.append(a2 * u * u * u * u + c1 * 4.0 * u * u * u * t + c2 * 6.0 * u * u * t * t + c3 * 4.0 * u * t * t * t + b2 * t * t * t * t)
	puntos.append(b)
	return puntos


## Extremos del tramo curvo (tras el tramo recto de salida de cada borne) y sus controles de
## salida: [inicio, control 1, control 2, fin].
func _controles_curva(c: Array) -> Array:
	var a := posicion_borne(c[0])
	var b := posicion_borne(c[1])
	var da := salida_borne(c[0])
	var db := salida_borne(c[1])
	var recto := minf(TRAMO_RECTO, a.distance_to(b) * 0.25)
	var a2 := a + da * recto
	var b2 := b + db * recto
	var largo := _largo_salida(a2, b2)
	return [a2, a2 + da * largo, b2 + db * largo, b2]


## Hacia dónde sale un cable de su borne: alejándose del centro del aparato, por el lado más
## cercano (arriba o abajo en contactores y relés; a un costado en bornes laterales).
func salida_borne(nodo: String) -> Vector2:
	var id := nodo.get_slice(".", 0)
	var tam := tamano_pieza(id)
	var rel := posicion_borne(nodo) - (posicion_pieza(id) + tam / 2.0)
	rel = Vector2(rel.x / maxf(tam.x, 1.0), rel.y / maxf(tam.y, 1.0))
	if absf(rel.x) > absf(rel.y):
		return Vector2(signf(rel.x), 0.0)
	return Vector2(0.0, -1.0 if rel.y < 0.0 else 1.0)


func _largo_salida(a: Vector2, b: Vector2) -> float:
	return clampf(a.distance_to(b) * SALIDA_CABLE, SALIDA_MIN, SALIDA_MAX)


## Caída del control del medio: el centro del cable cuelga CURVA_CABLE/2 de su largo, como antes.
func _caida(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(0.0, a.distance_to(b) * CURVA_CABLE / 0.75)


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


## Número de hilo de cada cable, por potencial: todos los cables unidos entre sí sin pasar por un
## aparato (un mismo punto eléctrico) llevan el mismo número, como en los tableros (IEC 81346).
##   L1, L2, L3  si el punto toca un borne de fase de la alimentación;
##   N, PE       neutro y tierra;
##   1U1, 2V1…   bornes del motor, con el número del motor delante (M1 → 1);
##   1L1, 2L3…   potencia tras el aparato nº 1, 2… (Q1, AS2): la fase sale del borne (1-2, 3-4, 5-6);
##   1, 2, 3…    el resto, en el orden de los cables.
## «hilos» (del tablero, opcional) fija el número de un punto por uno de sus nodos: {"Q1.14": "21"}.
var hilos := {}
var _cache_hilos := {"clave": -1, "numeros": []}


func numero_hilo(indice: int) -> String:
	var numeros: Array = _numeros_hilos()
	return str(numeros[indice]) if indice < numeros.size() else ""


## Marcador de los dos extremos de un cable: su número de hilo.
func marcador(indice: int, _extremo: int) -> String:
	return numero_hilo(indice)


func _numeros_hilos() -> Array:
	var clave := hash([sim.cables, hilos])
	if int(_cache_hilos["clave"]) == clave:
		return _cache_hilos["numeros"]
	# Puntos eléctricos: unión de los nodos que une cada cable.
	var padre := {}
	var raiz := func(n: String) -> String:
		var r := n
		while padre.get(r, r) != r:
			r = padre[r]
		return r
	for c: Array in sim.cables:
		for n: String in c:
			if not padre.has(n):
				padre[n] = n
		var a: String = raiz.call(c[0])
		var b: String = raiz.call(c[1])
		if a != b:
			padre[b] = a
	var redes := {}
	var orden: Array[String] = []
	for c: Array in sim.cables:
		var r: String = raiz.call(c[0])
		if not redes.has(r):
			redes[r] = []
			orden.append(r)
		for n: String in c:
			if not redes[r].has(n):
				redes[r].append(n)
	var nombre_red := {}
	var usados := {}
	for r: String in orden:
		var nombre := _nombre_red(redes[r])
		if not nombre.is_empty() and not usados.has(nombre):
			nombre_red[r] = nombre
			usados[nombre] = true
	var siguiente := 1
	for r: String in orden:
		if nombre_red.has(r):
			continue
		while usados.has(str(siguiente)):
			siguiente += 1
		nombre_red[r] = str(siguiente)
		usados[str(siguiente)] = true
	var numeros := []
	for c: Array in sim.cables:
		numeros.append(nombre_red[raiz.call(c[0])])
	_cache_hilos = {"clave": clave, "numeros": numeros}
	return numeros


func _nombre_red(nodos: Array) -> String:
	for n: String in nodos:
		if hilos.has(n):
			return str(hilos[n])
	var bornes_red := nodos.map(func(n: String) -> String: return borne_de(n))
	for especial: String in ["PE", "N", "L1", "L2", "L3"]:
		if bornes_red.has(especial):
			return especial
	for n: String in nodos:
		var id := n.get_slice(".", 0)
		var b := borne_de(n)
		if piezas.has(id) and str(piezas[id]["tipo"]).begins_with("motor") and b.length() == 2 and b[0] in ["U", "V", "W"]:
			return _digitos(id) + b
	var potencia := false
	for n: String in nodos:
		var id := n.get_slice(".", 0)
		if piezas.has(id) and entrada(piezas[id]["tipo"]).get("potencia", false) and borne_de(n) in ["1", "2", "3", "4", "5", "6"]:
			potencia = true
	if potencia:
		for n: String in nodos:
			var id := n.get_slice(".", 0)
			var b := borne_de(n)
			if piezas.has(id) and entrada(piezas[id]["tipo"]).get("potencia", false) and b in ["2", "4", "6"] and not _digitos(id).is_empty():
				return "%sL%d" % [_digitos(id), int(b) / 2]
	return ""


static func _digitos(id: String) -> String:
	var r := ""
	for ch in id:
		if ch >= "0" and ch <= "9":
			r += ch
	return r


## true si el cable es de potencia: una fase o la tierra de un aparato de potencia (puntera de
## 2,5 mm², cuello azul).
func cable_de_potencia(indice: int) -> bool:
	return conductor_cable(indice) in ["L1", "L2", "L3", "PE"]


## Datos del cable para el panel: su número de hilo, desde y hasta (borne y nombre del aparato) y
## si es de potencia.
func descripcion_cable(indice: int) -> Dictionary:
	var c: Array = sim.cables[indice]
	var lados := []
	for nodo: String in c:
		var id := nodo.get_slice(".", 0)
		var nombre := str(entrada(piezas[id]["tipo"]).get("nombre", id)) if piezas.has(id) else id
		lados.append({"borne": nodo.replace(".", ":"), "aparato": nombre})
	var conductor := conductor_cable(indice)
	return {"numero": numero_hilo(indice), "desde": lados[0], "hasta": lados[1], "potencia": cable_de_potencia(indice),
		"conductor": conductor, "nombre_conductor": CONDUCTORES[conductor]["nombre"], "color_nombre": CONDUCTORES[conductor]["color_nombre"]}


## Cables con el mismo número de hilo que el dado (el mismo punto eléctrico), él incluido.
func cables_del_hilo(indice: int) -> Array[int]:
	var n := numero_hilo(indice)
	var r: Array[int] = []
	for k in sim.cables.size():
		if numero_hilo(k) == n:
			r.append(k)
	return r


func color_cable(indice: int) -> Color:
	return CONDUCTORES[conductor_cable(indice)]["color"]


## Raya longitudinal del aislante (verde en el PE, blanca en el 0 V) o transparente.
func raya_cable(indice: int) -> Color:
	return CONDUCTORES[conductor_cable(indice)].get("raya", Color.TRANSPARENT)


## «colores» (del tablero, opcional) fija el conductor de un punto eléctrico por uno de sus nodos
## o por su número de hilo: {"Q1.14": "naranja"} o {"21": "naranja"}. Sirve para lo que no se
## deduce de los bornes, como un enclavamiento alimentado desde otro tablero.
var colores := {}
var _cache_conductores := {"clave": -1, "lista": []}


## Conductor del cable según los bornes de sus extremos, en este orden: lo que fije el tablero,
## tierra (PE), los hilos del propio cable de un sensor, fase de potencia, neutro, continua (0 V o
## +24 V y señales) y, si no, mando en alterna.
func conductor_cable(indice: int) -> String:
	var clave := hash([sim.cables, colores, hilos, piezas.keys()])
	if int(_cache_conductores["clave"]) != clave:
		var lista := []
		for i in sim.cables.size():
			lista.append(_conductor(i))
		_cache_conductores = {"clave": clave, "lista": lista}
	var l: Array = _cache_conductores["lista"]
	return str(l[indice]) if indice < l.size() else "CA"


func _conductor(indice: int) -> String:
	var c: Array = sim.cables[indice]
	if not colores.is_empty():
		var fijado := _conductor_fijado(indice)
		if not fijado.is_empty():
			return fijado
	var info := []
	for nodo: String in c:
		var id := nodo.get_slice(".", 0)
		info.append({"borne": borne_de(nodo), "entrada": entrada(piezas[id]["tipo"]) if piezas.has(id) else {}})
	for d: Dictionary in info:
		if d["borne"] == "PE":
			return "PE"
	for d: Dictionary in info:
		if d["entrada"].get("tipo", "") == "sensor_proximidad" and d["borne"] in ["BN", "BU", "BK"]:
			return d["borne"]
	for d: Dictionary in info:
		var b: String = d["borne"]
		var fases: Dictionary = d["entrada"].get("fases", {})
		if fases.has(b):
			return fases[b]
		if b in ["L1", "L2", "L3"]:
			return b
		if d["entrada"].get("potencia", false) and FASE_BORNE.has(b):
			return FASE_BORNE[b]
	for d: Dictionary in info:
		if d["borne"] == "N":
			return "N"
	for d: Dictionary in info:
		if d["borne"] in d["entrada"].get("cero_v", []):
			return "0V"
	for d: Dictionary in info:
		var cc: Variant = d["entrada"].get("cc", false)
		if (cc is bool and cc) or (cc is Array and d["borne"] in cc):
			return "CC"
	return "CA"


func _conductor_fijado(indice: int) -> String:
	var valor := ""
	var numero := numero_hilo(indice)
	if colores.has(numero):
		valor = str(colores[numero])
	else:
		for k in cables_del_hilo(indice):
			for nodo: String in sim.cables[k]:
				if colores.has(nodo):
					valor = str(colores[nodo])
	valor = COLOR_A_CONDUCTOR.get(valor, valor)
	return valor if CONDUCTORES.has(valor) else ""


func a_dict() -> Dictionary:
	return {"piezas": piezas.duplicate(true), "rutas": rutas.duplicate(true), "circuito": sim.a_dict()}


## Devuelve false si los datos no se pueden interpretar; entonces la mesa no cambia.
func desde_dict(datos: Variant) -> bool:
	if not datos is Dictionary or not datos.has("piezas") or not datos.has("circuito"):
		return false
	for pieza: Dictionary in datos["piezas"].values():
		if entrada(pieza.get("tipo", "")).is_empty():
			return false
	piezas = datos["piezas"].duplicate(true)
	rutas = datos.get("rutas", {}).duplicate(true)
	sim = SimSimulacion.desde_dict(datos["circuito"])
	_eventos_vistos = 0
	return true


func vaciar() -> void:
	piezas = {}
	rutas = {}
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
	rutas = {}
	sim = plantilla
	_eventos_vistos = 0
	var n := 0
	for c: SimComponente in sim.componentes.values():
		var fila := n / COLUMNAS_PLANTILLA
		var columna := n % COLUMNAS_PLANTILLA
		piezas[c.id] = {"tipo": _catalogo_de(c), "x": columna * SEPARACION_PLANTILLA.x, "y": fila * SEPARACION_PLANTILLA.y}
		n += 1
	return true


## Coloca un circuito con posiciones fijas, como el de una misión: id -> [x, y].
func cargar_circuito(circuito: Dictionary, posiciones: Dictionary) -> void:
	piezas = {}
	rutas = {}
	ocultas = {}
	sim = SimSimulacion.desde_dict(circuito.duplicate(true))
	_eventos_vistos = 0
	for c: SimComponente in sim.componentes.values():
		var p: Array = posiciones[c.id]
		piezas[c.id] = {"tipo": _catalogo_de(c), "x": float(p[0]), "y": float(p[1])}


func _catalogo_de(c: SimComponente) -> String:
	# Consumidores, el arrancador 3RW40 y el relé de 110 V AC dicen qué pieza los dibuja.
	if c.params.has("pieza"):
		return c.params["pieza"]
	match c.tipo():
		"pulsador":
			return "pulsador_na" if c.params["contacto"] == "NA" else "pulsador_nc"
		"motor_trifasico":
			return "motor_220" if is_equal_approx(c.params["v_delta"], 220.0) else "motor_380"
		"lampara":
			# Luces piloto de 230 V en los tableros del buque y lámparas de tierra de 380 V.
			var v := roundi(float(c.params["v_nominal"]))
			return "lampara_%d" % v if v in [24, 230, 380] else "lampara"
		"transformador_mando":
			return "transformador_230" if is_equal_approx(c.params["v_secundario"], 230.0) else "transformador_mando"
		"sensor_proximidad":
			return "sensor_npn" if c.params["salida"] == "npn" else "sensor_pnp"
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
	if ocultas.has(id):
		return false
	var e: Dictionary = sim.componente(id).estado
	return e.get("quemado", false) or e.get("soldado", false) or e.get("bobina_quemada", false) \
		or e.get("fundido", false) or e.get("quemada", false) or e.get("averiado", false) or e.get("averiada", false)


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
			if e["bobina_quemada"] and not ocultas.has(id):
				return "Bobina quemada"
			return "Cerrado" if e["energizada"] else "Abierto"
		"rele_termico":
			return "Disparado" if e["disparado"] else "Normal"
		"arrancador_suave":
			return " · ".join((c as SimArrancadorSuave).pantalla())
		"guardamotor", "interruptor_automatico":
			if e["disparado"]:
				return "Disparado"
			return "Cerrado" if e["encendido"] else "Abierto"
		"diferencial":
			if e["disparado"]:
				return "Disparado · %s mA de fuga" % TextoTecnico.numero(float(e["residual_a"]) * 1000.0, 1)
			return ("Cerrado · %s mA de fuga" % TextoTecnico.numero(float(e["residual_a"]) * 1000.0, 1)) if e["encendido"] else "Abierto"
		"rele_control_fases":
			if e["rele"]:
				return "Red correcta: 11-14 cerrado"
			return "Relé suelto: %s" % str(e["falla"]).replace("_", " ")
		"consumidor":
			return "Con tensión" if e["alimentado"] else "Sin tensión"
		"maquina_principal":
			var mp := c as SimMaquinaPrincipal
			return "%s · %s rpm" % ["Encendida" if mp.encendida() else ("Girando" if mp.rpm() > 1.0 else "Parada"), TextoTecnico.numero(mp.rpm(), 0)]
		"transmisor_4_20":
			return "%s %s" % [TextoTecnico.numero((c as SimTransmisor420).valor(), 1), c.params["unidad"]]
		"power_block":
			return "%s · %s rpm" % [(c as SimPowerBlock).sentido().capitalize(), TextoTecnico.numero(absf(e["rpm"]), 0)]
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
			return "%d / %d V" % [roundi(c.params["v_primario"]), roundi(c.params["v_secundario"])]
		"selector":
			return "Posición %s" % (c as SimSelector).nombre_posicion()
		"seta":
			return "Enclavada" if e["enclavada"] else "Liberada"
		"seccionador":
			return ("Cerrado" if e["cerrado"] else "Abierto") + (" · con candado" if e["candado"] else "")
		"horometro":
			return "%s h" % TextoTecnico.numero(e["horas"], 1)
		"carga_trifasica":
			return "Conectada · %s kW" % TextoTecnico.numero(c.params["p_kw"], 0) if e["conectada"] else "Desconectada"
		"hidroforo":
			return "%s bar · presostato %s" % [TextoTecnico.numero(e["presion"], 1), "cerrado: pide agua" if e["pide"] else "abierto"]
		"timon":
			var a: float = e["angulo"]
			return "Timón a la vía" if absf(a) < 0.5 else "Timón %s° a %s" % [TextoTecnico.numero(absf(a), 0), "estribor" if a > 0.0 else "babor"]
		"resistencia":
			return "%s Ω" % TextoTecnico.numero(c.params.get("ohm", 0.0), 0)
		"fuente_dc":
			if e["averiada"]:
				return "Averiada"
			if e["protegida"]:
				return "Salida cortada por sobrecarga"
			return "%s V · %s A" % [TextoTecnico.numero((c as SimFuenteDC).v_salida(), 1), TextoTecnico.numero(e["i_salida"], 2)] if (c as SimFuenteDC).activa() else "Sin alimentación"
		"sensor_proximidad":
			if e["averiado"]:
				return "Averiado"
			var pieza := "pieza delante" if e["objeto"] else "sin pieza"
			if not e["alimentado"]:
				return "%s · sin alimentación" % pieza
			return "%s · salida %s" % [pieza, "activa" if e["activa"] else "inactiva"]
		"rele_dc":
			if e["bobina_quemada"]:
				return "Bobina quemada"
			return "Activado" if e["energizado"] else "En reposo"
		"plc":
			var plc := c as SimPLC
			if not e["alimentado"]:
				return "Sin alimentación"
			var activas := PackedStringArray()
			for i in SimPLC.ENTRADAS:
				if plc.entrada_activa(i):
					activas.append(SimPLC.entrada(i))
			return "%s · entradas %s · %s" % [e["modo"], plc.params["entradas"].to_upper(), ", ".join(activas) if not activas.is_empty() else "ninguna activa"]
		"masa":
			return "Casco"
	return ""
