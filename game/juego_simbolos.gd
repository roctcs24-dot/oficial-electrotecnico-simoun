class_name JuegoSimbolos
extends RefCounted
## Lógica del minijuego de identificación de símbolos, sin dependencias de la interfaz.

const CANTIDAD_OPCIONES := 4
const NORMAS := ["iec", "ansi"]


## Cada ronda es {id, norma, opciones: [ids], correcta: índice}. Los símbolos que comparten
## dibujo en una norma ("similares") no se ofrecen juntos, para que la pregunta tenga respuesta.
static func crear_rondas(simbolos: Array, cantidad: int, azar: RandomNumberGenerator) -> Array:
	var orden := mezclar(simbolos, azar)
	var rondas := []
	for i in cantidad:
		rondas.append(_ronda(orden[i % orden.size()], simbolos, azar))
	return rondas


## La ronda de un símbolo concreto, para repasarlo.
static func crear_ronda(id: String, simbolos: Array, azar: RandomNumberGenerator) -> Dictionary:
	for s: Dictionary in simbolos:
		if s["id"] == id:
			return _ronda(s, simbolos, azar)
	return {}


static func _ronda(s: Dictionary, simbolos: Array, azar: RandomNumberGenerator) -> Dictionary:
	var opciones: Array = [s["id"]]
	for otro: Dictionary in mezclar(simbolos, azar):
		if opciones.size() >= CANTIDAD_OPCIONES:
			break
		if otro["id"] != s["id"] and not s.get("similares", []).has(otro["id"]):
			opciones.append(otro["id"])
	opciones = mezclar(opciones, azar)
	return {
		"id": s["id"],
		"norma": NORMAS[azar.randi_range(0, NORMAS.size() - 1)],
		"opciones": opciones,
		"correcta": opciones.find(s["id"]),
	}


static func mezclar(lista: Array, azar: RandomNumberGenerator) -> Array:
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
