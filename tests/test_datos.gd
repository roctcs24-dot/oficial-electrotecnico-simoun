extends RefCounted
## Cada prueba devuelve "" si pasa, o el motivo del fallo.

const RUTA_BARCO := "res://data/barco_via_simoun.json"


func test_barco_es_json_valido() -> String:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_BARCO))
	return "" if datos is Dictionary else "%s no es un objeto JSON" % RUTA_BARCO


func test_red_principal_coincide_con_el_barco() -> String:
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RUTA_BARCO))
	var red: Dictionary = datos["red_principal"]
	if not is_equal_approx(float(red["tension_v"]["valor"]), SimRed.V_LINEA):
		return "la tensión del barco debe coincidir con la de la simulación, %d V" % SimRed.V_LINEA
	if not is_equal_approx(float(red["frecuencia_hz"]["valor"]), SimRed.F_HZ):
		return "la frecuencia del barco debe coincidir con la de la simulación, %d Hz" % SimRed.F_HZ
	if datos["generacion"]["cantidad"]["valor"] != 4:
		return "deben ser 4 generadores"
	return ""
