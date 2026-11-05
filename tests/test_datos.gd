extends RefCounted
## Cada prueba devuelve "" si pasa, o el motivo del fallo.

const RUTA_BARCO := "res://data/barco_via_simoun.json"


func test_barco_es_json_valido() -> String:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_BARCO))
	return "" if datos is Dictionary else "%s no es un objeto JSON" % RUTA_BARCO


func test_red_principal_coincide_con_el_barco() -> String:
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RUTA_BARCO))
	var red: Dictionary = datos["red_principal"]
	if red["tension_v"]["valor"] != 440:
		return "la tensión debe ser 440 V"
	if red["frecuencia_hz"]["valor"] != 60:
		return "la frecuencia debe ser 60 Hz"
	if datos["generacion"]["cantidad"]["valor"] != 3:
		return "deben ser 3 generadores"
	return ""
