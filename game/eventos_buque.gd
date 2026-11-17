class_name EventosBuque
extends RefCounted
## Registro de eventos y alarmas de la sesión de juego, como la barra de eventos y la lista de
## alarmas de un simulador de sala de máquinas. No se guarda en la partida.

signal cambiado

const MAXIMO := 40

## Cada entrada: {hora, texto, tipo ("evento", "alarma" o "normal"), reconocida}.
var entradas: Array[Dictionary] = []


func registrar(texto: String, tipo := "evento") -> void:
	if texto.is_empty():
		return
	# Una alarma repetida no se duplica: se trae al principio.
	for i in entradas.size():
		if entradas[i]["texto"] == texto and entradas[i]["tipo"] == tipo:
			entradas.remove_at(i)
			break
	entradas.push_front({"hora": hora(), "texto": texto, "tipo": tipo, "reconocida": false})
	if entradas.size() > MAXIMO:
		entradas.resize(MAXIMO)
	cambiado.emit()


func ultimo() -> Dictionary:
	return entradas[0] if not entradas.is_empty() else {}


func alarmas() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e in entradas:
		if e["tipo"] != "evento":
			r.append(e)
	return r


func sin_reconocer() -> int:
	var n := 0
	for e in entradas:
		if e["tipo"] == "alarma" and not e["reconocida"]:
			n += 1
	return n


## ACK: las alarmas dejan de parpadear, pero siguen en la lista.
func reconocer() -> void:
	for e in entradas:
		e["reconocida"] = true
	cambiado.emit()


func vaciar() -> void:
	entradas.clear()
	cambiado.emit()


static func hora() -> String:
	var t := Time.get_time_dict_from_system()
	return "%02d:%02d" % [t["hour"], t["minute"]]
