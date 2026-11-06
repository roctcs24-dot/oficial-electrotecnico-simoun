class_name OperadorPlanta
extends RefCounted
## Mandos de la planta de frío sobre la simulación, sin interfaz. Cada orden devuelve un aviso
## {tipo, titulo, texto}: con el título vacío no hay nada que explicar. Las misiones de la planta
## podrán ofrecer los mismos métodos y comprobar el procedimiento antes de pasar la orden.

var sim: SimSimulacion
## planta.json: presostatos, tuberías, paso de la corredera y textos.
var datos: Dictionary


func _init(simulacion: SimSimulacion, datos_planta: Dictionary) -> void:
	sim = simulacion
	datos = datos_planta


func planta() -> SimPlantaFrio:
	return sim.componente("PLANTA")


func guardamotor() -> SimGuardamotor:
	return sim.componente("Q1")


func en_marcha() -> bool:
	return (sim.componente("K1") as SimContactor).cerrado()


func corriente_motor() -> float:
	if sim.solucion == null:
		sim.paso()
	return (sim.componente("F2") as SimReleTermico).corriente(sim.solucion, 0)


func alternar_guardamotor() -> Dictionary:
	var q := guardamotor()
	q.accionar(not q.cerrado())
	return _aviso("hecho", "", "")


## Pulsadores de marcha (S1) y parada (S0): se mantienen mientras el dedo está encima.
func pulsar(id: String, presionado: bool) -> Dictionary:
	sim.componente(id).estado["presionado"] = presionado
	return _aviso("hecho", "", "")


func rearmar_presostato(id: String) -> Dictionary:
	if (sim.componente(id) as SimPresostato).rearmar():
		return _aviso("hecho", "", "")
	return _aviso("aviso", "No rearma", "La presión sigue fuera del valor del presostato %s. Corrija la causa y espere a que se normalice." % id)


func rearmar_rele() -> Dictionary:
	if (sim.componente("F2") as SimReleTermico).rearmar():
		return _aviso("hecho", "", "")
	return _aviso("aviso", "Todavía caliente", "El relé no rearma hasta enfriarse. Aproveche para buscar la causa de la sobrecarga.")


func alternar_bomba(nombre: String) -> Dictionary:
	var p := planta()
	p.estado[nombre] = not p.estado[nombre]
	return _aviso("hecho", "", "")


func alternar_automatico() -> Dictionary:
	var p := planta()
	p.estado["automatico"] = not p.estado["automatico"]
	if not p.estado["automatico"]:
		p.estado["capacidad_manual"] = snappedf(p.estado["capacidad"], 0.1)
	return _aviso("hecho", "", "")


func capacidad(signo: float) -> Dictionary:
	var p := planta()
	if p.estado["automatico"]:
		return _aviso("aviso", "Corredera en automático", "Pase la capacidad a manual para mover la corredera con los mandos.")
	p.estado["capacidad_manual"] = clampf(p.estado["capacidad_manual"] + signo * float(datos["paso_capacidad"]), SimPlantaFrio.CAPACIDAD_MINIMA, 1.0)
	return _aviso("hecho", "", "")


func alternar_ventilacion() -> Dictionary:
	var p := planta()
	p.estado["ventilacion_emergencia"] = not p.estado["ventilacion_emergencia"]
	return _aviso("hecho", "", "")


static func _aviso(tipo: String, titulo: String, texto: String) -> Dictionary:
	return {"tipo": tipo, "titulo": titulo, "texto": texto}
