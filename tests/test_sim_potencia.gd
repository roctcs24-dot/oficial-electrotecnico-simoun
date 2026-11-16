extends RefCounted
## Potencia y medida: transformador de intensidad, aparatos de cuadro, analizador de red,
## condensadores, variador con el motor a frecuencia variable, resistencia de caldeo, bornera y
## transformador con un devanado cortado.

const A := preload("res://tests/ayuda_sim.gd")


func _cuadro(estado := {}) -> SimSimulacion:
	var sim := A.circuito("cuadro_medida")
	for id: String in estado:
		sim.componente(id).estado.merge(estado[id], true)
	sim.avanzar_tiempo(0.3)
	return sim


func test_ti_da_la_relacion_y_abierto_sube_la_tension() -> String:
	var sim := _cuadro()
	var sol := sim.resolver()
	var ti: SimTransformadorIntensidad = sim.componente("TI1")
	var primaria := ti.corriente_primaria(sol)
	var bobina := (sim.componente("A1") as SimAmperimetro).corriente_bobina(sol)
	var lectura: float = sim.componente("A1").leer(sol)["valor"]
	var abierto := _cuadro({"A1": {"bobina_cortada": true}})
	var v_abierto := abierto.resolver().entre("TI1.S1", "TI1.S2").modulo()
	var puenteado := _cuadro({"TI1": {"puente": true}})
	var con_puente: float = puenteado.componente("A1").leer(puenteado.resolver())["valor"]
	return A.primero([
		A.cerca(bobina, primaria / 20.0, 0.05, "secundario = primario / 20"),
		A.cerca(lectura, primaria, 1.0, "el amperímetro marca la corriente de la barra"),
		A.cierto(v_abierto > 500.0, "secundario abierto: cientos de voltios (%d V)" % roundi(v_abierto)),
		A.cerca(con_puente, 0.0, 0.5, "con el puente cerrado el amperímetro marca cero"),
	])


func test_analizador_coincide_con_la_carga() -> String:
	var sim := _cuadro()
	var sol := sim.resolver()
	var an: SimAnalizadorRed = sim.componente("AN1")
	var p: float = an.leer(sol, "p")["valor"]
	var q: float = an.leer(sol, "q")["valor"]
	var fp := an.factor_potencia(sol)
	var v: float = sim.componente("V1").leer(sol)["valor"]
	return A.primero([
		A.cerca(p, 40.0, 1.5, "P de la carga de 40 kW"),
		A.cerca(q, 30.0, 1.5, "Q de la carga de 30 kvar"),
		A.cerca(fp, 0.8, 0.02, "factor de potencia 0,8"),
		A.cerca(v, 380.0, 5.0, "voltímetro entre L1 y L2"),
	])


func test_condensadores_suben_el_factor_de_potencia() -> String:
	var con := A.circuito("compensacion_servicio")
	con.avanzar_tiempo(0.3)
	var sin := A.circuito("compensacion_servicio")
	sin.componente("CB1").params["q_kvar"] = 0.0
	sin.avanzar_tiempo(0.3)
	var fp_con := (con.componente("AN1") as SimAnalizadorRed).factor_potencia(con.resolver())
	var fp_sin := (sin.componente("AN1") as SimAnalizadorRed).factor_potencia(sin.resolver())
	var i_con: float = con.componente("AN1").leer(con.resolver(), "i1")["valor"]
	var i_sin: float = sin.componente("AN1").leer(sin.resolver(), "i1")["valor"]
	var medir := A.circuito("medir_condensadores")
	var r_dc := medir.resolver(true, func(e: SimEstampa) -> void: e.inyectar("CB1.L1", "CB1.L2", 0.001)).entre("CB1.L1", "CB1.L2").modulo() / 0.001
	return A.primero([
		A.cerca(fp_sin, 0.75, 0.02, "sin batería, FP 0,75"),
		A.cerca(fp_con, 0.97, 0.02, "con 25 kvar, FP 0,97"),
		A.cierto(i_con < i_sin, "compensada, la red da menos corriente (%d A frente a %d A)" % [roundi(i_con), roundi(i_sin)]),
		A.cerca(r_dc / 1000.0, 146.7, 2.0, "en continua solo quedan las resistencias de descarga"),
	])


func _variador(consigna: float, segundos := 10.0) -> SimSimulacion:
	var sim := A.circuito("variador_servicio")
	sim.componente("VF1").params["consigna_hz"] = consigna
	(sim.componente("VF1") as SimVariador).marchar()
	sim.avanzar_tiempo(segundos)
	return sim


