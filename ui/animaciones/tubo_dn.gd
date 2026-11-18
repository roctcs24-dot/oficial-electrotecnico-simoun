extends Animacion
## Tubos de varios DN (params «dn», por defecto 15, 25, 50 y 100) con su diámetro exterior: una
## tecla por DN y, debajo, su NPS y su exterior (data/tablas/roscas.json).

const ALTO := 170.0

var tubo: TuboDN
var lista: Array = []
var _filas := {}
var _botones: Array[Button] = []
var _nombre: Label
var _nota: Label


func preparar() -> void:
	lienzo.custom_minimum_size.y = ALTO
	lista = params.get("dn", [15, 25, 50, 100])
	if contenido != null:
		for f: Dictionary in contenido.leer("tablas/roscas.json").get("dn", []):
			_filas[int(f["dn"])] = f
	tubo = TuboDN.new()
	tubo.set_anchors_preset(Control.PRESET_FULL_RECT)
	lienzo.add_child(tubo)
	var c := tarjeta_mandos()
	var fila := GridContainer.new()
	fila.columns = mini(lista.size(), 4)
	fila.add_theme_constant_override("h_separation", 6)
	c.add_child(fila)
	for dn in lista:
		var b := boton_mando(fila, elegir.bind(int(dn)))
		b.text = "DN%d" % int(dn)
		_botones.append(b)
	_nombre = Label.new()
	_nombre.theme_type_variation = "Fuerte"
	c.add_child(_nombre)
	_nota = nota_mandos(c)
	elegir(int(lista[0]))


func elegir(dn: int) -> void:
	var f: Dictionary = _filas.get(dn, {"dn": dn, "nps": "?", "exterior": 60.3})
	tubo.exterior = float(f["exterior"])
	for i in _botones.size():
		_botones[i].modulate = Color(1, 1, 1, 1.0 if int(lista[i]) == dn else 0.55)
	if _nombre != null:
		_nombre.text = "DN%d = %s\" NPS" % [dn, f["nps"]]
		_nota.text = "Exterior %s mm. El interior depende del espesor (cédula)." % JuegoRacores.mm(float(f["exterior"]))


func dibujar() -> void:
	DibujoAri.degradado(lienzo, Rect2(Vector2.ZERO, lienzo.size), 10.0, [Color("26313c"), Color("141b22")])
