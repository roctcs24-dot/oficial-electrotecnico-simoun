class_name SimNH3
extends RefCounted
## Relación presión–temperatura del amoníaco saturado, por interpolación en la tabla de
## data/frio/nh3.json: entre puntos se interpola el logaritmo de la presión, que es casi lineal
## con la temperatura. Fuera de la tabla se usa el tramo más cercano.

const RUTA := "res://data/frio/nh3.json"

static var _tabla: Array = []
static var _atmosfera := 1.013
static var _psi_por_bar := 14.5038


static func _cargar() -> void:
	if not _tabla.is_empty():
		return
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	_tabla = datos["tabla"]
	_atmosfera = datos["atmosfera_bar"]
	_psi_por_bar = datos["psi_por_bar"]


static func atmosfera() -> float:
	_cargar()
	return _atmosfera


## Presión absoluta de saturación, en bar, a la temperatura t_c (°C).
static func p_sat_abs(t_c: float) -> float:
	_cargar()
	var i := _tramo_por_temperatura(t_c)
	var a: Array = _tabla[i]
	var b: Array = _tabla[i + 1]
	var f := (t_c - float(a[0])) / (float(b[0]) - float(a[0]))
	return exp(lerpf(log(float(a[1])), log(float(b[1])), f))


## Presión relativa de saturación, en bar: la que marca un manómetro.
static func p_sat_rel(t_c: float) -> float:
	return p_sat_abs(t_c) - atmosfera()


## Temperatura de saturación (°C) a la presión absoluta p_abs (bar).
static func t_sat_abs(p_abs: float) -> float:
	_cargar()
	var p := maxf(p_abs, 0.01)
	var i := _tramo_por_presion(p)
	var a: Array = _tabla[i]
	var b: Array = _tabla[i + 1]
	var f := (log(p) - log(float(a[1]))) / (log(float(b[1])) - log(float(a[1])))
	return lerpf(float(a[0]), float(b[0]), f)


static func t_sat_rel(p_rel: float) -> float:
	return t_sat_abs(p_rel + atmosfera())


static func bar_a_psi(bar: float) -> float:
	_cargar()
	return bar * _psi_por_bar


static func _tramo_por_temperatura(t_c: float) -> int:
	for i in range(_tabla.size() - 2, -1, -1):
		if t_c >= float(_tabla[i][0]):
			return i
	return 0


static func _tramo_por_presion(p_abs: float) -> int:
	for i in range(_tabla.size() - 2, -1, -1):
		if p_abs >= float(_tabla[i][1]):
			return i
	return 0
