class_name SimPantallaHMI
extends RefCounted
## Pantalla local (HMI) de un equipo, como la Omron de un MYCOM: lee los valores de su propio
## controlador por un cable aparte de la red del puesto de alarmas, guarda su tendencia y
## tiene sus alarmas locales, con límites que se cambian en la página de ajustes.
## Sin comunicación con el controlador, muestra #### y un aviso de error de comunicación.

const MUESTRAS := 120
const PERIODO_TENDENCIA_S := 1.0

var red: SimRedModbus
var datos: Dictionary
var alarmas: SimSistemaAlarmas
## Lista de muestras por cada traza de la tendencia.
var tendencia: Array[PackedFloat32Array] = []
var nivel_tecnico := false
var _hasta_muestra := 0.0


func _init(red_buque: SimRedModbus) -> void:
	red = red_buque
	datos = red.datos.get("hmi", {}).duplicate(true)
	var lista: Array = []
	for a: Dictionary in datos.get("ajustes", []):
		lista.append({"id": a["id"], "texto": a["texto"], "tipo": a["tipo"], "limite": float(a["valor"]), "retardo_s": float(a.get("retardo_s", 0.0)), "registro": int(a["reg"])})
	alarmas = SimSistemaAlarmas.new(lista, func(p: Dictionary) -> float: return valor(p["registro"]))
	for _t in datos.get("tendencia", []):
		tendencia.append(PackedFloat32Array())


func esclavo() -> String:
	return datos.get("esclavo", "")


func comunica() -> bool:
	return not red.hmi_sin_comunicacion and red.esclavo(esclavo()).get("alimentado", false)


func valor(reg: int) -> float:
	return red.valor_local(esclavo(), reg) if comunica() else NAN


func avanzar(dt: float) -> void:
	alarmas.actualizar(dt)
	_hasta_muestra -= dt
	while _hasta_muestra <= 0.0:
		_hasta_muestra += PERIODO_TENDENCIA_S
		var trazas: Array = datos.get("tendencia", [])
		for i in trazas.size():
			var serie := tendencia[i]
			serie.append(valor(int(trazas[i]["reg"])))
			if serie.size() > MUESTRAS:
				serie.remove_at(0)
			tendencia[i] = serie


func ajuste(id: String) -> Dictionary:
	for a: Dictionary in datos.get("ajustes", []):
		if a["id"] == id:
			return a
	return {}


## Cambia un límite de alarma. Solo con nivel de técnico y dentro de los límites que admite
## el equipo. Devuelve "" si se cambió, o el motivo del rechazo.
func cambiar_ajuste(id: String, pasos: int) -> String:
	if not nivel_tecnico:
		return "Los ajustes están protegidos: hace falta el nivel de técnico."
	var a := ajuste(id)
	var nuevo := snappedf(float(a["valor"]) + pasos * float(a["paso"]), float(a["paso"]))
	if nuevo < float(a["min"]) - 1e-6 or nuevo > float(a["max"]) + 1e-6:
		return "Fuera de los límites que admite el equipo: de %s a %s %s." % [TextoTecnico.numero(a["min"], int(a.get("decimales", 0))), TextoTecnico.numero(a["max"], int(a.get("decimales", 0))), a["unidad"]]
	a["valor"] = nuevo
	alarmas.punto(id)["limite"] = nuevo
	return ""
