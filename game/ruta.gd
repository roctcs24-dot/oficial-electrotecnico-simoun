class_name Ruta
extends RefCounted
## Lo que el inicio recomienda hacer a continuación: la primera lección sin completar,
## recorriendo los sistemas activos en orden.


## {sistema, leccion, numero, total} de la siguiente lección, o {} si están todas hechas.
static func siguiente(contenido: Contenido, partida: Partida) -> Dictionary:
	for s: Dictionary in contenido.todos():
		if s.get("estado", "") != "activo":
			continue
		var lecciones: Array = s.get("modos", {}).get("aprender", {}).get("lecciones", [])
		for i in lecciones.size():
			if not partida.leccion_completada(lecciones[i]):
				return {"sistema": int(s["id"]), "leccion": lecciones[i], "numero": i + 1, "total": lecciones.size()}
	return {}
