class_name SimSelector
extends SimComponente
## Selector rotativo de varias posiciones, como el MAN-OFF-AUT de las bombas de prelubricación o el
## 0-1-START de la purificadora. Tiene dos contactos, 13-14 y 23-24: cada uno cierra en las
## posiciones que indica params contactos. Una posición de retorno por resorte, como START, vuelve
## sola a la anterior al soltar el mando.


func tipo() -> String:
	return "selector"


func _params_por_defecto() -> Dictionary:
	return {
		"posiciones": ["0", "1"],
		# Posiciones en que cierra cada contacto.
		"contactos": {"13-14": ["1"], "23-24": []},
		"retorno": [],
		# Posición al instalarlo; vacía, la primera.
		"inicial": "",
	}


func _estado_inicial() -> Dictionary:
	return {"posicion": maxi(params["posiciones"].find(params["inicial"]), 0)}


func posiciones() -> Array:
	return params["posiciones"]


func nombre_posicion() -> String:
	return str(posiciones()[estado["posicion"]])


## Gira una posición a la izquierda (-1) o a la derecha (+1), sin pasar de los topes.
func girar(sentido: int) -> void:
	estado["posicion"] = clampi(int(estado["posicion"]) + sentido, 0, posiciones().size() - 1)


func poner(nombre: String) -> void:
	var i := posiciones().find(nombre)
	if i >= 0:
		estado["posicion"] = i


## Al soltar el mando, una posición con resorte vuelve a la anterior.
func soltar() -> void:
	if params["retorno"].has(nombre_posicion()):
		girar(-1)


func cerrado(contacto: String) -> bool:
	return params["contactos"].get(contacto, []).has(nombre_posicion())


func estampar(e: SimEstampa) -> void:
	for contacto: String in ["13-14", "23-24"]:
		if cerrado(contacto):
			var bornes := contacto.split("-")
			e.enlace(n(bornes[0]), n(bornes[1]))
