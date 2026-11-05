extends RefCounted
## Motor: estrella y delta según la placa, sobrecargas, falta de fase y giro.

const A := preload("res://tests/ayuda_sim.gd")


func test_440d_en_delta_trabaja_a_corriente_nominal() -> String:
	var sim := A.banco_motor(A.PLACA_440D, "delta", 25.0, {"carga": 1.0})
	sim.avanzar_tiempo(60.0)
	var m: SimMotorTrifasico = sim.componente("M1")
	return A.primero([
		A.cerca(sim.solucion.entre("M1.U1", "M1.U2").modulo(), 440.0, 0.01, "tensión de devanado"),
		A.cerca(sim.componente("F2").corriente(sim.solucion, 0), 25.0, 0.15, "corriente de línea"),
		A.cerca(m.rpm(), 1760.0, 0.02, "velocidad"),
		A.cierto(not sim.componente("F2").estado["disparado"], "no debe disparar a plena carga"),
		A.cierto(m.sentido() == "horario", "L1-L2-L3 en U1-V1-W1 gira en sentido horario"),
	])


func test_254d_en_estrella_es_correcto_en_440v() -> String:
	var sim := A.banco_motor(A.PLACA_254D, "estrella", 25.0, {"carga": 1.0})
	sim.avanzar_tiempo(60.0)
	return A.primero([
		A.cerca(sim.solucion.entre("M1.U1", "M1.U2").modulo(), 254.0, 0.01, "tensión de devanado"),
		A.cerca(sim.componente("F2").corriente(sim.solucion, 0), 25.0, 0.15, "corriente de línea"),
		A.cierto(not sim.componente("F2").estado["disparado"], "no debe disparar"),
	])


func test_254d_en_delta_dispara_el_termico() -> String:
	var sim := A.banco_motor(A.PLACA_254D, "delta", 25.0)
	sim.avanzar_tiempo(1.0)
	var corriente: float = sim.componente("F2").corriente(sim.solucion, 0)
	var v := sim.solucion.entre("M1.U1", "M1.U2").modulo()
	sim.avanzar_tiempo(120.0)
	# La tensión se lee antes: al final el motor ya está quemado y hunde la red.
	return A.primero([
		A.cerca(v, 440.0, 0.03, "√3 veces la tensión de devanado"),
		A.cierto(corriente > 25.0 * 2.0, "la corriente debe ser muy superior a la nominal: %.1f A" % corriente),
		A.cierto(sim.hubo_evento("disparo_rele_termico", "F2"), "debe disparar el térmico"),
	])


func test_254d_en_delta_sin_proteccion_se_quema() -> String:
	var sim := A.banco_motor(A.PLACA_254D, "delta", 0.0)
	sim.avanzar_tiempo(300.0)
	return A.cierto(sim.componente("M1").quemado(), "sin protección el motor debe quemarse")


func test_440d_en_estrella_a_plena_carga_sobrecalienta() -> String:
	var sim := A.banco_motor(A.PLACA_440D, "estrella", 14.5, {"carga": 1.0})
	sim.avanzar_tiempo(20.0)
	var v := sim.solucion.entre("M1.U1", "M1.U2").modulo()
	var corriente: float = sim.componente("F2").corriente(sim.solucion, 0)
	sim.avanzar_tiempo(600.0)
	return A.primero([
		A.cerca(v, 254.0, 0.01, "tensión de devanado reducida"),
		A.cierto(corriente > 14.5 * 1.25, "debe superar la nominal en estrella: %.1f A" % corriente),
		A.cierto(sim.hubo_evento("disparo_rele_termico", "F2"), "debe disparar por sobrecarga"),
	])


func test_corriente_de_arranque_directo() -> String:
	var sim := A.banco_motor(A.PLACA_440D, "delta", 0.0)
	sim.paso()
	var corriente: float = sim.componente("F2").corriente(sim.solucion, 0)
	return A.cerca(corriente, 25.0 * 6.5, 0.15, "corriente con rotor parado")


func test_invertir_dos_fases_invierte_el_giro() -> String:
	var sim := A.banco_motor(A.PLACA_440D, "delta", 0.0)
	sim.desconectar("B.L1", "F2.1")
	sim.desconectar("B.L2", "F2.3")
	sim.conectar("B.L2", "F2.1")
	sim.conectar("B.L1", "F2.3")
	sim.avanzar_tiempo(10.0)
	var m: SimMotorTrifasico = sim.componente("M1")
	return A.primero([
		A.cierto(m.sentido() == "antihorario", "debe girar al revés: %s" % m.sentido()),
		A.cerca(absf(m.rpm()), 1760.0, 0.02, "velocidad"),
	])


