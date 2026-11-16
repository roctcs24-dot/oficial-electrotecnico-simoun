extends RefCounted
## Componentes de la electrónica II: transistor, MOSFET, tiristor, triac, optoacoplador,
## regulador, operacional como comparador y puertas lógicas.

const A := preload("res://tests/ayuda_sim.gd")


func _multimetro() -> SimMultimetro:
	var m := SimMultimetro.new()
	m.ruido = 0.0
	return m


func _pulsado(nombre: String, segundos := 0.3) -> SimSimulacion:
	var sim := A.circuito(nombre)
	sim.componente("S1").estado["presionado"] = true
	sim.avanzar_tiempo(segundos)
	return sim


func test_transistor_satura_y_manda_el_rele() -> String:
	var reposo := A.circuito("transistor_servicio")
	reposo.avanzar_tiempo(0.3)
	var con_orden := _pulsado("transistor_servicio")
	var q: SimTransistor = con_orden.componente("Q1")
	var m := _multimetro()
	var debil := A.circuito("transistor_servicio")
	debil.componente("RB").params["ohm"] = 470000.0
	debil.componente("S1").estado["presionado"] = true
	debil.avanzar_tiempo(0.3)
	return A.primero([
		A.cerca(m.medir(reposo, "vdc", "Q1.C", "Q1.E")["valor"], 24.0, 0.01, "sin orden, toda la tensión en C-E"),
		A.cierto(q.saturado(), "con 2,3 mA de base debe saturar"),
		A.cerca(m.medir(con_orden, "vdc", "Q1.C", "Q1.E")["valor"], 0.2, 0.15, "saturado: 0,2 V"),
		A.cierto(con_orden.componente("K1").estado["energizado"], "el relé entra"),
		A.cierto(debil.componente("Q1").estado["activa"] and not debil.componente("K1").estado["energizado"], "con 470 kΩ no satura y el relé no entra"),
	])


func test_transistor_con_el_ohmetro_son_dos_diodos() -> String:
	var sim := A.circuito("medir_transistor")
	var m := _multimetro()
	return A.primero([
		A.cerca(m.medir(sim, "diodo", "Q1.B", "Q1.E")["valor"], 0.7, 0.02, "B→E"),
		A.cerca(m.medir(sim, "diodo", "Q1.B", "Q1.C")["valor"], 0.7, 0.02, "B→C"),
		A.cierto(m.medir(sim, "diodo", "Q1.C", "Q1.E")["fuera_de_rango"], "C-E: OL"),
		A.cierto(m.medir(sim, "diodo", "Q1.E", "Q1.B")["fuera_de_rango"], "E→B: OL"),
	])


func test_mosfet_a_medias_se_quema() -> String:
	var pleno := _pulsado("mosfet_servicio")
	var q: SimMosfet = pleno.componente("Q1")
	var medias := A.circuito("mosfet_servicio")
	(medias.componente("FG") as SimFuenteDC).params["v_salida"] = 5.0
	medias.componente("S1").estado["presionado"] = true
	medias.avanzar_tiempo(0.5)
	var m := _multimetro()
	return A.primero([
		A.cierto(int(q.estado["nivel"]) == 2 and q.potencia(pleno.solucion) < 0.5, "con 12 V de puerta conduce pleno y apenas calienta"),
		A.cierto(m.medir(pleno, "vdc", "Q1.D", "Q1.S")["valor"] < 0.2, "D-S casi 0 V"),
		A.cierto(medias.componente("Q1").estado["quemado"] and medias.hubo_evento("mosfet_quemado", "Q1"), "con 5 V de puerta conduce a medias y se quema"),
		A.cerca(m.medir(A.circuito("medir_mosfet"), "diodo", "Q1.S", "Q1.D")["valor"], 0.5, 0.02, "diodo interno S→D"),
	])


func test_tiristor_se_enclava_y_se_apaga_al_cortar() -> String:
	var sim := _pulsado("tiristor_servicio")
	var disparado: bool = sim.componente("V1").estado["disparado"]
	sim.componente("S1").estado["presionado"] = false
	sim.avanzar_tiempo(0.3)
	var enclavado: bool = sim.componente("V1").estado["disparado"]
	sim.componente("S2").estado["presionado"] = true
	sim.avanzar_tiempo(0.3)
	var apagado: bool = not sim.componente("V1").estado["disparado"]
	sim.componente("S2").estado["presionado"] = false
	sim.avanzar_tiempo(0.3)
	var sigue_apagado: bool = not sim.componente("V1").estado["disparado"]
	return A.primero([
		A.cierto(disparado, "el impulso de puerta lo dispara"),
		A.cierto(enclavado, "sin puerta sigue conduciendo"),
		A.cierto(apagado and sigue_apagado, "S2 corta la corriente y queda apagado"),
	])


func test_triac_conduce_con_puerta_suficiente() -> String:
	var reposo := A.circuito("triac_servicio")
	reposo.avanzar_tiempo(0.3)
	var on := _pulsado("triac_servicio")
	var debil := A.circuito("triac_servicio")
	debil.componente("RG").params["ohm"] = 1000.0
	debil.componente("S1").estado["presionado"] = true
	debil.avanzar_tiempo(0.3)
	var m := _multimetro()
	return A.primero([
		A.cierto(m.medir(reposo, "vac", "RL.A", "RL.B")["valor"] < 2.0, "sin puerta, la carga sin tensión"),
		A.cerca(m.medir(on, "vac", "RL.A", "RL.B")["valor"], 229.0, 0.02, "con puerta, 230 V en la carga"),
		A.cierto(not debil.componente("V1").estado["conduce"], "con 1 kΩ de puerta, 4,7 mA no bastan"),
	])


