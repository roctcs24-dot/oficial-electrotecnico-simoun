extends Pantalla
## Mangueras hidráulicas (data/tablas/roscas.json, «mangueras» y «marcados»): arriba, una manguera
## con su marcado impreso y los visores de diámetro interior y presión; los botones cambian de
## ejemplo. Debajo, los tipos SAE y EN con una lámpara según su presión. Si hay una foto a bordo
## del marcado, se enseña junto a los ejemplos. El ejemplo elegido vive en args.

const COLOR := Color("d9534f")
const LAMPARA := {"verde": "verde", "ambar": "ambar", "rojo": "rojo"}

var tabla := {}
var botones: Array[BotonAri] = []
var filas: Array[Control] = []


func construir() -> void:
	tabla = raiz.contenido.leer("tablas/roscas.json")
	if not args.has("marcado"):
		args["marcado"] = 0
	var cabecera := CabeceraFicha.new()
	cabecera.iniciar(raiz, "Mangueras hidráulicas", "Pañol · cómo se lee el marcado SAE y EN", COLOR, "herramientas")
	add_child(cabecera)
	var lectura := _lectura()
	var tipos := _tipos()
	var desplazable := _desplazable()
	add_child(desplazable)
	if raiz.vertical:
		var columna := _columna(10)
		desplazable.add_child(_ancho_lectura(columna))
		columna.add_child(lectura)
		columna.add_child(tipos)
	else:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 12)
		fila.mouse_filter = Control.MOUSE_FILTER_PASS
		desplazable.add_child(fila)
		lectura.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tipos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(lectura)
		fila.add_child(tipos)


func marcado() -> Dictionary:
	var lista: Array = tabla.get("marcados", [])
	return lista[clampi(int(args["marcado"]), 0, lista.size() - 1)]


