class_name MisionBase
extends RefCounted
## Lo común a todas las misiones de Guardia: reporte, pistas, diagnóstico, faltas del
## procedimiento, informe de accidente o de incidente, libro de registro y calificación.
## Las acciones devuelven un aviso {tipo, titulo, texto}, donde tipo es hecho, aviso, error
## o accidente.

var contenido: Contenido
var datos: Dictionary
## guardia.json: faltas, accidentes, incidentes y sus preguntas de repaso.
var comunes: Dictionary
## "" mientras está en curso; después, "accidente" o "completada". Un incidente del cuadro
## también termina en "accidente": el informe dice cuál fue.
var fin := ""
var accidente := {}
## Marcas del procedimiento, como epp o aviso, y las que ponen las acciones de la misión.
var hechos := {}
var acciones_hechas: Array[String] = []
var faltas: Array[Dictionary] = []
var pistas_usadas := 0
var diagnostico_ok := false
var prueba_ok := false


func _init(contenido_juego: Contenido, id_mision: String) -> void:
	contenido = contenido_juego
	datos = contenido.mision(id_mision)
	comunes = contenido.leer("guardia.json")


func id() -> String:
	return datos["id"]


# --- Pistas ---

func hay_pista() -> bool:
	return pistas_usadas < datos.get("pistas", []).size()


func siguiente_pista() -> String:
	var pista: String = datos["pistas"][pistas_usadas]
	pistas_usadas += 1
	return pista


# --- Diagnóstico ---

## Las pruebas que debe haber reunido antes de diagnosticar. Cada misión decide cuáles son.
func evidencias_completas() -> bool:
	return true


func diagnosticar(indice: int) -> Dictionary:
	var d: Dictionary = datos["diagnostico"]
	var opcion: Dictionary = d["opciones"][indice]
	if not opcion.get("correcta", false):
		var titulo: String = "Diagnóstico incorrecto: %s" % opcion["texto"]
		_anotar_falta("diagnostico_%s" % id(), titulo, opcion["explicacion"])
		return _aviso("error", titulo, opcion["explicacion"])
	diagnostico_ok = true
	hechos["diagnostico"] = true
	if not evidencias_completas():
		var falta := _falta("diagnostico_sin_medir")
		return _aviso("error", falta["titulo"], "%s\n\n%s" % [opcion["explicacion"], falta["texto"]])
	return _aviso("hecho", "Diagnóstico confirmado", opcion["explicacion"])


# --- Libro de registro ---

func campos_libro() -> Array:
	return datos["libro"]["campos"]


func puede_firmar() -> bool:
	return prueba_ok and diagnostico_ok


## respuestas: índice elegido por campo. Devuelve lo que falta corregir, o completa la misión.
func firmar(respuestas: Dictionary) -> Dictionary:
	if not puede_firmar():
		return _aviso("aviso", "Todavía no", "Antes de firmar, confirme el diagnóstico y supere la prueba en servicio.")
	var campos := campos_libro()
	for i in campos.size():
		if not respuestas.has(i):
			return _aviso("aviso", "Libro incompleto", "Complete: %s." % campos[i]["etiqueta"])
		if int(respuestas[i]) != int(campos[i]["correcta"]):
			var titulo: String = "Dato incorrecto: %s" % campos[i]["etiqueta"]
			_anotar_falta("libro_%s" % id(), titulo, campos[i]["explicacion"])
			return _aviso("error", titulo, campos[i]["explicacion"])
	fin = "completada"
	return _aviso("hecho", "Libro firmado", "Avería cerrada.")


# --- Resultado ---

func estrellas() -> int:
	if fin != "completada":
		return 0
	if faltas.is_empty() and pistas_usadas == 0:
		return 3
	return 2 if faltas.size() <= 2 else 1


## Piezas dañadas al terminar, que quedan así hasta que se cambie el repuesto.
func danos() -> Dictionary:
	return {}


## Termina la misión con su informe. grupo es "accidentes" o "incidentes" de guardia.json; la
## misión puede cambiar los textos con su propio apartado del mismo nombre.
func _ocurre_accidente(tipo: String, grupo := "accidentes") -> Dictionary:
	var informe: Dictionary = comunes[grupo][tipo].duplicate()
	informe.merge(datos.get(grupo, {}).get(tipo, {}), true)
	accidente = informe
	accidente["tema"] = "%s_%s" % [grupo.trim_suffix("s"), tipo]
	fin = "accidente"
	return _aviso("accidente", informe["titulo"], informe["que_ocurrio"])


func _aviso(tipo: String, titulo: String, texto: String) -> Dictionary:
	return {"tipo": tipo, "titulo": titulo, "texto": texto}


func _falta(tema: String) -> Dictionary:
	var f: Dictionary = comunes["faltas"][tema]
	_anotar_falta(tema, f["titulo"], f["texto"])
	return _aviso("error", f["titulo"], f["texto"])


## Cada falta cuenta una sola vez por misión.
func _anotar_falta(tema: String, titulo: String, texto: String) -> void:
	for f: Dictionary in faltas:
		if f["tema"] == tema and f["titulo"] == titulo:
			return
	faltas.append({"tema": tema, "titulo": titulo, "texto": texto})
