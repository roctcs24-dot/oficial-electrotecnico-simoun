class_name SimMegohmetro
extends RefCounted
## Megóhmetro de 250, 500 o 1000 V. Se comprueba primero que no haya tensión:
## usarlo sobre un circuito energizado lo destruye.
## El mínimo de 5 MΩ es el que recomienda IEEE 43 para devanados de menos de 1 kV: verificar
## con el manual del equipo y el criterio del buque.

const TENSIONES := [250, 500, 1000]
const R_ENTRADA := 1e7
const V_MAX_EXTERNA := 30.0
const I_PRUEBA := 0.001
const MOHM_MAX := 999.0
const MINIMO_MOHM := 5.0

var ruido := 0.02
var destruido := false
var _azar := RandomNumberGenerator.new()


## Devuelve {mohm, fuera_de_rango, averia, aceptable}.
func medir(sim: SimSimulacion, a: String, b: String, v_prueba := 500) -> Dictionary:
	if destruido or not TENSIONES.has(v_prueba):
		return {"mohm": 0.0, "fuera_de_rango": false, "averia": "megohmetro_no_disponible", "aceptable": false}
	var sol_ac := sim.resolver(false, func(e: SimEstampa) -> void: e.impedancia(a, b, R_ENTRADA))
	var v := sol_ac.entre(a, b).modulo()
	if v > V_MAX_EXTERNA:
		destruido = true
		sim.registrar_evento("megohmetro_destruido", "megohmetro", {"tension_v": v})
		return {"mohm": 0.0, "fuera_de_rango": false, "averia": "megohmetro_destruido", "aceptable": false}
	var sol := sim.resolver(true, func(e: SimEstampa) -> void: e.inyectar(a, b, I_PRUEBA))
	var mohm := sol.entre(a, b).modulo() / I_PRUEBA / 1e6
	var fuera := mohm > MOHM_MAX
	var mostrado := MOHM_MAX if fuera else mohm * (1.0 + ruido * _azar.randf_range(-1.0, 1.0))
	return {"mohm": mostrado, "fuera_de_rango": fuera, "averia": "", "aceptable": mohm >= MINIMO_MOHM}
