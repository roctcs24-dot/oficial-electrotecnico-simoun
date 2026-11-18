extends PantallaPreguntas
## Examen de la versión: preguntas al azar de un banco, con calificación final.


func _datos() -> Dictionary:
	return raiz.contenido.leer("examenes/%s.json" % args["id"])


func _crear_items() -> Array:
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	var datos := _datos()
	return ExamenTeorico.crear(datos, raiz.contenido.simbolos(int(datos.get("sistema_simbolos", -1))), azar)


func _titulo() -> String:
	return _datos()["titulo"]


## Sistema del buque o módulo que publica el examen, para el color de la cabecera.
func _area() -> Dictionary:
	for s: Dictionary in raiz.contenido.todos():
		if s.get("modos", {}).get("examen", {}).get("examenes", []).has(args["id"]):
			return s
	return {}


func _color() -> Color:
	var a := _area()
	return Tema.color_area(a) if not a.is_empty() else Tema.ACENTO


func _subtitulo() -> String:
	var a := _area()
	var minimo := roundi(float(_datos().get("minimo", 0)))
	if raiz.vertical:
		return "Mínimo %d %%" % minimo
	if a.is_empty():
		return "Mínimo para aprobar: %d %%" % minimo
	return "%s · mínimo para aprobar: %d %%" % [a.get("nombre", ""), minimo]


func _al_contestar(item: Dictionary, acierto: bool) -> void:
	if not acierto:
		raiz.partida.registrar_error(item["tema"])


func _construir_final() -> void:
	var datos := _datos()
	var total: int = args["items"].size()
	var correctas := aciertos()
	var minimo: float = datos["minimo"]
	var porcentaje := ExamenTeorico.porcentaje(correctas, total)
	var aprobado := ExamenTeorico.aprobado(correctas, total, minimo)
	var estrellas := ExamenTeorico.estrellas(correctas, total, minimo)
	if not args.has("ganados"):
		args["ganados"] = raiz.partida.registrar_examen(args["id"], porcentaje, estrellas, aprobado)
	_poner_cabecera("Resultado" if raiz.vertical else "Resultado · %s" % _area().get("nombre", ""))
	var calif: Array = _placa_con("Calificación", "PlacaCalificacion")
	var placa_c: Control = calif[0]
	var cal := Calificacion.new()
	cal.porcentaje = porcentaje
	cal.minimo = minimo
	cal.estrellas = estrellas if aprobado else 0
	cal.aprobado = aprobado
	cal.correctas = correctas
	cal.total = total
	cal.puntos = int(args["ganados"])
	calif[1].add_child(cal)
	var izquierda: Array[Control] = [placa_c]
	var derecha: Array[Control] = []
	var falladas := _falladas()
	if not falladas.is_empty():
		var temas: Array = _placa_con("Temas a repasar · %d" % falladas.size(), "TemasARepasar")
		for t: String in falladas:
			temas[1].add_child(PiezasLeccion.fila_lampara("rojo", t, 14))
		derecha.append(temas[0])
	var mas: Array = _placa_con("Para saber más", "Mas")
	mas[1].add_child(PiezasLeccion.referencias(datos.get("para_saber_mas", [])))
	derecha.append(mas[0])
	_disponer(izquierda, derecha)
	var botones: Array = []
	if correctas < total:
		botones.append(["REPASAR MIS ERRORES", _ir_al_repaso, "Repasar", str(raiz.partida.temas_pendientes().size())])
	botones.append(["REPETIR CON OTRAS" if raiz.vertical else "REPETIR CON OTRAS PREGUNTAS", _repetir, "Repetir"])
	botones.append(["VOLVER", raiz.volver, "Volver"])
	_botones_pie(botones)


## Títulos de los temas de las preguntas falladas, sin repetir.
func _falladas() -> Array[String]:
	var items: Array = args["items"]
	var banco := BancoRepaso.new(raiz.contenido)
	var r: Array[String] = []
	for i in items.size():
		if args["respuestas"].get(i, {}).get("acierto", false):
			continue
		var t := banco.titulo(items[i]["tema"])
		if not r.has(t):
			r.append(t)
	return r


func _ir_al_repaso() -> void:
	raiz.volver()
	raiz.ir_a("repaso")


func _repetir() -> void:
	for clave in ["items", "indice", "respuestas", "ganados"]:
		args.erase(clave)
	raiz.reconstruir()


