extends RefCounted
## Refrigeración por amoníaco: tabla presión–temperatura, régimen de la planta, presostatos,
## hielo, falta de refrigerante, fugas y válvula de seguridad.

const A := preload("res://tests/ayuda_sim.gd")


func _planta(sim: SimSimulacion) -> SimPlantaFrio:
	return sim.componente("PLANTA")


func _presostato(sim: SimSimulacion, id: String) -> SimPresostato:
	return sim.componente(id)


## Pasos de 1 s: con el motor ya arrancado son estables y mucho más rápidos.
func _avanzar(sim: SimSimulacion, segundos: int) -> void:
	for _i in segundos:
		sim.paso(1.0)


## Planta con el compresor arrancado. averias cambia parámetros de la planta antes de arrancar.
func _arrancar(averias := {}) -> SimSimulacion:
	var sim := A.circuito("planta_frio")
	_planta(sim).params.merge(averias, true)
	sim.componente("Q1").accionar(true)
	sim.avanzar_tiempo(0.1)
	A.pulsar(sim, "S1", 0.3)
	sim.avanzar_tiempo(5.0)
	return sim


func _en_marcha(sim: SimSimulacion) -> bool:
	return (sim.componente("K1") as SimContactor).cerrado() and _planta(sim).compresor_en_marcha()


func test_tabla_del_amoniaco() -> String:
	return A.primero([
		A.cerca(SimNH3.p_sat_abs(-33.34), 1.013, 0.01, "ebullición a presión atmosférica"),
		A.cerca(SimNH3.p_sat_abs(0.0), 4.294, 0.001, "0 °C, punto de la tabla"),
		A.cerca(SimNH3.p_sat_rel(35.0), 12.49, 0.01, "35 °C en relativa"),
		A.cerca(SimNH3.p_sat_abs(-27.5), 1.35, 0.02, "interpolación entre −30 y −25 °C"),
		A.cerca(SimNH3.t_sat_abs(SimNH3.p_sat_abs(-12.3)), -12.3, 0.001, "ida y vuelta"),
		A.cerca(SimNH3.bar_a_psi(1.0), 14.5, 0.001, "1 bar en psi"),
	])


func test_arranca_y_enfria_la_salmuera() -> String:
	var sim := _arrancar()
	var planta := _planta(sim)
	var ts_inicial: float = planta.temperatura("salmuera")
	_avanzar(sim, 60)
	var te: float = planta.temperatura("evaporacion")
	var i_motor: float = (sim.componente("F2") as SimReleTermico).corriente(sim.solucion, 0)
	_avanzar(sim, 340)
	var ts: float = planta.temperatura("salmuera")
	var tc: float = planta.temperatura("condensacion")
	return A.primero([
		A.cierto(_en_marcha(sim), "el compresor debe seguir en marcha"),
		A.cierto(te < ts_inicial - 5.0, "evapora por debajo de la salmuera: %.1f °C" % te),
		A.cierto(i_motor < 202.0 * 1.05, "el limitador mantiene la corriente del motor: %.0f A" % i_motor),
		A.cierto(ts < -10.0, "la salmuera debe bajar de −10 °C en unos minutos: %.1f °C" % ts),
		A.cierto(tc > 30.0 and tc < 42.0, "condensación típica con agua de mar a 29 °C: %.1f °C" % tc),
		A.cierto(not sim.hubo_evento("disparo_presostato"), "sin disparos"),
		A.cierto(not (sim.componente("F2") as SimReleTermico).estado["disparado"], "el relé térmico no dispara"),
	])


func test_regimen_en_la_consigna() -> String:
	var sim := _arrancar()
	var planta := _planta(sim)
	_avanzar(sim, 900)
	var ts: float = planta.temperatura("salmuera")
	var te: float = planta.temperatura("evaporacion")
	return A.primero([
		# El pistón regula por etapas: con la base ya enfría algo más que la carga.
		A.cerca(ts, -15.0, 0.15, "la salmuera cerca de su consigna"),
		A.cierto(planta.estado["capacidad"] < 0.6, "en la consigna el compresor trabaja descargado: %.2f" % planta.estado["capacidad"]),
		A.cierto(te > -22.0 and te < ts, "evaporación unos grados por debajo de la salmuera: %.1f °C" % te),
		A.cierto(planta.presion("succion") > 0.3, "succión por encima del corte de baja: %.2f bar" % planta.presion("succion")),
		A.cierto(planta.estado["hielo"] < 0.01, "con la salmuera bien concentrada no se forma hielo"),
		A.cierto(not sim.hubo_evento("disparo_presostato"), "sin disparos"),
	])


