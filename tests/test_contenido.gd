extends RefCounted
## Validación del contenido de data/: una referencia rota debe detectarse aquí, no a bordo.

const A := preload("res://tests/ayuda_sim.gd")
const SECCIONES_FICHA := ["funcion", "partes", "conexion", "ajuste", "pruebas", "fallas", "mantenimiento"]


func _archivos_json(carpeta: String, lista: Array[String]) -> void:
	for f in DirAccess.get_files_at(carpeta):
		if f.ends_with(".json"):
			lista.append(carpeta.path_join(f))
	for d in DirAccess.get_directories_at(carpeta):
		_archivos_json(carpeta.path_join(d), lista)


func test_todos_los_json_son_validos() -> String:
	var lista: Array[String] = []
	_archivos_json("res://data", lista)
	if lista.is_empty():
		return "no se encontró contenido"
	for ruta in lista:
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(ruta)) != OK:
			return "%s, línea %d: %s" % [ruta, json.get_error_line(), json.get_error_message()]
	return ""


func test_todos_los_circuitos_cargan() -> String:
	var c := Contenido.new()
	for f in DirAccess.get_files_at("res://data/circuitos"):
		var sim := c.circuito(f.get_basename())
		if sim == null:
			return "no carga %s" % f
		sim.paso()
	return "; ".join(c.errores)


func test_sistemas_cubren_0_a_6_y_v1_activos() -> String:
	var c := Contenido.new()
	var ids := []
	for s: Dictionary in c.sistemas():
		ids.append(int(s["id"]))
		var z: Array = s["zona"]
		if z[0] < 0 or z[1] < 0 or z[0] + z[2] > 1000 or z[1] + z[3] > 420:
			return "la zona del sistema %d se sale del plano" % int(s["id"])
	return A.primero([
		A.cierto(ids == [0, 1, 2, 3, 4, 5, 6], "deben estar los sistemas 0 a 6: %s" % str(ids)),
		A.cierto(c.sistema(0)["estado"] == "activo", "el sistema 0 es de la v1"),
		A.cierto(c.sistema(3)["estado"] == "activo", "el sistema 3 es de la v1"),
	])


func test_referencias_de_los_sistemas_existen() -> String:
	var c := Contenido.new()
	for s: Dictionary in c.sistemas():
		for id: String in s["modos"].get("aprender", {}).get("fichas", []):
			if c.ficha(id).is_empty():
				return "el sistema %d apunta a una ficha que no existe: %s" % [int(s["id"]), id]
	return "; ".join(c.errores)


func test_fichas_completas_y_con_terminos_del_glosario() -> String:
	var c := Contenido.new()
	var glosario := c.glosario()
	for f in DirAccess.get_files_at("res://data/fichas"):
		var ficha := c.ficha(f.get_basename())
		var ids := []
		for seccion: Dictionary in ficha["secciones"]:
			ids.append(seccion["id"])
			for t in TextoTecnico.terminos(seccion["texto"]):
				if not glosario.has(t):
					return "%s usa un término fuera del glosario: %s" % [f, t]
		for requerida in SECCIONES_FICHA:
			if not ids.has(requerida):
				return "a %s le falta la sección %s" % [f, requerida]
		if ficha.get("para_saber_mas", []).is_empty():
			return "a %s le falta Para saber más" % f
	return "; ".join(c.errores)


func test_dibujos_de_las_fichas_se_pueden_rasterizar() -> String:
	var c := Contenido.new()
	var rutas: Array = [c.plano()["svg"]]
	for f in DirAccess.get_files_at("res://data/fichas"):
		var ficha := c.ficha(f.get_basename())
		rutas.append(ficha["dibujo"]["svg"])
		for extra: Dictionary in ficha.get("dibujos_extra", []):
			rutas.append(extra["svg"])
		if ficha["simbolos"].has("lista"):
			for id: String in ficha["simbolos"]["lista"]:
				if c.simbolo(id).is_empty():
					return "%s usa un símbolo que no existe: %s" % [f, id]
		else:
			rutas.append_array([ficha["simbolos"]["iec"]["svg"], ficha["simbolos"]["ansi"]["svg"]])
	for s: Dictionary in c.simbolos():
		rutas.append_array([s["iec"]["svg"], s["ansi"]["svg"]])
	for ruta: String in rutas:
		var textura := VistaSvg.rasterizar(ruta, 0.5)
		if textura == null or textura.get_width() == 0:
			return "no se puede dibujar %s" % ruta
	return ""


## Sin importer="keep", Godot exporta solo la versión importada: los dibujos funcionarían
## en el editor pero faltarían en el APK y el .exe.
func test_los_svg_se_exportan_tal_cual() -> String:
	var lista: Array[String] = []
	_archivos_svg("res://art", lista)
	if lista.is_empty():
		return "no se encontraron dibujos"
	for ruta in lista:
		if not FileAccess.get_file_as_string(ruta + ".import").contains("importer=\"keep\""):
			return "%s.import debe contener importer=\"keep\"" % ruta
	return ""


