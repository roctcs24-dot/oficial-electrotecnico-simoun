class_name SimSolver
extends RefCounted
## Análisis nodal con fasores. Los enlaces ideales fusionan nodos antes de armar
## la matriz, así que su tamaño es el número de redes eléctricas distintas.

const TIERRA := "PE"
## Conductancia mínima a tierra: evita redes flotantes con matriz singular.
const G_MIN := 1e-10


class Solucion:
	var _indice: Dictionary = {}
	var _re: PackedFloat64Array
	var _im: PackedFloat64Array
	## El punto de trabajo en continua, cuando la red tiene electrónica de continua. La
	## tensión real de un nodo es la suma de las dos partes: v() es solo la alterna.
	var dc: Solucion

	## Tensión del nodo respecto a tierra. Un nodo sin conexiones vale cero.
	func v(nodo: String) -> Cx:
		var i: int = _indice.get(nodo, -1)
		if i < 0:
			return Cx.new()
		return Cx.new(_re[i], _im[i])

	func entre(a: String, b: String) -> Cx:
		return v(a).menos(v(b))

	## Tensión continua del nodo respecto a tierra, con signo.
	func vdc(nodo: String) -> float:
		return dc.v(nodo).re if dc != null else 0.0

	func entre_dc(a: String, b: String) -> float:
		return vdc(a) - vdc(b)


static func resolver(e: SimEstampa) -> Solucion:
	var padres := {TIERRA: TIERRA}
	for par in e.enlaces:
		_unir(padres, par[0], par[1])
	for rama in e.ramas:
		_registrar(padres, rama[0])
		_registrar(padres, rama[1])
	for iny in e.inyecciones:
		_registrar(padres, iny[0])

	var raiz_tierra := _raiz(padres, TIERRA)
	var indice_red := {}
	var sol := Solucion.new()
	for nodo in padres:
		var raiz := _raiz(padres, nodo)
		if raiz == raiz_tierra:
			sol._indice[nodo] = -1
			continue
		if not indice_red.has(raiz):
			indice_red[raiz] = indice_red.size()
		sol._indice[nodo] = indice_red[raiz]

	var n := indice_red.size()
	var a_re := PackedFloat64Array()
	var a_im := PackedFloat64Array()
	a_re.resize(n * n)
	a_im.resize(n * n)
	a_re.fill(0.0)
	a_im.fill(0.0)
	var b_re := PackedFloat64Array()
	var b_im := PackedFloat64Array()
	b_re.resize(n)
	b_im.resize(n)
	b_re.fill(0.0)
	b_im.fill(0.0)

	for i in n:
		a_re[i * n + i] = G_MIN
	for rama in e.ramas:
		var p: int = sol._indice[rama[0]]
		var q: int = sol._indice[rama[1]]
		if p == q:
			continue
		var g: float = rama[2]
		var h: float = rama[3]
		if p >= 0:
			a_re[p * n + p] += g
			a_im[p * n + p] += h
		if q >= 0:
			a_re[q * n + q] += g
			a_im[q * n + q] += h
		if p >= 0 and q >= 0:
			a_re[p * n + q] -= g
			a_im[p * n + q] -= h
			a_re[q * n + p] -= g
			a_im[q * n + p] -= h
	for iny in e.inyecciones:
		var k: int = sol._indice[iny[0]]
		if k >= 0:
			b_re[k] += iny[1]
			b_im[k] += iny[2]

	_eliminar(n, a_re, a_im, b_re, b_im)
	sol._re = b_re
	sol._im = b_im
	return sol


## Eliminación gaussiana compleja con pivoteo parcial. Deja la solución en b.
static func _eliminar(
	n: int,
	a_re: PackedFloat64Array,
	a_im: PackedFloat64Array,
	b_re: PackedFloat64Array,
	b_im: PackedFloat64Array
) -> void:
	for c in n:
		var pivote := c
		var mejor := -1.0
		for f in range(c, n):
			var m := a_re[f * n + c] * a_re[f * n + c] + a_im[f * n + c] * a_im[f * n + c]
			if m > mejor:
				mejor = m
				pivote = f
		if pivote != c:
			for j in range(c, n):
				var t_re := a_re[c * n + j]
				var t_im := a_im[c * n + j]
				a_re[c * n + j] = a_re[pivote * n + j]
				a_im[c * n + j] = a_im[pivote * n + j]
				a_re[pivote * n + j] = t_re
				a_im[pivote * n + j] = t_im
			var u_re := b_re[c]
			var u_im := b_im[c]
			b_re[c] = b_re[pivote]
			b_im[c] = b_im[pivote]
			b_re[pivote] = u_re
			b_im[pivote] = u_im
		var d_re := a_re[c * n + c]
		var d_im := a_im[c * n + c]
		var d := d_re * d_re + d_im * d_im
		for f in range(c + 1, n):
			var x_re := a_re[f * n + c]
			var x_im := a_im[f * n + c]
			if x_re == 0.0 and x_im == 0.0:
				continue
			var k_re := (x_re * d_re + x_im * d_im) / d
			var k_im := (x_im * d_re - x_re * d_im) / d
			for j in range(c + 1, n):
				var y_re := a_re[c * n + j]
				var y_im := a_im[c * n + j]
				a_re[f * n + j] -= k_re * y_re - k_im * y_im
				a_im[f * n + j] -= k_re * y_im + k_im * y_re
			b_re[f] -= k_re * b_re[c] - k_im * b_im[c]
			b_im[f] -= k_re * b_im[c] + k_im * b_re[c]
	for f in range(n - 1, -1, -1):
		var s_re := b_re[f]
		var s_im := b_im[f]
		for j in range(f + 1, n):
			s_re -= a_re[f * n + j] * b_re[j] - a_im[f * n + j] * b_im[j]
			s_im -= a_re[f * n + j] * b_im[j] + a_im[f * n + j] * b_re[j]
		var e_re := a_re[f * n + f]
		var e_im := a_im[f * n + f]
		var e_d := e_re * e_re + e_im * e_im
		b_re[f] = (s_re * e_re + s_im * e_im) / e_d
		b_im[f] = (s_im * e_re - s_re * e_im) / e_d


static func _registrar(padres: Dictionary, nodo: String) -> void:
	if not padres.has(nodo):
		padres[nodo] = nodo


static func _raiz(padres: Dictionary, nodo: String) -> String:
	var r := nodo
	while padres[r] != r:
		padres[r] = padres[padres[r]]
		r = padres[r]
	return r


static func _unir(padres: Dictionary, a: String, b: String) -> void:
	_registrar(padres, a)
	_registrar(padres, b)
	padres[_raiz(padres, a)] = _raiz(padres, b)
