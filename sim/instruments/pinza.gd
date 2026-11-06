class_name SimPinza
extends RefCounted
## Pinza amperimétrica de alterna: mide la corriente de los conductores que abraza, sin abrir el
## circuito. Con varios conductores mide su suma: los tres de un mismo circuito trifásico dan casi
## cero, y por eso se abraza una sola fase. Rango y resolución de una pinza típica: verificar con
## la del buque.

const RANGO_A := 400.0
const RESOLUCION_A := 0.1
## Impedancia con la que se sustituye cada cable abrazado para saber qué corriente lo recorre.
const R_SONDA := 0.0001

var ruido := 0.01
var _azar := RandomNumberGenerator.new()


## cables: índices de sim.cables abrazados, en el sentido en que están dibujados.
## Devuelve {valor, unidad, fuera_de_rango, averia}.
func medir(sim: SimSimulacion, cables: Array) -> Dictionary:
	if cables.is_empty():
		return {"valor": 0.0, "unidad": "A", "fuera_de_rango": false, "averia": "sin_conductor"}
	var sol := sim.resolver(false, func(e: SimEstampa) -> void:
		for i: int in cables:
			e.impedancia(sim.cables[i][0], sim.cables[i][1], R_SONDA), cables)
	var suma := Cx.new(0.0, 0.0)
	for i: int in cables:
		suma = suma.mas(sol.entre(sim.cables[i][0], sim.cables[i][1]).escala(1.0 / R_SONDA))
	var i_a := suma.modulo()
	if i_a > RANGO_A:
		return {"valor": RANGO_A, "unidad": "A", "fuera_de_rango": true, "averia": ""}
	# Por debajo de la resolución la pantalla marca cero, aunque haya una corriente de mando.
	var mostrado := 0.0 if i_a < RESOLUCION_A / 2.0 else i_a * (1.0 + ruido * _azar.randf_range(-1.0, 1.0))
	return {"valor": mostrado, "unidad": "A", "fuera_de_rango": false, "averia": ""}