func test_variador_regula_la_velocidad_con_v_f() -> String:
	var a50 := _variador(50.0)
	var a25 := _variador(25.0)
	var vf50: SimVariador = a50.componente("VF1")
	var vf25: SimVariador = a25.componente("VF1")
	var rpm50 := (a50.componente("M1") as SimMotorTrifasico).rpm()
	var rpm25 := (a25.componente("M1") as SimMotorTrifasico).rpm()
	var rampa := _variador(50.0, 2.0)
	return A.primero([
		A.cerca(rpm50, 1460.0, 15.0, "a 50 Hz gira cerca de su velocidad de placa"),
		A.cerca(rpm25, 735.0, 15.0, "a 25 Hz, la mitad"),
		A.cerca(vf25.tension_salida(), 190.0, 1.0, "V/f: 190 V a 25 Hz"),
		A.cerca(float(vf50.estado["bus_v"]), 513.0, 5.0, "bus a 1,35 × la red"),
		A.cierto(float(vf25.estado["i"]) < float(vf50.estado["i"]), "a menos velocidad, menos corriente de bomba"),
		A.cierto(float(rampa.componente("VF1").estado["f"]) < 25.0, "a los 2 s aún está en rampa"),
	])


func test_variador_dispara_por_corto_y_por_temperatura() -> String:
	var corto := A.circuito("variador_servicio")
	corto.componente("VF1").estado["corto_salida"] = true
	(corto.componente("VF1") as SimVariador).marchar()
	corto.avanzar_tiempo(3.0)
	var caliente := A.circuito("variador_servicio")
	caliente.componente("VF1").estado["ventilador_parado"] = true
	(caliente.componente("VF1") as SimVariador).marchar()
	caliente.avanzar_tiempo(30.0)
	var vf: SimVariador = caliente.componente("VF1")
	var rearma := vf.rearmar()
	return A.primero([
		A.cierto(str(corto.componente("VF1").estado["fallo"]).begins_with("F001"), "corto en la salida: F001"),
		A.cierto(corto.hubo_evento("variador_fallo"), "avisa del fallo"),
		A.cierto(rearma and not vf.en_fallo(), "rearma tras el fallo de temperatura"),
	])


func test_motor_directo_no_cambia_con_frecuencia_de_placa() -> String:
	var sim := A.circuito("arranque_directo")
	sim.componente("Q1").accionar(true)
	sim.paso()
	A.pulsar(sim, "S1")
	sim.avanzar_tiempo(5.0)
	var m: SimMotorTrifasico = sim.componente("M1")
	return A.primero([
		A.cierto(not m.estado.has("f_alim"), "sin variador el motor no recibe otra frecuencia"),
		A.cerca(m.rpm(), 1470.0, 20.0, "gira a su velocidad de placa"),
	])


func test_caldeo_solo_con_el_motor_parado() -> String:
	var sim := A.circuito("caldeo_servicio")
	sim.avanzar_tiempo(0.3)
	var r: SimResistenciaCaldeo = sim.componente("R1")
	var parado := r.potencia(sim.resolver())
	sim.componente("S1").estado["presionado"] = true
	sim.avanzar_tiempo(0.3)
	var en_marcha := r.potencia(sim.resolver())
	return A.primero([
		A.cerca(parado, 100.0, 5.0, "parado calienta con sus 100 W"),
		A.cierto(en_marcha < 0.5, "en marcha el NC del contactor la apaga: %.1f W" % en_marcha),
	])


func test_borne_flojo_cae_tension_y_suelto_deja_dos_fases() -> String:
	var sanos := A.circuito("bornera_servicio")
	A.pulsar(sanos, "S1")
	sanos.avanzar_tiempo(5.0)
	var flojo := A.circuito("bornera_servicio")
	flojo.componente("X1").estado["flojos"] = ["2"]
	A.pulsar(flojo, "S1")
	flojo.avanzar_tiempo(5.0)
	var x1: SimBornera = flojo.componente("X1")
	var caida := flojo.resolver().entre("X1.2A", "X1.2B").modulo()
	return A.primero([
		A.cierto(sanos.resolver().entre("X1.2A", "X1.2B").modulo() < 0.1, "borne apretado: casi sin caída"),
		A.cerca(caida, 1.2, 0.2, "borne flojo: 1,2 V con 24 A"),
		A.cerca(x1.calor_w(flojo.resolver(), "2"), 29.0, 4.0, "unos 29 W en el borne"),
	])


func test_transformador_con_columna_cortada() -> String:
	var sano := A.circuito("transformador_servicio")
	sano.avanzar_tiempo(0.3)
	var cortado := A.circuito("transformador_servicio")
	cortado.componente("TU").estado["primario_cortado"] = true
	cortado.avanzar_tiempo(0.3)
	var v_sano := sano.resolver().entre("TU.X1", "TV.X1").modulo()
	var v_cortado := cortado.resolver().entre("TU.X1", "TV.X1").modulo()
	return A.primero([
		A.cerca(v_sano, 216.0, 4.0, "220 V menos la caída con carga"),
		A.cierto(v_cortado > 190.0, "en triángulo abierto sigue dando tensión (%d V)" % roundi(v_cortado)),
	])
