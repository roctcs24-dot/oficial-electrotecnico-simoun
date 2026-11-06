class_name MisionPlanta
extends MisionBase
## Una misión de Guardia en la planta de frío por amoníaco. Las maniobras son las del Taller de
## la planta, sobre la misma simulación; la misión vigila el procedimiento, los disparos y las
## fugas, y lleva el bloqueo del compresor y de las bombas, el trabajo sobre los equipos, la
## exposición al amoníaco y la prueba final.
## Ofrece los mismos mandos que OperadorPlanta, así la pantalla de la planta sirve para las dos.

const V_PRESENCIA := 30.0
const PRESOSTATOS := ["PA", "PB", "PO"]
## La prueba en servicio se observa con pasos de medio segundo: la planta cambia despacio.
const PASO_OBSERVACION_S := 0.5
## Eventos que terminan la misión con un informe de incidente.
const EVENTOS_INCIDENTE := {"valvula_seguridad": "valvula_seguridad"}
## Lecturas que una acción puede citar en su texto.
const LECTURAS := {
	"{ppm}": ["estado", "ppm_sala", 0],
	"{hielo}": ["estado", "hielo", 1],
	"{aceite}": ["presion", "aceite", 1],
	"{succion}": ["presion", "succion", 2],
	"{descarga}": ["presion", "descarga", 1],
	"{salmuera}": ["temperatura", "salmuera", 1],
	"{condensacion}": ["temperatura", "condensacion", 1],
}

var sim: SimSimulacion
## planta.json con la nota de la misión: lo que la pantalla de la planta necesita.
var panel: Dictionary
var operador: OperadorPlanta
var bloqueos := {}
var verificados := {}
## Lo medido durante la misión, en el orden en que se midió, para el libro.
var mediciones: Array[String] = []
## Puntos de tubería medidos con el termómetro y el lugar de su anotación en mediciones.
var medidos := {}
## Faltas y avisos que surgen solos con el tiempo, como un disparo. La pantalla los muestra.
var avisos_pendientes: Array[Dictionary] = []
var objetivos_s := 0.0
var observando_total := 0.0
var _evidencias := {}
var _evidencia_s := {}
var _eventos_anotados := 0
## Veces que ocurrió cada evento durante la misión.
var _veces := {}
var _observar_restante := 0.0


func _init(contenido_juego: Contenido, id_mision: String) -> void:
	super(contenido_juego, id_mision)
	panel = contenido.leer("planta.json").duplicate(true)
	panel["nota"] = datos["reporte"]["nota"]
	sim = contenido.circuito(panel["circuito"])
	operador = OperadorPlanta.new(sim, panel)
	operador.guardamotor().accionar(true)
	sim.avanzar_tiempo(0.1)
	_aplicar(datos.get("preparar", []))
	sim.paso()
	_eventos_anotados = sim.eventos.size()


# --- Lecturas de la planta: las mismas que OperadorPlanta ---

func planta() -> SimPlantaFrio:
	return operador.planta()


func guardamotor() -> SimGuardamotor:
	return operador.guardamotor()


func en_marcha() -> bool:
	return operador.en_marcha()


func corriente_motor() -> float:
	return operador.corriente_motor()


# --- Mandos de la planta: los mismos que OperadorPlanta ---

func alternar_guardamotor() -> Dictionary:
	if bloqueos.has("Q1"):
		return _aviso("aviso", "Q1 bloqueado", "El guardamotor tiene candado y tarjeta. Termine el trabajo y quite el bloqueo antes de cerrarlo.")
	return _tras_mando(operador.alternar_guardamotor())


## Los pulsadores no devuelven aviso: la pantalla los mantiene mientras el dedo está encima.
func pulsar(id_pulsador: String, presionado: bool) -> Dictionary:
	return operador.pulsar(id_pulsador, presionado)


func rearmar_presostato(id_presostato: String) -> Dictionary:
	return _tras_mando(operador.rearmar_presostato(id_presostato))


func rearmar_rele() -> Dictionary:
	return _tras_mando(operador.rearmar_rele())


func alternar_bomba(nombre: String) -> Dictionary:
	if bloqueos.has(nombre):
		return _aviso("aviso", "Bomba bloqueada", "La bomba tiene candado y tarjeta en su arrancador. Quite el bloqueo cuando termine el trabajo.")
	return _tras_mando(operador.alternar_bomba(nombre))


func alternar_automatico() -> Dictionary:
	return _tras_mando(operador.alternar_automatico())


func capacidad(signo: float) -> Dictionary:
	return _tras_mando(operador.capacidad(signo))


func alternar_ventilacion() -> Dictionary:
	return _tras_mando(operador.alternar_ventilacion())


func _tras_mando(resultado: Dictionary) -> Dictionary:
	_anotar_eventos()
	if fin == "accidente":
		return _aviso("accidente", accidente["titulo"], accidente["que_ocurrio"])
	return resultado


