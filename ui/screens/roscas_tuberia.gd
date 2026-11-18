extends Pantalla
## Roscas y medidas de tubería (data/tablas/roscas.json): a la izquierda la tabla de roscas BSP y
## NPT (diámetro exterior e hilos por pulgada); a la derecha el conversor DN ↔ NPS con el tubo
## dibujado y los visores. El DN elegido y la medida resaltada viven en args.

const COLOR := Color("d9534f")
const FilaTabla := preload("res://ui/screens/tabla_llaves.gd").FilaTabla

var tabla := {}
var filas: Array[Control] = []
var botones: Array[BotonAri] = []
var tubo: TuboDN


func construir() -> void:
	tabla = raiz.contenido.leer("tablas/roscas.json")
	if not args.has("dn"):
		args["dn"] = 50
	if not args.has("medida"):
		args["medida"] = "1/2"
	var cabecera := CabeceraFicha.new()
	cabecera.iniciar(raiz, "Roscas y medidas de tubería", "Pañol · BSP, NPT, DN y NPS", COLOR, "herramientas")
	add_child(cabecera)
	var izquierda := _tabla()
	var derecha := _conversor()
	if raiz.vertical:
		var desplazable := _desplazable()
		add_child(desplazable)
		var columna := _columna(10)
		desplazable.add_child(_ancho_lectura(columna))
		columna.add_child(derecha)
		columna.add_child(izquierda)
	else:
		var fila := HBoxContainer.new()
		fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fila.add_theme_constant_override("separation", 12)
		add_child(fila)
		var desplazable := _desplazable()
		desplazable.add_child(izquierda)
		fila.add_child(desplazable)
		derecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(derecha)


func elegido() -> Dictionary:
	for d: Dictionary in tabla.get("dn", []):
		if int(d["dn"]) == int(args["dn"]):
			return d
	return tabla["dn"][0]


func _tabla() -> Control:
	var placa := PiezasLeccion.placa(10.0, 10.0)
	placa.name = "Tabla"
	placa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 0)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(columna)
	columna.add_child(PiezasLeccion.rotulo("Roscas de tubería · diámetro exterior"))
	columna.add_child(_fila_rosca(["MEDIDA", "BSP mm", "hilos", "NPT mm", "hilos"], true))
	filas.clear()
	for r: Dictionary in tabla.get("roscas", []):
		var f := _fila_rosca(["%s\"" % r["medida"], JuegoRacores.mm(float(r["bsp_mm"])), _hilos(r["bsp_hilos"]), JuegoRacores.mm(float(r["npt_mm"])), _hilos(r["npt_hilos"])], false, str(r["medida"]) == str(args["medida"]))
		f.name = "Rosca_%s" % str(r["medida"]).replace("/", "_")
		filas.append(f)
		columna.add_child(f)
	var nota := PiezasLeccion.etiqueta(str(tabla.get("nota_roscas", "")), 12, Tema.TEXTO_SUAVE)
	columna.add_child(nota)
	return placa


static func _hilos(v) -> String:
	var f := float(v)
	return JuegoRacores.mm(f)


func _fila_rosca(textos: Array, cabecera := false, elegida := false) -> Control:
	var fila := FilaTabla.new()
	fila.elegida = elegida
	fila.add_theme_constant_override("separation", 4)
	var colores := [Color.WHITE, Color("cfd8df"), Tema.ACENTO, Color("cfd8df"), Color("8cc4f0")]
	for i in textos.size():
		var e := PiezasLeccion.etiqueta(textos[i], 12 if cabecera else 14, Tema.TEXTO_SUAVE if cabecera else colores[i], Tema.PESO_NEGRITA)
		e.autowrap_mode = TextServer.AUTOWRAP_OFF
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		e.custom_minimum_size.x = 48.0
		fila.add_child(e)
	fila.custom_minimum_size.y = 28.0 if cabecera else 32.0
	return fila


func _conversor() -> Control:
	var d := elegido()
	var visor := VisorFicha.new(12.0)
	visor.name = "Conversor"
	visor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	visor.add_child(columna)
	columna.add_child(PiezasLeccion.rotulo("DN ↔ NPS · elija el tubo"))
	var rejilla := GridContainer.new()
	rejilla.columns = 4 if raiz.vertical else 6
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	columna.add_child(rejilla)
	botones.clear()
	for f: Dictionary in tabla.get("dn", []):
		var b := BotonAri.new("DN%d" % int(f["dn"]), elegir.bind(int(f["dn"])), "ambar" if int(f["dn"]) == int(args["dn"]) else "oscuro")
		b.name = "DN_%d" % int(f["dn"])
		b.custom_minimum_size = Vector2(64, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rejilla.add_child(b)
		botones.append(b)
	tubo = TuboDN.new()
	tubo.name = "Tubo"
	tubo.exterior = float(d["exterior"])
	tubo.custom_minimum_size.y = 120.0
	tubo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(tubo)
	var lecturas := LecturasDN.new()
	lecturas.dn = int(d["dn"])
	lecturas.nps = str(d["nps"])
	lecturas.exterior = float(d["exterior"])
	columna.add_child(lecturas)
	columna.add_child(PiezasLeccion.etiqueta(str(tabla.get("nota_dn", "")), 12, Tema.TEXTO_SUAVE))
	return visor


func elegir(dn: int) -> void:
	args["dn"] = dn
	for f: Dictionary in tabla.get("dn", []):
		if int(f["dn"]) == dn:
			for r: Dictionary in tabla.get("roscas", []):
				if str(r["medida"]) == str(f["nps"]):
					args["medida"] = str(r["medida"])
	raiz.reconstruir()


## Dos visores: el NPS en pulgadas y el diámetro exterior en mm.
class LecturasDN:
	extends Control

	var dn := 50
	var nps := "2"
	var exterior := 60.3

	func _init() -> void:
		name = "LecturasDN"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(260, 66)

	func _draw() -> void:
		var w := (size.x - 8.0) / 2.0
		# El visor de 7 segmentos no tiene «/»: las pulgadas se escriben con letra encima.
		var datos := [["", "", "DN%d EN PULGADAS (NPS)" % dn, Tema.ARI_LCD_VERDE], [JuegoRacores.mm(exterior), "mm", "DIÁMETRO EXTERIOR", Tema.ARI_LCD_AMBAR]]
		for i in 2:
			var caja := Rect2(i * (w + 8.0), 0, w, 64.0)
			DibujoAri.sombra(self, caja, 8.0, 0.5, Vector2(0, 2))
			DibujoAri.degradado(self, caja, 8.0, [Color("05080a"), Color("2a3b48")])
			PiezasAri.visor(self, Rect2(caja.position + Vector2(6, 6), Vector2(caja.size.x - 12.0, 32.0)), 1.0, datos[i][0], datos[i][1], datos[i][3], 20.0)
			PiezasAri.texto(self, datos[i][2], caja.get_center().x, caja.end.y - 9.0, float(Tema.tam(9.5)), Color("a9b6c1"), Tema.PESO_NEGRITA)
		var c := Vector2(w / 2.0, 22.0)
		Relieve.halo(self, c, 26.0, Tema.ARI_LCD_VERDE, 0.35)
		PiezasAri.texto(self, "%s\"" % nps.replace("-", " "), c.x, c.y + 8.0, 22.0, Tema.ARI_LCD_VERDE)