func test_optoacoplador_pasa_la_senal_aislada() -> String:
	var reposo := A.circuito("optoacoplador_servicio")
	reposo.avanzar_tiempo(0.3)
	var activa := _pulsado("optoacoplador_servicio")
	var m := _multimetro()
	var mg := SimMegohmetro.new()
	mg.ruido = 0.0
	var aislamiento := mg.medir(A.circuito("medir_optoacoplador"), "OK1.1", "OK1.3", 500)
	var sin_r := A.circuito("optoacoplador_servicio")
	sin_r.componente("R1").params["ohm"] = 10.0
	sin_r.componente("S1").estado["presionado"] = true
	sin_r.avanzar_tiempo(0.3)
	return A.primero([
		A.cerca(m.medir(reposo, "vdc", "OK1.4", "OK1.3")["valor"], 5.0, 0.01, "inactiva: 5 V"),
		A.cerca(m.medir(activa, "vdc", "OK1.4", "OK1.3")["valor"], 0.2, 0.2, "activa: unos 0,2 V"),
		A.cierto(aislamiento["fuera_de_rango"], "entre los dos lados, más de 999 MΩ"),
		A.cierto(sin_r.componente("OK1").estado["quemado"], "sin resistencia, el LED se quema"),
	])


func test_regulador_regula_y_corta_por_temperatura() -> String:
	var bien := A.circuito("regulador_servicio")
	bien.avanzar_tiempo(30.0)
	var sin := A.circuito("regulador_servicio")
	sin.componente("U2").params["disipador"] = false
	sin.avanzar_tiempo(12.0)
	var corto := A.circuito("regulador_servicio")
	corto.componente("U2").estado["corto"] = true
	corto.avanzar_tiempo(1.0)
	var m := _multimetro()
	var u2: SimRegulador = bien.componente("U2")
	return A.primero([
		A.cerca(m.medir(bien, "vdc", "U2.OUT", "U2.GND")["valor"], 12.0, 0.01, "12 V con su disipador"),
		A.cerca(u2.potencia(), 6.0, 0.03, "disipa (24 − 12) × 0,5 = 6 W"),
		A.cierto(float(u2.estado["temperatura"]) < 80.0, "con disipador, unos 70 °C"),
		A.cierto(sin.componente("U2").estado["corte_termico"] and sin.hubo_evento("regulador_corte_termico", "U2"), "sin disipador corta por temperatura"),
		A.cerca(m.medir(corto, "vdc", "U2.OUT", "U2.GND")["valor"], 24.0, 0.01, "en corto, la salida recibe la entrada"),
	])


func test_operacional_compara_la_sonda_con_la_referencia() -> String:
	var m := _multimetro()
	var frio := A.circuito("operacional_servicio")
	frio.avanzar_tiempo(0.3)
	var caliente := A.circuito("operacional_servicio")
	caliente.componente("RT1").estado["temperatura_c"] = 70.0
	caliente.avanzar_tiempo(0.3)
	var abierta := A.circuito("operacional_servicio")
	abierta.componente("RT1").estado["temperatura_c"] = 70.0
	abierta.componente("RT1").estado["abierto"] = true
	abierta.avanzar_tiempo(0.3)
	return A.primero([
		A.cierto(m.medir(frio, "vdc", "U1.6", "U1.4")["valor"] < 0.5, "a 25 °C, sin alarma"),
		A.cierto(m.medir(caliente, "vdc", "U1.6", "U1.4")["valor"] > 9.0, "a 70 °C, alarma"),
		A.cierto((caliente.componente("LD1") as SimLed).encendido(caliente.solucion), "el LED de alarma se enciende"),
		A.cierto(m.medir(abierta, "vdc", "U1.6", "U1.4")["valor"] < 0.5, "con la sonda abierta no hay alarma"),
	])


func test_puertas_siguen_su_tabla_de_verdad() -> String:
	var tablas := {"and": [0, 0, 0, 1], "or": [0, 1, 1, 1], "nand": [1, 1, 1, 0], "nor": [1, 0, 0, 0], "xor": [0, 1, 1, 0]}
	var m := _multimetro()
	var fallos: Array[String] = []
	for tipo: String in tablas:
		var k := 0
		for ab in [[false, false], [true, false], [false, true], [true, true]]:
			var sim := A.circuito("puertas_servicio")
			sim.componente("U1").params["tipo"] = tipo
			sim.componente("S1").estado["presionado"] = ab[0]
			sim.componente("S2").estado["presionado"] = ab[1]
			sim.avanzar_tiempo(0.2)
			var y: int = 1 if m.medir(sim, "vdc", "U1.Y", "U1.GND")["valor"] > 3.0 else 0
			if y != tablas[tipo][k]:
				fallos.append("%s %s: %d" % [tipo, str(ab), y])
			k += 1
	var aire := A.circuito("puertas_servicio")
	aire.componente("R1").estado["cortada"] = true
	aire.componente("S2").estado["presionado"] = true
	aire.avanzar_tiempo(0.2)
	var media: float = m.medir(aire, "vdc", "U1.Y", "U1.GND")["valor"]
	return A.primero([
		A.cierto(fallos.is_empty(), "tablas de verdad: %s" % ", ".join(fallos)),
		A.cierto(int(aire.componente("U1").estado["salida"]) == -1 and media > 1.5 and media < 3.5, "entrada al aire: salida indefinida a media tensión (%s V)" % media),
	])
