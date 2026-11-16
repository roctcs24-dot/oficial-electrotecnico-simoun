extends Animacion
## Relé de control de fases sobre la simulación (circuito rele_fases_servicio): a la izquierda,
## las tres tensiones de fase giran como en la red, en su orden; a la derecha, el relé con sus
## LED y su contacto 11-12-14. Se puede quitar una fase (polo quemado del interruptor general),
## invertir la secuencia o cambiar la tensión: el relé suelta tras su retardo.

const ANCHO := 408.0
const ALTO := 320.0
const COLORES := {"L1": Color("8a4b1c"), "L2": Color("20242a"), "L3": Color("8a949b")}

var sim: SimSimulacion
var sin_l3 := false
var inversa := false
var tension := 380.0
var _acumulado := 0.0
var _valor: Label
var _nota: Label
var _boton_fase: Button
var _boton_secuencia: Button


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c := tarjeta_mandos()
	_valor = fila_valor(c, "Tensión de la red")
	barra(c, 280.0, 460.0, 5.0, tension, poner_tension)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	c.add_child(fila)
	_boton_fase = boton_mando(fila, func() -> void: quitar_fase(not sin_l3))
	_boton_secuencia = boton_mando(fila, func() -> void: invertir(not inversa))
	_nota = nota_mandos(c)
	sim = contenido.circuito("rele_fases_servicio")
	sim.avanzar_tiempo(1.0)
	_actualizar_textos()


func rele() -> SimReleControlFases:
	return sim.componente("R1")


func activado() -> bool:
	return rele().estado["rele"]


func poner_tension(v: float) -> void:
	tension = v
	sim.componente("B").params["v_linea"] = v
	_actualizar_textos()


func quitar_fase(quitar: bool) -> void:
	sin_l3 = quitar
	sim.componente("Q0").params["polo_danado"] = "5-6" if quitar else ""
	_actualizar_textos()


func invertir(si: bool) -> void:
	inversa = si
	sim.componente("B").params["secuencia"] = "inversa" if si else "directa"
	_actualizar_textos()


func avanzar(segundos: float) -> void:
	sim.avanzar_tiempo(segundos)
	_actualizar_textos()


## Lo que ve el relé ahora mismo, antes de su retardo.
func diagnostico() -> String:
	return rele().diagnostico(sim.resolver())


## 1 red correcta, 2 hay falla pero aún no soltó (retardo), 3 soltó.
func fase() -> int:
	if not activado():
		return 3
	return 2 if not diagnostico().is_empty() else 1


func _process(delta: float) -> void:
	_acumulado += delta
	if _acumulado >= SimSimulacion.PASO_S:
		_acumulado = 0.0
		var antes := activado()
		sim.paso()
		if activado() != antes:
			_actualizar_textos()
	super(delta)


const MOTIVOS := {
	"": "red correcta",
	"falta_fase": "falta una fase",
	"secuencia": "secuencia inversa",
	"subtension": "tensión baja",
	"sobretension": "tensión alta",
	"asimetria": "fases desequilibradas",
	"sin_tension": "sin tensión",
}


func _actualizar_textos() -> void:
	if _valor == null:
		return
	_valor.text = "%d V" % roundi(tension)
	_boton_fase.text = "Devolver L3" if sin_l3 else "Quitar L3"
	_boton_secuencia.text = "Secuencia directa" if inversa else "Invertir L2 y L3"
	var motivo: String = MOTIVOS.get(diagnostico(), diagnostico())
	if activado():
		_nota.text = "Relé activado: 11-14 cerrado, el mando puede arrancar. Margen típico: de 323 a 418 V (85 %% y 110 %% de 380 V), con %s s de retardo." % coma(float(rele().params["retardo_s"]))
	else:
		_nota.text = "Relé suelto por %s: 11-14 abierto y 11-12 cerrado. Los motores no arrancan." % motivo


