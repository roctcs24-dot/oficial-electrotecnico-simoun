class_name Avance
extends RefCounted
## Cuánto ha hecho el jugador de cada sistema y de cada modo, para las barras y las marcas de
## los menús. Cada función devuelve [hechos, total].


static func lecciones(s: Dictionary, partida: Partida) -> Array[int]:
	var ids: Array = s.get("modos", {}).get("aprender", {}).get("lecciones", [])
	return _contar(ids, partida.leccion_completada)


static func misiones(s: Dictionary, partida: Partida) -> Array[int]:
	var ids: Array = s.get("modos", {}).get("guardia", {}).get("misiones", [])
	return _contar(ids, partida.mision_completada)


static func examenes(s: Dictionary, partida: Partida) -> Array[int]:
	var ids: Array = s.get("modos", {}).get("examen", {}).get("examenes", [])
	return _contar(ids, partida.examen_aprobado)


## Lecciones, misiones y exámenes juntos.
static func sistema(s: Dictionary, partida: Partida) -> Array[int]:
	var hechos := 0
	var total := 0
	for parte: Array[int] in [lecciones(s, partida), misiones(s, partida), examenes(s, partida)]:
		hechos += parte[0]
		total += parte[1]
	return [hechos, total]


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
