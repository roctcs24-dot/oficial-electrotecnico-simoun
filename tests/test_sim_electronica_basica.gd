extends RefCounted
## Componentes de la electrónica I: resistencia con su potencia, potenciómetro, termistores NTC y
## PTC, varistor, condensador con el capacímetro, Zener, LED y el puente con su prueba de diodos.

const A := preload("res://tests/ayuda_sim.gd")


func _multimetro() -> SimMultimetro:
	var m := SimMultimetro.new()
	m.ruido = 0.0
	return m


func _fuente(v := 24.0) -> SimFuenteDC:
	return SimFuenteDC.new("F", {"entrada": "ninguna", "v_salida": v})


func test_resistencia_se_quema_por_exceso_de_potencia() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(_fuente())
	sim.agregar(SimResistencia.new("R1", {"ohm": 100.0, "w": 0.25}))
	sim.conectar("F.+", "R1.A")
	sim.conectar("R1.B", "F.-")
	# La potencia antes del primer paso: en él ya se corta.
	var potencia := (sim.componente("R1") as SimResistencia).potencia(sim.resolver_completa())
	sim.avanzar_tiempo(1.0)
	var holgada := SimSimulacion.new()
	holgada.agregar(_fuente())
	holgada.agregar(SimResistencia.new("R1", {"ohm": 4700.0, "w": 0.25}))
	holgada.conectar("F.+", "R1.A")
	holgada.conectar("R1.B", "F.-")
	holgada.avanzar_tiempo(10.0)
	return A.primero([
		A.cerca(potencia, 5.76, 0.01, "24 V en 100 Ω: 5,76 W"),
		A.cierto(sim.componente("R1").estado["cortada"] and sim.hubo_evento("resistencia_quemada", "R1"), "con 23 veces su potencia debe cortarse"),
		A.cierto(not holgada.componente("R1").estado["cortada"], "4,7 kΩ a 24 V disipan 0,12 W: aguanta"),
	])


func test_resistencia_sin_potencia_nominal_aguanta_todo() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(_fuente())
	sim.agregar(SimResistencia.new("R1", {"ohm": 1.0}))
	sim.conectar("F.+", "R1.A")
	sim.conectar("R1.B", "F.-")
	sim.avanzar_tiempo(1.0)
	return A.cierto(not sim.componente("R1").estado["cortada"], "las prácticas de la ley de Ohm no queman resistencias")


func test_potenciometro_divide_la_tension() -> String:
	var sim := A.circuito("potenciometro_servicio")
	var m := _multimetro()
	var lecturas: Array[float] = []
	for p in [0.0, 0.25, 1.0]:
		sim.componente("P1").estado["posicion"] = p
		sim.avanzar_tiempo(0.2)
		lecturas.append(m.medir(sim, "vdc", "P1.2", "P1.1")["valor"])
	var suelto := A.circuito("medir_potenciometro")
	suelto.componente("P1").estado["posicion"] = 0.3
	var r12: float = m.medir(suelto, "ohm", "P1.1", "P1.2")["valor"]
	var r23: float = m.medir(suelto, "ohm", "P1.2", "P1.3")["valor"]
	return A.primero([
		A.cierto(absf(lecturas[0]) < 0.01, "al mínimo, 0 V: %s" % lecturas[0]),
		A.cerca(lecturas[1], 2.5, 0.01, "un cuarto de giro"),
		A.cerca(lecturas[2], 10.0, 0.01, "al máximo, la referencia"),
		A.cerca(r12 + r23, 10000.0, 0.001, "1-2 más 2-3 es la pista entera"),
		A.cerca(r12, 3000.0, 0.001, "al 30 %, 3 kΩ entre 1 y 2"),
	])


func test_ntc_sigue_su_curva_beta() -> String:
	var ntc := SimTermistor.new("RT", {"tipo": "ntc", "r25": 10000.0, "beta": 3950.0})
	return A.primero([
		A.cerca(ntc.ohmios_a(25.0), 10000.0, 0.001, "10 kΩ a 25 °C"),
		A.cerca(ntc.ohmios_a(0.0), 33620.0, 0.01, "unos 33,6 kΩ a 0 °C"),
		A.cerca(ntc.ohmios_a(100.0), 697.0, 0.02, "unos 700 Ω a 100 °C"),
		A.cierto(ntc.ohmios_a(60.0) < ntc.ohmios_a(59.0), "baja al calentarse"),
	])


