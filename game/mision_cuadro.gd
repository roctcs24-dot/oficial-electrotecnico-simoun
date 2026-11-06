class_name MisionCuadro
extends MisionBase
## Una misión de Guardia en el cuadro principal. Las maniobras son las del Taller del cuadro,
## sobre la misma simulación de generación; la misión vigila el procedimiento, los disparos y el
## blackout, y lleva el bloqueo de equipos, el trabajo sobre ellos y la prueba final.
## Ofrece los mismos mandos que OperadorCuadro, así la pantalla del cuadro sirve para las dos.

const V_PRESENCIA := 30.0
const BARRAS_CON_TENSION := 0.9
const BARRAS_SIN_TENSION := 0.1
## Faltas que causan los eventos de la simulación. La misión puede cambiarlas en "eventos", o
## anularlas con un tema vacío.
const EVENTOS_FALTA := {
	"cierre_brusco": "cierre_brusco",
	"disparo_potencia_inversa": "potencia_inversa",
	"disparo_preferente": "disparo_preferente",
	"disparo_sobrecarga_generador": "sobrecarga_generador",
}
## Eventos que terminan la misión con un informe de incidente.
const EVENTOS_INCIDENTE := {"cierre_fuera_de_fase": "fuera_de_fase"}

var sim: SimSimulacion
## cuadro.json con las salidas de la misión: lo que la pantalla del cuadro necesita.
var panel: Dictionary
var operador: OperadorCuadro
var bloqueos := {}
var verificados := {}
## Lo medido durante la misión, en el orden en que se midió, para el libro.
var mediciones: Array[String] = []
## Faltas y avisos que surgen solos con el tiempo, como un disparo. La pantalla los muestra.
var avisos_pendientes: Array[Dictionary] = []
var objetivos_s := 0.0
var observando_total := 0.0
var _evidencias := {}
var _evidencia_s := {}
var _con_tension := false
var _eventos_anotados := 0
var _observar_restante := 0.0


func _init(contenido_juego: Contenido, id_mision: String) -> void:
	super(contenido_juego, id_mision)
	panel = contenido.leer("cuadro.json").duplicate(true)
	var cuadro: Dictionary = datos["cuadro"]
	panel["cargas"] = cuadro["cargas"]
	# La nota de la práctica libre no vale en una misión: se muestra la del reporte.
	panel["nota"] = datos["reporte"]["nota"]
	sim = SimSimulacion.desde_dict(_circuito(cuadro))
	operador = OperadorCuadro.new(sim, panel)
	_aplicar(datos.get("preparar", []))
	sim.paso()
	_eventos_anotados = sim.eventos.size()
	_con_tension = operador.tension_barras() > _v_nominal() * BARRAS_CON_TENSION


## El cuadro de tres generadores con las salidas y los ajustes propios de la misión. Las salidas
## de las barras principales se sustituyen por las de la misión; las de emergencia se quedan.
func _circuito(cuadro: Dictionary) -> Dictionary:
	var base: Dictionary = contenido.leer("circuitos/%s.json" % cuadro.get("circuito", "cuadro_principal")).duplicate(true)
	var cargas := {}
	for c: Dictionary in base["componentes"]:
		if c["tipo"] == "carga_trifasica":
			cargas[c["id"]] = true
	var quitadas := {}
	for cable: Array in base["cables"]:
		for i in 2:
			var id: String = cable[i].get_slice(".", 0)
			if cargas.has(id) and cable[1 - i].begins_with("BP."):
				quitadas[id] = true
	var componentes := []
	for c: Dictionary in base["componentes"]:
		if not quitadas.has(c["id"]):
			componentes.append(c)
	var cables := []
	for cable: Array in base["cables"]:
		if not quitadas.has(cable[0].get_slice(".", 0)) and not quitadas.has(cable[1].get_slice(".", 0)):
			cables.append(cable)
	for c: Dictionary in cuadro["cargas"]:
		componentes.append({"id": c["id"], "tipo": "carga_trifasica", "params": c.get("params", {}), "estado": c.get("estado", {})})
		for fase in ["L1", "L2", "L3"]:
			cables.append(["%s.%s" % [c["id"], fase], "BP.%s" % fase])
	var ajustes: Dictionary = cuadro.get("ajustes", {})
	for c: Dictionary in componentes:
		if ajustes.has(c["id"]):
			var p: Dictionary = c.get("params", {})
			p.merge(ajustes[c["id"]], true)
			c["params"] = p
	base["componentes"] = componentes
	base["cables"] = cables
	return base


