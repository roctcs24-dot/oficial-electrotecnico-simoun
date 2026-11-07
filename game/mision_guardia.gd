class_name MisionGuardia
extends MisionBase
## Una avería de guardia sobre un circuito simulado: las lecturas, los disparos y los daños
## salen del motor de simulación. No depende de la interfaz, así se puede probar sin pantalla.

## Por encima de este valor se considera que hay tensión. Criterio del juego: verificar a bordo.
const V_PRESENCIA := 30.0
const MARGEN_CORRIENTE := 1.05
const MINIMO_MONITOR_MOHM := 1.0
## El arranque se simula con el paso normal; después se puede avanzar más rápido sin perder
## exactitud, porque el motor integra su velocidad con un paso propio.
const OBSERVACION_LENTA_S := 5.0
const PASO_RAPIDO_S := 1.0
const EXTENSION_SIN_PROTECCION_S := 1800.0
const CLAVES_DANO := ["quemado", "soldado", "bobina_quemada", "fundido", "quemada"]

var mesa: MesaTaller
var candados := {}
var mediciones: Array[Dictionary] = []
var hubo_bloqueo := false
var observando_total := 0.0
var _verificacion := {}
var _orden_verificacion := 0
var _observar_restante := 0.0
var _observacion_inicio := 0.0
var _extendida := false
var _eventos_anotados := 0


func _init(contenido_juego: Contenido, id_mision: String, danos_previos := {}) -> void:
	super(contenido_juego, id_mision)
	mesa = MesaTaller.new(contenido)
	if datos.has("tablero"):
		# La misión ocurre en un tablero del buque: su circuito y su interior salen de él.
		var t := contenido.tablero(datos["tablero"])
		mesa.cargar_circuito(contenido.leer("circuitos/%s.json" % t["circuito"]), t["interior"])
	else:
		mesa.cargar_circuito(datos["circuito"], datos["posiciones"])
	# Averías y estados con que empieza la misión: {"id": {"param": valor}}.
	for id: String in datos.get("params_iniciales", {}):
		mesa.sim.componente(id).params.merge(datos["params_iniciales"][id], true)
	for id: String in datos.get("estado_inicial", {}):
		mesa.sim.componente(id).estado.merge(datos["estado_inicial"][id], true)
	for oculta: String in datos.get("averias_ocultas", []):
		mesa.ocultas[oculta] = true
	for pieza: String in danos_previos:
		if mesa.piezas.has(pieza):
			mesa.sim.componente(pieza).estado.merge(danos_previos[pieza], true)
	mesa.avanzar(1)


# --- Lecturas del panel ---

func motor() -> SimMotorTrifasico:
	return mesa.sim.componente(datos["prueba"]["motor"])


func rele() -> SimReleTermico:
	return mesa.sim.componente(datos["prueba"]["rele"])


func contactor() -> SimContactor:
	return mesa.sim.componente(datos["prueba"]["contactor"])


func corrientes() -> Array:
	var r := rele()
	return [r.corriente(mesa.sim.solucion, 0), r.corriente(mesa.sim.solucion, 1), r.corriente(mesa.sim.solucion, 2)]


func corriente_maxima() -> float:
	var maxima := 0.0
	for i: float in corrientes():
		maxima = maxf(maxima, i)
	return maxima


func i_nominal() -> float:
	return float(motor().params["i_delta"])


func tiene_monitor() -> bool:
	return datos.has("monitor")


## El monitor ve el aislamiento del motor solo mientras está conectado a las barras.
func monitor_mohm() -> float:
	var m: Dictionary = datos.get("monitor", {})
	var resto := float(m.get("resto_mohm", 25.0))
	if not contactor().cerrado():
		return resto
	var minimo := resto
	for r: float in motor().params["aislamiento_mohm"]:
		minimo = minf(minimo, r)
	return minimo


# --- Aislamiento y bloqueo ---

