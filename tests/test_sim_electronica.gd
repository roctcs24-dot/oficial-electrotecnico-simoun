extends RefCounted
## Electrónica en continua: fuente de 24 V, diodos, LED, puente, relés, sensores NPN y PNP,
## lazo de 4–20 mA, PT100, termocupla y el multímetro en continua.

const A := preload("res://tests/ayuda_sim.gd")


## Fuente de 24 V sin entrada de alterna, como una batería, y una resistencia de carga.
func _con_fuente(r_ohm := 240.0) -> SimSimulacion:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteDC.new("F", {"entrada": "ninguna"}))
	sim.agregar(SimResistencia.new("R", {"ohm": r_ohm}))
	sim.conectar("F.+", "R.A")
	sim.conectar("R.B", "F.-")
	return sim


func _multimetro() -> SimMultimetro:
	var m := SimMultimetro.new()
	m.ruido = 0.0
	return m


func _cero(valor: float, tolerancia: float, etiqueta: String) -> String:
	return A.cierto(absf(valor) <= tolerancia, "%s: %.4f, se esperaba 0" % [etiqueta, valor])


# --- Fuente y multímetro ---

func test_fuente_y_ley_de_ohm_en_continua() -> String:
	var sim := _con_fuente()
	sim.paso()
	var m := _multimetro()
	var v := m.medir(sim, "vdc", "R.A", "R.B")
	var invertida := m.medir(sim, "vdc", "R.B", "R.A")
	var alterna := m.medir(sim, "vac", "R.A", "R.B")
	var f: SimFuenteDC = sim.componente("F")
	return A.primero([
		A.cerca(v["valor"], 24.0, 0.01, "24 V en la carga"),
		A.cerca(invertida["valor"], -24.0, 0.01, "con las puntas al revés, la lectura es negativa"),
		_cero(alterna["valor"], 0.01, "en V~ una continua pura no marca"),
		A.cerca(f.estado["i_salida"], 0.1, 0.01, "I = 24 V / 240 Ω"),
	])


func test_un_circuito_de_alterna_no_calcula_continua() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteTrifasica.new("B"))
	sim.paso()
	return A.primero([
		A.cierto(not sim.con_continua() and sim.solucion.dc == null, "sin electrónica no debe resolver la continua"),
		_cero(_multimetro().medir(sim, "vdc", "B.L1", "B.N")["valor"], 0.001, "en V= la alterna no marca"),
	])


func test_fuente_necesita_su_alimentacion_de_alterna() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteTrifasica.new("B"))
	sim.agregar(SimFuenteDC.new("F"))
	sim.agregar(SimResistencia.new("R", {"ohm": 48.0}))
	sim.conectar("F.+", "R.A")
	sim.conectar("R.B", "F.-")
	sim.paso()
	var sin_entrada := sim.solucion.entre_dc("R.A", "R.B")
	sim.conectar("B.L1", "F.L")
	sim.conectar("B.N", "F.N")
	sim.avanzar_tiempo(0.5)
	var con_entrada := sim.solucion.entre_dc("R.A", "R.B")
	var f: SimFuenteDC = sim.componente("F")
	return A.primero([
		_cero(sin_entrada, 0.01, "sin alterna en L-N no hay salida"),
		A.cerca(con_entrada, 24.0, 0.01, "alimentada, da 24 V"),
		A.cerca(f.estado["p_salida_w"], 12.0, 0.02, "entrega 12 W a 48 Ω"),
		A.cerca(f._r_entrada(), 230.0 * 230.0 / (12.0 / 0.88 + 3.0), 0.02, "y la entrada los consume de la alterna, con sus pérdidas"),
	])