## El termómetro sobre una tubería: queda anotado para el libro con la última lectura.
func medir_tuberia(punto: String) -> void:
	var texto := "%s: %s °C" % [panel["tuberias"][punto], TextoTecnico.numero(planta().temperatura_tuberia(punto), 1)]
	if medidos.has(punto):
		mediciones[medidos[punto]] = texto
	else:
		medidos[punto] = mediciones.size()
		mediciones.append(texto)


# --- Tiempo ---

func avanzar(segundos: float, paso := SimSimulacion.PASO_S) -> void:
	var pasos := maxi(int(ceil(segundos / paso - 1e-6)), 1)
	for _i in pasos:
		if not fin.is_empty():
			return
		sim.paso(paso)
		_vigilar(paso)


func _vigilar(dt: float) -> void:
	_anotar_eventos()
	if not fin.is_empty():
		return
	# Arrancar contra válvulas cerradas comprime el amoníaco atrapado en el tramo aislado.
	if hechos.get("aislado", false) and operador.en_marcha():
		_ocurre_accidente("arranque_aislado", "incidentes")
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


## Disparos, alarmas y aperturas de la válvula de seguridad que ya registró la simulación. Los
## disparos de presostato llevan el punto, como disparo_presostato_descarga.
## En "repetidos", la falta cuenta desde la segunda vez: el primer disparo sirve para ver la avería.
func _anotar_eventos() -> void:
	var eventos := sim.eventos
	var temas: Dictionary = datos.get("eventos", {})
	var repetidos: Dictionary = datos.get("repetidos", {})
	while _eventos_anotados < eventos.size() and fin.is_empty():
		var e: Dictionary = eventos[_eventos_anotados]
		_eventos_anotados += 1
		var tipo: String = e["tipo"]
		if tipo == "disparo_presostato":
			tipo += "_" + str(e["detalle"].get("punto", ""))
		_veces[tipo] = _veces.get(tipo, 0) + 1
		if EVENTOS_INCIDENTE.has(tipo):
			_ocurre_accidente(EVENTOS_INCIDENTE[tipo], "incidentes")
			return
		if not temas.get(tipo, "").is_empty():
			_falta_pendiente(temas[tipo])
		if repetidos.has(tipo) and _veces[tipo] >= 2:
			_falta_pendiente(repetidos[tipo])


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
	var p := planta()
	match c["c"]:
		"en_marcha":
			return operador.en_marcha() and p.compresor_en_marcha()
		"parado":
			return not operador.en_marcha()
		"presion":
			return _entre(p.presion(c["punto"]), c)
		"temperatura":
			return _entre(p.temperatura(c["punto"]), c)
		"planta":
			return _entre(float(p.estado[c["clave"]]), c)
		"estado":
			return sim.componente(c["id"]).estado[c["clave"]] == c["valor"]
		"param":
			return _entre(float(sim.componente(c["id"]).params[c["clave"]]), c)
		"presostatos":
			for id_presostato: String in PRESOSTATOS:
				if not (sim.componente(id_presostato) as SimPresostato).cerrado():
					return false
			return true
		"bomba":
			return p.bomba_en_marcha(c["nombre"])
		"bomba_parada":
			return not p.bomba_en_marcha(c["nombre"])
		"automatico":
			return p.estado["automatico"] == bool(c["valor"])
		"sin_bloqueos":
			return bloqueos.is_empty()
		"marca":
			return hechos.get(c["marca"], false)
		"sin_marca":
			return not hechos.get(c["marca"], false)
		"medido":
			return medidos.has(c["punto"])
	push_error("Condición de misión desconocida: %s" % c["c"])
	return false


func _entre(valor: float, c: Dictionary) -> bool:
	return valor >= float(c.get("min", -INF)) and valor <= float(c.get("max", INF))


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
		avanzar(PASO_OBSERVACION_S, PASO_OBSERVACION_S)
		_observar_restante -= PASO_OBSERVACION_S
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


## Candado y tarjeta en el guardamotor del compresor, abierto y con el compresor parado, o en
## el arrancador de una bomba parada.
func bloquear(id_equipo: String) -> Dictionary:
	if id_equipo == "Q1":
		if operador.en_marcha():
			return _aviso("aviso", "Compresor en marcha", "Pare el compresor con el pulsador de parada antes de bloquear.")
		if guardamotor().cerrado():
			return _aviso("aviso", "Guardamotor cerrado", "Abra el guardamotor Q1 antes de colocar el candado.")
	elif planta().estado[id_equipo]:
		return _aviso("aviso", "Bomba en marcha", "Pare la bomba antes de bloquear su arrancador.")
	var resultado := _aviso("hecho", "", "")
	if not hechos.has("aviso"):
		resultado = _falta("sin_aviso")
		hechos["aviso"] = true
	bloqueos[id_equipo] = true
	verificados.erase(id_equipo)
	return resultado


func desbloquear(id_equipo: String) -> Dictionary:
	bloqueos.erase(id_equipo)
	verificados.erase(id_equipo)
	return _aviso("hecho", "", "")