func test_sin_agua_de_mar_dispara_por_alta() -> String:
	var sim := _arrancar()
	var planta := _planta(sim)
	_avanzar(sim, 120)
	planta.estado["bomba_agua_mar"] = false
	_avanzar(sim, 90)
	var pa := _presostato(sim, "PA")
	var parado := not _en_marcha(sim)
	var rearme_con_presion := pa.rearmar()
	planta.estado["bomba_agua_mar"] = true
	_avanzar(sim, 120)
	var sigue_abierto: bool = pa.estado["disparado"]
	var rearme := pa.rearmar()
	return A.primero([
		A.cierto(sim.hubo_evento("disparo_presostato", "PA"), "debe disparar el presostato de alta"),
		A.cierto(parado, "debe parar el compresor"),
		A.cierto(not rearme_con_presion, "con presión alta no se puede rearmar"),
		A.cierto(sigue_abierto, "el rearme es manual: sigue abierto al recuperarse"),
		A.cierto(rearme and not pa.estado["disparado"], "con la presión normal, se rearma"),
		A.cierto(planta.presion("descarga") < 12.0, "parado, la descarga baja hacia la del agua de mar: %.1f bar" % planta.presion("descarga")),
	])


func test_sin_bomba_de_salmuera_dispara_por_baja() -> String:
	var sim := _arrancar()
	var planta := _planta(sim)
	_avanzar(sim, 120)
	planta.estado["bomba_salmuera"] = false
	# El pistón tarda algo más en bajar la succión; a los 140 s el de baja ya rearmaría solo.
	_avanzar(sim, 100)
	var pb := _presostato(sim, "PB")
	var disparado: bool = pb.estado["disparado"]
	var parado := not _en_marcha(sim)
	planta.estado["bomba_salmuera"] = true
	_avanzar(sim, 120)
	return A.primero([
		A.cierto(disparado and sim.hubo_evento("disparo_presostato", "PB"), "debe disparar el presostato de baja"),
		A.cierto(parado, "debe parar el compresor"),
		A.cierto(not pb.estado["disparado"], "el de baja se rearma solo al subir la presión"),
		A.cierto(not _en_marcha(sim), "pero el compresor no vuelve a arrancar sin pulsar marcha"),
	])


func test_aceite_bajo_dispara_tras_el_retardo() -> String:
	var sim := _arrancar({"obstruccion_filtro_aceite": 0.8})
	_avanzar(sim, 35)
	var antes := not sim.hubo_evento("disparo_presostato", "PO")
	_avanzar(sim, 15)
	var sano := _arrancar()
	_avanzar(sano, 60)
	return A.primero([
		A.cierto(antes, "durante el retardo no debe disparar"),
		A.cierto(sim.hubo_evento("disparo_presostato", "PO") and not _en_marcha(sim), "pasado el retardo dispara y para"),
		A.cierto(_planta(sano).presion("aceite") > 2.5, "con el filtro limpio, unos 3 bar de diferencial: %.2f" % _planta(sano).presion("aceite")),
		A.cierto(_en_marcha(sano), "con presión de aceite correcta sigue en marcha"),
	])


func test_falta_de_refrigerante_baja_la_succion() -> String:
	var normal := _arrancar()
	var falta := _arrancar({})
	_planta(falta).estado["carga_refrigerante"] = 0.55
	_avanzar(normal, 200)
	_avanzar(falta, 200)
	var p_normal: float = _planta(normal).presion("succion")
	var p_falta: float = _planta(falta).presion("succion")
	return A.primero([
		A.cierto(p_falta < p_normal - 0.3, "con poca carga, menos succión: %.2f frente a %.2f bar" % [p_falta, p_normal]),
		A.cierto(_planta(falta).temperatura("salmuera") > _planta(normal).temperatura("salmuera"), "y la salmuera se enfría más despacio"),
	])


func test_salmuera_floja_forma_hielo() -> String:
	var sim := _arrancar({"congelacion_salmuera": -8.0})
	_avanzar(sim, 400)
	var planta := _planta(sim)
	return A.primero([
		A.cierto(planta.estado["hielo"] > 0.3, "debe formarse hielo en los tubos: %.2f" % planta.estado["hielo"]),
		A.cierto(planta.temperatura("salmuera") > -15.0, "con hielo, la salmuera no llega a la consigna: %.1f °C" % planta.temperatura("salmuera")),
	])