func _v_nominal() -> float:
	return float(operador.pms().params["v_linea"])


# --- Lecturas del cuadro: las mismas que OperadorCuadro ---

func generador(id_grupo: String) -> SimGenerador:
	return operador.generador(id_grupo)


func interruptor_de(id_grupo: String) -> SimInterruptorGenerador:
	return operador.interruptor_de(id_grupo)


func carga(id_carga: String) -> SimCargaTrifasica:
	return operador.carga(id_carga)


func pms() -> SimPMS:
	return operador.pms()


func tension_barras() -> float:
	return operador.tension_barras()


func frecuencia_barras() -> float:
	return operador.frecuencia_barras()


func tensiones_a_tierra() -> Array[float]:
	return operador.tensiones_a_tierra()


func emergencia() -> Dictionary:
	return operador.emergencia()


func interruptor(id_interruptor: String) -> SimInterruptorGenerador:
	return operador.interruptor(id_interruptor)


func tension_emergencia() -> float:
	return operador.tension_emergencia()


# --- Mandos del cuadro: los mismos que OperadorCuadro ---

func alternar_diesel(id_grupo: String) -> Dictionary:
	return _tras_mando(operador.alternar_diesel(id_grupo))


func alternar_interruptor(id_grupo: String) -> Dictionary:
	return _tras_mando(operador.alternar_interruptor(id_grupo))


func velocidad(id_grupo: String, signo: float) -> Dictionary:
	return _tras_mando(operador.velocidad(id_grupo, signo))


func tension(id_grupo: String, signo: float) -> Dictionary:
	return _tras_mando(operador.tension(id_grupo, signo))


func rearmar(id_grupo: String) -> Dictionary:
	return _tras_mando(operador.rearmar(id_grupo))


func reparar(_id_grupo: String) -> Dictionary:
	return _aviso("aviso", "No disponible", "En una misión, un grupo dañado no se repara desde el cuadro.")


func sincronizar(id_grupo: String) -> Dictionary:
	return _tras_mando(operador.sincronizar(id_grupo))


func cancelar_sincronizacion() -> Dictionary:
	return _tras_mando(operador.cancelar_sincronizacion())


func alternar_pms() -> Dictionary:
	return _tras_mando(operador.alternar_pms())


func alternar_interruptor_id(id_interruptor: String) -> Dictionary:
	return _tras_mando(operador.alternar_interruptor_id(id_interruptor))


func rearmar_id(id_interruptor: String) -> Dictionary:
	return _tras_mando(operador.rearmar_id(id_interruptor))


func alternar_arranque_automatico(id_grupo: String) -> Dictionary:
	return _tras_mando(operador.alternar_arranque_automatico(id_grupo))


## Antes de cortar una salida se comprueban las reglas de la misión, como avisar al puente.
func alternar_carga(id_carga: String) -> Dictionary:
	var c := operador.carga(id_carga)
	var falta := {}
	if c.estado["conectada"]:
		for r: Dictionary in datos.get("reglas", []):
			if r.get("al", "") != "desconectar":
				continue
			var aplica: bool = r.get("id", "") == id_carga or (r.get("esencial", false) and c.params["esencial"])
			if aplica and not hechos.get(r["sin"], false):
				falta = _falta(r["falta"])
	var resultado := _tras_mando(operador.alternar_carga(id_carga))
	return falta if not falta.is_empty() and resultado["tipo"] == "hecho" else resultado


## Una orden puede cerrar fuera de fase en el acto: el incidente se informa enseguida.
func _tras_mando(resultado: Dictionary) -> Dictionary:
	_anotar_eventos()
	if fin == "accidente":
		return _aviso("accidente", accidente["titulo"], accidente["que_ocurrio"])
	return resultado


# --- Tiempo ---