## Los guardamotores del circuito, o los que fije la misión con "aisladores": un guardamotor, un
## interruptor general (seccionador) o la alimentación desde el cuadro (fuente_trifasica).
func aisladores() -> Array[String]:
	var lista: Array[String] = []
	if datos.has("aisladores"):
		lista.assign(datos["aisladores"])
		return lista
	for c: SimComponente in mesa.sim.componentes.values():
		if c.tipo() == "guardamotor":
			lista.append(c.id)
	return lista


func aislador_cerrado(pieza: String) -> bool:
	var c := mesa.sim.componente(pieza)
	match c.tipo():
		"seccionador":
			return c.estado["cerrado"]
		"fuente_trifasica":
			return c.estado["activa"]
	return c.estado["encendido"]


func tiene_candado(pieza: String) -> bool:
	return candados.has(pieza)


func bloqueado() -> bool:
	for a in aisladores():
		if not candados.has(a):
			return false
	return true


func colocar_epp() -> void:
	hechos["epp"] = true


func dar_aviso() -> void:
	hechos["aviso"] = true


func avisar_energizado() -> void:
	hechos["aviso_energizar"] = true


func accionar_aislador(pieza: String, cerrar: bool) -> Dictionary:
	if candados.has(pieza):
		return _aviso("aviso", "Aislador bloqueado", "No se puede accionar %s con el candado colocado." % pieza)
	var c := mesa.sim.componente(pieza)
	var resultado := _aviso("hecho", "", "")
	if cerrar:
		if hubo_bloqueo and not hechos.has("aviso_energizar"):
			resultado = _falta("energizar_sin_aviso")
	elif contactor().cerrado() and absf(motor().rpm()) > 5.0:
		resultado = _falta("abrir_con_carga")
	match c.tipo():
		"seccionador":
			(c as SimSeccionador).accionar(cerrar)
		"fuente_trifasica":
			c.estado["activa"] = cerrar
		_:
			(c as SimGuardamotor).accionar(cerrar)
	_reiniciar_verificacion()
	return resultado


func poner_candado(pieza: String) -> Dictionary:
	if aislador_cerrado(pieza):
		return _aviso("aviso", "Aislador cerrado", "Abra %s antes de colocar el candado." % pieza)
	var resultado := _aviso("hecho", "", "")
	if not hechos.has("aviso"):
		resultado = _falta("sin_aviso")
		hechos["aviso"] = true
	candados[pieza] = true
	if mesa.sim.componente(pieza) is SimSeccionador:
		mesa.sim.componente(pieza).estado["candado"] = true
	hubo_bloqueo = true
	hechos.erase("aviso_energizar")
	_reiniciar_verificacion()
	return resultado


func quitar_candado(pieza: String) -> Dictionary:
	if hechos.get("bornera_abierta", false):
		return _falta("bornera_abierta")
	var resultado := _aviso("hecho", "", "")
	if not _remediciones_hechas():
		resultado = _falta("sin_remedir")
	candados.erase(pieza)
	if mesa.sim.componente(pieza) is SimSeccionador:
		mesa.sim.componente(pieza).estado["candado"] = false
	_reiniciar_verificacion()
	return resultado


# --- Verificación de ausencia de tensión ---

## Probar, medir, probar: en la fuente conocida, en cada punto y de nuevo en la fuente.
func pasos_verificacion() -> Array[Dictionary]:
	var aislamiento: Dictionary = datos["verificacion"]
	var fuente: Array = aislamiento["fuente_conocida"]
	var pasos: Array[Dictionary] = [{"id": "antes", "texto": "Probar el instrumento en la fuente conocida", "a": fuente[0], "b": fuente[1]}]
	for p: Dictionary in aislamiento["puntos"]:
		pasos.append({"id": p["a"] + "|" + p["b"], "texto": p["texto"], "a": p["a"], "b": p["b"]})
	pasos.append({"id": "despues", "texto": "Probar de nuevo en la fuente conocida", "a": fuente[0], "b": fuente[1]})
	return pasos


