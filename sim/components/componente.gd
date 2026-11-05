class_name SimComponente
extends RefCounted
## Base de los componentes. params es la configuración; estado es lo que cambia
## durante el juego (daños, disparos, posiciones) y se guarda con el circuito.

const R_CONTACTO := 0.001

var id: String
var params: Dictionary
var estado: Dictionary
## Referencia débil: la simulación ya es dueña de sus componentes.
var sim_ref: WeakRef


func _init(p_id: String, p_params := {}, p_estado := {}) -> void:
	id = p_id
	params = _params_por_defecto()
	params.merge(p_params, true)
	estado = _estado_inicial()
	estado.merge(p_estado, true)
	_preparar()


func tipo() -> String:
	return ""


func _params_por_defecto() -> Dictionary:
	return {}


func _estado_inicial() -> Dictionary:
	return {}


func _preparar() -> void:
	pass


func estampar(_e: SimEstampa) -> void:
	pass


## Cambios instantáneos (bobinas). Devuelve true si algo cambió y hay que volver a resolver.
func asentar(_sol: SimSolver.Solucion) -> bool:
	return false


## Cambios con el tiempo (temperatura, temporizadores, protecciones).
func avanzar(_dt: float, _sol: SimSolver.Solucion) -> void:
	pass


## Paso de tiempo más largo con el que el componente sigue siendo estable. La simulación
## divide los pasos más largos.
func paso_maximo() -> float:
	return INF


func sim() -> SimSimulacion:
	return sim_ref.get_ref() if sim_ref != null else null


## Cambiar el repuesto: el componente vuelve a su estado de fábrica.
func reemplazar() -> void:
	estado = _estado_inicial()
	_preparar()


func n(terminal: String) -> String:
	return id + "." + terminal


func tension(sol: SimSolver.Solucion, a: String, b: String) -> float:
	return sol.entre(n(a), n(b)).modulo()


func avisar(evento: String, detalle := {}) -> void:
	var sim: Variant = sim_ref.get_ref() if sim_ref != null else null
	if sim != null:
		sim.registrar_evento(evento, id, detalle)
