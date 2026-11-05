extends Control
## Pantalla inicial provisional de la etapa 0. Comprueba que el contenido
## de data/ viaja dentro del juego exportado.

const RUTA_BARCO := "res://data/barco_via_simoun.json"

@onready var _estado: Label = %Estado


func _ready() -> void:
	var barco := _cargar_barco()
	if barco.is_empty():
		_estado.text = "No se pudo cargar %s" % RUTA_BARCO
		return
	var red: Dictionary = barco["red_principal"]
	_estado.text = "%s\nRed principal: %d V, %d Hz, trifásica\nGeneradores: %d" % [
		barco["nombre"],
		red["tension_v"]["valor"],
		red["frecuencia_hz"]["valor"],
		barco["generacion"]["cantidad"]["valor"],
	]


func _cargar_barco() -> Dictionary:
	var texto := FileAccess.get_file_as_string(RUTA_BARCO)
	var datos: Variant = JSON.parse_string(texto)
	return datos if datos is Dictionary else {}