func test_fuga_llena_la_sala_de_amoniaco() -> String:
	var sim := _arrancar({"fuga_kg_h": 20.0})
	_avanzar(sim, 30)
	var planta := _planta(sim)
	var ppm: float = planta.estado["ppm_sala"]
	planta.estado["ventilacion_emergencia"] = true
	planta.params["fuga_kg_h"] = 0.0
	_avanzar(sim, 300)
	return A.primero([
		A.cierto(ppm > 150.0, "la sala debe pasar de la alarma alta: %.0f ppm" % ppm),
		A.cierto(sim.hubo_evento("alarma_nh3") and sim.hubo_evento("alarma_nh3_alta"), "deben saltar los dos niveles de alarma"),
		A.cierto(planta.estado["carga_refrigerante"] < 1.0, "la fuga pierde carga"),
		A.cierto(planta.estado["ppm_sala"] < ppm / 5.0, "parada la fuga, la ventilación de emergencia limpia la sala: %.0f ppm" % planta.estado["ppm_sala"]),
	])


func test_valvula_de_seguridad_con_el_presostato_puenteado() -> String:
	var sim := _arrancar()
	var planta := _planta(sim)
	_avanzar(sim, 60)
	_presostato(sim, "PA").estado["puenteado"] = true
	planta.estado["bomba_agua_mar"] = false
	_avanzar(sim, 300)
	return A.primero([
		A.cierto(sim.hubo_evento("valvula_seguridad"), "debe abrir la válvula de seguridad"),
		A.cierto(planta.presion("descarga") <= 20.05, "la válvula limita la presión: %.2f bar" % planta.presion("descarga")),
		A.cierto(planta.estado["carga_refrigerante"] < 1.0, "y descarga amoníaco a la atmósfera"),
	])


func test_al_parar_se_igualan_las_presiones() -> String:
	var sim := _arrancar()
	_avanzar(sim, 120)
	A.pulsar(sim, "S0", 0.3)
	_avanzar(sim, 300)
	var planta := _planta(sim)
	return A.primero([
		A.cierto(not _en_marcha(sim), "debe estar parado"),
		A.cerca(planta.temperatura("evaporacion"), planta.temperatura("salmuera"), 0.1, "la evaporación sube a la temperatura de la salmuera"),
		A.cerca(planta.temperatura("condensacion"), 29.0, 0.03, "la condensación baja a la del agua de mar"),
		A.cerca(planta.estado["capacidad"], planta.etapa_base(), 0.001, "vuelve a la etapa base para arrancar descargado"),
	])


## Los datos típicos del barco y los de la simulación deben ser los mismos.
func test_la_planta_coincide_con_los_datos_del_barco() -> String:
	var barco: Dictionary = Contenido.new().barco()["refrigeracion"]
	var sim := A.circuito("planta_frio")
	var planta := _planta(sim)
	var valor := func(clave: String) -> float: return float(barco[clave]["valor"])
	var pares := [
		["capacidad_por_compresor_kw", float(planta.params["q_nominal_kw"])],
		["motor_compresor_kw", float(sim.componente("M1").params["p_kw"])],
		["consigna_salmuera_c", float(planta.params["consigna_salmuera"])],
		["congelacion_salmuera_c", float(planta.params["congelacion_salmuera"])],
		["temperatura_agua_mar_c", float(planta.params["t_agua_mar"])],
		["carga_nh3_kg", float(planta.params["masa_nh3_kg"])],
		["presostato_alta_bar", float(_presostato(sim, "PA").params["corte_bar"])],
		["presostato_baja_bar", float(_presostato(sim, "PB").params["corte_bar"])],
		["presostato_aceite_bar", float(_presostato(sim, "PO").params["corte_bar"])],
		["valvula_seguridad_bar", float(planta.params["valvula_seguridad_bar"])],
	]
	for par: Array in pares:
		if not is_equal_approx(valor.call(par[0]), par[1]):
			return "%s: el barco dice %s y la simulación %s" % [par[0], str(valor.call(par[0])), str(par[1])]
	var alarmas: Array = barco["alarmas_nh3_ppm"]["valor"]
	return A.cierto(is_equal_approx(float(alarmas[0]), planta.params["alarma_ppm"]) and is_equal_approx(float(alarmas[1]), planta.params["alarma_alta_ppm"]), "alarmas de NH3")
