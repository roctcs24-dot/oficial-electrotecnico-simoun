class_name PuntosJuego
extends RefCounted
## Puntos que da todo el contenido publicado, por partes: lecciones (con sus aciertos), misiones de
## Guardia con tres estrellas y evaluaciones (exámenes aprobados al 100 % y minijuegos con tres
## estrellas). Sirve para calibrar los rangos y para enseñarlo en «Mi progreso».


static func maximos(c: Contenido) -> Dictionary:
	var lecciones := 0
	var misiones := 0
	var evaluaciones := 0
	for s: Dictionary in c.todos():
		var modos: Dictionary = s.get("modos", {})
		for id: String in modos.get("aprender", {}).get("lecciones", []):
			lecciones += Partida.PUNTOS_LECCION
			for pagina: Dictionary in c.leccion(id).get("paginas", []):
				for b: Dictionary in pagina.get("bloques", []):
					if b.get("tipo", "") in ["quiz", "ordenar"]:
						lecciones += Partida.PUNTOS_ACIERTO
		for _id: String in modos.get("guardia", {}).get("misiones", []):
			misiones += Partida.PUNTOS_MISION + 3 * Partida.PUNTOS_ESTRELLA
		evaluaciones += modos.get("examen", {}).get("minijuegos", []).size() * 3 * Partida.PUNTOS_ESTRELLA
	evaluaciones += c.examenes().size() * (Partida.PUNTOS_EXAMEN + 3 * Partida.PUNTOS_ESTRELLA)
	return {"lecciones": lecciones, "misiones": misiones, "evaluaciones": evaluaciones, "total": lecciones + misiones + evaluaciones}