func _lectura() -> Control:
	var m := marcado()
	var visor := VisorFicha.new(12.0)
	visor.name = "Lectura"
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	visor.add_child(columna)
	columna.add_child(PiezasLeccion.rotulo("Lea el marcado de la manguera"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	columna.add_child(fila)
	botones.clear()
	for i in tabla.get("marcados", []).size():
		var b := BotonAri.new("EJEMPLO %d" % (i + 1), elegir.bind(i), "ambar" if i == int(args["marcado"]) else "oscuro")
		b.name = "Marcado_%d" % i
		b.custom_minimum_size.y = 44.0
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)
		botones.append(b)
	var manguera := Manguera.new()
	manguera.texto = str(m["texto"])
	columna.add_child(manguera)
	var lecturas := Visores.new()
	lecturas.dn = int(m["dn"])
	lecturas.pulgadas = str(m["pulgadas"])
	lecturas.presion = int(m["presion"])
	columna.add_child(lecturas)
	var tipo := _tipo(str(m["tipo"]))
	if not tipo.is_empty():
		columna.add_child(PiezasLeccion.fila_lampara(LAMPARA.get(tipo["nivel"], "verde"), "%s: %s, %s" % [tipo["nombre"], str(tipo["refuerzo"]).to_lower(), str(tipo["uso"]).to_lower()], 13))
	columna.add_child(PiezasLeccion.etiqueta("Fecha %s: es la de fabricación. Revise la vida útil que da el fabricante." % m["fecha"], 12, Tema.TEXTO_SUAVE))
	var fotos := FotosPiezas.de_pieza(raiz.contenido.leer(FotosPiezas.ARCHIVO), "latiguillo").filter(func(f: Dictionary) -> bool: return str(f["id"]).begins_with("marcado"))
	if not fotos.is_empty():
		var foto := FotoPieza.desde(fotos[0], str(raiz.contenido.leer(FotosPiezas.ARCHIVO).get("credito", "")))
		foto.custom_minimum_size.y = 150.0
		columna.add_child(foto)
		columna.add_child(PiezasLeccion.etiqueta(str(fotos[0]["texto"]), 12, Tema.TEXTO_SUAVE))
	return visor


func _tipo(id: String) -> Dictionary:
	for t: Dictionary in tabla.get("mangueras", []):
		if t["id"] == id:
			return t
	return {}


func _tipos() -> Control:
	var placa := PiezasLeccion.placa(10.0, 10.0)
	placa.name = "Tipos"
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	columna.mouse_filter = Control.MOUSE_FILTER_PASS
	placa.add_child(columna)
	columna.add_child(PiezasLeccion.rotulo("Tipos · valores típicos — verificar"))
	filas.clear()
	for t: Dictionary in tabla.get("mangueras", []):
		var presion := " · %d bar en 1/2\"" % int(t["presion"]) if int(t["presion"]) > 0 and str(t["id"]) in ["1sn", "2sn"] else ""
		var f := PiezasLeccion.fila_lampara(LAMPARA.get(t["nivel"], "verde"), "%s — %s%s. %s" % [t["nombre"], str(t["refuerzo"]).to_lower(), presion, t["uso"]], 13)
		f.name = "Tipo_%s" % t["id"]
		columna.add_child(f)
		filas.append(f)
	columna.add_child(PiezasLeccion.etiqueta(str(tabla.get("nota_mangueras", "")), 12, Tema.TEXTO_SUAVE))
	return placa


func elegir(i: int) -> void:
	args["marcado"] = i
	raiz.reconstruir()


## Manguera de goma con el marcado impreso en amarillo, como sale de fábrica.
class Manguera:
	extends Control

	var texto := ""

	func _init() -> void:
		name = "Manguera"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(260, 84)

	func _draw() -> void:
		var r := Rect2(4, size.y / 2.0 - 26.0, size.x - 8.0, 52.0)
		DibujoAri.relleno(self, Rect2(r.position + Vector2(0, 6), r.size), 26.0, Color(0, 0, 0, 0.45))
		DibujoAri.degradado(self, r, 26.0, [Color("5a6066"), Color("2b3035"), Color("15181b"), Color("24282c")], [0.0, 0.3, 0.75, 1.0])
		DibujoAri.relleno(self, Rect2(r.position + Vector2(24, 6), Vector2(r.size.x - 48.0, 6.0)), 3.0, Color(1, 1, 1, 0.16))
		var tam := clampf(r.size.x / maxf(texto.length(), 1.0) * 1.55, 9.0, 15.0)
		PiezasAri.texto(self, texto, r.get_center().x, r.get_center().y + tam * 0.36, tam, Color("ffd166"))


## Visores del diámetro interior (DN y pulgadas) y de la presión de trabajo.
class Visores:
	extends Control

	var dn := 12
	var pulgadas := "1/2"
	var presion := 275

	func _init() -> void:
		name = "Visores"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(260, 66)

	func _draw() -> void:
		var w := (size.x - 8.0) / 2.0
		var datos := [[str(dn), "DN", "INTERIOR · %s\"" % pulgadas, Tema.ARI_LCD_VERDE], [str(presion), "bar", "TRABAJO MÁXIMO", Tema.ARI_LCD_AMBAR]]
		for i in 2:
			var caja := Rect2(i * (w + 8.0), 0, w, 64.0)
			DibujoAri.sombra(self, caja, 8.0, 0.5, Vector2(0, 2))
			DibujoAri.degradado(self, caja, 8.0, [Color("05080a"), Color("2a3b48")])
			PiezasAri.visor(self, Rect2(caja.position + Vector2(6, 6), Vector2(caja.size.x - 12.0, 32.0)), 1.0, datos[i][0], datos[i][1], datos[i][3], 20.0)
			PiezasAri.texto(self, datos[i][2], caja.get_center().x, caja.end.y - 9.0, float(Tema.tam(9.5)), Color("a9b6c1"), Tema.PESO_NEGRITA)
