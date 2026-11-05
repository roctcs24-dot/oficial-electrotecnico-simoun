class_name SimInterruptorGenerador
extends SimComponente
## Interruptor de generador (ACB) con su unidad de protección. Polos 1-2, 3-4 y 5-6: los
## bornes impares van al generador y los pares a las barras.
##
## Protecciones: sobrecarga (largo retardo), cortocircuito (corto retardo e instantáneo),
## potencia inversa, mínima tensión y disparo preferente de cargas no esenciales. Ajustes
## típicos, a verificar con el estudio de selectividad del buque.

const POLOS := [["1", "2"], ["3", "4"], ["5", "6"]]
## Comprobación de sincronismo al cerrar.
const ANGULO_BRUSCO := 15.0
const ANGULO_FUERA_DE_FASE := 60.0
const ANGULO_DANO := 120.0
const BARRA_MUERTA := 0.1
const TENSION_PARA_CERRAR := 0.85
const CIERRE_AUTOMATICO_S := 1.0

var _cierre_auto_s := 0.0


func tipo() -> String:
	return "interruptor_generador"


func _params_por_defecto() -> Dictionary:
	return {
		"in_a": 750.0,
		"v_linea": 440.0,
		"p_kw_nominal": 450.0,
		"isd_veces": 2.5,
		"tsd_s": 0.2,
		"ii_veces": 10.0,
		"potencia_inversa_pct": 8.0,
		"potencia_inversa_s": 5.0,
		"minima_tension_pct": 70.0,
		"minima_tension_s": 1.0,
		"preferente_veces": 1.0,
		"preferente_s": 5.0,
		"cierre_automatico": false,
		"enclavados": [],
	}


func _estado_inicial() -> Dictionary:
	return {
		"cerrado": false, "disparado": false, "causa": "", "memoria": [0.0, 0.0, 0.0],
		"t_corto": 0.0, "t_inversa": 0.0, "t_minima": 0.0, "t_preferente": 0.0, "preferente_activo": false,
		"p_kw": 0.0, "i": 0.0,
	}


func cerrado() -> bool:
	return estado["cerrado"]


## Lado del generador y lado de las barras, entre L1 y L2.
func tension_generador(sol: SimSolver.Solucion) -> Cx:
	return sol.entre(n("1"), n("3"))


func tension_barras(sol: SimSolver.Solucion) -> Cx:
	return sol.entre(n("2"), n("4"))


## Devuelve "" si cerró, o el motivo por el que no puede. Comprueba el sincronismo y, si se
## cierra fuera de fase, aplica la consecuencia.
func cerrar() -> String:
	if estado["cerrado"]:
		return ""
	if estado["disparado"]:
		return "El interruptor está disparado: rearme antes de cerrar."
	var simulacion := sim()
	if simulacion == null or simulacion.solucion == null:
		return "Sin medida de tensión."
	for otro: String in params["enclavados"]:
		var c: SimComponente = simulacion.componentes.get(otro)
		if c != null and c.estado.get("cerrado", false):
			return "Enclavado: abra antes %s." % otro
	var sol := simulacion.solucion
	var v_gen := tension_generador(sol)
	var v_barras := tension_barras(sol)
	if v_gen.modulo() < params["v_linea"] * TENSION_PARA_CERRAR:
		return "La bobina de mínima tensión no deja cerrar: el generador no tiene tensión."
	estado["cerrado"] = true
	if v_barras.modulo() < params["v_linea"] * BARRA_MUERTA:
		avisar("cierre_barra_muerta")
		return ""
	var angulo := absf(Cx.diferencia_angulo(v_gen.angulo(), v_barras.angulo()))
	if angulo >= ANGULO_FUERA_DE_FASE:
		_disparar("cierre_fuera_de_fase", {"angulo": angulo})
		if angulo >= ANGULO_DANO:
			for c: SimComponente in simulacion.componentes.values():
				if c is SimGenerador and _alimenta(c, sol):
					c.estado["danado"] = true
					c.estado["en_marcha"] = false
					c.avisar("generador_danado", {"angulo": angulo})
	elif angulo >= ANGULO_BRUSCO:
		avisar("cierre_brusco", {"angulo": angulo})
	else:
		avisar("cierre_sincronizado", {"angulo": angulo})
	return ""


## Si el generador está conectado al lado de este interruptor: sus bornes miden lo mismo.
func _alimenta(g: SimGenerador, sol: SimSolver.Solucion) -> bool:
	return sol.entre(g.n("L1"), n("1")).modulo() < 1.0 and sol.entre(g.n("L2"), n("3")).modulo() < 1.0


func abrir() -> void:
	estado["cerrado"] = false


func rearmar() -> void:
	estado["disparado"] = false
	estado["causa"] = ""