func lectura_verificacion(paso_id: String) -> Dictionary:
	return _verificacion.get(paso_id, {})


func verificar(paso: Dictionary, multimetro: SimMultimetro) -> Dictionary:
	var r := multimetro.medir(mesa.sim, "vac", paso["a"], paso["b"])
	var valor: float = r["valor"]
	var es_fuente: bool = paso["id"] == "antes" or paso["id"] == "despues"
	_orden_verificacion += 1
	_verificacion[paso["id"]] = {"valor": valor, "orden": _orden_verificacion}
	registrar_medicion("multimetro", "vac", paso["a"], paso["b"], r)
	if not r["averia"].is_empty():
		return _aviso("aviso", "Instrumento averiado", "El multímetro no puede medir. Cámbielo antes de continuar.")
	if es_fuente and valor < V_PRESENCIA:
		return _aviso("aviso", "El instrumento no indica tensión", "En la fuente conocida debe leer tensión. Sin esa comprobación, un 0 V no demuestra nada: cambie el instrumento.")
	if not es_fuente and valor >= V_PRESENCIA:
		return _aviso("aviso", "Hay tensión: %s V" % TextoTecnico.numero(valor, 0), "El punto sigue energizado. No intervenga: busque de dónde llega esa tensión, abra esa alimentación y bloquéela.")
	return _aviso("hecho", "", "")


## Solo vale después del bloqueo, con todos los puntos sin tensión y el instrumento probado
## antes y después.
func verificado() -> bool:
	if not bloqueado():
		return false
	var antes := lectura_verificacion("antes")
	var despues := lectura_verificacion("despues")
	if antes.is_empty() or despues.is_empty() or antes["valor"] < V_PRESENCIA or despues["valor"] < V_PRESENCIA:
		return false
	for p in pasos_verificacion():
		if p["id"] == "antes" or p["id"] == "despues":
			continue
		var l := lectura_verificacion(p["id"])
		if l.is_empty() or l["valor"] >= V_PRESENCIA or l["orden"] < antes["orden"] or l["orden"] > despues["orden"]:
			return false
	return true


func _reiniciar_verificacion() -> void:
	_verificacion = {}


# --- Mediciones y evidencias ---

func registrar_medicion(instrumento: String, modo: String, a: String, b: String, r: Dictionary) -> void:
	if not r.get("averia", "").is_empty():
		return
	var nueva := {
		"instrumento": instrumento, "modo": modo, "a": a, "b": b, "resultado": r,
		"bloqueado": bloqueado(), "tras_acciones": acciones_hechas.size(),
	}
	var ultima: Dictionary = mediciones.back() if not mediciones.is_empty() else {}
	if not ultima.is_empty() and ultima["instrumento"] == instrumento and ultima["modo"] == modo \
			and ultima["a"] == a and ultima["b"] == b and ultima["tras_acciones"] == nueva["tras_acciones"]:
		mediciones[-1] = nueva
	else:
		mediciones.append(nueva)
	if instrumento == "multimetro" and modo == "vac":
		if float(r["valor"]) >= V_PRESENCIA and not hechos.has("epp"):
			_falta("sin_epp")
	elif instrumento == "pinza":
		# La pinza no toca el conductor, pero se usa con el tablero abierto y en tensión.
		if float(r["valor"]) > 0.0 and not hechos.has("epp"):
			_falta("sin_epp")
	elif (instrumento == "megohmetro" or modo in ["ohm", "continuidad", "diodo"]) and not bloqueado():
		_falta("medir_sin_bloqueo")


func _cumplida(e: Dictionary) -> bool:
	if e.has("accion"):
		return acciones_hechas.has(e["accion"])
	var desde := 0
	if e.has("despues_de"):
		desde = acciones_hechas.find(e["despues_de"]) + 1
		if desde == 0:
			return false
	for m: Dictionary in mediciones:
		if m["instrumento"] != e["instrumento"] or m["tras_acciones"] < desde:
			continue
		if e.has("modos") and not e["modos"].has(m["modo"]):
			continue
		if (m["a"] == e["a"] and m["b"] == e["b"]) or (m["a"] == e["b"] and m["b"] == e["a"]):
			return true
	return false


