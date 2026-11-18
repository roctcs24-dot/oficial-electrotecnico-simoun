class_name JuegoRacores
extends RefCounted
## Minijuego «Elija el racor»: rondas con un racor del catálogo dibujado (sin rótulos) y su
## descripción, dos rondas de DN y NPS (data/tablas/roscas.json) y hasta dos fotos tomadas a
## bordo que traen su propia pregunta (data/fotos_piezas.json).

const REGISTRO := "elija_racor"
const RONDAS_DN := 2
const FOTOS_RONDAS := 2


static func crear_rondas(catalogo: Dictionary, tabla: Dictionary, n: int, azar: RandomNumberGenerator, fotos: Array = []) -> Array:
	var lista: Array = catalogo.get("racores", [])
	var rondas := []
	if lista.is_empty():
		return rondas
	var de_fotos := mini(mini(FOTOS_RONDAS, fotos.size()), n)
	var de_dn := mini(RONDAS_DN, n - de_fotos) if not tabla.get("dn", []).is_empty() else 0
	var orden := range(lista.size())
	_barajar(orden, azar)
	for k in n - de_fotos - de_dn:
		rondas.append(ronda_racor(lista[orden[k % orden.size()]], lista, azar))
	var dns: Array = tabla.get("dn", []).duplicate()
	_barajar(dns, azar)
	for k in de_dn:
		rondas.insert(azar.randi_range(0, rondas.size()), ronda_dn(dns[k % dns.size()], tabla["dn"], k % 2 == 1, azar))
	var usables := fotos.duplicate()
	_barajar(usables, azar)
	for k in de_fotos:
		rondas.insert(azar.randi_range(0, rondas.size()), ronda_foto(usables[k]))
	return rondas


static func ronda_racor(r: Dictionary, lista: Array, azar: RandomNumberGenerator) -> Dictionary:
	var otras: Array = []
	for id: String in r.get("similares", []):
		for o: Dictionary in lista:
			if o["id"] == id and otras.size() < 3:
				otras.append(o["nombre"])
	var resto := lista.filter(func(o: Dictionary) -> bool: return o["id"] != r["id"] and not otras.has(o["nombre"]))
	_barajar(resto, azar)
	while otras.size() < 3 and not resto.is_empty():
		otras.append(resto.pop_back()["nombre"])
	var opciones: Array = [r["nombre"]] + otras
	_barajar(opciones, azar)
	return {
		"tipo": "racor", "id": r["id"], "dibujo": r["dibujo"],
		"pregunta": r["pista"], "opciones": opciones, "correcta": opciones.find(r["nombre"]),
		"explicacion": "%s (%s). Dónde sella: %s" % [r["nombre"], r["en"], _minuscula(str(r["sella"]))],
		"tema": "racor_%s" % r["id"],
	}


## Ronda de DN: «¿qué NPS es DN50?» o, si «por_exterior», «mide 60,3 mm: ¿qué DN es?».
static func ronda_dn(fila: Dictionary, tabla: Array, por_exterior: bool, azar: RandomNumberGenerator) -> Dictionary:
	var i := tabla.find(fila)
	var vecinos: Array = []
	for d in [-2, -1, 1, 2]:
		if i + d >= 0 and i + d < tabla.size():
			vecinos.append(tabla[i + d])
	_barajar(vecinos, azar)
	var elegidos: Array = [fila] + vecinos.slice(0, 2)
	var opciones: Array = []
	for f: Dictionary in elegidos:
		opciones.append("DN%d" % int(f["dn"]) if por_exterior else "%s\" NPS" % f["nps"])
	var buena: String = opciones[0]
	_barajar(opciones, azar)
	var exterior := mm(float(fila["exterior"]))
	return {
		"tipo": "dn", "id": "dn%d" % int(fila["dn"]), "dn": int(fila["dn"]), "nps": str(fila["nps"]), "exterior": float(fila["exterior"]), "por_exterior": por_exterior,
		"pregunta": ("Un tubo mide %s mm de diámetro exterior. ¿Qué DN es?" % exterior) if por_exterior else ("Un tubo es DN%d. ¿A qué medida en pulgadas (NPS) corresponde?" % int(fila["dn"])),
		"opciones": opciones, "correcta": opciones.find(buena),
		"explicacion": "DN%d es %s\" NPS y mide %s mm por fuera. El DN y el NPS son nombres: ninguno es el diámetro real." % [int(fila["dn"]), fila["nps"], exterior],
		"tema": "dn_nps",
	}


static func ronda_foto(foto: Dictionary) -> Dictionary:
	return {
		"tipo": "foto", "id": foto["pieza"], "foto": foto["id"],
		"pregunta": foto["pregunta"], "opciones": foto["opciones"], "correcta": int(foto["correcta"]),
		"explicacion": foto["texto"], "tema": "racor_foto_%s" % foto["id"],
	}


## Milímetros con coma y sin ceros de más: 60,3; 20,955; 33,4.
static func mm(v: float) -> String:
	var s := "%.3f" % v
	s = s.rstrip("0").trim_suffix(".")
	return s.replace(".", ",")


static func _minuscula(t: String) -> String:
	return t.left(1).to_lower() + t.substr(1) if not t.is_empty() else t


static func _barajar(a: Array, azar: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := azar.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