func test_cortocircuito_corta_la_fuente_y_rearma() -> String:
	var sim := _con_fuente(0.001)
	sim.avanzar_tiempo(0.5)
	var f: SimFuenteDC = sim.componente("F")
	var protegida: bool = f.estado["protegida"]
	var evento := sim.hubo_evento("fuente_sobrecarga", "F")
	(sim.componente("R") as SimResistencia).params["ohm"] = 240.0
	sim.avanzar_tiempo(2.5)
	return A.primero([
		A.cierto(protegida and evento, "un corto debe cortar la salida"),
		A.cierto(not f.estado["protegida"], "quitado el corto, vuelve a dar tensión"),
		A.cerca(sim.solucion.entre_dc("R.A", "R.B"), 24.0, 0.01, "de nuevo 24 V"),
	])


func test_fuente_degradada_da_menos_tension() -> String:
	var sim := _con_fuente()
	(sim.componente("F") as SimFuenteDC).params["tension_pu"] = 0.75
	sim.paso()
	return A.cerca(sim.solucion.entre_dc("R.A", "R.B"), 18.0, 0.01, "una fuente degradada da 18 V")


# --- Diodos y LED ---

func _con_diodo(clase: GDScript, directo: bool, r_ohm: float) -> SimSimulacion:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteDC.new("F", {"entrada": "ninguna"}))
	sim.agregar(clase.new("D"))
	sim.agregar(SimResistencia.new("R", {"ohm": r_ohm}))
	sim.conectar("F.+", "D.A" if directo else "D.K")
	sim.conectar("D.K" if directo else "D.A", "R.A")
	sim.conectar("R.B", "F.-")
	return sim


func test_diodo_conduce_en_directa_y_bloquea_en_inversa() -> String:
	var directa := _con_diodo(SimDiodo, true, 1000.0)
	directa.paso()
	var inversa := _con_diodo(SimDiodo, false, 1000.0)
	inversa.paso()
	var d: SimDiodo = directa.componente("D")
	return A.primero([
		A.cerca(d.corriente(directa.solucion), 0.0233, 0.01, "en directa: (24 − 0,7) / 1000"),
		A.cerca(directa.solucion.entre_dc("D.A", "D.K"), 0.7, 0.05, "caída de unos 0,7 V"),
		_cero(inversa.solucion.entre_dc("R.A", "R.B"), 0.01, "en inversa no pasa corriente"),
		A.cerca(inversa.solucion.entre_dc("D.K", "D.A"), 24.0, 0.01, "en inversa el diodo soporta toda la tensión"),
	])


func test_led_con_resistencia_enciende_y_sin_ella_se_quema() -> String:
	var bien := _con_diodo(SimLed, true, 1200.0)
	bien.paso()
	var sin_r := _con_diodo(SimLed, true, 0.001)
	sin_r.avanzar_tiempo(0.2)
	var led: SimLed = bien.componente("D")
	var quemado: SimLed = sin_r.componente("D")
	return A.primero([
		A.cierto(led.encendido(bien.solucion), "con 1,2 kΩ debe encender"),
		A.cerca(led.corriente(bien.solucion), 0.0183, 0.02, "unos 18 mA"),
		A.cierto(quemado.estado["quemado"] and sin_r.hubo_evento("led_quemado"), "sin resistencia debe quemarse"),
		_cero(quemado.corriente(sin_r.solucion), 1e-6, "quemado queda abierto"),
	])


func test_multimetro_prueba_diodos() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimDiodo.new("D"))
	sim.agregar(SimLed.new("L"))
	var m := _multimetro()
	var directa := m.medir(sim, "diodo", "D.A", "D.K")
	var inversa := m.medir(sim, "diodo", "D.K", "D.A")
	var led := m.medir(sim, "diodo", "L.A", "L.K")
	var ohm := m.medir(sim, "ohm", "D.K", "D.A")
	var d: SimDiodo = sim.componente("D")
	return A.primero([
		A.cerca(directa["valor"], 0.7, 0.05, "en directa marca la caída"),
		A.cierto(inversa["fuera_de_rango"], "en inversa marca fuera de rango"),
		A.cerca(led["valor"], 2.0, 0.05, "un LED cae unos 2 V"),
		A.cierto(ohm["fuera_de_rango"], "en Ω, el diodo en inversa no conduce"),
		A.cierto(not d.estado["conduce_prueba"], "la medida no debe dejar cambiado el diodo"),
	])


