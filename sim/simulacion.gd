class_name SimSimulacion
extends RefCounted
## Red de componentes y cables. Cada borne es un nodo "ID.BORNE" y "PE" es la tierra.
## paso() resuelve, deja asentar bobinas hasta que nada cambie y luego avanza el tiempo.

const PASO_S := 0.05
const MAX_ASENTADOS := 25

var componentes: Dictionary = {}
var cables: Array = []
var eventos: Array = []
var tiempo := 0.0
var solucion: SimSolver.Solucion
var _con_continua := false


static func tipos() -> Dictionary:
	return {
		"fuente_trifasica": SimFuenteTrifasica,
		"transformador_mando": SimTransformadorMando,
		"guardamotor": SimGuardamotor,
		"fusible": SimFusible,
		"contactor": SimContactor,
		"rele_termico": SimReleTermico,
		"pulsador": SimPulsador,
		"lampara": SimLampara,
		"temporizador": SimTemporizador,
		"resistencia": SimResistencia,
		"motor_trifasico": SimMotorTrifasico,
		"masa": SimMasa,
		"generador": SimGenerador,
		"interruptor_generador": SimInterruptorGenerador,
		"barras": SimBarras,
		"carga_trifasica": SimCargaTrifasica,
		"sincronoscopio": SimSincronoscopio,
		"monitor_aislamiento": SimMonitorAislamiento,
		"pms": SimPMS,
		"planta_frio": SimPlantaFrio,
		"presostato": SimPresostato,
		"interruptor_nivel": SimInterruptorNivel,
		"fuente_dc": SimFuenteDC,
		"diodo": SimDiodo,
		"led": SimLed,
		"puente_rectificador": SimPuenteRectificador,
		"rele_dc": SimReleDC,
		"rele_estado_solido": SimReleEstadoSolido,
		"sensor_proximidad": SimSensorProximidad,
		"transmisor_4_20": SimTransmisor420,
		"pt100": SimPT100,
		"termocupla": SimTermocupla,
		"plc": SimPLC,
		"selector": SimSelector,
		"seta": SimSeta,
		"seccionador": SimSeccionador,
		"horometro": SimHorometro,
	}


static func desde_dict(datos: Dictionary) -> SimSimulacion:
	var s := SimSimulacion.new()
	var clases := tipos()
	for c in datos.get("componentes", []):
		var clase: GDScript = clases[c["tipo"]]
		s.agregar(clase.new(c["id"], c.get("params", {}), c.get("estado", {})))
	for cable in datos.get("cables", []):
		s.conectar(cable[0], cable[1])
	return s


func a_dict() -> Dictionary:
	var lista := []
	for c: SimComponente in componentes.values():
		lista.append({"id": c.id, "tipo": c.tipo(), "params": c.params, "estado": c.estado})
	return {"componentes": lista, "cables": cables.duplicate(true)}


func agregar(c: SimComponente) -> SimComponente:
	c.sim_ref = weakref(self)
	componentes[c.id] = c
	if c.usa_continua():
		_con_continua = true
	return c


## True si algún componente trabaja en continua: entonces cada resolución calcula también
## el punto de trabajo en continua. Los circuitos de solo alterna no pagan ese cálculo.
func con_continua() -> bool:
	return _con_continua


func conectar(a: String, b: String) -> void:
	cables.append([a, b])


func desconectar(a: String, b: String) -> void:
	cables = cables.filter(func(c: Array) -> bool:
		return not ((c[0] == a and c[1] == b) or (c[0] == b and c[1] == a)))


func componente(id: String) -> SimComponente:
	return componentes[id]


func registrar_evento(tipo: String, id: String, detalle := {}) -> void:
	eventos.append({"tipo": tipo, "componente": id, "t": tiempo, "detalle": detalle})


func hubo_evento(tipo: String, id := "") -> bool:
	for e in eventos:
		if e["tipo"] == tipo and (id.is_empty() or e["componente"] == id):
			return true
	return false


## Resuelve la red con su estado actual. extra añade elementos, como un instrumento. Los cables
## de excluir (índices) no se unen: así extra puede ponerles una impedancia y medir su corriente.
func resolver(dc := false, extra := Callable(), excluir: Array = []) -> SimSolver.Solucion:
	return _resolver(SimEstampa.new(dc), extra, excluir)


## Punto de trabajo en continua: las fuentes de continua inyectan y las de alterna no.
func resolver_continua(extra := Callable(), excluir: Array = []) -> SimSolver.Solucion:
	return _resolver(SimEstampa.new(true, true), extra, excluir)


## La alterna y, si hay electrónica, la continua en solucion.dc.
func resolver_completa() -> SimSolver.Solucion:
	var sol := resolver()
	if _con_continua:
		sol.dc = resolver_continua()
	return sol


func _resolver(e: SimEstampa, extra: Callable, excluir: Array) -> SimSolver.Solucion:
	for i in cables.size():
		if not excluir.has(i):
			e.enlace(cables[i][0], cables[i][1])
	for c: SimComponente in componentes.values():
		c.estampar(e)
	if extra.is_valid():
		extra.call(e)
	return SimSolver.resolver(e)


## Divide el paso si algún componente, como un generador, necesita pasos más cortos.
func paso(dt := PASO_S) -> void:
	var limite := INF
	for c: SimComponente in componentes.values():
		limite = minf(limite, c.paso_maximo())
	var partes := maxi(int(ceil(dt / limite - 1e-6)), 1)
	for _i in partes:
		_paso(dt / partes)


## Momento del último evento de un tipo, o -1 si no ocurrió.
func tiempo_ultimo(tipo: String) -> float:
	for i in range(eventos.size() - 1, -1, -1):
		if eventos[i]["tipo"] == tipo:
			return eventos[i]["t"]
	return -1.0


func _paso(dt: float) -> void:
	_asentar()
	for c: SimComponente in componentes.values():
		c.avanzar(dt, solucion)
	tiempo += dt
	_asentar()


func avanzar_tiempo(segundos: float) -> void:
	var pasos := int(ceil(segundos / PASO_S))
	for _i in pasos:
		paso()


func _asentar() -> void:
	for _i in MAX_ASENTADOS:
		solucion = resolver_completa()
		var cambio := false
		for c: SimComponente in componentes.values():
			if c.asentar(solucion):
				cambio = true
		if not cambio:
			return
	registrar_evento("vibracion_mando", "", {})
