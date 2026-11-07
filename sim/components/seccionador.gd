class_name SimSeccionador
extends SimComponente
## Interruptor general rotativo del tablero (main switch), de tres polos 1-2, 3-4 y 5-6, con un
## contacto auxiliar 13-14. En la posición 0-OFF admite candado: es el punto de bloqueo para LOTO.
## Con el candado puesto no se puede cerrar.


func tipo() -> String:
	return "seccionador"


## Avería: un polo quemado no conduce aunque el interruptor esté cerrado ("1-2", "3-4" o "5-6").
func _params_por_defecto() -> Dictionary:
	return {"polo_danado": ""}


func _estado_inicial() -> Dictionary:
	return {"cerrado": false, "candado": false}


func cerrado() -> bool:
	return estado["cerrado"]


## Devuelve false si el candado impide la maniobra.
func accionar(cerrar: bool) -> bool:
	if cerrar and estado["candado"]:
		return false
	estado["cerrado"] = cerrar
	return true


## El candado solo entra con el interruptor abierto.
func poner_candado(poner: bool) -> bool:
	if poner and estado["cerrado"]:
		return false
	estado["candado"] = poner
	return true


func estampar(e: SimEstampa) -> void:
	if estado["cerrado"]:
		for polo: Array in [["1", "2"], ["3", "4"], ["5", "6"]]:
			if params["polo_danado"] != "%s-%s" % [polo[0], polo[1]]:
				e.impedancia(n(polo[0]), n(polo[1]), R_CONTACTO)
		e.enlace(n("13"), n("14"))
