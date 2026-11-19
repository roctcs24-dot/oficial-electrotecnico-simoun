class_name ExamenTeorico
extends RefCounted
## Selección y calificación de un examen. No depende de la interfaz.

const TIPOS_DEL_BANCO := ["quiz", "caso", "ordenar"]
const PORCENTAJE_DOS_ESTRELLAS := 90.0
const PORCENTAJE_TRES_ESTRELLAS := 100.0
## Opciones de una pregunta de símbolo ISO 1219: tres, como las de concepto, para que quepan apaisado.
const OPCIONES_ISO := 3


## Elige al azar según datos["composicion"]: tipo -> cantidad. Los símbolos salen del minijuego.
## «simbolo_iso» son símbolos ISO 1219 (lista «iso», de JuegoIso1219.leer): se ve el símbolo y se
## elige su nombre entre otros de su misma familia.
static func crear(datos: Dictionary, simbolos: Array, azar: RandomNumberGenerator, iso: Array = []) -> Array:
	var composicion: Dictionary = datos["composicion"]
	var items := []
	for tipo: String in TIPOS_DEL_BANCO:
		var del_tipo := []
		for p: Dictionary in datos["preguntas"]:
			if p["tipo"] == tipo:
				del_tipo.append(p)
		del_tipo = JuegoSimbolos.mezclar(del_tipo, azar)
		items.append_array(del_tipo.slice(0, int(composicion.get(tipo, 0))))
	for r: Dictionary in JuegoSimbolos.crear_rondas(simbolos, int(composicion.get("simbolo", 0)), azar):
		var item := r.duplicate()
		item["tipo"] = "simbolo"
		item["tema"] = "simbolo_%s" % r["id"]
		items.append(item)
	for s: Dictionary in JuegoSimbolos.mezclar(iso, azar).slice(0, int(composicion.get("simbolo_iso", 0))):
		var familia := iso.filter(func(o: Dictionary) -> bool: return o.get("familia", "") == s.get("familia", ""))
		var item := JuegoIso1219.ronda_nombre(s, familia, azar)
		# Se quitan opciones falsas hasta dejar OPCIONES_ISO.
		while item["opciones"].size() > OPCIONES_ISO:
			var quitar := 0 if int(item["correcta"]) != 0 else 1
			item["opciones"].remove_at(quitar)
			if quitar < int(item["correcta"]):
				item["correcta"] = int(item["correcta"]) - 1
		item["tipo"] = "simbolo_iso"
		item["tema"] = "iso1219_%s" % s["id"]
		items.append(item)
	return JuegoSimbolos.mezclar(items, azar)


static func porcentaje(aciertos: int, total: int) -> float:
	return 0.0 if total <= 0 else 100.0 * aciertos / total


static func aprobado(aciertos: int, total: int, minimo: float) -> bool:
	return porcentaje(aciertos, total) >= minimo


static func estrellas(aciertos: int, total: int, minimo: float) -> int:
	if not aprobado(aciertos, total, minimo):
		return 0
	var p := porcentaje(aciertos, total)
	if p >= PORCENTAJE_TRES_ESTRELLAS:
		return 3
	return 2 if p >= PORCENTAJE_DOS_ESTRELLAS else 1