func test_diodo_quemado_en_corto_marca_cero_en_las_dos_direcciones() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimDiodo.new("D", {}, {"quemado": true}))
	var m := _multimetro()
	var ida := m.medir(sim, "diodo", "D.A", "D.K")
	var vuelta := m.medir(sim, "diodo", "D.K", "D.A")
	return A.primero([
		_cero(ida["valor"], 0.01, "en corto, directa"),
		_cero(vuelta["valor"], 0.01, "en corto, inversa"),
	])


func test_puente_rectificador_con_y_sin_filtro() -> String:
	var lecturas := []
	for filtro in [false, true]:
		var sim := SimSimulacion.new()
		sim.agregar(SimFuenteTrifasica.new("B"))
		sim.agregar(SimTransformadorMando.new("T"))
		sim.agregar(SimPuenteRectificador.new("P", {"filtro": filtro}))
		sim.agregar(SimResistencia.new("R", {"ohm": 1000.0}))
		sim.conectar("B.L1", "T.H1")
		sim.conectar("B.L2", "T.H2")
		sim.conectar("T.X1", "P.~1")
		sim.conectar("T.X2", "P.~2")
		sim.conectar("P.+", "R.A")
		sim.conectar("R.B", "P.-")
		sim.avanzar_tiempo(0.3)
		lecturas.append(sim.solucion.entre_dc("R.A", "R.B"))
	return A.primero([
		A.cerca(lecturas[0], 0.9 * 110.0 - 1.4, 0.03, "sin filtro, la media rectificada"),
		A.cerca(lecturas[1], 1.414 * 110.0 - 1.4, 0.03, "con filtro, la de pico"),
	])


# --- Relés ---

func test_rele_dc_cierra_con_su_tension() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteDC.new("F", {"entrada": "ninguna"}))
	sim.agregar(SimReleDC.new("K"))
	sim.conectar("F.+", "K.A1")
	sim.conectar("K.A2", "F.-")
	sim.paso()
	var k: SimReleDC = sim.componente("K")
	var cierra: bool = k.estado["energizado"]
	var na := _multimetro().medir(sim, "continuidad", "K.11", "K.14")
	(sim.componente("F") as SimFuenteDC).params["tension_pu"] = 0.5
	sim.paso()
	var con_12v: bool = k.estado["energizado"]
	(sim.componente("F") as SimFuenteDC).params["tension_pu"] = 0.2
	sim.paso()
	return A.primero([
		A.cierto(cierra, "con 24 V debe cerrar"),
		A.cierto(na.get("pita", false), "cerrado, 11-14 tiene continuidad"),
		A.cierto(con_12v, "una vez cerrado, con 12 V se mantiene"),
		A.cierto(not k.estado["energizado"], "con 4,8 V suelta"),
	])


func test_rele_estado_solido_maneja_alterna_desde_continua() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteTrifasica.new("B"))
	sim.agregar(SimTransformadorMando.new("T"))
	sim.agregar(SimFuenteDC.new("F", {"entrada": "ninguna"}))
	sim.agregar(SimReleEstadoSolido.new("SSR"))
	sim.agregar(SimLampara.new("H"))
	sim.agregar(SimPulsador.new("S", {"contacto": "NA"}))
	sim.conectar("B.L1", "T.H1")
	sim.conectar("B.L2", "T.H2")
	sim.conectar("T.X1", "SSR.1")
	sim.conectar("SSR.2", "H.X1")
	sim.conectar("H.X2", "T.X2")
	sim.conectar("F.+", "S.13")
	sim.conectar("S.14", "SSR.3")
	sim.conectar("SSR.4", "F.-")
	sim.avanzar_tiempo(0.2)
	var h: SimLampara = sim.componente("H")
	var apagada: bool = not h.estado["encendida"]
	var fuga := _multimetro().medir(sim, "vac", "H.X1", "H.X2")
	sim.componente("S").estado["presionado"] = true
	sim.avanzar_tiempo(0.2)
	return A.primero([
		A.cierto(apagada, "sin control la luz está apagada"),
		A.cierto(fuga["valor"] > 5.0, "con el SSR abierto se mide tensión de fuga en la carga: %.1f V" % fuga["valor"]),
		A.cierto(h.estado["encendida"], "con 24 V de control conduce"),
	])