func _archivos_svg(carpeta: String, lista: Array[String]) -> void:
	for f in DirAccess.get_files_at(carpeta):
		if f.ends_with(".svg"):
			lista.append(carpeta.path_join(f))
	for d in DirAccess.get_directories_at(carpeta):
		_archivos_svg(carpeta.path_join(d), lista)


func test_componentes_de_la_v1_tienen_ficha_y_simbolo() -> String:
	var c := Contenido.new()
	var publicadas: Array = c.sistema(3)["modos"]["aprender"]["fichas"]
	for id in ["motor_trifasico", "contactor", "rele_termico", "guardamotor", "pulsador"]:
		if not publicadas.has(id):
			return "falta publicar la ficha %s" % id
	for id in ["bobina", "contacto_principal", "contacto_na", "contacto_nc", "rele_termico", "guardamotor", "pulsador_na", "pulsador_nc", "motor"]:
		if c.simbolo(id).is_empty():
			return "falta el símbolo %s" % id
	var extras: Array = c.ficha("motor_trifasico")["dibujos_extra"]
	return A.cierto(extras.size() >= 3, "el motor debe mostrar placa y bornera en estrella y delta")


func test_equipos_de_generacion_tienen_ficha_y_simbolo() -> String:
	var c := Contenido.new()
	var publicadas: Array = c.sistema(1)["modos"]["aprender"]["fichas"]
	for id in ["alternador", "avr", "acb", "rele_potencia_inversa", "sincronoscopio", "controlador_generador", "monitor_aislamiento", "generador_emergencia"]:
		if not publicadas.has(id):
			return "falta publicar la ficha %s" % id
	for id in ["generador", "interruptor_potencia", "rele_potencia_inversa", "sincronoscopio", "monitor_aislamiento"]:
		if c.simbolo(id).is_empty():
			return "falta el símbolo %s" % id
	return A.cierto(c.ficha("alternador").get("dibujos_extra", []).size() >= 1, "el alternador debe mostrar su placa")


func test_rondas_del_minijuego_son_validas() -> String:
	var c := Contenido.new()
	var azar := RandomNumberGenerator.new()
	azar.seed = 4
	for _intento in 30:
		var rondas := JuegoSimbolos.crear_rondas(c.simbolos(), 10, azar)
		if rondas.size() != 10:
			return "debe haber 10 rondas"
		for r: Dictionary in rondas:
			var opciones: Array = r["opciones"]
			var distintas := {}
			for o: String in opciones:
				distintas[o] = true
			if opciones.size() != 4 or distintas.size() != 4:
				return "deben ser 4 opciones distintas: %s" % str(opciones)
			if opciones[r["correcta"]] != r["id"]:
				return "la respuesta correcta no coincide"
			for similar: String in c.simbolo(r["id"]).get("similares", []):
				if opciones.has(similar):
					return "%s y %s comparten dibujo y no pueden ofrecerse juntos" % [r["id"], similar]
	return ""


func test_el_minijuego_cubre_los_simbolos_sin_repetir() -> String:
	var c := Contenido.new()
	var azar := RandomNumberGenerator.new()
	azar.seed = 9
	var ids := {}
	for r: Dictionary in JuegoSimbolos.crear_rondas(c.simbolos(), 10, azar):
		ids[r["id"]] = true
	return A.cierto(ids.size() == 10, "10 rondas no deben repetir símbolos: %d distintos" % ids.size())


## Cada minijuego y cada examen preguntan solo los símbolos de su sistema.
func test_simbolos_separados_por_sistema() -> String:
	var c := Contenido.new()
	for s: Dictionary in c.simbolos():
		if not int(s.get("sistema", -1)) in [1, 2, 3, 4, 5, 6]:
			return "el símbolo %s no indica su sistema" % s["id"]
	var azar := RandomNumberGenerator.new()
	azar.seed = 5
	for sistema in [1, 2, 3, 4, 5, 6]:
		var ids := {}
		for r: Dictionary in JuegoSimbolos.crear_rondas(c.simbolos(sistema), 10, azar):
			ids[r["id"]] = true
			for o: String in r["opciones"]:
				if int(c.simbolo(o)["sistema"]) != sistema:
					return "el minijuego del sistema %d ofrece %s" % [sistema, o]
		if ids.size() != 10:
			return "el sistema %d debe tener 10 símbolos distintos: %d" % [sistema, ids.size()]
	for par in [["v1", 3], ["v2", 1], ["v3", 4], ["v4", 6], ["v5", 2]]:
		var datos := c.examen(par[0])
		if int(datos["sistema_simbolos"]) != par[1]:
			return "el examen %s debe preguntar los símbolos del sistema %d" % par
		for item: Dictionary in ExamenTeorico.crear(datos, c.simbolos(par[1]), azar):
			if item["tipo"] == "simbolo" and int(c.simbolo(item["id"])["sistema"]) != par[1]:
				return "el examen %s pregunta un símbolo de otro sistema: %s" % [par[0], item["id"]]
	return ""


