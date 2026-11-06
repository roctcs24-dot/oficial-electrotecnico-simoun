class_name SimLed
extends SimDiodo
## LED: un diodo con más caída, que se enciende con unos miliamperios. Conectado a 24 V sin
## resistencia en serie, la corriente lo quema enseguida, y queda abierto.

const I_ENCIENDE := 0.002


func tipo() -> String:
	return "led"


func _params_por_defecto() -> Dictionary:
	return {"vf": 2.0, "r_on": 20.0, "r_off": 1e8, "i_max": 0.03, "v_inversa": 30.0, "falla": "abierto"}


func encendido(sol: SimSolver.Solucion) -> bool:
	return not estado["quemado"] and corriente(sol) >= I_ENCIENDE