func test_rele_estado_solido_con_polaridad_invertida_no_conduce() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteDC.new("F", {"entrada": "ninguna"}))
	sim.agregar(SimReleEstadoSolido.new("SSR"))
	sim.conectar("F.+", "SSR.4")
	sim.conectar("SSR.3", "F.-")
	sim.paso()
	return A.cierto(not sim.componente("SSR").estado["conduce"], "con el control al revés no conduce")


# --- Sensores de proximidad ---

## Fuente, sensor de tres hilos y una carga de 3 kΩ como una entrada de PLC: en un PNP, entre
## la salida y el −; en un NPN, entre el + y la salida.
func _con_sensor(salida: String, contacto := "NA", tension_pu := 1.0) -> SimSimulacion:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteDC.new("F", {"entrada": "ninguna", "tension_pu": tension_pu}))
	sim.agregar(SimSensorProximidad.new("S", {"salida": salida, "contacto": contacto}))
	sim.agregar(SimResistencia.new("E", {"ohm": 3000.0}))
	sim.conectar("F.+", "S.BN")
	sim.conectar("S.BU", "F.-")
	if salida == "pnp":
		sim.conectar("S.BK", "E.A")
		sim.conectar("E.B", "F.-")
	else:
		sim.conectar("F.+", "E.A")
		sim.conectar("E.B", "S.BK")
	return sim


func _en_la_entrada(sim: SimSimulacion) -> float:
	return sim.solucion.entre_dc("E.A", "E.B")


func test_sensor_pnp_da_24_v_a_la_entrada() -> String:
	var sim := _con_sensor("pnp")
	sim.paso()
	var sin_objeto := _en_la_entrada(sim)
	sim.componente("S").estado["objeto"] = true
	sim.paso()
	return A.primero([
		_cero(sin_objeto, 0.1, "sin objeto la entrada no recibe tensión"),
		A.cerca(_en_la_entrada(sim), 24.0, 0.02, "con objeto, la salida PNP da el + a la entrada"),
		A.cierto(sim.componente("S").estado["activa"], "debe encenderse su LED de salida"),
	])


func test_sensor_npn_cierra_al_negativo() -> String:
	var sim := _con_sensor("npn")
	sim.componente("S").estado["objeto"] = true
	sim.paso()
	return A.primero([
		A.cerca(_en_la_entrada(sim), 24.0, 0.02, "la carga queda entre el + y la salida NPN, que va al −"),
		A.cierto(sim.solucion.entre_dc("S.BK", "S.BU") < 1.0, "la salida NPN está casi a 0 V"),
	])


func test_sensor_normalmente_cerrado_invierte() -> String:
	var sim := _con_sensor("pnp", "NC")
	sim.paso()
	return A.cerca(_en_la_entrada(sim), 24.0, 0.02, "un NC está activo sin objeto")


func test_sensor_sin_tension_suficiente_no_funciona() -> String:
	var sim := _con_sensor("pnp", "NA", 0.3)
	sim.componente("S").estado["objeto"] = true
	sim.paso()
	return A.primero([
		A.cierto(not sim.componente("S").estado["alimentado"], "con 7,2 V no se alimenta"),
		_cero(_en_la_entrada(sim), 0.1, "y no da salida"),
	])


