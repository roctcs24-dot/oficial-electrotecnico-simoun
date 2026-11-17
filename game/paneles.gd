class_name Paneles
extends RefCounted
## Índice de paneles del marco de simulador (data/paneles.json): grupos con su color, paneles
## con su código, la pantalla que abren y sus consejos.

var datos: Dictionary
var _por_codigo := {}


func _init(contenido: Contenido) -> void:
	datos = contenido.leer("paneles.json")
	for p: Dictionary in lista():
		_por_codigo[p["codigo"]] = p


func grupos() -> Array:
	return datos.get("grupos", [])


func grupo(id: String) -> Dictionary:
	for g: Dictionary in grupos():
		if g["id"] == id:
			return g
	return {}


func lista() -> Array:
	return datos.get("paneles", [])


func de_grupo(id: String) -> Array:
	return lista().filter(func(p: Dictionary) -> bool: return p["grupo"] == id)


func panel(codigo: String) -> Dictionary:
	return _por_codigo.get(codigo, {})


## Un panel sin pantalla todavía sale en gris como «próximamente».
static func disponible(p: Dictionary) -> bool:
	return not str(p.get("pantalla", "")).is_empty()


func disponibles() -> Array:
	return lista().filter(disponible)


## Código del panel que corresponde a una pantalla abierta: el que se usó para llegar, si
## sigue valiendo, o el primero cuya pantalla y argumentos coinciden.
func codigo_de(nombre: String, args: Dictionary) -> String:
	var dado: String = args.get("panel", "")
	if _coincide(panel(dado), nombre, args):
		return dado
	for p: Dictionary in disponibles():
		if _coincide(p, nombre, args):
			return p["codigo"]
	return ""


func _coincide(p: Dictionary, nombre: String, args: Dictionary) -> bool:
	if p.is_empty() or p.get("pantalla", "") != nombre:
		return false
	var esperados: Dictionary = p.get("args", {})
	# El banco libre no lleva argumentos: solo coincide con un banco sin plantilla.
	if esperados.is_empty():
		return not args.has("plantilla") and not args.has("tablero") and not args.has("circuito")
	for clave: String in esperados:
		if clave == "pestana":
			continue
		if str(args.get(clave, "")) != str(esperados[clave]):
			return false
	return true


## Panel anterior (paso -1) o siguiente (paso 1) entre los disponibles, en orden circular.
func vecino(codigo: String, paso: int) -> String:
	var lista_d := disponibles()
	if lista_d.is_empty():
		return ""
	var i := -1
	for k in lista_d.size():
		if lista_d[k]["codigo"] == codigo:
			i = k
	if i < 0:
		return lista_d[0 if paso > 0 else lista_d.size() - 1]["codigo"]
	return lista_d[posmod(i + paso, lista_d.size())]["codigo"]


## Datos de una pantalla sin panel propio, como la lista de misiones o una avería.
func pantalla(nombre: String) -> Dictionary:
	return datos.get("pantallas", {}).get(nombre, {})
