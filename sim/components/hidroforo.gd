class_name SimHidroforo
extends SimComponente
## Tanque hidróforo con su presostato 13-14: el aire comprimido del tanque mantiene la presión de la
## red de agua. El consumo la baja; cada bomba en marcha la sube. El presostato cierra por debajo
## de la presión de arranque y abre al llegar a la de parada, y manda las bombas en AUT.
## Modelo concentrado para enseñar. Presiones y caudales típicos: verificar a bordo.


func tipo() -> String:
	return "hidroforo"


func _params_por_defecto() -> Dictionary:
	return {
		"bombas": ["M1", "M2"],
		"arranque_bar": 2.5,
		"parada_bar": 4.0,
		# Bar por segundo que sube una bomba a su velocidad, y que baja con el consumo normal.
		"sube_bar_s": 0.05,
		"consumo_bar_s": 0.02,
		"maxima_bar": 6.0,
	}


func _estado_inicial() -> Dictionary:
	return {"presion": 3.2, "pide": false, "consumo": 1.0}


func estampar(e: SimEstampa) -> void:
	if estado["pide"]:
		e.enlace(n("13"), n("14"))


func avanzar(dt: float, _sol: SimSolver.Solucion) -> void:
	var sube := 0.0
	for id: String in params["bombas"]:
		if not sim().componentes.has(id):
			continue
		var m: SimMotorTrifasico = sim().componente(id)
		var giro := clampf(absf(m.rpm()) / float(m.params["rpm"]), 0.0, 1.0)
		# Una bomba centrífuga da presión con el cuadrado de la velocidad.
		sube += float(params["sube_bar_s"]) * giro * giro
	var p: float = estado["presion"] + (sube - float(params["consumo_bar_s"]) * float(estado["consumo"])) * dt
	estado["presion"] = clampf(p, 0.0, params["maxima_bar"])
	if estado["presion"] <= params["arranque_bar"]:
		estado["pide"] = true
	elif estado["presion"] >= params["parada_bar"]:
		estado["pide"] = false