func evidencias_completas() -> bool:
	for e: Dictionary in datos["evidencias"]:
		if not _cumplida(e):
			return false
	return true


## Las mediciones que deben repetirse después de la reparación.
func _remediciones_hechas() -> bool:
	for e: Dictionary in datos.get("remediciones", []):
		if acciones_hechas.has(e["despues_de"]) and not _cumplida(e):
			return false
	return true


## Disparos y daños a los instrumentos, ya registrados por la simulación.
func anotar_eventos() -> void:
	var eventos := mesa.sim.eventos
	for i in range(_eventos_anotados, eventos.size()):
		match eventos[i]["tipo"]:
			"multimetro_destruido", "megohmetro_destruido":
				_falta("instrumento_destruido")
			"fusible_multimetro":
				_falta("fusible_instrumento")
	_eventos_anotados = eventos.size()


# --- Trabajo sobre el equipo ---

func accion(accion_id: String) -> Dictionary:
	for a: Dictionary in datos["acciones"]:
		if a["id"] == accion_id:
			return a
	return {}


func ejecutar(accion_id: String) -> Dictionary:
	var a := accion(accion_id)
	var peligro := _comprobar_seguridad()
	if not peligro.is_empty():
		return peligro
	for marca: String in a.get("necesita", []):
		if not hechos.get(marca, false):
			return _aviso("aviso", "Todavía no", a.get("si_falta", "Falta un paso previo."))
	for marca: String in a.get("impide", []):
		if hechos.get(marca, false):
			return _aviso("aviso", "Ya está hecho", a.get("si_impide", "Este paso ya se realizó."))
	_aplicar(a.get("efecto", []))
	for marca: String in a.get("pone", {}):
		hechos[marca] = a["pone"][marca]
	acciones_hechas.append(accion_id)
	if a.get("innecesaria", false):
		_anotar_falta(a.get("tema", "reparacion_innecesaria"), a["titulo"], a["texto"])
		return _aviso("error", a["titulo"], a["texto"])
	return _aviso("hecho", a["titulo"], a["texto"])


func cambiar_repuesto(pieza: String) -> Dictionary:
	var peligro := _comprobar_seguridad()
	if not peligro.is_empty():
		return peligro
	mesa.reparar(pieza)
	mesa.ocultas.erase(pieza)
	acciones_hechas.append("repuesto_" + pieza)
	return _aviso("hecho", "Repuesto colocado", "%s quedó sustituido. Antes de energizar, resuelva la causa del daño." % pieza)


func _comprobar_seguridad() -> Dictionary:
	if not bloqueado():
		return _ocurre_accidente("sin_bloqueo")
	if not verificado():
		return _ocurre_accidente("sin_verificar")
	return {}


func _aplicar(efectos: Array) -> void:
	for ef: Dictionary in efectos:
		match ef["op"]:
			"param":
				mesa.sim.componente(ef["id"]).params[ef["clave"]] = ef["valor"]
			"reemplazar":
				mesa.reparar(ef["id"])
				mesa.ocultas.erase(ef["id"])
			"desconectar":
				for c: Array in ef["cables"]:
					mesa.sim.desconectar(c[0], c[1])
			"conectar":
				for c: Array in ef["cables"]:
					mesa.sim.conectar(c[0], c[1])
			_:
				push_error("Efecto de misión desconocido: %s" % ef["op"])


# --- Prueba en servicio ---

func observando() -> bool:
	return _observar_restante > 0.0


func avance_observacion() -> float:
	return 1.0 - _observar_restante / observando_total if observando_total > 0.0 else 1.0


func observar(segundos: float) -> void:
	_observar_restante = segundos
	observando_total = segundos
	_observacion_inicio = mesa.sim.tiempo
	_extendida = false


