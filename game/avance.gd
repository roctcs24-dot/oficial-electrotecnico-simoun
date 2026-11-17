class_name Avance
extends RefCounted
## Cuánto ha hecho el jugador de cada sistema y de cada modo, para las barras y las marcas de
## los menús. Cada función devuelve [hechos, total].


static func lecciones(s: Dictionary, partida: Partida) -> Array[int]:
	var ids: Array = s.get("modos", {}).get("aprender", {}).get("lecciones", [])
	return _contar(ids, partida.leccion_completada)


## Fichas del atlas con sus cinco pestañas vistas.
static func atlas(s: Dictionary, partida: Partida) -> Array[int]:
	var ids: Array = s.get("modos", {}).get("aprender", {}).get("atlas", [])
	return _contar(ids, partida.atlas_completo)


## Lo que cuenta en Aprender: lecciones y fichas del atlas.
static func aprender(s: Dictionary, partida: Partida) -> Array[int]:
	var l := lecciones(s, partida)
	var a := atlas(s, partida)
	return [l[0] + a[0], l[1] + a[1]]


static func misiones(s: Dictionary, partida: Partida) -> Array[int]:
	var ids: Array = s.get("modos", {}).get("guardia", {}).get("misiones", [])
	return _contar(ids, partida.mision_completada)


static func examenes(s: Dictionary, partida: Partida) -> Array[int]:
	var ids: Array = s.get("modos", {}).get("examen", {}).get("examenes", [])
	return _contar(ids, partida.examen_aprobado)


## Lecciones, fichas del atlas, misiones y exámenes juntos.
static func sistema(s: Dictionary, partida: Partida) -> Array[int]:
	var hechos := 0
	var total := 0
	for parte: Array[int] in [aprender(s, partida), misiones(s, partida), examenes(s, partida)]:
		hechos += parte[0]
		total += parte[1]
	return [hechos, total]


## Lámpara de la zona del sistema en el buque del inicio: «averia» si quedó un equipo dañado en
## una de sus misiones, «completo» con todo hecho, «en_curso» si hay algo hecho y «sin_empezar».
static func estado(s: Dictionary, partida: Partida) -> String:
	if not misiones_danadas(s, partida).is_empty():
		return "averia"
	var parte := sistema(s, partida)
	if parte[1] > 0 and parte[0] == parte[1]:
		return "completo"
	return "en_curso" if parte[0] > 0 else "sin_empezar"


## Misiones del sistema que dejaron un equipo dañado, sin repararlo todavía.
static func misiones_danadas(s: Dictionary, partida: Partida) -> Array[String]:
	var r: Array[String] = []
	for id: String in s.get("modos", {}).get("guardia", {}).get("misiones", []):
		if not partida.danos_mision(id).is_empty():
			r.append(id)
	return r


static func fraccion(parte: Array[int]) -> float:
	return float(parte[0]) / float(parte[1]) if parte[1] > 0 else 0.0


## La primera lección sin completar, o "" si están todas hechas.
static func siguiente_leccion(s: Dictionary, partida: Partida) -> String:
	for id: String in s.get("modos", {}).get("aprender", {}).get("lecciones", []):
		if not partida.leccion_completada(id):
			return id
	return ""


static func _contar(ids: Array, hecho: Callable) -> Array[int]:
	var n := 0
	for id: String in ids:
		if hecho.call(id):
			n += 1
	return [n, ids.size()]