func test_estrellas_del_minijuego() -> String:
	return A.primero([
		A.cierto(JuegoSimbolos.estrellas(10, 10) == 3, "10 de 10"),
		A.cierto(JuegoSimbolos.estrellas(9, 10) == 3, "9 de 10"),
		A.cierto(JuegoSimbolos.estrellas(7, 10) == 2, "7 de 10"),
		A.cierto(JuegoSimbolos.estrellas(5, 10) == 1, "5 de 10"),
		A.cierto(JuegoSimbolos.estrellas(4, 10) == 0, "4 de 10"),
		A.cierto(JuegoSimbolos.estrellas(0, 0) == 0, "sin rondas"),
	])


## Un término seguido de letras queda "devanado (winding)s", y uno al inicio de una viñeta
## o de un rótulo en negrita debe escribirse con mayúscula: {{Estator}}.
func test_terminos_bien_escritos_en_el_contenido() -> String:
	var lista: Array[String] = []
	_archivos_json("res://data", lista)
	var pegado := RegEx.create_from_string("\\}\\}[a-záéíóúñ]")
	var inicio := RegEx.create_from_string("(•\\s*|\\[b\\])\\{\\{[a-z]")
	for ruta in lista:
		var texto := FileAccess.get_file_as_string(ruta)
		var m := pegado.search(texto)
		if m != null:
			return "%s: letras pegadas a un término, cerca de %s" % [ruta, texto.substr(m.get_start() - 20, 30)]
		m = inicio.search(texto)
		if m != null:
			return "%s: término en minúscula al iniciar, cerca de %s" % [ruta, texto.substr(m.get_start(), 30)]
	return ""


func _archivos_texto(carpeta: String, lista: Array[String]) -> void:
	for f in DirAccess.get_files_at(carpeta):
		if f.ends_with(".json") or f.ends_with(".gd"):
			lista.append(carpeta.path_join(f))
	for d in DirAccess.get_directories_at(carpeta):
		_archivos_texto(carpeta.path_join(d), lista)


## Un carácter sin dibujo saldría como un recuadro vacío en pantalla.
func test_la_fuente_tiene_todos_los_caracteres() -> String:
	var base: FontFile = load(Tema.RUTA_FUENTE)
	var respaldo := ThemeDB.fallback_font
	var lista: Array[String] = []
	_archivos_texto("res://data", lista)
	_archivos_texto("res://ui", lista)
	var faltan := {}
	var en_respaldo := {}
	for ruta in lista:
		var texto := FileAccess.get_file_as_string(ruta)
		for i in texto.length():
			var c := texto.unicode_at(i)
			if c < 128 or base.has_char(c):
				continue
			if respaldo.has_char(c):
				en_respaldo[String.chr(c)] = true
			else:
				faltan[String.chr(c)] = ruta
	if not en_respaldo.is_empty():
		print("      caracteres resueltos por la fuente de respaldo: %s" % " ".join(en_respaldo.keys()))
	return A.cierto(faltan.is_empty(), "sin dibujo en ninguna fuente: %s" % str(faltan))


func test_registro_del_barco_marcado_para_verificar() -> String:
	var registro: Dictionary = Contenido.new().barco()["registro"]
	for clave: String in registro:
		if not registro[clave]["verificar"]:
			return "%s viene de un registro público y debe marcarse para verificar" % clave
	return A.cierto(int(registro["eslora"]["valor"]) == 69, "eslora del registro WCPFC")


func test_mayuscula_inicial_en_terminos() -> String:
	var glosario := {"estator": {"es": "estator", "en": "stator"}}
	var vistos := {}
	var uno := TextoTecnico.expandir("{{Estator}} y {{estator}}.", glosario, vistos)
	return A.cierto(uno == "Estator ([i]stator[/i]) y estator.", "debe capitalizar y contar como el mismo término: %s" % uno)


func test_el_ingles_solo_aparece_la_primera_vez() -> String:
	var glosario := {"bobina": {"es": "bobina", "en": "coil"}}
	var vistos := {}
	var uno := TextoTecnico.expandir("La {{bobina}} y la {{bobina}}.", glosario, vistos)
	var dos := TextoTecnico.expandir("Otra {{bobina}}.", glosario, vistos)
	var nuevo := TextoTecnico.expandir("Otra {{bobina}}.", glosario, {})
	return A.primero([
		A.cierto(uno == "La bobina ([i]coil[/i]) y la bobina.", "primera aparición: %s" % uno),
		A.cierto(dos == "Otra bobina.", "misma ficha: %s" % dos),
		A.cierto(nuevo == "Otra bobina ([i]coil[/i]).", "otra ficha vuelve a mostrarlo: %s" % nuevo),
	])


func test_termino_igual_en_ingles_no_se_repite() -> String:
	var glosario := {"contactor": {"es": "contactor", "en": "contactor"}, "power_block": {"es": "power block", "en": "power block"}}
	var uno := TextoTecnico.expandir("El {{contactor}} y el {{power_block}}.", glosario, {})
	return A.cierto(uno == "El contactor y el power block.", "no debe repetir el término: %s" % uno)