func tiempo_de_prueba() -> float:
	return float(datos["prueba"]["observar_s"])


## Avanza dentro del límite de tiempo real. Al terminar devuelve el aviso; antes, {}.
func procesar_observacion(limite_ms: int) -> Dictionary:
	var inicio := Time.get_ticks_msec()
	var estaba_en_marcha := _en_marcha()
	while _observar_restante > 0.0 and Time.get_ticks_msec() - inicio < limite_ms:
		var dt := SimSimulacion.PASO_S if mesa.sim.tiempo - _observacion_inicio < OBSERVACION_LENTA_S else PASO_RAPIDO_S
		mesa.sim.paso(dt)
		_observar_restante -= dt
		if estaba_en_marcha and not _en_marcha():
			_observar_restante = 0.0
	if _observar_restante > 0.0:
		return {}
	_observar_restante = 0.0
	return _al_terminar_observacion()


func _en_marcha() -> bool:
	return contactor().cerrado() and absf(motor().rpm()) > 5.0


func _al_terminar_observacion() -> Dictionary:
	var transcurrido := mesa.sim.tiempo - _observacion_inicio
	var motivo := _motivo_prueba_fallida()
	if motivo.is_empty() and transcurrido >= tiempo_de_prueba() - 0.01:
		prueba_ok = true
		return _aviso("hecho", "Prueba superada", "El equipo funcionó %s sin disparos, con corriente por debajo de la nominal." % _minutos(transcurrido))
	if motivo.is_empty():
		return _aviso("aviso", "Observación terminada", "Transcurrieron %s sin disparos. Para dar por buena la prueba, observe %s de una vez." % [_minutos(transcurrido), _minutos(tiempo_de_prueba())])
	# Con el relé fuera de su ajuste, nada corta la sobrecarga: el motor se calienta hasta el daño.
	if not _extendida and float(rele().params["ajuste_a"]) > i_nominal() * MARGEN_CORRIENTE and _en_marcha() and corriente_maxima() > i_nominal() * MARGEN_CORRIENTE:
		_extendida = true
		_falta("ajuste_alterado")
		_observar_restante = EXTENSION_SIN_PROTECCION_S
		observando_total = EXTENSION_SIN_PROTECCION_S
		return {}
	if hubo_bloqueo:
		_falta("prueba_fallida")
	return _aviso("aviso", "Sigue la avería", "%s, tras %s." % [motivo, _minutos(transcurrido)])


## "" si el equipo se comporta bien ahora mismo; si no, lo que se observa.
func _motivo_prueba_fallida() -> String:
	var p: Dictionary = datos["prueba"]
	if motor().quemado():
		return "El motor está quemado"
	if rele().estado["disparado"]:
		return "El relé térmico disparó"
	if not contactor().cerrado():
		return "El contactor no está cerrado"
	if absf(motor().rpm()) < float(p["rpm_min"]):
		return "El motor no alcanza su velocidad"
	if corriente_maxima() > i_nominal() * MARGEN_CORRIENTE:
		return "La corriente supera la nominal"
	if float(rele().params["ajuste_a"]) > i_nominal() * MARGEN_CORRIENTE:
		return "El ajuste del relé supera la corriente de la placa"
	if tiene_monitor() and monitor_mohm() < MINIMO_MONITOR_MOHM:
		return "El monitor de aislamiento sigue en alarma"
	return ""


func _minutos(segundos: float) -> String:
	var total := roundi(segundos)
	return "%d min %02d s" % [total / 60, total % 60]


# --- Resultado ---

## Piezas dañadas al terminar: quedan así hasta que se cambie el repuesto.
func danos() -> Dictionary:
	var resultado := {}
	for pieza: String in mesa.piezas:
		var estado: Dictionary = mesa.sim.componente(pieza).estado
		for clave: String in CLAVES_DANO:
			if estado.get(clave, false):
				if not resultado.has(pieza):
					resultado[pieza] = {}
				resultado[pieza][clave] = true
	return resultado
