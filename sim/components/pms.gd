class_name SimPMS
extends SimComponente
## Sistema de gestión de potencia (PMS) básico. En automático reparte la carga entre los
## grupos en barras y mantiene la frecuencia nominal, arranca y sincroniza un grupo de reserva cuando la carga
## es alta, y tras un blackout cierra un grupo sobre las barras muertas.
## En manual no actúa: todo depende del operador. No tiene bornes: actúa sobre los equipos.
## Ajustes típicos de un PMS genérico: verificar con el del buque.

const F_NOMINAL := SimRed.F_HZ
const K_FRECUENCIA := 0.5
const K_REPARTO := 1.0
const K_SINCRONIZACION := 1.0
const DESLIZAMIENTO_OBJETIVO_HZ := 0.1
const VENTANA_ANGULO := 8.0
const VENTANA_DESLIZAMIENTO_HZ := 0.25
const VENTANA_TENSION := 0.05
const VELOCIDAD_PARA_SINCRONIZAR := 0.95
const SINCRONIZACION_MAXIMA_S := 60.0


func tipo() -> String:
	return "pms"


func _params_por_defecto() -> Dictionary:
	return {
		"generadores": ["G1", "G2", "G3"],
		"interruptores": ["Q1", "Q2", "Q3"],
		"carga_arranque": 0.85,
		"carga_arranque_s": 5.0,
		"v_linea": SimRed.V_LINEA,
		# Sin sincronizador automático, el PMS arranca la reserva pero no la cierra en barras.
		"sincronizador": true,
	}


func _estado_inicial() -> Dictionary:
	return {"automatico": false, "sincronizando": "", "sincronizando_s": 0.0, "alta_s": 0.0, "mensaje": ""}


func automatico() -> bool:
	return estado["automatico"]


func fijar_automatico(valor: bool) -> void:
	estado["automatico"] = valor
	estado["sincronizando"] = ""
	estado["mensaje"] = "Automático" if valor else "Manual"


func _grupo(i: int) -> SimGenerador:
	return sim().componente(params["generadores"][i])


func _interruptor(i: int) -> SimInterruptorGenerador:
	return sim().componente(params["interruptores"][i])


func _disponible(i: int) -> bool:
	return _grupo(i).disponible() and not _interruptor(i).estado["disparado"]


## Sincronización automática de un grupo concreto, pedida por el operador también en manual.
## Devuelve "" o el motivo por el que no puede empezar.
func sincronizar(id: String) -> String:
	var i: int = params["generadores"].find(id)
	if i < 0:
		return "Grupo desconocido."
	if not params["sincronizador"]:
		return "El sincronizador automático está fuera de servicio. Sincronice a mano con el sincronoscopio."
	if not _disponible(i):
		return "El grupo o su interruptor están fuera de servicio."
	if not _grupo(i).en_marcha():
		return "Arranque primero el diésel de %s." % id
	if _interruptor(i).cerrado():
		return "%s ya está en barras." % id
	if _en_barras().is_empty():
		return "No hay ningún grupo en barras: no hace falta sincronizar, cierre directamente."
	estado["sincronizando"] = id
	estado["sincronizando_s"] = 0.0
	estado["mensaje"] = "Sincronizando %s" % id
	return ""


func cancelar_sincronizacion() -> void:
	if not estado["sincronizando"].is_empty():
		estado["mensaje"] = "Sincronización de %s cancelada" % estado["sincronizando"]
	estado["sincronizando"] = ""


func sincronizando() -> String:
	return estado["sincronizando"]


func _en_barras() -> Array[int]:
	var en_barras: Array[int] = []
	for i in params["generadores"].size():
		if _interruptor(i).cerrado():
			en_barras.append(i)
	return en_barras


func avanzar(dt: float, sol: SimSolver.Solucion) -> void:
	if sim() == null:
		return
	var en_barras := _en_barras()
	# En manual solo actúa el sincronizador, si el operador lo pidió.
	if not estado["automatico"]:
		if not estado["sincronizando"].is_empty():
			if en_barras.is_empty():
				cancelar_sincronizacion()
			else:
				_sincronizar(en_barras, dt, sol)
		return
	if en_barras.is_empty():
		_recuperar_barras(sol)
		return
	_repartir(en_barras, dt)
	_vigilar_carga(en_barras, dt)
	_sincronizar(en_barras, dt, sol)


