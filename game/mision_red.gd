class_name MisionRed
extends MisionBase
## Una misión de Guardia en la red Modbus del puesto de alarmas o en la pantalla local de un
## equipo. El jugador usa los mismos paneles que en el Taller (puesto, red RS-485, pantalla
## MYCOM): la pantalla avisa a la misión de cada acción con registrar(), y la misión anota lo
## que se ha comprobado, las faltas y la prueba en servicio. Ofrece los métodos de
## procedimiento que usa PanelMision.

const PASO_OBSERVACION_S := 0.5
const TEXTOS_ESTADO := {"ok": "comunica", "intermitente": "errores intermitentes", "falla": "sin comunicación"}

var red: SimRedModbus
var puesto: SimSistemaAlarmas
var hmi: SimPantallaHMI
var bloqueos := {}
var verificados := {}
var mediciones: Array[String] = []
var avisos_pendientes: Array[Dictionary] = []
var objetivos_s := 0.0
var _observar_restante := 0.0
var _observar_total := 0.0


func _init(contenido_juego: Contenido, id_mision: String) -> void:
	super(contenido_juego, id_mision)
	red = contenido.red(datos.get("red", "sala_maquinas"))
	puesto = SimSistemaAlarmas.desde_red(red)
	hmi = SimPantallaHMI.new(red)
	_aplicar(datos.get("preparar", []))
	# La misión empieza con la avería ya presente: el puesto ya ha dado sus alarmas.
	for _i in int(float(datos.get("preparar_s", 20.0)) / PASO_OBSERVACION_S):
		_paso(PASO_OBSERVACION_S)


# --- Tiempo ---

func _paso(dt: float) -> void:
	red.avanzar(dt)
	puesto.actualizar(dt)
	hmi.avanzar(dt)


func avanzar(segundos: float) -> void:
	if not fin.is_empty():
		return
	_paso(segundos)
	_vigilar(segundos)


func _vigilar(dt: float) -> void:
	if prueba_ok:
		return
	if objetivos_cumplidos():
		objetivos_s += dt
		if objetivos_s >= tiempo_de_prueba():
			prueba_ok = true
			avisos_pendientes.append(_aviso("hecho", "Prueba superada", datos["prueba"]["superada"]))
	else:
		objetivos_s = 0.0


# --- Lo que hace el jugador en los paneles ---

## La pantalla avisa de cada acción: ver una pestaña, seleccionar un equipo, medir, cambiar
## un ajuste, reconocer alarmas...
func registrar(accion_jugador: String, detalle := {}) -> void:
	if not fin.is_empty():
		return
	match accion_jugador:
		"pestana":
			var p: String = detalle["pestana"]
			if p == "red" and not hechos.has("vio_diagnostico"):
				hechos["vio_diagnostico"] = true
				mediciones.append("Diagnóstico del maestro: %s" % _resumen_diagnostico())
			hechos["vio_" + p] = true
		"pagina_hmi":
			hechos["vio_hmi_" + String(detalle["pagina"])] = true
		"seleccionar":
			hechos["menu_" + String(detalle["equipo"])] = true
		"medir_ab":
			hechos["midio_ab"] = true
			mediciones.append("Resistencia entre A y B en el conector del maestro, con la red sin alimentación: %s" % _texto_ohmios(detalle["ohmios"]))
		"ajuste":
			_revisar_ajuste(detalle)
		"ajuste_hmi":
			_revisar_ajuste_hmi(detalle)
		"empalmar":
			hechos["empalmado"] = true
		_:
			hechos[accion_jugador] = true


func _texto_ohmios(r: float) -> String:
	return "OL" if r > 2000.0 else "%s Ω" % TextoTecnico.numero(r, 0)


func _resumen_diagnostico() -> String:
	var partes: Array[String] = []
	for s: Dictionary in red.sondeo:
		var d: Dictionary = s["datos"]
		if s["estado"] != "ok" or int(s["crc"]) > 0:
			partes.append("dir. %d %s (sin respuesta %d, CRC %d, excepción %d)" % [int(d["direccion"]), TEXTOS_ESTADO[s["estado"]], s["sin_respuesta"], s["crc"], s["excepciones"]])
	return "todas las direcciones comunican" if partes.is_empty() else "; ".join(partes)


## Cambiar los ajustes de comunicación de un equipo que comunicaba bien es tocar lo que no
## estaba averiado: puede dejarlo sin comunicación a él o a toda la red.
func _revisar_ajuste(detalle: Dictionary) -> void:
	var equipo: String = detalle["equipo"]
	var bien := false
	if equipo == red.maestro["id"]:
		for s: Dictionary in red.sondeo:
			if s["estado"] == "ok":
				bien = true
	else:
		bien = red.estado_de(equipo).get("estado", "") == "ok" and red.indice_esclavo(equipo) >= 0
	if bien and not datos.get("ajustes_libres", []).has(equipo):
		_falta_pendiente("ajuste_red_innecesario")
	hechos["ajusto_" + equipo] = true


func _revisar_ajuste_hmi(detalle: Dictionary) -> void:
	hechos["ajusto_hmi_" + String(detalle["id"])] = true
	# Mover un límite hacia el lado inseguro: subir una alarma de alta o bajar una de baja.
	var a := hmi.ajuste(detalle["id"])
	var pasos := int(detalle.get("pasos", 0))
	if (a["tipo"] == "alta" and pasos > 0) or (a["tipo"] == "baja" and pasos < 0):
		_falta_pendiente("limite_alarma_alterado")


func _falta_pendiente(tema: String) -> void:
	var antes := faltas.size()
	var a := _falta(tema)
	if faltas.size() > antes:
		avisos_pendientes.append(a)


# --- Procedimiento ---