func estampar(e: SimEstampa) -> void:
	if estado["cerrado"]:
		for polo in POLOS:
			e.impedancia(n(polo[0]), n(polo[1]), R_CONTACTO)


func corriente(sol: SimSolver.Solucion, polo: int) -> float:
	if not estado["cerrado"]:
		return 0.0
	return sol.entre(n(POLOS[polo][0]), n(POLOS[polo][1])).modulo() / R_CONTACTO


## Potencia que pasa del generador a las barras, por el método de los dos vatímetros.
func potencia_kw(sol: SimSolver.Solucion) -> float:
	if not estado["cerrado"]:
		return 0.0
	var i1 := sol.entre(n("1"), n("2")).escala(1.0 / R_CONTACTO)
	var i3 := sol.entre(n("5"), n("6")).escala(1.0 / R_CONTACTO)
	var v12 := sol.entre(n("1"), n("3"))
	var v32 := sol.entre(n("5"), n("3"))
	return (v12.por(i1.conjugado()).re + v32.por(i3.conjugado()).re) / 1000.0


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	# Si cierra solo en este paso, la solución es de antes del cierre: la tensión entre polos
	# se leería como una corriente enorme. Las protecciones miden desde el paso siguiente.
	if _cierre_automatico(dt, sol):
		return
	var i_max := 0.0
	for polo in 3:
		i_max = maxf(i_max, corriente(sol, polo))
	estado["i"] = i_max
	estado["p_kw"] = potencia_kw(sol)
	var memoria: Array = estado["memoria"]
	for polo in 3:
		memoria[polo] = SimTermico.actualizar(memoria[polo], corriente(sol, polo), params["in_a"], dt)
	if not estado["cerrado"]:
		estado["t_corto"] = 0.0
		estado["t_inversa"] = 0.0
		estado["t_minima"] = 0.0
		estado["t_preferente"] = 0.0
		return
	var i_n: float = params["in_a"]
	if i_max > i_n * params["ii_veces"]:
		_disparar("disparo_instantaneo", {"corriente_a": i_max})
		return
	estado["t_corto"] = estado["t_corto"] + dt if i_max > i_n * params["isd_veces"] else 0.0
	if estado["t_corto"] >= params["tsd_s"]:
		_disparar("disparo_cortocircuito", {"corriente_a": i_max})
		return
	for m: float in memoria:
		if m >= SimTermico.UMBRAL:
			_disparar("disparo_sobrecarga_generador", {"corriente_a": i_max})
			return
	var inversa: bool = estado["p_kw"] < -params["p_kw_nominal"] * params["potencia_inversa_pct"] / 100.0
	estado["t_inversa"] = estado["t_inversa"] + dt if inversa else 0.0
	if estado["t_inversa"] >= params["potencia_inversa_s"]:
		_disparar("disparo_potencia_inversa", {"p_kw": estado["p_kw"]})
		return
	var baja: bool = tension_generador(sol).modulo() < params["v_linea"] * params["minima_tension_pct"] / 100.0
	estado["t_minima"] = estado["t_minima"] + dt if baja else 0.0
	if estado["t_minima"] >= params["minima_tension_s"]:
		_disparar("disparo_minima_tension", {})
		return
	_vigilar_preferente(dt, i_max)


## Primer escalón de sobrecarga: avisa a las cargas no esenciales para que se desconecten,
## antes de que el interruptor tenga que disparar.
func _vigilar_preferente(dt: float, i_max: float) -> void:
	if i_max > params["in_a"] * params["preferente_veces"]:
		estado["t_preferente"] += dt
		if estado["t_preferente"] >= params["preferente_s"] and not estado["preferente_activo"]:
			estado["preferente_activo"] = true
			avisar("disparo_preferente", {"corriente_a": i_max})
	else:
		estado["t_preferente"] = 0.0
		estado["preferente_activo"] = false


## Como en un cuadro de emergencia: cierra solo sobre barras muertas cuando su generador
## ya tiene tensión.
## Devuelve true si cerró en este paso.
func _cierre_automatico(dt: float, sol: SimSolver.Solucion) -> bool:
	if not params["cierre_automatico"] or estado["cerrado"] or estado["disparado"]:
		_cierre_auto_s = 0.0
		return false
	var listo: bool = tension_generador(sol).modulo() > params["v_linea"] * 0.9 and tension_barras(sol).modulo() < params["v_linea"] * BARRA_MUERTA
	_cierre_auto_s = _cierre_auto_s + dt if listo else 0.0
	if _cierre_auto_s >= CIERRE_AUTOMATICO_S:
		_cierre_auto_s = 0.0
		return cerrar().is_empty() and estado["cerrado"]
	return false


func _disparar(evento: String, detalle: Dictionary) -> void:
	estado["cerrado"] = false
	estado["disparado"] = true
	estado["causa"] = evento
	avisar(evento, detalle)
