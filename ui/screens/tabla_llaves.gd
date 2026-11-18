extends Pantalla
## Llaves en milímetros y pulgadas (data/tablas/llaves.json): a la izquierda la tabla con cada
## medida en pulgadas, su valor en mm y la llave métrica que le sirve, con su lámpara; a la
## derecha el conversor, con la llave dibujada y los visores. La medida elegida vive en args.

const COLOR := Color("d9534f")

var tabla := {}
var filas: Array[Control] = []
var botones: Array[BotonAri] = []
var dibujo: DibujoHerramienta


func construir() -> void:
	tabla = raiz.contenido.leer("tablas/llaves.json")
	var pulgadas: Array = tabla.get("pulgadas", [])
	if not args.has("pulgada"):
		args["pulgada"] = "3/4" if pulgadas.has("3/4") else str(pulgadas[0])
	var cabecera := CabeceraFicha.new()
	cabecera.iniciar(raiz, "Llaves: milímetros y pulgadas", "Pañol · qué llave métrica entra en una tuerca en pulgadas" if not raiz.vertical else "Pañol · medida entre caras", COLOR, "herramientas")
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
		desplazable.size_flags_stretch_ratio = 0.75
		desplazable.add_child(izquierda)
		fila.add_child(desplazable)
		derecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(derecha)


func metricas() -> Array:
	return tabla.get("metricas", [])


func _tabla() -> Control:
	var placa := PiezasLeccion.placa(10.0, 10.0)
	placa.name = "Tabla"
	placa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 0)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(columna)
	columna.add_child(PiezasLeccion.rotulo("Tabla · entre caras"))
	columna.add_child(_fila_tabla(["PULGADAS", "mm", "LLAVE", ""], "", true))
	filas.clear()
	for p: String in tabla.get("pulgadas", []):
		var t := TablaLlaves.a_mm(p)
		var m := TablaLlaves.mejor_metrica(t, metricas())
		var est := TablaLlaves.estado(float(m), t)
		# Sin llave métrica que sirva, se dice que se use la de pulgadas.
		var llave: String = "%d mm" % m if est != "redondea" else "—"
		var texto: String = TablaLlaves.NOMBRES[est] if est != "redondea" else "use la de pulgadas"
		var f := _fila_tabla(["%s\"" % p, TablaLlaves.numero(t), llave, texto], est, false, p == args["pulgada"])
		f.name = "Fila_%s" % p.replace("/", "_")
		filas.append(f)
		columna.add_child(f)
	columna.add_child(PiezasLeccion.etiqueta(str(tabla.get("nota", "")), 12, Tema.TEXTO_SUAVE))
	return placa


func _fila_tabla(textos: Array, estado: String, cabecera := false, elegida := false) -> Control:
	var fila := FilaTabla.new()
	fila.elegida = elegida
	fila.add_theme_constant_override("separation", 6)
	for i in textos.size():
		var e := PiezasLeccion.etiqueta(textos[i], 12 if cabecera else 14, Tema.TEXTO_SUAVE if cabecera else ([Color.WHITE, Color("cfd8df"), Tema.ACENTO, Color("cfd8df")][i]), Tema.PESO_NEGRITA if i != 1 and i != 3 else Tema.PESO_MEDIO)
		e.autowrap_mode = TextServer.AUTOWRAP_OFF
		e.custom_minimum_size.x = [70.0, 64.0, 66.0, 0.0][i]
		if i == 3:
			e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if not estado.is_empty():
				var luz := PiezasLeccion.Lampara.new(TablaLlaves.ESTADOS[estado], true, 4.5)
				luz.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				fila.add_child(luz)
		fila.add_child(e)
	fila.custom_minimum_size.y = 30.0 if cabecera else 34.0
	return fila


func _conversor() -> Control:
	var p: String = args["pulgada"]
	var t := TablaLlaves.a_mm(p)
	var m := TablaLlaves.mejor_metrica(t, metricas())
	var visor := VisorFicha.new(12.0)
	visor.name = "Conversor"
	visor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	visor.add_child(columna)
	columna.add_child(PiezasLeccion.rotulo("Conversor · elija la medida"))
	var rejilla := GridContainer.new()
	rejilla.columns = 4 if raiz.vertical else 6
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	columna.add_child(rejilla)
	botones.clear()
	for q: String in tabla.get("pulgadas", []):
		var b := BotonAri.new("%s\"" % q, elegir.bind(q), "ambar" if q == p else "oscuro")
		b.name = "Pulgada_%s" % q.replace("/", "_")
		b.custom_minimum_size = Vector2(56, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rejilla.add_child(b)
		botones.append(b)
	dibujo = DibujoHerramienta.new()
	dibujo.tipo = "combinada"
	dibujo.medida = "%d mm" % m
	dibujo.custom_minimum_size.y = 130.0
	dibujo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(dibujo)
	var visores := Lecturas.new()
	visores.pulgada = p
	visores.tuerca = t
	visores.llave = m
	columna.add_child(visores)
	return visor


func elegir(p: String) -> void:
	args["pulgada"] = p
	raiz.reconstruir()


## Los tres visores del conversor: la medida en mm, la llave métrica y la diferencia.
class Lecturas:
	extends Control

	var pulgada := ""
	var tuerca := 0.0
	var llave := 0

	func _init() -> void:
		name = "Lecturas"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(300, 66)

	func _draw() -> void:
		var est := TablaLlaves.estado(float(llave), tuerca)
		var w := (size.x - 16.0) / 3.0
		var datos := [
			[TablaLlaves.numero(tuerca), "mm", "%s\" EN mm" % pulgada, Tema.ARI_LCD_VERDE],
			[str(llave), "mm", "LLAVE · %s" % TablaLlaves.NOMBRES[est].to_upper(), Tema.ARI_LCD_VERDE if est == "entra" else (Tema.ARI_LCD_AMBAR if est == "holgada" else Color("ff5a4a"))],
			[TablaLlaves.numero(absf(float(llave) - tuerca)), "mm", "DIFERENCIA", Tema.ARI_LCD_AMBAR],
		]
		for i in 3:
			var caja := Rect2(i * (w + 8.0), 0, w, 64.0)
			DibujoAri.sombra(self, caja, 8.0, 0.5, Vector2(0, 2))
			DibujoAri.degradado(self, caja, 8.0, [Color("05080a"), Color("2a3b48")])
			PiezasAri.visor(self, Rect2(caja.position + Vector2(6, 6), Vector2(caja.size.x - 12.0, 32.0)), 1.0, datos[i][0], datos[i][1], datos[i][3], 20.0)
			var tam := float(Tema.tam(9.5))
			PiezasAri.texto(self, datos[i][2], caja.get_center().x, caja.end.y - 9.0, tam, Color("a9b6c1"), Tema.PESO_NEGRITA)


## Fila de la tabla; la elegida se ilumina en ámbar.
class FilaTabla:
	extends HBoxContainer

	var elegida := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		draw_line(Vector2(0, 0), Vector2(size.x, 0), Color(1, 1, 1, 0.06), 1.0)
		if elegida:
			DibujoAri.degradado(self, Rect2(Vector2.ZERO, size), 6.0, [Color(1.0, 0.76, 0.23, 0.18), Color(1.0, 0.76, 0.23, 0.02)])