## Calificación del examen: anillo ámbar con el porcentaje en un visor y el mínimo debajo, las
## tres estrellas, la lámpara de APROBADO (o NO APROBADO) y los visores de aciertos y puntos.
class Calificacion:
	extends Control

	var porcentaje := 0.0
	var minimo := 0.0
	var estrellas := 0
	var aprobado := false
	var correctas := 0
	var total := 0
	var puntos := 0

	func _init() -> void:
		name = "Calificacion"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(300, 214)

	func _draw() -> void:
		var r := 46.0
		var c := Vector2(r + 18.0, 66.0)
		Relieve.halo(self, c, r * 1.6, Relieve.VERDE_MARCA if aprobado else Color("ff3c28"), 0.8)
		draw_circle(c + Vector2(0, 3), r + 10.0, Color(0, 0, 0, 0.5))
		draw_circle(c, r + 10.0, Color("0c1116"))
		draw_arc(c, r + 10.0, 0, TAU, 64, Color("3b4855"), 1.0, true)
		Relieve.anillo(self, c, r + 5.0, 6.0, porcentaje / 100.0, Relieve.AMBAR, Color("1d262f"))
		draw_circle(c, r, Color("05080a"))
		PiezasAri.visor(self, Rect2(c.x - 38.0, c.y - 20.0, 76.0, 32.0), 1.0, str(roundi(porcentaje)), "%", Tema.ARI_LCD_VERDE if aprobado else Color("ff5a4a"), 21.0)
		PiezasAri.texto(self, "MÍN. %d %%" % roundi(minimo), c.x, c.y + 28.0, float(Tema.tam(9)), Color("7f8c97"), Tema.PESO_NEGRITA)
		var x := c.x + r + 26.0
		for i in 3:
			_estrella(Vector2(x + 20.0 + i * 46.0, 34.0), 17.0, i < estrellas)
		var placa := Rect2(x, 70.0, minf(size.x - x - 4.0, 230.0), 42.0)
		DibujoAri.degradado(self, placa, 10.0, [Color("070b0e"), Color("111a21")])
		DibujoAri.borde(self, placa, 10.0, Relieve.HUECO_BORDE, 1.0)
		PiezasAri.lampara(self, Vector2(placa.position.x + 22.0, placa.get_center().y), 7.0, "verde" if aprobado else "rojo", 1.0)
		var tinta := Color("7dffab") if aprobado else Color("ff6a5a")
		var tam := float(Tema.tam(15))
		PiezasAri.texto(self, "APROBADO" if aprobado else "NO APROBADO", placa.position.x + 42.0, placa.get_center().y + tam * 0.36, tam, tinta, Tema.PESO_NEGRITA, HORIZONTAL_ALIGNMENT_LEFT)
		var w := (size.x - 10.0) / 2.0
		for k in 2:
			var caja := Rect2(k * (w + 10.0), 146.0, w, 64.0)
			DibujoAri.sombra(self, caja, 8.0, 0.5, Vector2(0, 2))
			DibujoAri.degradado(self, caja, 8.0, [Color("05080a"), Color("2a3b48")])
			var lcd := Rect2(caja.position + Vector2(6, 6), Vector2(caja.size.x - 12.0, 34.0))
			if k == 0:
				PiezasAri.visor(self, lcd, 1.0, str(correctas), "DE %d" % total, Tema.ARI_LCD_VERDE, 22.0)
			else:
				PiezasAri.visor(self, lcd, 1.0, str(puntos), "PTS", Tema.ARI_LCD_AMBAR, 22.0)
			PiezasAri.texto(self, "ACIERTOS" if k == 0 else "PUNTOS", caja.get_center().x, caja.end.y - 8.0, float(Tema.tam(10)), Color("a9b6c1"), Tema.PESO_NEGRITA)

	func _estrella(c: Vector2, r: float, encendida: bool) -> void:
		var puntos_e := PackedVector2Array()
		for k in 10:
			var a := -PI / 2.0 + k * PI / 5.0
			puntos_e.append(c + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.45))
		if encendida:
			Relieve.halo(self, c, r * 1.7, Relieve.AMBAR_HALO, 1.0)
			var sombra := PackedVector2Array()
			for q in puntos_e:
				sombra.append(q + Vector2(0, 2))
			draw_colored_polygon(sombra, Color(0, 0, 0, 0.5))
			Relieve.poligono_degradado(self, puntos_e, [Color("fff4cf"), Color("ffd166"), Color("f0a21a"), Color("a86500")], c + Vector2(-r * 0.4, -r), c + Vector2(r * 0.4, r))
			var linea := puntos_e.duplicate()
			linea.append(puntos_e[0])
			draw_polyline(linea, Color("7a5000"), 1.2, true)
		else:
			Relieve.poligono_degradado(self, puntos_e, [Color("3a4550"), Color("232c35"), Color("141a20")], c + Vector2(0, -r), c + Vector2(0, r))
			var linea := puntos_e.duplicate()
			linea.append(puntos_e[0])
			draw_polyline(linea, Color("3b4855"), 1.2, true)