## Barras sin ningún grupo: cierra el primero que tenga tensión, o arranca uno.
func _recuperar_barras(sol: SimSolver.Solucion) -> void:
	for i in params["generadores"].size():
		var q := _interruptor(i)
		if _disponible(i) and _grupo(i).en_marcha() and q.tension_generador(sol).modulo() > params["v_linea"] * 0.9:
			if q.cerrar().is_empty() and q.cerrado():
				estado["mensaje"] = "Barras recuperadas con %s" % _grupo(i).id
			return
	for i in params["generadores"].size():
		if _grupo(i).en_marcha():
			return
	for i in params["generadores"].size():
		if _disponible(i):
			_grupo(i).arrancar()
			estado["mensaje"] = "Barras sin tensión: arrancando %s" % _grupo(i).id
			avisar("pms_arranque", {"grupo": _grupo(i).id})
			return


## Reparto isócrono: cada grupo corrige su velocidad para llevar la frecuencia a la nominal y su
## carga a la misma fracción de su potencia que los demás.
func _repartir(en_barras: Array[int], dt: float) -> void:
	var total := 0.0
	var capacidad := 0.0
	for i in en_barras:
		total += _grupo(i).estado["p_kw"]
		capacidad += _grupo(i).params["p_kw"]
	var fraccion := total / capacidad
	for i in en_barras:
		var g := _grupo(i)
		var propia: float = g.estado["p_kw"] / g.params["p_kw"]
		g.estado["f_ref"] += (K_FRECUENCIA * (F_NOMINAL - g.frecuencia()) + K_REPARTO * (fraccion - propia)) * dt


func _vigilar_carga(en_barras: Array[int], dt: float) -> void:
	if not estado["sincronizando"].is_empty():
		estado["alta_s"] = 0.0
		return
	var total := 0.0
	var capacidad := 0.0
	for i in en_barras:
		total += _grupo(i).estado["p_kw"]
		capacidad += _grupo(i).params["p_kw"]
	if total < capacidad * params["carga_arranque"]:
		estado["alta_s"] = 0.0
		return
	estado["alta_s"] += dt
	if estado["alta_s"] < params["carga_arranque_s"]:
		return
	estado["alta_s"] = 0.0
	for i in params["generadores"].size():
		if not en_barras.has(i) and _disponible(i) and _grupo(i).en_marcha() and not params["sincronizador"]:
			estado["mensaje"] = "Carga alta: sincronice a mano %s" % _grupo(i).id
			return
	for i in params["generadores"].size():
		if not en_barras.has(i) and _disponible(i):
			_grupo(i).arrancar()
			estado["mensaje"] = "Carga alta: arrancando %s" % _grupo(i).id
			if params["sincronizador"]:
				estado["sincronizando"] = _grupo(i).id
				estado["sincronizando_s"] = 0.0
			else:
				estado["mensaje"] += ". Sincronícelo a mano"
			avisar("pms_arranque", {"grupo": _grupo(i).id})
			return
	estado["mensaje"] = "Carga alta y sin grupos de reserva"


## Sincronizador automático: deja el entrante un poco más rápido que las barras y cierra
## cuando el ángulo, el deslizamiento y la tensión están dentro de la ventana.
func _sincronizar(en_barras: Array[int], dt: float, sol: SimSolver.Solucion) -> void:
	var id: String = estado["sincronizando"]
	if id.is_empty():
		return
	var i: int = params["generadores"].find(id)
	var g := _grupo(i)
	var q := _interruptor(i)
	if not _disponible(i) or not g.en_marcha() or q.cerrado():
		estado["sincronizando"] = ""
		return
	estado["sincronizando_s"] += dt
	if estado["sincronizando_s"] > SINCRONIZACION_MAXIMA_S:
		estado["sincronizando"] = ""
		estado["mensaje"] = "Sincronización de %s fallida" % id
		avisar("pms_sincronizacion_fallida", {"grupo": id})
		return
	if g.frecuencia() < F_NOMINAL * VELOCIDAD_PARA_SINCRONIZAR:
		return
	var f_barras := _grupo(en_barras[0]).frecuencia()
	g.estado["f_ref"] += K_SINCRONIZACION * (f_barras + DESLIZAMIENTO_OBJETIVO_HZ - g.frecuencia()) * dt
	var v_gen := q.tension_generador(sol)
	var v_barras := q.tension_barras(sol)
	var angulo := absf(Cx.diferencia_angulo(v_gen.angulo(), v_barras.angulo()))
	var deslizamiento := absf(g.frecuencia() - f_barras)
	var dv: float = absf(v_gen.modulo() - v_barras.modulo()) / params["v_linea"]
	if angulo <= VENTANA_ANGULO and deslizamiento <= VENTANA_DESLIZAMIENTO_HZ and dv <= VENTANA_TENSION:
		if q.cerrar().is_empty() and q.cerrado():
			estado["mensaje"] = "%s sincronizado" % id
		estado["sincronizando"] = ""
