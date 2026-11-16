class_name SimDiferencial
extends SimComponente
## Interruptor diferencial (residual current device, RCD) de 2 polos: 1-2 la fase y 3-4 el
## neutro, los dos por dentro del transformador toroidal. Suma las corrientes de los dos polos;
## si la suma (la corriente que se fue a tierra) pasa de IΔn, abre los dos polos.
## El botón de prueba T une, por una resistencia interna, la salida de la fase (2) con la
## entrada del neutro (3): esa corriente cruza el toroide por un solo conductor y lo dispara.
## En una red aislada una fuga casi no hace circular corriente, y el diferencial no la ve.
## El disparo real tarda menos de 300 ms con IΔn (IEC 61008): aquí es instantáneo.

const POLOS := [["1", "2"], ["3", "4"]]


func tipo() -> String:
	return "diferencial"


func _params_por_defecto() -> Dictionary:
	return {"idn_a": 0.03, "in_a": 40.0, "r_prueba": 6000.0, "averiado": false}


func _estado_inicial() -> Dictionary:
	return {"encendido": false, "disparado": false, "prueba": false, "residual_a": 0.0}


func cerrado() -> bool:
	return estado["encendido"] and not estado["disparado"]


## Subir o bajar la maneta. Tras un disparo, primero hay que bajarla.
func accionar(encender: bool) -> void:
	if not encender:
		estado["encendido"] = false
		estado["disparado"] = false
	elif not estado["disparado"]:
		estado["encendido"] = true


func pulsar_prueba(pulsado: bool) -> void:
	estado["prueba"] = pulsado


func estampar(e: SimEstampa) -> void:
	if not cerrado():
		return
	for polo in POLOS:
		e.impedancia(n(polo[0]), n(polo[1]), R_CONTACTO)
	if estado["prueba"]:
		e.impedancia(n("2"), n("3"), float(params["r_prueba"]))


## Corriente que entra por un borne de arriba y sale por el de abajo, como fasor.
func _corriente(sol: SimSolver.Solucion, polo: int) -> Cx:
	return sol.entre(n(POLOS[polo][0]), n(POLOS[polo][1])).escala(1.0 / R_CONTACTO)


## Corriente diferencial en amperios: la que entra por un polo y no vuelve por el otro.
func residual(sol: SimSolver.Solucion) -> float:
	if not cerrado():
		return 0.0
	return _corriente(sol, 0).mas(_corriente(sol, 1)).modulo()


func avanzar(_dt: float, sol: SimSolver.Solucion) -> void:
	var r := residual(sol)
	estado["residual_a"] = r
	if cerrado() and not params["averiado"] and r > float(params["idn_a"]):
		estado["disparado"] = true
		avisar("disparo_diferencial", {"corriente_ma": r * 1000.0})
