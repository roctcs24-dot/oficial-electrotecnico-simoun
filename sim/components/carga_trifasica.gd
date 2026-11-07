class_name SimCargaTrifasica
extends SimComponente
## Salida del cuadro con su interruptor: una carga trifásica equilibrada de impedancia
## constante, con la potencia indicada a la tensión nominal. Bornes L1, L2 y L3.
## Si no es esencial, el disparo preferente la desconecta.
## Una falla a tierra aguas abajo se simula con falla_mohm, entre falla_fase y el casco: solo
## está en la red mientras la salida está conectada.

## Aislamiento de una salida sana contra el casco. Valor del simulador: verificar a bordo.
const AISLAMIENTO_SANO_MOHM := 150.0


func tipo() -> String:
	return "carga_trifasica"


func _params_por_defecto() -> Dictionary:
	return {"p_kw": 100.0, "q_kvar": 75.0, "v_linea": SimRed.V_LINEA, "esencial": true, "falla_mohm": 0.0, "falla_fase": "L1"}


func _estado_inicial() -> Dictionary:
	return {"conectada": true, "desde": 0.0, "bloqueada": false}


func conectar() -> void:
	estado["conectada"] = true
	var simulacion := sim()
	estado["desde"] = simulacion.tiempo if simulacion != null else 0.0


func desconectar() -> void:
	estado["conectada"] = false


## Lo que mide un megóhmetro entre la salida, abierta, y el casco.
func aislamiento_mohm() -> float:
	return params["falla_mohm"] if params["falla_mohm"] > 0.0 else AISLAMIENTO_SANO_MOHM


func estampar(e: SimEstampa) -> void:
	if not estado["conectada"]:
		return
	if params["falla_mohm"] > 0.0:
		e.impedancia(n(params["falla_fase"]), SimSolver.TIERRA, params["falla_mohm"] * 1e6)
	var s := Cx.new(params["p_kw"] * 1000.0 / 3.0, params["q_kvar"] * 1000.0 / 3.0)
	var d := s.re * s.re + s.im * s.im
	if d <= 0.0:
		return
	var v_fase2: float = params["v_linea"] * params["v_linea"] / 3.0
	for fase in ["L1", "L2", "L3"]:
		e.impedancia(n(fase), n("N"), v_fase2 * s.re / d, v_fase2 * s.im / d)


func avanzar(_dt: float, _sol: SimSolver.Solucion) -> void:
	if params["esencial"] or not estado["conectada"]:
		return
	var simulacion := sim()
	if simulacion != null and simulacion.tiempo_ultimo("disparo_preferente") >= estado["desde"]:
		estado["conectada"] = false
		avisar("carga_desconectada")