func avanzar(segundos: float) -> void:
	var pasos := maxi(int(ceil(segundos / SimSimulacion.PASO_S - 1e-6)), 1)
	for _i in pasos:
		if not fin.is_empty():
			return
		sim.paso()
		_vigilar(SimSimulacion.PASO_S)


func _vigilar(dt: float) -> void:
	_anotar_eventos()
	if not fin.is_empty():
		return
	var v := operador.tension_barras()
	if v >= _v_nominal() * BARRAS_CON_TENSION:
		_con_tension = true
	elif v < _v_nominal() * BARRAS_SIN_TENSION and _con_tension:
		_con_tension = false
		_ocurre_accidente("blackout", "incidentes")
		return
	var evidencias: Array = datos.get("evidencias", [])
	for i in evidencias.size():
		var e: Dictionary = evidencias[i]
		if not e.has("condiciones") or _evidencias.has(i):
			continue
		if _todas(e["condiciones"]):
			_evidencia_s[i] = _evidencia_s.get(i, 0.0) + dt
			if _evidencia_s[i] >= float(e.get("durante_s", 0.0)):
				_evidencias[i] = true
		else:
			_evidencia_s[i] = 0.0
	if prueba_ok:
		return
	if objetivos_cumplidos():
		objetivos_s += dt
		if objetivos_s >= tiempo_de_prueba():
			prueba_ok = true
			avisos_pendientes.append(_aviso("hecho", "Prueba superada", datos["prueba"]["superada"]))
	else:
		objetivos_s = 0.0


## Disparos y cierres que ya registró la simulación.
func _anotar_eventos() -> void:
	var eventos := sim.eventos
	var temas: Dictionary = EVENTOS_FALTA.duplicate()
	temas.merge(datos.get("eventos", {}), true)
	while _eventos_anotados < eventos.size() and fin.is_empty():
		var e: Dictionary = eventos[_eventos_anotados]
		_eventos_anotados += 1
		if EVENTOS_INCIDENTE.has(e["tipo"]):
			_ocurre_accidente(EVENTOS_INCIDENTE[e["tipo"]], "incidentes")
			return
		if not temas.get(e["tipo"], "").is_empty():
			_falta_pendiente(temas[e["tipo"]])
		for r: Dictionary in datos.get("reglas", []):
			if r.get("evento", "") != e["tipo"]:
				continue
			if r.has("componentes") and not r["componentes"].has(e["componente"]):
				continue
			if r.has("si_conectada") and not operador.carga(r["si_conectada"]).estado["conectada"]:
				continue
			_falta_pendiente(r["falta"])


func _falta_pendiente(tema: String) -> void:
	var antes := faltas.size()
	var a := _falta(tema)
	if faltas.size() > antes:
		avisos_pendientes.append(a)


# --- Prueba en servicio ---

func objetivos() -> Array:
	return datos["prueba"]["objetivos"]


func objetivos_cumplidos() -> bool:
	return _todas(objetivos())


func tiempo_de_prueba() -> float:
	return float(datos["prueba"]["mantener_s"])


func _todas(condiciones: Array) -> bool:
	for c: Dictionary in condiciones:
		if not condicion(c):
			return false
	return true


func condicion(c: Dictionary) -> bool:
	match c["c"]:
		"cerrado":
			return _interruptor_condicion(c).cerrado()
		"abierto":
			return not _interruptor_condicion(c).cerrado()
		"en_marcha":
			return operador.generador(c["id"]).en_marcha()
		"parado":
			return not operador.generador(c["id"]).en_marcha()
		"conectada":
			return operador.carga(c["id"]).estado["conectada"]
		"desconectada":
			return not operador.carga(c["id"]).estado["conectada"]
		"frecuencia":
			return _entre(operador.frecuencia_barras(), c)
		"tension":
			return _entre(operador.tension_barras(), c)
		"reparto":
			return _repartida(c["ids"], float(c["pct"]))
		"aislamiento":
			return float(sim.componente("MA").estado["mohm"]) >= float(c["min"])
		"pms":
			return operador.pms().automatico() == bool(c["automatico"])
		"sin_bloqueos":
			return bloqueos.is_empty()
		"param":
			return _entre(float(sim.componente(c["id"]).params[c["clave"]]), c)
	push_error("Condición de misión desconocida: %s" % c["c"])
	return false


