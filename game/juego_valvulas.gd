class_name JuegoValvulas
extends RefCounted
## Minijuego «¿Abierta o cerrada?»: rondas con una válvula del catálogo en un estado al azar, su
## pregunta y sus opciones (data/catalogos/valvulas.json, campo «minijuego»).

const REGISTRO := "abierta_cerrada"


## Válvulas del catálogo que tienen minijuego.
static func jugables(catalogo: Dictionary) -> Array:
	return catalogo.get("valvulas", []).filter(func(v: Dictionary) -> bool: return v.has("minijuego"))


## «n» rondas sin repetir la misma válvula y estado seguidos; reparte los tipos.
static func crear_rondas(catalogo: Dictionary, n: int, azar: RandomNumberGenerator) -> Array:
	var lista := jugables(catalogo)
	var servicios: Array = catalogo.get("servicios", [])
	var rondas := []
	if lista.is_empty():
		return rondas
	var orden := range(lista.size())
	for i in range(orden.size() - 1, 0, -1):
		var j := azar.randi_range(0, i)
		var t: int = orden[i]
		orden[i] = orden[j]
		orden[j] = t
	var anterior := ""
	for k in n:
		var v: Dictionary = lista[orden[k % orden.size()]]
		var juego: Dictionary = v["minijuego"]
		var estados: Array = juego["estados"]
		var e: Dictionary = estados[azar.randi_range(0, estados.size() - 1)]
		var clave := "%s_%s" % [v["id"], JSON.stringify(e)]
		if clave == anterior and estados.size() > 1:
			e = estados[(estados.find(e) + 1) % estados.size()]
			clave = "%s_%s" % [v["id"], JSON.stringify(e)]
		anterior = clave
		rondas.append({
			"tipo": "valvula",
			"id": v["id"],
			"dibujo": v["dibujo"],
			"apertura": float(e.get("apertura", 1.0)),
			"via": str(e.get("via", "b")),
			"pregunta": juego["pregunta"],
			"opciones": juego["opciones"],
			"correcta": int(e["correcta"]),
			"explicacion": v["como_saber"],
			"tema": "valvula_%s" % v["id"],
			"servicio": servicios[azar.randi_range(0, servicios.size() - 1)] if not servicios.is_empty() else "",
		})
	return rondas


static func estrellas(aciertos: int, total: int) -> int:
	return JuegoSimbolos.estrellas(aciertos, total)