func test_sensor_pnp_cableado_a_una_entrada_npn_no_activa() -> String:
	# Entrada para NPN (la carga va al +) con un sensor PNP: la salida da +24 V a un borne que
	# ya está a +24 V, y por la carga no pasa corriente.
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteDC.new("F", {"entrada": "ninguna"}))
	sim.agregar(SimSensorProximidad.new("S", {"salida": "pnp"}, {"objeto": true}))
	sim.agregar(SimResistencia.new("E", {"ohm": 3000.0}))
	sim.conectar("F.+", "S.BN")
	sim.conectar("S.BU", "F.-")
	sim.conectar("F.+", "E.A")
	sim.conectar("E.B", "S.BK")
	sim.paso()
	return A.cierto(absf(sim.solucion.entre_dc("E.A", "E.B")) < 0.5, "la entrada no ve la señal: %.2f V" % sim.solucion.entre_dc("E.A", "E.B"))


func test_salida_del_sensor_en_corto_se_protege() -> String:
	var sim := _con_sensor("pnp")
	(sim.componente("E") as SimResistencia).params["ohm"] = 0.01
	sim.componente("S").estado["objeto"] = true
	sim.avanzar_tiempo(0.2)
	var s: SimSensorProximidad = sim.componente("S")
	return A.cierto(s.estado["protegido"] and sim.hubo_evento("sensor_cortocircuito") and not s.estado["averiado"], "debe protegerse sin averiarse")


func test_sensor_de_dos_hilos_en_serie_con_la_carga() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteDC.new("F", {"entrada": "ninguna"}))
	sim.agregar(SimSensorProximidad.new("S", {"salida": "dos_hilos"}))
	sim.agregar(SimResistencia.new("E", {"ohm": 2400.0}))
	sim.conectar("F.+", "S.BN")
	sim.conectar("S.BU", "E.A")
	sim.conectar("E.B", "F.-")
	sim.paso()
	var fuga := sim.solucion.entre_dc("E.A", "E.B") / 2400.0
	sim.componente("S").estado["objeto"] = true
	sim.paso()
	var activa := sim.solucion.entre_dc("E.A", "E.B") / 2400.0
	return A.primero([
		A.cerca(fuga, 0.0009, 0.05, "inactivo deja pasar una fuga de casi 1 mA"),
		A.cerca(activa, (24.0 - 5.0) / 2410.0, 0.03, "activo cae unos 5 V"),
	])


# --- Lazo de 4–20 mA, PT100 y termocupla ---

## Lazo: + de la fuente al + del transmisor, su − a la resistencia de entrada y de ahí al −.
## Sin cable entre T.- y R.A, para medir la corriente en serie con el multímetro.
func _con_lazo(r_ohm: float, valor: float, unido := true) -> SimSimulacion:
	var sim := SimSimulacion.new()
	sim.agregar(SimFuenteDC.new("F", {"entrada": "ninguna"}))
	sim.agregar(SimTransmisor420.new("T", {"min": 0.0, "max": 10.0, "valor": valor}))
	sim.agregar(SimResistencia.new("R", {"ohm": r_ohm}))
	sim.conectar("F.+", "T.+")
	if unido:
		sim.conectar("T.-", "R.A")
	sim.conectar("R.B", "F.-")
	return sim


func test_lazo_4_20_ma_sigue_al_valor() -> String:
	var lecturas := []
	for valor in [0.0, 5.0, 10.0]:
		var sim := _con_lazo(250.0, valor)
		sim.paso()
		lecturas.append(sim.solucion.entre_dc("R.A", "R.B") / 250.0)
	var serie := _con_lazo(250.0, 5.0, false)
	serie.paso()
	var m := _multimetro().medir(serie, "ma", "T.-", "R.A")
	return A.primero([
		A.cerca(lecturas[0], 0.004, 0.01, "inicio de escala, 4 mA"),
		A.cerca(lecturas[1], 0.012, 0.01, "mitad de escala, 12 mA"),
		A.cerca(lecturas[2], 0.020, 0.01, "final de escala, 20 mA"),
		A.cerca(m["valor"], 12.0, 0.02, "el multímetro en serie marca 12 mA"),
	])


