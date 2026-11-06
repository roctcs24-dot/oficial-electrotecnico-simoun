class_name SimEstampa
extends RefCounted
## Lista de elementos que cada componente aporta a la red en una resolución.
## En modo dc las reactancias valen cero y las fuentes de alterna solo aportan su impedancia.
## Con continua, además, las fuentes de continua inyectan: es el punto de trabajo en continua.
## Con dc y sin continua no inyecta ninguna fuente: es lo que ve un óhmetro.

var dc: bool
var continua: bool
var enlaces: Array = []
var ramas: Array = []
var inyecciones: Array = []


func _init(p_dc := false, p_continua := false) -> void:
	dc = p_dc or p_continua
	continua = p_continua


## Conexión ideal: los dos nodos pasan a ser el mismo.
func enlace(a: String, b: String) -> void:
	enlaces.append([a, b])


func impedancia(a: String, b: String, r: float, x := 0.0) -> void:
	var xe := 0.0 if dc else x
	var d := r * r + xe * xe
	if d <= 0.0:
		enlace(a, b)
		return
	ramas.append([a, b, r / d, -xe / d])


## Fuente de tensión v (de b hacia a) con impedancia interna, como equivalente Norton.
func fuente(a: String, b: String, v: Cx, r: float, x := 0.0) -> void:
	impedancia(a, b, r, x)
	if dc:
		return
	var i := v.entre(Cx.new(r, x))
	inyectar(a, b, i.re, i.im)


## Fuente de continua v (de b hacia a) con resistencia interna. Solo inyecta en el punto de
## trabajo en continua; en alterna y en el óhmetro queda su resistencia.
func fuente_continua(a: String, b: String, v: float, r: float) -> void:
	impedancia(a, b, r)
	if continua:
		inyectar(a, b, v / r)


## Caída fija v (de b hacia a), como la de un diodo que conduce. A diferencia de una fuente,
## también actúa con la corriente de prueba del óhmetro: así el multímetro mide la caída del diodo.
func caida(a: String, b: String, v: float, r: float) -> void:
	impedancia(a, b, r)
	if dc:
		inyectar(a, b, v / r)


## Corriente que entra por a y sale por b.
func inyectar(a: String, b: String, i_re: float, i_im := 0.0) -> void:
	inyecciones.append([a, i_re, i_im])
	inyecciones.append([b, -i_re, -i_im])
