class_name JuegoLineas
extends RefCounted
## Esquemas de líneas (data/lineas/<id>.json) y sus ejercicios: «seguir» (recorrer con el dedo los
## tramos de la ruta, en orden), «aislar» (elegir las válvulas que se cierran) y «servicio» (decir
## qué lleva un tramo por su color). Las coordenadas van en el espacio del esquema (ancho × alto).

const REGISTRO := "seguir_lineas"
const CARPETA := "lineas/%s.json"
## Distancia máxima, en unidades del esquema, para que un punto toque un tramo o una válvula.
const TOLERANCIA_TRAMO := 9.0
const RADIO_VALVULA := 17.0


static func leer(contenido: Contenido, id: String) -> Dictionary:
	return contenido.leer(CARPETA % id)


static func ejercicio(esquema: Dictionary, id: String) -> Dictionary:
	for e: Dictionary in esquema.get("ejercicios", []):
		if e["id"] == id:
			return e
	return {}


static func tramo(esquema: Dictionary, id: String) -> Dictionary:
	for t: Dictionary in esquema.get("tramos", []):
		if t["id"] == id:
			return t
	return {}


static func puntos(t: Dictionary) -> PackedVector2Array:
	var p := PackedVector2Array()
	for q: Array in t.get("puntos", []):
		p.append(Vector2(float(q[0]), float(q[1])))
	return p


static func distancia_a_tramo(t: Dictionary, punto: Vector2) -> float:
	var p := puntos(t)
	var mejor := INF
	for i in p.size() - 1:
		mejor = minf(mejor, punto.distance_to(Geometry2D.get_closest_point_to_segment(punto, p[i], p[i + 1])))
	return mejor


## El tramo más cercano a «punto» dentro de la tolerancia, o "".
static func tramo_en(esquema: Dictionary, punto: Vector2) -> String:
	var elegido := ""
	var mejor := TOLERANCIA_TRAMO
	for t: Dictionary in esquema.get("tramos", []):
		var d := distancia_a_tramo(t, punto)
		if d <= mejor:
			mejor = d
			elegido = t["id"]
	return elegido


static func valvula_en(esquema: Dictionary, punto: Vector2) -> String:
	for v: Dictionary in esquema.get("valvulas", []):
		if punto.distance_to(Vector2(float(v["x"]), float(v["y"]))) <= RADIO_VALVULA:
			return v["id"]
	return ""


## Punto medio de un tramo, para que las pruebas lo «toquen».
static func centro_tramo(t: Dictionary) -> Vector2:
	var p := puntos(t)
	var total := 0.0
	for i in p.size() - 1:
		total += p[i].distance_to(p[i + 1])
	var falta := total / 2.0
	for i in p.size() - 1:
		var l := p[i].distance_to(p[i + 1])
		if falta <= l:
			return p[i].lerp(p[i + 1], falta / maxf(l, 0.001))
		falta -= l
	return p[p.size() - 1]


## Avance de un ejercicio «seguir» al pasar por «tramo_id». Devuelve "avanza", "error" o "".
## «hechos» es la lista de tramos ya recorridos (se modifica).
static func paso_seguir(ruta: Array, hechos: Array, tramo_id: String) -> String:
	if tramo_id.is_empty() or hechos.has(tramo_id):
		return ""
	if hechos.size() < ruta.size() and ruta[hechos.size()] == tramo_id:
		hechos.append(tramo_id)
		return "avanza"
	# Volver a un tramo de la ruta que viene más adelante no es error: solo no cuenta todavía.
	if ruta.has(tramo_id):
		return ""
	return "error"


static func aislar_correcto(elegidas: Array, correctas: Array) -> bool:
	if elegidas.size() != correctas.size():
		return false
	for v in correctas:
		if not elegidas.has(v):
			return false
	return true


## Rondas del minijuego: los ejercicios del esquema, en su orden.
static func crear_items(esquema: Dictionary) -> Array:
	var items := []
	for e: Dictionary in esquema.get("ejercicios", []):
		items.append({"tipo": "linea", "esquema": esquema["id"], "ejercicio": e["id"], "tema": "linea_%s_%s" % [esquema["id"], e["id"]]})
	return items


static func estrellas(aciertos: int, total: int) -> int:
	return JuegoSimbolos.estrellas(aciertos, total)
