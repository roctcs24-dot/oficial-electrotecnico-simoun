class_name Partida
extends RefCounted
## Progreso del jugador en un JSON. Cada guardado escribe primero un temporal y conserva
## el anterior como copia, así un corte de corriente no deja la partida a medias.

const ID_JUEGO := "oficial-electrotecnico-simoun"
const VERSION := 1
const RUTA := "user://partida.json"
const PUNTOS_LECCION := 20
const PUNTOS_ACIERTO := 5
const PUNTOS_ESTRELLA := 10

var ruta := RUTA
var datos := datos_nuevos()
## Mensaje para el jugador si al cargar hubo que recuperar algo.
var aviso := ""


static func datos_nuevos() -> Dictionary:
	return {
		"juego": ID_JUEGO,
		"version": VERSION,
		"puntos": 0,
		"fichas_vistas": {},
		"lecciones": {},
		"misiones": {},
		"errores": {},
		"equipos_danados": {},
		"minijuegos": {},
	}


## Devuelve "" si el valor es una partida utilizable, o el motivo por el que no lo es.
static func validar(valor: Variant) -> String:
	if not valor is Dictionary:
		return "no es una partida"
	var d: Dictionary = valor
	if d.get("juego") != ID_JUEGO:
		return "es de otro juego"
	if not (d.get("version") is float or d.get("version") is int):
		return "no indica su versión"
	if d["version"] > VERSION:
		return "es de una versión más nueva del juego"
	if not (d.get("puntos", 0) is float or d.get("puntos", 0) is int) or d.get("puntos", 0) < 0:
		return "tiene puntos no válidos"
	for clave in ["fichas_vistas", "lecciones", "misiones", "errores", "equipos_danados", "minijuegos"]:
		if not d.get(clave, {}) is Dictionary:
			return "tiene dañado el apartado %s" % clave
	return ""


func _init(ruta_archivo := RUTA) -> void:
	ruta = ruta_archivo


func a_texto() -> String:
	return JSON.stringify(datos, "\t")


## Sustituye los datos si el texto es válido. Devuelve "" o el motivo del rechazo.
func desde_texto(texto: String) -> String:
	var json := JSON.new()
	if json.parse(texto) != OK:
		return "el archivo está dañado"
	var motivo := validar(json.data)
	if not motivo.is_empty():
		return motivo
	var nuevos := datos_nuevos()
	nuevos.merge(json.data, true)
	nuevos["version"] = VERSION
	datos = nuevos
	return ""


func guardar() -> bool:
	var temporal := ruta + ".tmp"
	var archivo := FileAccess.open(temporal, FileAccess.WRITE)
	if archivo == null:
		aviso = "No se pudo guardar la partida."
		return false
	archivo.store_string(a_texto())
	archivo.close()
	if FileAccess.file_exists(ruta):
		DirAccess.rename_absolute(ruta, ruta + ".bak")
	if DirAccess.rename_absolute(temporal, ruta) != OK:
		aviso = "No se pudo guardar la partida."
		return false
	return true


## Carga la partida, o la copia anterior si está dañada. Sin ninguna de las dos empieza de cero.
func cargar() -> void:
	aviso = ""
	var existia := FileAccess.file_exists(ruta)
	if existia and desde_texto(FileAccess.get_file_as_string(ruta)).is_empty():
		return
	var copia := ruta + ".bak"
	if FileAccess.file_exists(copia) and desde_texto(FileAccess.get_file_as_string(copia)).is_empty():
		if existia:
			aviso = "La partida estaba dañada: se recuperó la copia anterior."
		return
	datos = datos_nuevos()
	if existia:
		# El archivo dañado se aparta en vez de borrarse: quizá aún se pueda rescatar.
		DirAccess.rename_absolute(ruta, ruta + ".danada")
		aviso = "La partida estaba dañada y no había copia: se empieza de nuevo."


func exportar(destino: String) -> bool:
	var archivo := FileAccess.open(destino, FileAccess.WRITE)
	if archivo == null:
		return false
	archivo.store_string(a_texto())
	archivo.close()
	return true


## Reemplaza la partida por la del archivo. Devuelve "" o el motivo del rechazo,
## y en ese caso la partida actual no cambia.
func importar(origen: String) -> String:
	if not FileAccess.file_exists(origen):
		return "no se encontró el archivo"
	var motivo := desde_texto(FileAccess.get_file_as_string(origen))
	if not motivo.is_empty():
		return motivo
	return "" if guardar() else "no se pudo guardar la partida importada"


func marcar_ficha_vista(id: String) -> void:
	if datos["fichas_vistas"].has(id):
		return
	datos["fichas_vistas"][id] = true
	guardar()


func ficha_vista(id: String) -> bool:
	return datos["fichas_vistas"].has(id)


func leccion_completada(id: String) -> bool:
	return datos["lecciones"].has(id)


## Conserva el mejor resultado. Los puntos solo se suman la primera vez; devuelve los ganados.
func completar_leccion(id: String, aciertos: int, total: int) -> int:
	var lecciones: Dictionary = datos["lecciones"]
	var ganados := 0
	if lecciones.has(id):
		lecciones[id]["aciertos"] = maxi(int(lecciones[id]["aciertos"]), aciertos)
	else:
		ganados = PUNTOS_LECCION + PUNTOS_ACIERTO * aciertos
		datos["puntos"] += ganados
		lecciones[id] = {"aciertos": aciertos, "total": total}
	guardar()
	return ganados


## Solo suman puntos las estrellas nuevas; devuelve los ganados.
func registrar_minijuego(id: String, estrellas: int) -> int:
	var juegos: Dictionary = datos["minijuegos"]
	var previo: Dictionary = juegos.get(id, {"estrellas": 0, "partidas": 0})
	var mejor := int(previo["estrellas"])
	var ganados := maxi(estrellas - mejor, 0) * PUNTOS_ESTRELLA
	datos["puntos"] += ganados
	juegos[id] = {"estrellas": maxi(mejor, estrellas), "partidas": int(previo["partidas"]) + 1}
	guardar()
	return ganados


## Cada fallo alimenta el repaso de errores.
func registrar_error(tema: String) -> void:
	var errores: Dictionary = datos["errores"]
	var previo: Dictionary = errores.get(tema, {"fallos": 0})
	errores[tema] = {"fallos": int(previo["fallos"]) + 1, "ultimo": Time.get_unix_time_from_system()}
	guardar()


## rangos va de menor a mayor: [{nombre, puntos}].
func rango(rangos: Array) -> String:
	var actual := ""
	for r in rangos:
		if datos["puntos"] >= r["puntos"]:
			actual = r["nombre"]
	return actual