## Probar, medir, probar: el multímetro se prueba en la alimentación de la planta antes y
## después de medir los bornes del motor entre fases.
func verificar(id_equipo: String) -> Dictionary:
	if not bloqueos.has(id_equipo):
		return _aviso("aviso", "Sin bloqueo", "La verificación solo vale con el equipo bloqueado.")
	if datos.get("verificar_en_sala", false):
		var expuesto := _comprobar_sala()
		if not expuesto.is_empty():
			return expuesto
	var v := tension_equipo(id_equipo)
	if v >= V_PRESENCIA:
		return _aviso("aviso", "Hay tensión: %s V" % TextoTecnico.numero(v, 0), "El equipo sigue energizado. No intervenga: busque de dónde llega esa tensión.")
	verificados[id_equipo] = true
	var nombre := "los bornes del motor del compresor" if id_equipo == "Q1" else "los bornes del motor de la bomba"
	mediciones.append("Ausencia de tensión en %s: 0 V entre fases, multímetro probado antes y después" % nombre)
	return _aviso("hecho", "Ausencia de tensión verificada", "El multímetro marcó 440 V en la alimentación antes y después, y 0 V entre fases en %s." % nombre)


func verificado(id_equipo: String) -> bool:
	return verificados.has(id_equipo)


## La mayor tensión entre fases en los bornes del motor del equipo.
func tension_equipo(id_equipo: String) -> float:
	if id_equipo != "Q1":
		return 440.0 if planta().estado[id_equipo] else 0.0
	if sim.solucion == null:
		sim.paso()
	var m := sim.componente("M1")
	var maxima := 0.0
	for par in [["U1", "V1"], ["V1", "W1"], ["W1", "U1"]]:
		maxima = maxf(maxima, m.tension(sim.solucion, par[0], par[1]))
	return maxima


## Con amoníaco en la sala por encima del aviso, solo se entra con equipo de respiración
## autónomo y acompañado.
func _comprobar_sala() -> Dictionary:
	var p := planta()
	if p.estado["ppm_sala"] < float(p.params["alarma_ppm"]):
		return {}
	if hechos.get("era", false) and hechos.get("companero", false):
		return {}
	return _ocurre_accidente("exposicion_nh3")


# --- Trabajo sobre los equipos ---

func accion(accion_id: String) -> Dictionary:
	for a: Dictionary in datos.get("acciones", []):
		if a["id"] == accion_id:
			return a
	return {}


func ejecutar(accion_id: String) -> Dictionary:
	var a := accion(accion_id)
	if a.get("en_sala", false):
		var expuesto := _comprobar_sala()
		if not expuesto.is_empty():
			return expuesto
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
	# Estados de la planta sin los que la acción no se puede hacer, como una bomba parada.
	for r: Dictionary in a.get("requiere", []):
		if not condicion(r):
			return _aviso("aviso", "Todavía no", r["si_no"])
	if a.get("abre_circuito", false) and not hechos.get("aislado", false):
		return _ocurre_accidente("abrir_con_presion")
	var falta := {}
	for comprobacion: Dictionary in a.get("comprobar", []):
		if not condicion(comprobacion):
			falta = _falta(comprobacion["falta"])
	var texto := _con_lecturas(a["texto"])
	if a.get("medicion", false):
		mediciones.append(texto)
	_aplicar(a.get("efecto", []))
	for marca: String in a.get("pone", []):
		hechos[marca] = true
	for marca: String in a.get("quita", []):
		hechos.erase(marca)
	acciones_hechas.append(accion_id)
	if a.get("innecesaria", false):
		_anotar_falta(a.get("tema", "reparacion_innecesaria"), a["titulo"], texto)
		return _aviso("error", a["titulo"], texto)
	if not falta.is_empty():
		return falta
	return _aviso("hecho", a["titulo"], texto)


func _con_lecturas(texto: String) -> String:
	var p := planta()
	for clave: String in LECTURAS:
		if not texto.contains(clave):
			continue
		var l: Array = LECTURAS[clave]
		var valor: float
		match l[0]:
			"estado":
				valor = p.estado[l[1]]
			"presion":
				valor = p.presion(l[1])
			"temperatura":
				valor = p.temperatura(l[1])
		texto = texto.replace(clave, TextoTecnico.numero(valor, l[2]))
	return texto


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
			"marcha":
				_pulsar_marcha()
			"avanzar":
				# Con pasos de un segundo: la preparación puede durar minutos de planta.
				for _i in int(op["s"]):
					sim.paso(1.0)
			"param":
				sim.componente(op["id"]).params[op["clave"]] = op["valor"]
			"estado":
				sim.componente(op["id"]).estado[op["clave"]] = op["valor"]
			"disparado":
				sim.componente(op["id"]).estado["disparado"] = true
			_:
				push_error("Operación de misión desconocida: %s" % op["op"])


func _pulsar_marcha() -> void:
	operador.pulsar("S1", true)
	sim.avanzar_tiempo(0.3)
	operador.pulsar("S1", false)
	sim.avanzar_tiempo(3.0)
