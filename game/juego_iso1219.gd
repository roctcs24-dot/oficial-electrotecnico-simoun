class_name JuegoIso1219
extends RefCounted
## Minijuego «Símbolos ISO 1219» (data/simbolos_iso1219.json), sin interfaz. Dos clases de ronda:
##   pieza:  {tipo, id, pieza, opciones: [ids de símbolo], correcta} — se ve la pieza dibujada y se
##           toca su símbolo entre cuatro;
##   nombre: {tipo, id, pregunta, opciones: [nombres], correcta, explicacion} — se ve el símbolo y
##           se elige su nombre.

const REGISTRO := "simbolos_iso1219"
const ARCHIVO := "simbolos_iso1219.json"
const OPCIONES := 4
const RONDAS_PIEZA := 4


static func leer(contenido: Contenido, familia := "") -> Array:
	var lista: Array = contenido.leer(ARCHIVO).get("simbolos", [])
	if familia.is_empty():
		return lista
	return lista.filter(func(s: Dictionary) -> bool: return s.get("familia", "") == familia)


static func simbolo(lista: Array, id: String) -> Dictionary:
	for s: Dictionary in lista:
		if s["id"] == id:
			return s
	return {}


static func crear_rondas(simbolos: Array, cantidad: int, azar: RandomNumberGenerator) -> Array:
	var con_pieza := JuegoSimbolos.mezclar(simbolos.filter(func(s: Dictionary) -> bool: return not str(s.get("pieza", "")).is_empty()), azar)
	var rondas := []
	var usados := {}
	for s: Dictionary in con_pieza.slice(0, mini(RONDAS_PIEZA, cantidad)):
		rondas.append(ronda_pieza(s, simbolos, azar))
		usados[s["id"]] = true
	var resto := JuegoSimbolos.mezclar(simbolos.filter(func(s: Dictionary) -> bool: return not usados.has(s["id"])), azar)
	var i := 0
	while rondas.size() < cantidad and not simbolos.is_empty():
		var s: Dictionary = resto[i % resto.size()] if not resto.is_empty() else simbolos[i % simbolos.size()]
		rondas.append(ronda_nombre(s, simbolos, azar))
		i += 1
	return JuegoSimbolos.mezclar(rondas, azar)


static func _otros(s: Dictionary, simbolos: Array, azar: RandomNumberGenerator) -> Array:
	var ids: Array = [s["id"]]
	for otro: Dictionary in JuegoSimbolos.mezclar(simbolos, azar):
		if ids.size() >= OPCIONES:
			break
		if otro["id"] != s["id"] and not s.get("similares", []).has(otro["id"]):
			ids.append(otro["id"])
	return JuegoSimbolos.mezclar(ids, azar)


static func ronda_pieza(s: Dictionary, simbolos: Array, azar: RandomNumberGenerator) -> Dictionary:
	var ids := _otros(s, simbolos, azar)
	return {"tipo": "pieza", "id": s["id"], "pieza": s["pieza"], "opciones": ids, "correcta": ids.find(s["id"])}


static func ronda_nombre(s: Dictionary, simbolos: Array, azar: RandomNumberGenerator) -> Dictionary:
	var ids := _otros(s, simbolos, azar)
	var nombres := []
	for id: String in ids:
		nombres.append(simbolo(simbolos, id)["nombre"])
	return {"tipo": "nombre", "id": s["id"], "pregunta": "¿Qué representa este símbolo ISO 1219?", "opciones": nombres,
		"correcta": ids.find(s["id"]), "explicacion": str(s.get("explicacion", ""))}
