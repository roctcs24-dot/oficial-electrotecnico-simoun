extends SceneTree
## Pasa los PNG de Chrome a WebP con pérdida (calidad 0,9): -- <png> <webp> [<png> <webp> ...]

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i + 1 < a.size():
		var img := Image.load_from_file(a[i])
		if img == null or img.is_empty():
			printerr("No se pudo leer ", a[i])
		else:
			img.save_webp(a[i + 1], true, 0.9)
			print(a[i + 1].get_file(), " ", img.get_size(), " ", FileAccess.get_file_as_bytes(a[i + 1]).size() / 1024, " KB")
		i += 2
	quit()
