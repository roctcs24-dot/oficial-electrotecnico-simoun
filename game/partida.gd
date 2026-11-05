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
const PUNTOS_MISION := 50
const PUNTOS_EXAMEN := 100
## Tras cada acierto en el repaso, el tema vuelve a preguntarse más tarde. Al superar el
## último intervalo queda resuelto, aunque sus fallos siguen en las estadísticas.
const INTERVALOS_REPASO_DIAS := [1, 3, 7, 14, 30]
const SEGUNDOS_POR_DIA := 86400.0
const APARTADOS := ["fichas_vistas", "lecciones", "misiones", "errores", "equipos_danados", "minijuegos", "examenes"]

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
		"examenes": {},
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
	for clave: String in APARTADOS:
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
	# En Android el selector devuelve una URI: se abre directamente, sin comprobar una ruta.
	var archivo := FileAccess.open(origen, FileAccess.READ)
	if archivo == null:
		return "no se encontró el archivo"
	return importar_texto(archivo.get_as_text())


func importar_texto(texto: String) -> String:
	var motivo := desde_texto(texto)
	if not motivo.is_empty():
		return motivo
	return "" if guardar() else "no se pudo guardar la partida importada"


## Sin cambiar nada: devuelve {motivo, puntos}, para pedir confirmación antes de reemplazar.
static func examinar(texto: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(texto) != OK:
		return {"motivo": "el archivo está dañado", "puntos": 0}
	var motivo := validar(json.data)
	if not motivo.is_empty():
		return {"motivo": motivo, "puntos": 0}
	return {"motivo": "", "puntos": int(json.data.get("puntos", 0))}


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


## Conserva la mejor calificación. La primera vez completada suma su base, y después solo
## suman las estrellas nuevas; devuelve los puntos ganados. Un accidente no suma.
func registrar_mision(id: String, estrellas: int, completada: bool) -> int:
	var misiones: Dictionary = datos["misiones"]
	var previo: Dictionary = misiones.get(id, {"estrellas": 0, "intentos": 0, "accidentes": 0, "completada": false})
	var mejor := int(previo["estrellas"])
	var ganados := maxi(estrellas - mejor, 0) * PUNTOS_ESTRELLA
	if completada and not previo["completada"]:
		ganados += PUNTOS_MISION
	datos["puntos"] += ganados
	misiones[id] = {
		"estrellas": maxi(mejor, estrellas),
		"intentos": int(previo["intentos"]) + 1,
		"accidentes": int(previo["accidentes"]) + (0 if completada else 1),
		"completada": completada or previo["completada"],
	}
	guardar()
	return ganados


func danos_mision(id: String) -> Dictionary:
	return datos["equipos_danados"].get(id, {})


## Un equipo dañado sigue así en el siguiente intento, hasta que se cambie el repuesto.
func guardar_danos_mision(id: String, danos: Dictionary) -> void:
	if danos.is_empty():
		datos["equipos_danados"].erase(id)
	else:
		datos["equipos_danados"][id] = danos
	guardar()


## Conserva el mejor resultado. El primer aprobado suma su base, y después solo suman las
## estrellas nuevas; devuelve los puntos ganados.
func registrar_examen(id: String, porcentaje: float, estrellas: int, aprobado: bool) -> int:
	var examenes: Dictionary = datos["examenes"]
	var previo: Dictionary = examenes.get(id, {"mejor": 0.0, "estrellas": 0, "aprobado": false, "intentos": 0})
	var mejor_estrellas := int(previo["estrellas"])
	var ganados := maxi(estrellas - mejor_estrellas, 0) * PUNTOS_ESTRELLA
	if aprobado and not previo["aprobado"]:
		ganados += PUNTOS_EXAMEN
	datos["puntos"] += ganados
	examenes[id] = {
		"mejor": maxf(float(previo["mejor"]), porcentaje),
		"estrellas": maxi(mejor_estrellas, estrellas),
		"aprobado": aprobado or previo["aprobado"],
		"intentos": int(previo["intentos"]) + 1,
	}
	guardar()
	return ganados


## Cada fallo alimenta el repaso de errores: el tema vuelve al principio de los intervalos.
func registrar_error(tema: String, ahora := -1.0) -> void:
	var momento := ahora if ahora >= 0.0 else Time.get_unix_time_from_system()
	var errores: Dictionary = datos["errores"]
	var previo: Dictionary = errores.get(tema, {"fallos": 0})
	errores[tema] = {"fallos": int(previo["fallos"]) + 1, "ultimo": momento, "caja": 0, "proximo": momento}
	guardar()


## Temas que toca repasar, primero los más fallados. Una partida antigua no tiene "proximo":
## sus temas quedan pendientes desde el principio.
func temas_pendientes(ahora := -1.0) -> Array[String]:
	var momento := ahora if ahora >= 0.0 else Time.get_unix_time_from_system()
	var errores: Dictionary = datos["errores"]
	var lista: Array[String] = []
	for tema: String in errores:
		if not errores[tema].get("resuelto", false) and float(errores[tema].get("proximo", 0.0)) <= momento:
			lista.append(tema)
	lista.sort_custom(func(a: String, b: String) -> bool:
		return int(errores[a]["fallos"]) > int(errores[b]["fallos"]))
	return lista


## Un acierto aleja el siguiente repaso; un fallo lo reinicia y cuenta como fallo.
func registrar_repaso(tema: String, acierto: bool, ahora := -1.0) -> void:
	if not acierto:
		registrar_error(tema, ahora)
		var e: Dictionary = datos["errores"][tema]
		e["proximo"] = float(e["ultimo"]) + SEGUNDOS_POR_DIA
		guardar()
		return
	var momento := ahora if ahora >= 0.0 else Time.get_unix_time_from_system()
	var entrada: Dictionary = datos["errores"].get(tema, {"fallos": 0})
	var caja := int(entrada.get("caja", 0))
	if caja >= INTERVALOS_REPASO_DIAS.size():
		entrada["resuelto"] = true
	else:
		entrada["proximo"] = momento + INTERVALOS_REPASO_DIAS[caja] * SEGUNDOS_POR_DIA
		entrada["caja"] = caja + 1
	datos["errores"][tema] = entrada
	guardar()


## Los temas más fallados, para las estadísticas.
func temas_mas_fallados(cantidad: int) -> Array[String]:
	var errores: Dictionary = datos["errores"]
	var lista: Array[String] = []
	for tema: String in errores:
		lista.append(tema)
	lista.sort_custom(func(a: String, b: String) -> bool:
		return int(errores[a]["fallos"]) > int(errores[b]["fallos"]))
	return lista.slice(0, cantidad)


func total_fallos() -> int:
	var total := 0
	for e: Dictionary in datos["errores"].values():
		total += int(e["fallos"])
	return total


## Puntos que faltan para el rango siguiente, y su nombre. En el último rango no hay siguiente.
func siguiente_rango(rangos: Array) -> Dictionary:
	for r: Dictionary in rangos:
		if datos["puntos"] < r["puntos"]:
			return {"nombre": r["nombre"], "faltan": int(r["puntos"]) - int(datos["puntos"])}
	return {}


## Avance hacia el rango siguiente, de 0 a 1. En el último rango vale 1.
func progreso_rango(rangos: Array) -> float:
	var puntos: float = datos["puntos"]
	var base := 0.0
	for r in rangos:
		if puntos >= float(r["puntos"]):
			base = r["puntos"]
		else:
			return (puntos - base) / (float(r["puntos"]) - base)
	return 1.0


## rangos va de menor a mayor: [{nombre, puntos}].
func rango(rangos: Array) -> String:
	var actual := ""
	for r in rangos:
		if datos["puntos"] >= r["puntos"]:
			actual = r["nombre"]
	return actual
