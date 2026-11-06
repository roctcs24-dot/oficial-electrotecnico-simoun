class_name OperadorCuadro
extends RefCounted
## Mandos del cuadro principal sobre la simulación, sin interfaz. Cada orden devuelve un aviso
## {tipo, titulo, texto}: con el título vacío no hay nada que explicar. Las misiones del cuadro
## ofrecen los mismos métodos y comprueban el procedimiento antes de pasar la orden.

var sim: SimSimulacion
## cuadro.json: generadores con su interruptor, salidas y pasos de los mandos.
var datos: Dictionary


func _init(simulacion: SimSimulacion, datos_cuadro: Dictionary) -> void:
	sim = simulacion
	datos = datos_cuadro


func generador(id: String) -> SimGenerador:
	return sim.componente(id)


func interruptor_de(id: String) -> SimInterruptorGenerador:
	for g: Dictionary in datos["generadores"]:
		if g["id"] == id:
			return sim.componente(g["interruptor"])
	return null


func carga(id: String) -> SimCargaTrifasica:
	return sim.componente(id)


func pms() -> SimPMS:
	return sim.componente("PMS")


func alternar_diesel(id: String) -> Dictionary:
	var g := generador(id)
	if g.en_marcha():
		g.parar()
		return _aviso("hecho", "", "")
	var motivo := g.arrancar()
	return _aviso("aviso", "No arranca", motivo) if not motivo.is_empty() else _aviso("hecho", "", "")


func alternar_interruptor(id: String) -> Dictionary:
	var q := interruptor_de(id)
	if q.cerrado():
		q.abrir()
		return _aviso("hecho", "", "")
	var motivo := q.cerrar()
	return _aviso("aviso", "No cierra", motivo) if not motivo.is_empty() else _aviso("hecho", "", "")


func velocidad(id: String, signo: float) -> Dictionary:
	generador(id).ajustar_velocidad(signo * datos["paso_velocidad_hz"])
	return _aviso("hecho", "", "")


func tension(id: String, signo: float) -> Dictionary:
	generador(id).ajustar_tension(signo * datos["paso_tension_v"])
	return _aviso("hecho", "", "")


func rearmar(id: String) -> Dictionary:
	interruptor_de(id).rearmar()
	return _aviso("hecho", "", "")


func reparar(id: String) -> Dictionary:
	generador(id).estado["danado"] = false
	return _aviso("hecho", "", "")


func alternar_carga(id: String) -> Dictionary:
	var c := carga(id)
	if c.estado["conectada"]:
		c.desconectar()
	elif c.estado["bloqueada"]:
		return _aviso("aviso", "Salida bloqueada", "%s tiene candado y tarjeta. Quite el bloqueo antes de conectarla." % id)
	else:
		c.conectar()
	return _aviso("hecho", "", "")


func sincronizar(id: String) -> Dictionary:
	var motivo := pms().sincronizar(id)
	return _aviso("aviso", "No se puede sincronizar", motivo) if not motivo.is_empty() else _aviso("hecho", "", "")


func cancelar_sincronizacion() -> Dictionary:
	pms().cancelar_sincronizacion()
	return _aviso("hecho", "", "")


func alternar_pms() -> Dictionary:
	pms().fijar_automatico(not pms().automatico())
	return _aviso("hecho", "", "")


## Tensión entre L1 y L2 de las barras principales.
func tension_barras() -> float:
	if sim.solucion == null:
		sim.paso()
	return sim.solucion.entre("BP.L1", "BP.L2").modulo()


## Frecuencia de las barras: la del primer grupo en barras, o 0 si no hay ninguno.
func frecuencia_barras() -> float:
	for d: Dictionary in datos["generadores"]:
		if (sim.componente(d["interruptor"]) as SimInterruptorGenerador).cerrado():
			return generador(d["id"]).frecuencia()
	return 0.0


## Tensión de cada fase de las barras contra el casco, como la ven las lámparas de tierra.
func tensiones_a_tierra() -> Array[float]:
	if sim.solucion == null:
		sim.paso()
	var lista: Array[float] = []
	for fase in ["L1", "L2", "L3"]:
		lista.append(sim.solucion.entre("BP." + fase, SimSolver.TIERRA).modulo())
	return lista


static func _aviso(tipo: String, titulo: String, texto: String) -> Dictionary:
	return {"tipo": tipo, "titulo": titulo, "texto": texto}
