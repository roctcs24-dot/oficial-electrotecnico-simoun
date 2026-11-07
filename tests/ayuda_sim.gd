extends RefCounted
## Utilidades de las pruebas del motor. Las comprobaciones devuelven "" o el motivo del fallo.

const PLACA_380D := {"p_kw": 15.0, "v_delta": 380.0, "v_estrella": 660.0, "i_delta": 29.5, "i_estrella": 17.0}
const PLACA_220D := {"p_kw": 15.0, "v_delta": 220.0, "v_estrella": 380.0, "i_delta": 51.1, "i_estrella": 29.5}


static func cerca(valor: float, esperado: float, tolerancia: float, etiqueta: String) -> String:
	if absf(valor - esperado) <= absf(esperado) * tolerancia:
		return ""
	return "%s: %.3f, se esperaba %.3f ± %d %%" % [etiqueta, valor, esperado, int(tolerancia * 100.0)]


static func cierto(condicion: bool, etiqueta: String) -> String:
	return "" if condicion else etiqueta


static func primero(resultados: Array) -> String:
	for r: String in resultados:
		if not r.is_empty():
			return r
	return ""


static func circuito(nombre: String) -> SimSimulacion:
	var texto := FileAccess.get_file_as_string("res://data/circuitos/%s.json" % nombre)
	return SimSimulacion.desde_dict(JSON.parse_string(texto))


static func pulsar(sim: SimSimulacion, id: String, segundos := 0.2) -> void:
	sim.componente(id).estado["presionado"] = true
	sim.avanzar_tiempo(segundos)
	sim.componente(id).estado["presionado"] = false
	sim.paso()


## Barras, relé térmico y motor conectado en la bornera según conexion ("delta" o "estrella").
static func banco_motor(placa: Dictionary, conexion: String, ajuste: float, extra := {}) -> SimSimulacion:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteTrifasica.new("B"))
	var ajuste_real := ajuste if ajuste > 0.0 else 100000.0
	sim.agregar(SimReleTermico.new("F2", {"ajuste_a": ajuste_real}))
	var p := placa.duplicate()
	p.merge(extra, true)
	sim.agregar(SimMotorTrifasico.new("M1", p))
	sim.conectar("B.L1", "F2.1")
	sim.conectar("B.L2", "F2.3")
	sim.conectar("B.L3", "F2.5")
	sim.conectar("F2.2", "M1.U1")
	sim.conectar("F2.4", "M1.V1")
	sim.conectar("F2.6", "M1.W1")
	if conexion == "delta":
		sim.conectar("M1.U1", "M1.W2")
		sim.conectar("M1.V1", "M1.U2")
		sim.conectar("M1.W1", "M1.V2")
	else:
		sim.conectar("M1.U2", "M1.V2")
		sim.conectar("M1.V2", "M1.W2")
	return sim