func dibujar() -> void:
	fondo()
	diseno(ANCHO, ALTO)
	var l := lienzo
	texto(Vector2(204, 14), "LO QUE VIGILA EL RELÉ DE CONTROL DE FASES", 12, Color("5b6267"))
	var sol := sim.resolver()
	var r := rele()
	# Tensiones de fase en los bornes del relé, giradas para que se vean rotar.
	var centro := Vector2(110, 150)
	var giro := fmod(t * 1.2, TAU)
	var fases := ["L1", "L2", "L3"]
	# El neutro de medida es la media de las tres: así se ve la estrella del relé.
	var suma := Cx.new()
	for f: String in fases:
		suma = suma.mas(sol.entre("R1." + f, "B.N"))
	var neutro := suma.escala(1.0 / 3.0)
	for f: String in fases:
		var v := sol.entre("R1." + f, "B.N").menos(neutro)
		var a := deg_to_rad(v.angulo()) + giro
		var largo := v.modulo() / 220.0 * 80.0
		var fin := centro + Vector2(cos(a), -sin(a)) * largo
		flecha(centro, fin, COLORES[f], 4.0)
		texto(fin + Vector2(cos(a), -sin(a)) * 14.0, f, 13, COLORES[f])
	l.draw_arc(centro, 96.0, -2.4, -0.9, 16, Color("5b6267"), 1.5, true)
	texto(Vector2(110, 268), "giran en sentido antihorario", 10, Color("5b6267"))
	texto(Vector2(110, 284), "y pasan por L1, L2, L3 en ese orden", 10, Color("5b6267"))
	# Lecturas de línea.
	var lineas := [["U12", "R1.L1", "R1.L2"], ["U23", "R1.L2", "R1.L3"], ["U31", "R1.L3", "R1.L1"]]
	l.draw_style_box(Tema.caja(Color("dfe3e4"), 8, 0, 0, Color("5b6267")), Rect2(232, 30, 166, 92))
	for i in 3:
		var u := sol.entre(lineas[i][1], lineas[i][2]).modulo()
		var fuera := u < float(r.params["umin"]) * float(r.params["v_nominal"]) or u > float(r.params["umax"]) * float(r.params["v_nominal"])
		texto(Vector2(244, 50 + i * 26), "%s  %d V" % [lineas[i][0], roundi(u)], 14, Tema.FALLO if fuera else Tema.TINTA, false)
	# Relé con sus LED y su contacto.
	l.draw_style_box(Tema.caja(Color("2f3840"), 8, 0, 0), Rect2(232, 134, 166, 132))
	l.draw_circle(Vector2(262, 156), 8.0, Color("5be37f") if sol.entre("R1.L1", "R1.L2").modulo() > 50.0 else Color("1d3a26"))
	texto(Vector2(280, 156), "U", 12, Color.WHITE, false)
	l.draw_circle(Vector2(322, 156), 8.0, Color("ffcf4a") if activado() else Color("4a3a12"))
	texto(Vector2(340, 156), "R", 12, Color.WHITE, false)
	# Contacto conmutado: 11 común, 12 NC, 14 NA.
	var comun := Vector2(262, 236)
	l.draw_line(Vector2(262, 254), comun, Color.WHITE, 3.0)
	var hacia := Vector2(330, 196) if activado() else Vector2(330, 222)
	l.draw_line(comun, comun.lerp(hacia, 0.95), Color.WHITE, 3.0, true)
	l.draw_line(Vector2(330, 196), Vector2(368, 196), Color.WHITE, 3.0)
	l.draw_line(Vector2(330, 222), Vector2(368, 222), Color.WHITE, 3.0)
	texto(Vector2(250, 254), "11", 11, Color.WHITE)
	texto(Vector2(384, 196), "14", 11, Color.WHITE)
	texto(Vector2(384, 222), "12", 11, Color.WHITE)
	var rotulo := "RED CORRECTA" if activado() else "SUELTO: " + str(MOTIVOS.get(str(r.estado["falla"]), "falla")).to_upper()
	rotulo_estado(Vector2(315, 294), rotulo, Tema.ACIERTO if activado() else Color("c0392b"))
	l.draw_set_transform(Vector2.ZERO)
