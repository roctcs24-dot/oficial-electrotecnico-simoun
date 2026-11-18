class_name FotosPiezas
extends RefCounted
## Fotos de piezas tomadas a bordo (data/fotos_piezas.json). Cada foto se prepara recortada en
## art/fotos con tools/fotos/preparar_fotos.gd; «recorte» y «halo» están en píxeles de la foto
## original, y aquí el halo se pasa a fracciones de la foto recortada.

const ARCHIVO := "fotos_piezas.json"


## Fotos de una pieza del catálogo («bola», «mariposa»…), en el orden del archivo.
static func de_pieza(datos: Dictionary, pieza: String) -> Array:
	return datos.get("fotos", []).filter(func(f: Dictionary) -> bool: return str(f.get("pieza", "")) == pieza and existe(f))


## Fotos con estado conocido («abierta» o «cerrada»): las que sirven para el minijuego.
static func con_estado(datos: Dictionary) -> Array:
	return datos.get("fotos", []).filter(func(f: Dictionary) -> bool: return str(f.get("estado", "")) in ["abierta", "cerrada"] and existe(f))


static func existe(foto: Dictionary) -> bool:
	return ResourceLoader.exists("res://" + str(foto.get("archivo", "")))


static func textura(foto: Dictionary) -> Texture2D:
	if not existe(foto):
		return null
	return load("res://" + str(foto["archivo"])) as Texture2D


## El halo como fracción (0 a 1) de la foto recortada; vacío si la foto no lo trae.
static func halo_relativo(foto: Dictionary) -> Rect2:
	var r: Array = foto.get("recorte", [])
	var h: Array = foto.get("halo", [])
	if r.size() != 4 or h.size() != 4 or float(r[2]) <= 0.0 or float(r[3]) <= 0.0:
		return Rect2()
	return Rect2((float(h[0]) - float(r[0])) / float(r[2]), (float(h[1]) - float(r[1])) / float(r[3]),
		float(h[2]) / float(r[2]), float(h[3]) / float(r[3]))