## Con "interruptor", uno por su id, como el enlace; con "id", el del generador.
func _interruptor_condicion(c: Dictionary) -> SimInterruptorGenerador:
	return operador.interruptor(c["interruptor"]) if c.has("interruptor") else operador.interruptor_de(c["id"])


func _entre(valor: float, c: Dictionary) -> bool:
	return valor >= float(c.get("min", -INF)) and valor <= float(c.get("max", INF))


## Todos los grupos con carga y con la misma fracción de su potencia, dentro de pct.
func _repartida(ids: Array, pct: float) -> bool:
	var minima := INF
	var maxima := -INF
	for g: String in ids:
		var gen := operador.generador(g)
		var fraccion: float = gen.estado["p_kw"] / gen.params["p_kw"]
		minima = minf(minima, fraccion)
		maxima = maxf(maxima, fraccion)
	return minima > 0.0 and (maxima - minima) * 100.0 <= pct


func observando() -> bool:
	return _observar_restante > 0.0


func avance_observacion() -> float:
	return 1.0 - _observar_restante / observando_total if observando_total > 0.0 else 1.0


func observar(segundos: float) -> void:
	_observar_restante = segundos
	observando_total = segundos


## Avanza dentro del límite de tiempo real. Al terminar devuelve el aviso; antes, {}.
func procesar_observacion(limite_ms: int) -> Dictionary:
	var inicio := Time.get_ticks_msec()
	while _observar_restante > 0.0 and Time.get_ticks_msec() - inicio < limite_ms:
		avanzar(SimSimulacion.PASO_S)
		_observar_restante -= SimSimulacion.PASO_S
		if not fin.is_empty() or prueba_ok:
			_observar_restante = 0.0
	if _observar_restante > 0.0:
		return {}
	_observar_restante = 0.0
	if not fin.is_empty():
		return _aviso("accidente", accidente["titulo"], accidente["que_ocurrio"])
	if prueba_ok:
		return {}
	for o: Dictionary in objetivos():
		if not condicion(o):
			return _aviso("aviso", "Observación terminada", "No se cumple: %s." % o["texto"])
	return _aviso("aviso", "Observación terminada", "Las condiciones se cumplen, pero aún no durante %d s seguidos." % roundi(tiempo_de_prueba()))


# --- Procedimiento ---

func dar_paso(paso_id: String) -> Dictionary:
	for p: Dictionary in datos.get("pasos", []):
		if p["id"] == paso_id:
			for marca: String in p["pone"]:
				hechos[marca] = true
	return _aviso("hecho", "", "")


func paso_hecho(paso_id: String) -> bool:
	for p: Dictionary in datos.get("pasos", []):
		if p["id"] == paso_id:
			for marca: String in p["pone"]:
				if not hechos.get(marca, false):
					return false
			return true
	return false


func bloqueables() -> Array:
	return datos.get("bloqueables", [])


func bloqueado(id_equipo: String) -> bool:
	return bloqueos.has(id_equipo)


## Candado y tarjeta en el arranque de un grupo parado o en el interruptor de una salida abierta.
func bloquear(id_equipo: String) -> Dictionary:
	var c := sim.componente(id_equipo)
	if c is SimGenerador:
		if (c as SimGenerador).en_marcha():
			return _aviso("aviso", "Grupo en marcha", "Pare el diésel de %s antes de bloquear su arranque." % id_equipo)
		if operador.interruptor_de(id_equipo).cerrado():
			return _aviso("aviso", "Interruptor cerrado", "Abra el interruptor de %s antes de bloquear." % id_equipo)
	elif c.estado["conectada"]:
		return _aviso("aviso", "Salida conectada", "Abra el interruptor de %s antes de colocar el candado." % id_equipo)
	var resultado := _aviso("hecho", "", "")
	if not hechos.has("aviso"):
		resultado = _falta("sin_aviso")
		hechos["aviso"] = true
	c.estado["bloqueado" if c is SimGenerador else "bloqueada"] = true
	bloqueos[id_equipo] = true
	verificados.erase(id_equipo)
	return resultado