func test_lazo_sin_tension_suficiente_queda_corto() -> String:
	var sim := _con_lazo(1000.0, 10.0)
	sim.paso()
	var i := sim.solucion.entre_dc("R.A", "R.B") / 1000.0
	return A.primero([
		A.cierto(sim.componente("T").estado["modo"] == "falta_tension", "con 1 kΩ y 20 mA no le llega tensión"),
		A.cierto(i < 0.0195, "la corriente se queda por debajo de 20 mA: %.4f" % i),
	])


func test_lazo_abierto_o_invertido_da_cero() -> String:
	var abierto := _con_lazo(250.0, 5.0)
	abierto.componente("T").params["averia"] = "abierto"
	abierto.paso()
	var invertido := SimSimulacion.new()
	invertido.agregar(SimFuenteDC.new("F", {"entrada": "ninguna"}))
	invertido.agregar(SimTransmisor420.new("T", {"valor": 5.0}))
	invertido.agregar(SimResistencia.new("R", {"ohm": 250.0}))
	invertido.conectar("F.+", "T.-")
	invertido.conectar("T.+", "R.A")
	invertido.conectar("R.B", "F.-")
	invertido.avanzar_tiempo(0.1)
	return A.primero([
		_cero(abierto.solucion.entre_dc("R.A", "R.B") / 250.0, 1e-5, "lazo abierto, 0 mA"),
		A.cierto(invertido.componente("T").estado["modo"] == "invertido", "al revés no regula"),
		_cero(invertido.solucion.entre_dc("R.A", "R.B") / 250.0, 1e-4, "al revés, casi 0 mA"),
	])


func test_pt100_con_el_ohmetro() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimPT100.new("P", {"temperatura": 0.0}))
	var m := _multimetro()
	var a_0 := m.medir(sim, "ohm", "P.1", "P.2")
	sim.componente("P").params["temperatura"] = 100.0
	var a_100 := m.medir(sim, "ohm", "P.1", "P.2")
	sim.componente("P").params["averia"] = "abierto"
	var abierta := m.medir(sim, "ohm", "P.1", "P.2")
	return A.primero([
		A.cerca(a_0["valor"], 100.0, 0.005, "100 Ω a 0 °C"),
		A.cerca(a_100["valor"], 138.5, 0.005, "138,5 Ω a 100 °C"),
		A.cierto(abierta["fuera_de_rango"], "abierta marca fuera de rango"),
	])


func test_termocupla_da_milivoltios_con_polaridad() -> String:
	var sim := SimSimulacion.new()
	sim.agregar(SimTermocupla.new("TC", {"temperatura": 400.0, "t_union_fria": 25.0}))
	sim.paso()
	var m := _multimetro()
	var v := m.medir(sim, "vdc", "TC.+", "TC.-")
	var al_reves := m.medir(sim, "vdc", "TC.-", "TC.+")
	return A.primero([
		A.cerca(v["valor"], 375.0 * 41e-6, 0.01, "unos 15,4 mV"),
		A.cierto(al_reves["valor"] < 0.0, "al revés la lectura es negativa"),
	])


# --- Multímetro y daños ---

func test_miliamperimetro_en_paralelo_funde_su_fusible() -> String:
	var sim := _con_fuente()
	sim.paso()
	var m := _multimetro()
	var lectura := m.medir(sim, "ma", "F.+", "F.-")
	return A.cierto(lectura["averia"] == "fusible_multimetro" and not m.fusible_ok, "en paralelo con la fuente debe fundir el fusible de mA")


func test_ohmetro_en_un_circuito_de_continua_con_tension() -> String:
	var sim := _con_fuente()
	sim.paso()
	var m := _multimetro()
	var lectura := m.medir(sim, "ohm", "R.A", "R.B")
	return A.cierto(lectura["averia"] == "fusible_multimetro", "medir Ω con 24 V debe fundir el fusible: %s" % str(lectura))
