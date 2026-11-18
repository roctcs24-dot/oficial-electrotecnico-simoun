extends SceneTree
## Prepara las fotos de piezas del buque: lee data/fotos_piezas.json, recorta cada foto original
## («origen» dentro de la carpeta que se pase como argumento, «recorte» en píxeles), la reduce a
## LADO_MAX píxeles por el lado largo y la guarda en WebP en «archivo».
##
## Uso (desde la carpeta del proyecto):
##   godot --headless --path . --script res://tools/fotos/preparar_fotos.gd -- C:/ruta/fotos_via_simoun/piezas
## Después, «godot --headless --path . --import» para que el juego vea las fotos nuevas.

const LADO_MAX := 1024
const CALIDAD := 0.8


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	if argumentos.is_empty():
		printerr("Falta la carpeta de las fotos originales.")
		quit(1)
		return
	var carpeta := str(argumentos[0]).trim_suffix("/").trim_suffix("\\")
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/fotos_piezas.json"))
	var errores := 0
	for f: Dictionary in datos.get("fotos", []):
		var origen := carpeta + "/" + str(f["origen"])
		var imagen := Image.load_from_file(origen)
		if imagen == null or imagen.is_empty():
			printerr("No se pudo leer ", origen)
			errores += 1
			continue
		var r: Array = f["recorte"]
		var region := Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])).intersection(Rect2i(Vector2i.ZERO, imagen.get_size()))
		var recorte := imagen.get_region(region)
		var escala := minf(1.0, float(LADO_MAX) / maxf(region.size.x, region.size.y))
		if escala < 1.0:
			recorte.resize(roundi(region.size.x * escala), roundi(region.size.y * escala), Image.INTERPOLATE_LANCZOS)
		var destino := ProjectSettings.globalize_path("res://" + str(f["archivo"]))
		DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
		var error := recorte.save_webp(destino, true, CALIDAD)
		if error != OK:
			printerr("No se pudo guardar ", destino)
			errores += 1
			continue
		print("%s  %dx%d  %d KB" % [f["archivo"], recorte.get_width(), recorte.get_height(), FileAccess.get_file_as_bytes(destino).size() / 1024])
	quit(1 if errores > 0 else 0)