func desbloquear(id_equipo: String) -> Dictionary:
	var c := sim.componente(id_equipo)
	var resultado := _aviso("hecho", "", "")
	if not _remediciones_hechas():
		resultado = _falta("sin_remedir")
	c.estado["bloqueado" if c is SimGenerador else "bloqueada"] = false
	bloqueos.erase(id_equipo)
	verificados.erase(id_equipo)
	return resultado


## Probar, medir, probar: el multímetro se prueba en las barras antes y después de medir el
## equipo entre fases y de cada fase a masa.
func verificar(id_equipo: String) -> Dictionary:
	if not bloqueos.has(id_equipo):
		return _aviso("aviso", "Sin bloqueo", "La verificación solo vale con el equipo bloqueado.")
	if operador.tension_barras() < V_PRESENCIA:
		return _aviso("aviso", "Sin fuente conocida", "Las barras no tienen tensión: no puede probar el multímetro antes de medir.")
	var v := tension_equipo(id_equipo)
	if v >= V_PRESENCIA:
		return _aviso("aviso", "Hay tensión: %s V" % TextoTecnico.numero(v, 0), "El equipo sigue energizado. No intervenga: busque de dónde llega esa tensión.")
	verificados[id_equipo] = true
	mediciones.append("Ausencia de tensión en %s: 0 V entre fases y a masa, multímetro probado en barras antes y después" % id_equipo)
	return _aviso("hecho", "Ausencia de tensión verificada", "El multímetro marcó tensión en las barras antes y después, y 0 V en %s entre fases y de cada fase a masa." % id_equipo)


func verificado(id_equipo: String) -> bool:
	return verificados.has(id_equipo)


## La mayor tensión entre fases o de fase a masa en los bornes del equipo.
func tension_equipo(id_equipo: String) -> float:
	var c := sim.componente(id_equipo)
	if c is SimCargaTrifasica:
		return operador.tension_barras() if c.estado["conectada"] else 0.0
	var sol := sim.solucion
	var maxima := 0.0
	for par in [["L1", "L2"], ["L2", "L3"], ["L3", "L1"]]:
		maxima = maxf(maxima, c.tension(sol, par[0], par[1]))
	for fase in ["L1", "L2", "L3"]:
		maxima = maxf(maxima, sol.entre(c.n(fase), SimSolver.TIERRA).modulo())
	return maxima


# --- Trabajo sobre los equipos ---

func accion(accion_id: String) -> Dictionary:
	for a: Dictionary in datos.get("acciones", []):
		if a["id"] == accion_id:
			return a
	return {}


func ejecutar(accion_id: String) -> Dictionary:
	var a := accion(accion_id)
	if a.has("bloqueo"):
		if not bloqueos.has(a["bloqueo"]):
			return _ocurre_accidente("sin_bloqueo")
		if a.get("verificar", true) and not verificados.has(a["bloqueo"]):
			return _ocurre_accidente("sin_verificar")
	for marca: String in a.get("necesita", []):
		if not hechos.get(marca, false):
			return _aviso("aviso", "Todavía no", a.get("si_falta", "Falta un paso previo."))
	for marca: String in a.get("impide", []):
		if hechos.get(marca, false):
			return _aviso("aviso", "Ya está hecho", a.get("si_impide", "Este paso ya se realizó."))
	var texto: String = a["texto"]
	if a.has("medir"):
		if not bloqueos.has(a["medir"]) or not verificados.has(a["medir"]):
			return _falta("medir_sin_bloqueo")
		var mohm: float = (sim.componente(a["medir"]) as SimCargaTrifasica).aislamiento_mohm()
		texto = texto.replace("{mohm}", TextoTecnico.numero(mohm, 2 if mohm < 1.0 else 0))
		mediciones.append(texto)
	_aplicar(a.get("efecto", []))
	for marca: String in a.get("pone", []):
		hechos[marca] = true
	acciones_hechas.append(accion_id)
	if a.get("innecesaria", false):
		_anotar_falta(a.get("tema", "reparacion_innecesaria"), a["titulo"], texto)
		return _aviso("error", a["titulo"], texto)
	return _aviso("hecho", a["titulo"], texto)