func bloqueables() -> Array:
	return []


func bloqueado(id_equipo: String) -> bool:
	return bloqueos.has(id_equipo)


func verificado(id_equipo: String) -> bool:
	return verificados.has(id_equipo)


func dar_paso(paso_id: String) -> Dictionary:
	for p: Dictionary in datos.get("pasos", []):
		if p["id"] == paso_id:
			for marca: String in p.get("pone", []):
				hechos[marca] = true
			return _aviso("hecho", p.get("titulo", "Hecho"), p.get("texto", p["boton"]))
	return {}


func paso_hecho(paso_id: String) -> bool:
	for p: Dictionary in datos.get("pasos", []):
		if p["id"] == paso_id:
			for marca: String in p.get("pone", []):
				if not hechos.get(marca, false):
					return false
			return true
	return false


func evidencias_completas() -> bool:
	for e: Dictionary in datos.get("evidencias", []):
		if e.has("accion") and not acciones_hechas.has(e["accion"]):
			return false
		if e.has("hecho") and not hechos.get(e["hecho"], false):
			return false
		if e.has("alguno"):
			var alguno := false
			for h: String in e["alguno"]:
				if hechos.get(h, false):
					alguno = true
			if not alguno:
				return false
	return true


# --- Trabajo ---

func accion(accion_id: String) -> Dictionary:
	for a: Dictionary in datos.get("acciones", []):
		if a["id"] == accion_id:
			return a
	return {}


func ejecutar(accion_id: String) -> Dictionary:
	var a := accion(accion_id)
	for marca: String in a.get("necesita", []):
		if not hechos.get(marca, false):
			return _aviso("aviso", "Todavía no", a.get("si_falta", "Falta un paso previo."))
	var texto: String = a["texto"]
	if a.get("medicion", false):
		mediciones.append(texto)
	_aplicar(a.get("efecto", []))
	for marca: String in a.get("pone", []):
		hechos[marca] = true
	acciones_hechas.append(accion_id)
	if a.get("innecesaria", false):
		_anotar_falta(a.get("tema", "reparacion_innecesaria"), a["titulo"], texto)
		return _aviso("error", a["titulo"], texto)
	return _aviso("hecho", a["titulo"], texto)


## Preparación y efectos: operaciones de la red (SimRedModbus.aplicar) y de la pantalla local.
func _aplicar(operaciones: Array) -> void:
	for op: Dictionary in operaciones:
		match op["op"]:
			"ajuste_hmi":
				var a := hmi.ajuste(op["id"])
				a["valor"] = float(op["valor"])
				hmi.alarmas.punto(op["id"])["limite"] = float(op["valor"])
			"reconocer":
				puesto.reconocer()
				hmi.alarmas.reconocer()
			_:
				red.aplicar(op)


# --- Prueba en servicio ---

func objetivos() -> Array:
	return datos["prueba"]["objetivos"]


func objetivos_cumplidos() -> bool:
	for c: Dictionary in objetivos():
		if not condicion(c):
			return false
	return true


func tiempo_de_prueba() -> float:
	return float(datos["prueba"]["mantener_s"])


func condicion(c: Dictionary) -> bool:
	match c["c"]:
		"comunica":
			var s := red.estado_de(c["esperado"])
			return s.get("estado", "") == "ok" and s.get("ultimo", "") == "ok"
		"todos_comunican":
			for s: Dictionary in red.sondeo:
				if s["estado"] != "ok":
					return false
			return true
		"terminadores":
			return red.extremos_terminados() and red.terminadores() == 2
		"valor":
			var v := red.valor_local(c["equipo"], int(c["registro"]))
			return not is_nan(v) and v >= float(c.get("min", -1e9)) and v <= float(c.get("max", 1e9))
		"sin_sin_reconocer":
			return puesto.sin_reconocer() == 0
		"ajuste_hmi":
			return is_equal_approx(float(hmi.ajuste(c["id"])["valor"]), float(c["valor"]))
		"sesion_cerrada":
			return not hmi.nivel_tecnico
		"hmi_comunica":
			return hmi.comunica()
		"marca":
			return hechos.get(c["marca"], false)
		"sin_marca":
			return not hechos.get(c["marca"], false)
		_:
			push_error("Condición de misión de red desconocida: %s" % c["c"])
			return false


func observando() -> bool:
	return _observar_restante > 0.0


func avance_observacion() -> float:
	return 1.0 - _observar_restante / _observar_total if _observar_total > 0.0 else 0.0


## Antes de observar, los pasos que el procedimiento exige haber dado.
func observar(segundos: float) -> void:
	for r: Dictionary in datos.get("pasos_requeridos", []):
		if not hechos.get(r["marca"], false):
			_falta_pendiente(r["falta"])
	_observar_total = segundos
	_observar_restante = segundos
	objetivos_s = 0.0


## Avanza dentro del límite de tiempo real. Al terminar devuelve el aviso; antes, {}.
func procesar_observacion(limite_ms: int) -> Dictionary:
	var inicio := Time.get_ticks_msec()
	while _observar_restante > 0.0 and Time.get_ticks_msec() - inicio < limite_ms:
		avanzar(PASO_OBSERVACION_S)
		_observar_restante -= PASO_OBSERVACION_S
		if prueba_ok:
			_observar_restante = 0.0
			return avisos_pendientes.pop_back()
	if _observar_restante > 0.0:
		return {}
	_observar_restante = 0.0
	var pendientes: Array[String] = []
	for c: Dictionary in objetivos():
		if not condicion(c):
			pendientes.append(c["texto"])
	_falta("prueba_fallida")
	return _aviso("error", "Prueba no superada", "No se mantuvieron todas las condiciones. Pendiente: %s." % ", ".join(pendientes))
