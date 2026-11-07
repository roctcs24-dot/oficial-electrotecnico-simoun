class_name EnsayoConexion
extends RefCounted
## Ensayo de un motor conectado en estrella o delta a la red, con su relé térmico ajustado a
## la corriente de esa conexión. Si el relé dispara, se corta la alimentación, como haría
## el contactor.

const PLACAS := {
	"380_660": {"p_kw": 15.0, "v_delta": 380.0, "v_estrella": 660.0, "i_delta": 29.5, "i_estrella": 17.0, "carga": 1.0},
	"220_380": {"p_kw": 15.0, "v_delta": 220.0, "v_estrella": 380.0, "i_delta": 51.1, "i_estrella": 29.5, "carga": 1.0},
}

var sim: SimSimulacion
var placa: String
var conexion: String
var v_devanado := 0.0
var corriente := 0.0


func _init(id_placa: String, tipo_conexion: String) -> void:
	placa = id_placa
	conexion = tipo_conexion
	var p: Dictionary = PLACAS[id_placa]
	sim = SimSimulacion.new()
	sim.agregar(SimFuenteTrifasica.new("B"))
	var ajuste: float = p["i_delta"] if tipo_conexion == "delta" else p["i_estrella"]
	sim.agregar(SimReleTermico.new("F2", {"ajuste_a": ajuste}))
	sim.agregar(SimMotorTrifasico.new("M1", p.duplicate()))
	for par in [["B.L1", "F2.1"], ["B.L2", "F2.3"], ["B.L3", "F2.5"], ["F2.2", "M1.U1"], ["F2.4", "M1.V1"], ["F2.6", "M1.W1"]]:
		sim.conectar(par[0], par[1])
	if tipo_conexion == "delta":
		for par in [["M1.U1", "M1.W2"], ["M1.V1", "M1.U2"], ["M1.W1", "M1.V2"]]:
			sim.conectar(par[0], par[1])
	else:
		sim.conectar("M1.U2", "M1.V2")
		sim.conectar("M1.V2", "M1.W2")


func motor() -> SimMotorTrifasico:
	return sim.componente("M1")


func avanzar(pasos: int) -> void:
	for _i in pasos:
		sim.paso()
		v_devanado = sim.solucion.entre("M1.U1", "M1.U2").modulo()
		corriente = sim.componente("F2").corriente(sim.solucion, 0)
		if sim.componente("F2").estado["disparado"]:
			sim.componente("B").estado["activa"] = false


func disparo() -> bool:
	return sim.hubo_evento("disparo_rele_termico", "F2")


func quemado() -> bool:
	return motor().quemado()


## "correcto" si la tensión de devanado es la admisible, "exceso" si la supera y "defecto"
## si es menor: en ese caso el motor no da su par y se sobrecarga.
static func diagnostico(id_placa: String, tipo_conexion: String) -> String:
	var v_admisible: float = PLACAS[id_placa]["v_delta"]
	var v_recibida := SimRed.V_LINEA if tipo_conexion == "delta" else SimRed.V_LINEA / sqrt(3.0)
	if v_recibida > v_admisible * 1.1:
		return "exceso"
	if v_recibida < v_admisible * 0.9:
		return "defecto"
	return "correcto"