## Cada medición de "remediciones" debe repetirse después de su reparación.
func _remediciones_hechas() -> bool:
	for r: Dictionary in datos.get("remediciones", []):
		var reparacion := acciones_hechas.rfind(r["despues_de"])
		if reparacion >= 0 and acciones_hechas.rfind(r["accion"]) < reparacion:
			return false
	return true


func evidencias_completas() -> bool:
	var evidencias: Array = datos.get("evidencias", [])
	for i in evidencias.size():
		var e: Dictionary = evidencias[i]
		if e.has("accion"):
			if not acciones_hechas.has(e["accion"]):
				return false
		elif not _evidencias.has(i):
			return false
	return true


## Preparación inicial y efectos de las acciones: órdenes sobre la simulación.
func _aplicar(operaciones: Array) -> void:
	for op: Dictionary in operaciones:
		match op["op"]:
			"arrancar":
				operador.generador(op["id"]).arrancar()
			"cerrar":
				operador.interruptor_de(op["id"]).cerrar()
			"abrir":
				operador.interruptor_de(op["id"]).abrir()
			"avanzar":
				sim.avanzar_tiempo(float(op["s"]))
			"pms":
				operador.pms().fijar_automatico(bool(op["automatico"]))
			"sincronizar":
				_sincronizar_ya(op["id"])
			"centrar":
				_centrar_frecuencia()
			"normalizar_emergencia":
				_normalizar_emergencia()
			"conectar":
				operador.carga(op["id"]).conectar()
			"desconectar":
				operador.carga(op["id"]).desconectar()
			"parada":
				operador.generador(op["id"]).parar_por_alarma(op["alarma"])
			"disparado":
				var q := operador.interruptor_de(op["id"])
				q.estado.merge({"cerrado": false, "disparado": true, "causa": op["causa"]}, true)
			"param":
				sim.componente(op["id"]).params[op["clave"]] = op["valor"]
			"estado":
				sim.componente(op["id"]).estado[op["clave"]] = op["valor"]
			_:
				push_error("Operación de misión desconocida: %s" % op["op"])


## Corrige a mano la consigna de los grupos en barras hasta dejar 60 Hz, sin el PMS: en
## automático, con carga alta, arrancaría la reserva.
func _centrar_frecuencia() -> void:
	for _i in 3:
		sim.avanzar_tiempo(5.0)
		for d: Dictionary in panel["generadores"]:
			if operador.interruptor_de(d["id"]).cerrado():
				var g := operador.generador(d["id"])
				g.ajustar_velocidad(SimPMS.F_NOMINAL - g.frecuencia())
	sim.avanzar_tiempo(5.0)


## Servicio normal del cuadro de emergencia: alimentado desde el principal por el enlace, con
## el generador de emergencia parado y en automático. Necesita las barras principales con tensión.
func _normalizar_emergencia() -> void:
	var e := operador.emergencia()
	var ge := operador.generador(e["generador"])
	operador.interruptor(e["interruptor"]).abrir()
	ge.parar()
	ge.estado.merge({"f": 0.0, "e_pu": 0.0, "pm_pu": 0.0}, true)
	# Si un grupo acaba de cerrar sobre las barras, su tensión tarda en recuperarse.
	sim.avanzar_tiempo(2.0)
	var qt := operador.interruptor(e["enlace"])
	qt.rearmar()
	var motivo := qt.cerrar()
	if not motivo.is_empty():
		push_error("No se pudo cerrar el enlace al preparar la misión: %s" % motivo)
	ge.params["arranque_automatico"] = true
	operador.interruptor(e["interruptor"]).params["cierre_automatico"] = true
	sim.avanzar_tiempo(1.0)


## Con el sincronizador del PMS, hasta que el grupo queda en barras.
func _sincronizar_ya(id_grupo: String) -> void:
	var motivo := operador.pms().sincronizar(id_grupo)
	if not motivo.is_empty():
		push_error("No se pudo preparar %s: %s" % [id_grupo, motivo])
		return
	var limite := SimPMS.SINCRONIZACION_MAXIMA_S
	while not operador.interruptor_de(id_grupo).cerrado() and limite > 0.0:
		sim.paso()
		limite -= SimSimulacion.PASO_S
