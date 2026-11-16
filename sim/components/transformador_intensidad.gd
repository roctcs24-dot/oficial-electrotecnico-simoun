class_name SimTransformadorIntensidad
extends SimComponente
## Transformador de intensidad (current transformer), como el 100/5 A de una salida del cuadro.
## El primario P1-P2 es el propio conductor y casi no tiene impedancia. El secundario S1-S2 da
## una corriente proporcional a la del primario, sea cual sea su carga: se representa como una
## fuente de corriente con la reactancia magnetizante en paralelo. Con el secundario abierto, esa
## corriente no tiene camino y la tensión sube hasta saturar el núcleo: con 5 A en el secundario
## y la reactancia de 200 Ω, unos 1000 V entre S1 y S2. Valor de enseñanza; en un TI real los
## picos son aún mayores. Por eso el secundario se cortocircuita (puente) antes de desconectar
## el amperímetro.
##
## La corriente del primario se toma de la resolución anterior, como el secundario del
## transformador de mando.

const TOLERANCIA_A := 0.005

var _i_sec := Cx.new()


func tipo() -> String:
	return "transformador_intensidad"


func _params_por_defecto() -> Dictionary:
	return {"i_primaria": 100.0, "i_secundaria": 5.0, "r_secundario": 0.15, "x_magnetizante": 200.0, "aislamiento_mohm": 0.0}


func _estado_inicial() -> Dictionary:
	return {"puente": false, "secundario_cortado": false}


func relacion() -> float:
	return float(params["i_secundaria"]) / float(params["i_primaria"])


func estampar(e: SimEstampa) -> void:
	e.impedancia(n("P1"), n("P2"), R_CONTACTO)
	if float(params["aislamiento_mohm"]) > 0.0:
		e.impedancia(n("P1"), SimSolver.TIERRA, float(params["aislamiento_mohm"]) * 1e6)
		e.impedancia(n("S2"), SimSolver.TIERRA, float(params["aislamiento_mohm"]) * 1e6)
	if estado["puente"]:
		e.enlace(n("S1"), n("S2"))
	if estado["secundario_cortado"]:
		return
	e.impedancia(n("m"), n("S1"), params["r_secundario"])
	e.impedancia(n("m"), n("S2"), 0.0, params["x_magnetizante"])
	if not e.dc:
		e.inyectar(n("m"), n("S2"), _i_sec.re, _i_sec.im)


func asentar(sol: SimSolver.Solucion) -> bool:
	if estado["secundario_cortado"]:
		_i_sec = Cx.new()
		return false
	var nueva := sol.entre(n("P1"), n("P2")).escala(relacion() / R_CONTACTO)
	var cambio := nueva.menos(_i_sec).modulo() > TOLERANCIA_A
	_i_sec = nueva
	return cambio


## Corriente del primario en la última resolución.
func corriente_primaria(sol: SimSolver.Solucion) -> float:
	return sol.entre(n("P1"), n("P2")).modulo() / R_CONTACTO