## Límites de DIN 44081 para cada sonda PTC: ≤ 250 Ω hasta TNF − 20, ≤ 550 Ω a TNF − 5,
## ≥ 1330 Ω a TNF + 5 y ≥ 4000 Ω a TNF + 15.
func test_ptc_cumple_los_limites_de_din_44081() -> String:
	var ptc := SimTermistor.new("RT", {"tipo": "ptc", "tnf": 130.0, "sensores": 1})
	var tres := SimTermistor.new("RT3", {"tipo": "ptc", "tnf": 130.0, "sensores": 3})
	return A.primero([
		A.cierto(ptc.ohmios_a(110.0) <= 250.0 and ptc.ohmios_a(-20.0) <= 250.0, "en frío, 250 Ω o menos"),
		A.cierto(ptc.ohmios_a(125.0) <= 550.0, "a TNF − 5: %d Ω" % roundi(ptc.ohmios_a(125.0))),
		A.cierto(ptc.ohmios_a(135.0) >= 1330.0, "a TNF + 5: %d Ω" % roundi(ptc.ohmios_a(135.0))),
		A.cierto(ptc.ohmios_a(145.0) >= 4000.0, "a TNF + 15: %d Ω" % roundi(ptc.ohmios_a(145.0))),
		A.cierto(tres.ohmios_a(25.0) > 60.0 and tres.ohmios_a(25.0) < 750.0, "las tres en frío, entre 60 y 750 Ω"),
		A.cierto(tres.ohmios_a(135.0) > 3600.0 and tres.ohmios_a(125.0) < 3600.0, "el relé dispara pasada la TNF y no antes"),
	])


func test_varistor_en_corto_funde_su_fusible() -> String:
	var sano := A.circuito("varistor_servicio")
	sano.avanzar_tiempo(0.5)
	var corto := A.circuito("varistor_servicio")
	corto.componente("RV1").estado["corto"] = true
	corto.avanzar_tiempo(0.5)
	var m := _multimetro()
	return A.primero([
		A.cerca(m.medir(sano, "vdc", "U1.+", "U1.-")["valor"], 24.0, 0.01, "con el varistor sano, la fuente da 24 V"),
		A.cierto(corto.componente("F1").estado["fundido"], "en corto, F1 se funde"),
		A.cierto(absf(m.medir(corto, "vdc", "U1.+", "U1.-")["valor"]) < 0.01, "y la fuente se queda sin entrada"),
	])


func test_condensador_reactancia_y_capacimetro() -> String:
	var c := SimCondensadorElectrico.new("C1", {"uf": 20.0})
	var sim := A.circuito("medir_condensador")
	var m := _multimetro()
	var sano: Dictionary = m.medir(sim, "capacidad", "C1.+", "C1.-")
	sim.componente("C1").estado["perdida"] = 0.25
	var seco: float = m.medir(sim, "capacidad", "C1.+", "C1.-")["valor"]
	sim.componente("C1").estado["perdida"] = 0.0
	var ohm: Dictionary = m.medir(sim, "ohm", "C1.+", "C1.-")
	var banco := A.circuito("condensador_servicio")
	banco.avanzar_tiempo(0.3)
	var corriente := (banco.componente("C1") as SimCondensadorElectrico).corriente(banco.solucion)
	return A.primero([
		A.cerca(c.reactancia(), 159.15, 0.001, "Xc de 20 µF a 50 Hz"),
		A.cerca(sano["valor"], 20.0, 0.001, "el capacímetro lee 20 µF"),
		A.cerca(seco, 15.0, 0.001, "con un 25 % perdido, 15 µF"),
		A.cierto(ohm["fuera_de_rango"], "en continua, cargado, no conduce: OL"),
		A.cerca(corriente, 230.0 / 159.15, 0.02, "a 230 V pasan 1,45 A"),
	])


func test_capacimetro_con_tension_se_protege() -> String:
	var sim := A.circuito("condensador_servicio")
	sim.avanzar_tiempo(0.2)
	var m := _multimetro()
	var r := m.medir(sim, "capacidad", "C1.+", "C1.-")
	return A.cierto(r["averia"] == "fusible_multimetro" or r["averia"] == "multimetro_destruido", "medir capacidad con 230 V debe dañar el multímetro: %s" % r["averia"])


func test_electrolitico_al_reves_queda_en_corto() -> String:
	var bien := A.circuito("condensador_filtro")
	bien.avanzar_tiempo(0.5)
	var reves := A.circuito("condensador_filtro_reves")
	reves.avanzar_tiempo(0.5)
	return A.primero([
		A.cierto(not bien.componente("C2").estado["corto"], "bien polarizado aguanta"),
		A.cierto(reves.componente("C2").estado["corto"] and reves.hubo_evento("condensador_quemado", "C2"), "al revés se quema en corto"),
		A.cierto(reves.componente("F").estado["protegida"] or reves.hubo_evento("fuente_sobrecarga", "F"), "y la fuente corta por sobrecarga"),
	])


