class_name Cx
extends RefCounted
## Número complejo de doble precisión para fasores e impedancias.
## No se usa Vector2 porque en Godot es de 32 bits.

var re: float
var im: float


func _init(p_re := 0.0, p_im := 0.0) -> void:
	re = p_re
	im = p_im


static func polar(modulo_valor: float, angulo_grados: float) -> Cx:
	var a := deg_to_rad(angulo_grados)
	return Cx.new(modulo_valor * cos(a), modulo_valor * sin(a))


func mas(o: Cx) -> Cx:
	return Cx.new(re + o.re, im + o.im)


func menos(o: Cx) -> Cx:
	return Cx.new(re - o.re, im - o.im)


func por(o: Cx) -> Cx:
	return Cx.new(re * o.re - im * o.im, re * o.im + im * o.re)


func entre(o: Cx) -> Cx:
	var d := o.re * o.re + o.im * o.im
	return Cx.new((re * o.re + im * o.im) / d, (im * o.re - re * o.im) / d)


func escala(k: float) -> Cx:
	return Cx.new(re * k, im * k)


func modulo() -> float:
	return sqrt(re * re + im * im)


func conjugado() -> Cx:
	return Cx.new(re, -im)


## Ángulo en grados, de -180 a 180.
func angulo() -> float:
	return rad_to_deg(atan2(im, re))


## Diferencia de ángulos llevada a -180..180.
static func diferencia_angulo(a: float, b: float) -> float:
	return fposmod(a - b + 180.0, 360.0) - 180.0
