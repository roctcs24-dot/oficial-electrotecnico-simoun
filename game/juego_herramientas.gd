class_name JuegoHerramientas
extends RefCounted
## Minijuego «Identifique la herramienta»: rondas con una herramienta del catálogo dibujada y
## cuatro nombres, y algunas rondas de llaves: qué llave métrica entra en una tuerca en pulgadas.

const REGISTRO := "identifique_herramienta"
const RONDAS_LLAVES := 3


static func crear_rondas(catalogo: Dictionary, tabla: Dictionary, n: int, azar: RandomNumberGenerator) -> Array:
	var lista: Array = catalogo.get("herramientas", [])
	var rondas := []
	var orden := range(lista.size())
	_barajar(orden, azar)
	var de_llaves := mini(RONDAS_LLAVES, n)
	for k in n - de_llaves:
		var h: Dictionary = lista[orden[k % orden.size()]]
		var otras: Array = []
		for id: String in h.get("similares", []):
			for o: Dictionary in lista:
				if o["id"] == id:
					otras.append(o["nombre"])
		var resto := lista.filter(func(o: Dictionary) -> bool: return o["id"] != h["id"] and not otras.has(o["nombre"]))
		_barajar(resto, azar)
		while otras.size() < 3 and not resto.is_empty():
			otras.append(resto.pop_back()["nombre"])
		var opciones: Array = [h["nombre"]] + otras.slice(0, 3)
		_barajar(opciones, azar)
		rondas.append({
			"tipo": "herramienta", "id": h["id"], "dibujo": h["dibujo"], "medida": str(h.get("medida", "")),
			"pregunta": "¿Cómo se llama esta herramienta?", "opciones": opciones, "correcta": opciones.find(h["nombre"]),
			"explicacion": "%s, en inglés %s. %s" % [h["nombre"], h["en"], h["para_que"]], "tema": "herramienta_%s" % h["id"],
		})
	var llaves: Array = tabla.get("metricas", [])
	var pulgadas := TablaLlaves.con_equivalente(tabla.get("pulgadas", []), llaves)
	_barajar(pulgadas, azar)
	for k in de_llaves:
		if pulgadas.is_empty():
			break
		var p: String = pulgadas[k % pulgadas.size()]
		var t := TablaLlaves.a_mm(p)
		var buena := TablaLlaves.mejor_metrica(t, llaves)
		var opciones: Array = ["%d mm" % (buena - 1), "%d mm" % buena, "%d mm" % (buena + 1)]
		_barajar(opciones, azar)
		rondas.insert(azar.randi_range(0, rondas.size()), {
			"tipo": "llave", "id": "llave_%s" % p, "dibujo": "combinada", "medida": "%s\"" % p,
			"pregunta": "¿Qué llave métrica entra en una tuerca de %s\"?" % p, "opciones": opciones, "correcta": opciones.find("%d mm" % buena),
			"explicacion": "%s\" son %s mm entre caras: la de %d mm entra. La de %d mm se queda corta y la de %d mm le queda grande." % [p, TablaLlaves.numero(t), buena, buena - 1, buena + 1],
			"tema": "llave_pulgadas",
		})
	return rondas


static func _barajar(a: Array, azar: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := azar.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