func test_zener_regula_y_tiene_tres_tramos() -> String:
	var sim := A.circuito("zener_servicio")
	sim.avanzar_tiempo(0.3)
	var z: SimZener = sim.componente("DZ1")
	var m := _multimetro()
	var salida: float = m.medir(sim, "vdc", "RL.A", "RL.B")["valor"]
	var en_ruptura: bool = z.estado["ruptura"] and not z.estado["conduce"]
	var iz := -z.corriente(sim.solucion)
	var baja := A.circuito("zener_servicio")
	(baja.componente("F") as SimFuenteDC).params["v_salida"] = 15.0
	baja.avanzar_tiempo(0.3)
	var sin_ruptura: float = m.medir(baja, "vdc", "RL.A", "RL.B")["valor"]
	var reves := A.circuito("zener_reves")
	reves.avanzar_tiempo(0.3)
	return A.primero([
		A.cerca(salida, 12.07, 0.01, "con 24 V regula a 12 V"),
		A.cierto(en_ruptura, "en servicio, el Zener está en ruptura"),
		A.cerca(iz, 0.0135, 0.05, "le sobran unos 13,5 mA"),
		A.cerca(sin_ruptura, 15.0 * 1000.0 / 1470.0, 0.01, "con 15 V la carga no llega a 12 V y no conduce"),
		A.cierto(reves.componente("DZ1").estado["conduce"], "al revés conduce en directa"),
		A.cierto(not sim.componente("DZ1").estado["quemado"], "0,16 W no lo queman"),
	])


func test_led_con_su_resistencia_y_sin_ella() -> String:
	var bien := A.circuito("led_servicio")
	bien.avanzar_tiempo(0.3)
	var led: SimLed = bien.componente("LD1")
	var sin_r := A.circuito("led_sin_resistencia")
	sin_r.avanzar_tiempo(0.3)
	return A.primero([
		A.cierto(led.encendido(bien.solucion), "con 1,1 kΩ se enciende"),
		A.cerca(led.corriente(bien.solucion), 0.0197, 0.01, "unos 20 mA"),
		A.cierto(not bien.componente("R1").estado["cortada"], "R1 de 0,5 W aguanta sus 0,43 W"),
		A.cierto(sin_r.componente("LD1").estado["quemado"] and sin_r.hubo_evento("led_quemado", "LD1"), "sin resistencia se funde"),
	])


func test_puente_ve_sus_cuatro_diodos_con_el_ohmetro() -> String:
	var sim := A.circuito("medir_puente")
	var m := _multimetro()
	var directa: Array[float] = []
	for par in [["~1", "+"], ["~2", "+"], ["-", "~1"], ["-", "~2"]]:
		directa.append(m.medir(sim, "diodo", "P1." + par[0], "P1." + par[1])["valor"])
	var inversa: Dictionary = m.medir(sim, "diodo", "P1.+", "P1.~2")
	var serie: float = m.medir(sim, "diodo", "P1.-", "P1.+")["valor"]
	sim.componente("P1").estado["diodo_corto"] = true
	var corto: float = m.medir(sim, "diodo", "P1.+", "P1.~1")["valor"]
	var otro: float = m.medir(sim, "diodo", "P1.~2", "P1.+")["valor"]
	var fallos: Array[String] = []
	for v in directa:
		if absf(v - 0.7) > 0.01:
			fallos.append(str(v))
	return A.primero([
		A.cierto(fallos.is_empty(), "los cuatro diodos en directa dan 0,7 V: %s" % str(directa)),
		A.cierto(inversa["fuera_de_rango"], "al revés, OL"),
		A.cerca(serie, 1.4, 0.01, "de − a +, dos diodos en serie"),
		A.cierto(absf(corto) < 0.01, "D1 en corto marca 0 V también al revés"),
		A.cerca(otro, 0.7, 0.01, "los demás diodos siguen sanos"),
	])


func test_puente_con_un_diodo_abierto_da_media_onda() -> String:
	var m := _multimetro()
	var lecturas := {}
	for caso: Array in [["filtro", {}, {}], ["sin_filtro", {"filtro": false}, {}], ["media_onda", {"filtro": false}, {"diodo_abierto": true}]]:
		var sim := A.circuito("puente_servicio")
		sim.componente("P1").params.merge(caso[1], true)
		sim.componente("P1").estado.merge(caso[2], true)
		sim.avanzar_tiempo(0.5)
		lecturas[caso[0]] = m.medir(sim, "vdc", "P1.+", "P1.-")["valor"]
	var corto := A.circuito("puente_servicio")
	corto.componente("P1").estado["diodo_corto"] = true
	corto.avanzar_tiempo(0.5)
	return A.primero([
		A.cerca(lecturas["filtro"], 24.0 * 1.414 - 1.4, 0.02, "con filtro, cerca del pico"),
		A.cerca(lecturas["sin_filtro"], 24.0 * 0.9 - 1.4, 0.02, "sin filtro, 0,9 × V~ menos dos caídas"),
		A.cerca(lecturas["media_onda"], 24.0 * 0.45 - 0.7, 0.03, "media onda: la mitad"),
		A.cierto(corto.componente("F1").estado["fundido"], "un diodo en corto funde el fusible de entrada"),
	])