func test_falta_de_fase_con_motor_parado_no_arranca() -> String:
	var sim := A.banco_motor(A.PLACA_440D, "estrella", 14.5, {"carga": 0.5})
	sim.desconectar("B.L3", "F2.5")
	sim.avanzar_tiempo(5.0)
	var corriente: float = sim.componente("F2").corriente(sim.solucion, 0)
	sim.avanzar_tiempo(60.0)
	return A.primero([
		A.cierto(absf(sim.componente("M1").rpm()) < 5.0, "no debe arrancar: %.0f rpm" % sim.componente("M1").rpm()),
		A.cierto(corriente > 14.5 * 2.0, "debe zumbar con corriente alta: %.1f A" % corriente),
		A.cierto(sim.hubo_evento("disparo_rele_termico", "F2"), "debe disparar"),
	])


func test_falta_de_fase_en_marcha_sube_la_corriente() -> String:
	var sim := A.banco_motor(A.PLACA_440D, "delta", 25.0, {"carga": 0.8})
	sim.avanzar_tiempo(20.0)
	var antes: float = sim.componente("F2").corriente(sim.solucion, 0)
	sim.desconectar("B.L3", "F2.5")
	sim.avanzar_tiempo(5.0)
	var despues: float = sim.componente("F2").corriente(sim.solucion, 0)
	return A.primero([
		A.cierto(despues > antes * 1.3, "la corriente debe subir: %.1f → %.1f A" % [antes, despues]),
		A.cierto(sim.componente("M1").rpm() > 500.0, "sigue girando con dos fases"),
	])


func test_devanado_invertido_desequilibra() -> String:
	var sim := A.banco_motor(A.PLACA_440D, "estrella", 0.0, {"carga": 0.2})
	sim.desconectar("M1.V2", "M1.W2")
	sim.desconectar("M1.U2", "M1.V2")
	sim.desconectar("F2.6", "M1.W1")
	sim.conectar("F2.6", "M1.W2")
	sim.conectar("M1.U2", "M1.V2")
	sim.conectar("M1.V2", "M1.W1")
	sim.avanzar_tiempo(10.0)
	var solo_bien := A.banco_motor(A.PLACA_440D, "estrella", 0.0, {"carga": 0.2})
	solo_bien.avanzar_tiempo(10.0)
	var ia: float = sim.componente("F2").corriente(sim.solucion, 0)
	var ic: float = sim.componente("F2").corriente(sim.solucion, 2)
	var normal: float = solo_bien.componente("F2").corriente(solo_bien.solucion, 0)
	return A.cierto(maxf(ia, ic) > normal * 1.5, "debe subir la corriente: %.1f frente a %.1f A" % [maxf(ia, ic), normal])


func test_rotor_bloqueado_dispara_en_segundos() -> String:
	var sim := A.banco_motor(A.PLACA_440D, "delta", 25.0, {"bloqueado": true})
	sim.avanzar_tiempo(15.0)
	return A.primero([
		A.cierto(sim.hubo_evento("disparo_rele_termico", "F2"), "debe disparar antes de 15 s"),
		A.cierto(not sim.componente("M1").quemado(), "el motor no debe alcanzar a quemarse"),
	])


func test_sobrecarga_dispara_y_carga_nominal_no() -> String:
	var sobrecarga := A.banco_motor(A.PLACA_440D, "delta", 25.0, {"carga": 1.6})
	sobrecarga.avanzar_tiempo(600.0)
	var nominal := A.banco_motor(A.PLACA_440D, "delta", 25.0, {"carga": 1.0})
	nominal.avanzar_tiempo(600.0)
	return A.primero([
		A.cierto(sobrecarga.hubo_evento("disparo_rele_termico", "F2"), "160 % de carga debe disparar"),
		A.cierto(not nominal.hubo_evento("disparo_rele_termico", "F2"), "100 % de carga no debe disparar"),
	])


func test_curva_termica_clase_10() -> String:
	var a_7 := _segundos_hasta_umbral(7.2)
	var a_105 := _segundos_hasta_umbral(1.05)
	return A.primero([
		A.cierto(a_7 > 4.0 and a_7 <= 10.0, "a 7,2 × Ir debe tardar entre 4 y 10 s: %.1f" % a_7),
		A.cierto(a_105 < 0.0, "a 1,05 × Ir no debe disparar"),
	])


func _segundos_hasta_umbral(veces: float) -> float:
	var memoria := 0.0
	var t := 0.0
	while t < 7200.0:
		memoria = SimTermico.actualizar(memoria, veces, 1.0, 0.05)
		t += 0.05
		if memoria >= SimTermico.UMBRAL:
			return t
	return -1.0


func test_motor_quemado_sigue_dañado_hasta_cambiarlo() -> String:
	var sim := A.banco_motor(A.PLACA_440D, "delta", 0.0)
	var m: SimMotorTrifasico = sim.componente("M1")
	m.estado["quemado"] = true
	sim.avanzar_tiempo(5.0)
	var quieto: bool = absf(m.rpm()) < 5.0 and m.quemado()
	m.reemplazar()
	sim.avanzar_tiempo(10.0)
	return A.primero([
		A.cierto(quieto, "quemado no debe girar"),
		A.cierto(m.rpm() > 1700.0, "el repuesto debe funcionar: %.0f rpm" % m.rpm()),
	])
