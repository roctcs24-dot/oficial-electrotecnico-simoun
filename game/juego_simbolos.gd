class_name JuegoSimbolos
extends RefCounted
## Lógica del minijuego de identificación de símbolos, sin dependencias de la interfaz.

const CANTIDAD_OPCIONES := 4
const NORMAS := ["iec", "ansi"]


## Cada ronda es {id, norma, opciones: [ids], correcta: índice}. Los símbolos que comparten
## dibujo en una norma ("similares") no se ofrecen juntos, para que la pregunta tenga respuesta.
static func crear_rondas(simbolos: Array, cantidad: int, azar: RandomNumberGenerator) -> Array:
	var orden := _mezclar(simbolos, azar)
	var rondas := []
	for i in cantidad:
		var s: Dictionary = orden[i % orden.size()]
		var opciones: Array = [s["id"]]
		for otro: Dictionary in _mezclar(simbolos, azar):
			if opciones.size() >= CANTIDAD_OPCIONES:
				break
			if otro["id"] != s["id"] and not s.get("similares", []).has(otro["id"]):
				opciones.append(otro["id"])
		opciones = _mezclar(opciones, azar)
		rondas.append({
			"id": s["id"],
			"norma": NORMAS[azar.randi_range(0, NORMAS.size() - 1)],
			"opciones": opciones,
			"correcta": opciones.find(s["id"]),
		})
	return rondas


static func _mezclar(lista: Array, azar: RandomNumberGenerator) -> Array:
	var copia := lista.duplicate()
	for i in range(copia.size() - 1, 0, -1):
		var j := azar.randi_range(0, i)
		var temporal: Variant = copia[i]
		copia[i] = copia[j]
		copia[j] = temporal
	return copia


static func estrellas(aciertos: int, total: int) -> int:
	if total <= 0:
		return 0
	var proporcion := float(aciertos) / total
	if proporcion >= 0.9:
		return 3
	if proporcion >= 0.7:
		return 2
	return 1 if proporcion >= 0.5 else 0
