extends RefCounted
## Guardado de partida: nada de lo que pase con el archivo debe perder el progreso en silencio.

const A := preload("res://tests/ayuda_sim.gd")
const CARPETA := "user://pruebas_partida/"


func _ruta_limpia(nombre: String) -> String:
	DirAccess.make_dir_recursive_absolute(CARPETA)
	var ruta := CARPETA + nombre
	for sufijo in ["", ".bak", ".tmp", ".danada"]:
		if FileAccess.file_exists(ruta + sufijo):
			DirAccess.remove_absolute(ruta + sufijo)
	return ruta


func _escribir(ruta: String, texto: String) -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func test_guardar_y_cargar_conserva_el_progreso() -> String:
	var ruta := _ruta_limpia("ida_vuelta.json")
	var p := Partida.new(ruta)
	p.datos["puntos"] = 750
	p.marcar_ficha_vista("contactor")
	var q := Partida.new(ruta)
	q.cargar()
	return A.primero([
		A.cierto(q.datos["puntos"] == 750, "deben conservarse los puntos"),
		A.cierto(q.ficha_vista("contactor"), "debe conservarse la ficha vista"),
		A.cierto(q.aviso.is_empty(), "una carga normal no debe avisar"),
	])


func test_sin_archivo_empieza_de_cero_sin_avisar() -> String:
	var q := Partida.new(_ruta_limpia("nueva.json"))
	q.cargar()
	return A.primero([
		A.cierto(q.datos["puntos"] == 0, "debe empezar en cero"),
		A.cierto(q.aviso.is_empty(), "no hay nada de lo que avisar"),
	])


func test_archivo_dañado_recupera_la_copia_anterior() -> String:
	var ruta := _ruta_limpia("danada.json")
	var p := Partida.new(ruta)
	p.datos["puntos"] = 100
	p.guardar()
	p.datos["puntos"] = 200
	p.guardar()
	_escribir(ruta, "{ esto no es json")
	var q := Partida.new(ruta)
	q.cargar()
	return A.primero([
		A.cierto(q.datos["puntos"] == 100, "debe recuperar la copia: %s" % q.datos["puntos"]),
		A.cierto(not q.aviso.is_empty(), "debe avisar al jugador"),
	])


func test_dañado_sin_copia_aparta_el_archivo() -> String:
	var ruta := _ruta_limpia("sin_copia.json")
	_escribir(ruta, "{ esto no es json")
	var q := Partida.new(ruta)
	q.cargar()
	return A.primero([
		A.cierto(q.datos["puntos"] == 0, "debe empezar de cero"),
		A.cierto(FileAccess.file_exists(ruta + ".danada"), "no debe borrar el archivo dañado"),
		A.cierto(not q.aviso.is_empty(), "debe avisar al jugador"),
	])


func test_exportar_e_importar_entre_dispositivos() -> String:
	var ruta_pc := _ruta_limpia("pc.json")
	var ruta_cel := _ruta_limpia("celular.json")
	var traspaso := _ruta_limpia("traspaso.json")
	var pc := Partida.new(ruta_pc)
	pc.datos["puntos"] = 1600
	var exportado := pc.exportar(traspaso)
	var cel := Partida.new(ruta_cel)
	var motivo := cel.importar(traspaso)
	var despues := Partida.new(ruta_cel)
	despues.cargar()
	return A.primero([
		A.cierto(exportado, "debe poder exportar"),
		A.cierto(motivo.is_empty(), "debe aceptar la partida: %s" % motivo),
		A.cierto(despues.datos["puntos"] == 1600, "la importación debe quedar guardada"),
	])


func test_importar_rechaza_sin_tocar_la_partida() -> String:
	var ruta := _ruta_limpia("actual.json")
	var p := Partida.new(ruta)
	p.datos["puntos"] = 300
	p.guardar()
	var casos := {
		"otro juego": '{"juego":"otro","version":1}',
		"versión futura": '{"juego":"%s","version":999}' % Partida.ID_JUEGO,
		"puntos negativos": '{"juego":"%s","version":1,"puntos":-5}' % Partida.ID_JUEGO,
		"apartado dañado": '{"juego":"%s","version":1,"misiones":[]}' % Partida.ID_JUEGO,
		"no es JSON": "hola",
	}
	var archivo := _ruta_limpia("mala.json")
	for caso: String in casos:
		_escribir(archivo, casos[caso])
		if p.importar(archivo).is_empty():
			return "debe rechazar: %s" % caso
		if p.datos["puntos"] != 300:
			return "%s no debe cambiar la partida" % caso
	return A.cierto(not p.importar(CARPETA + "no_existe.json").is_empty(), "debe rechazar un archivo inexistente")


func test_partida_antigua_recibe_los_apartados_nuevos() -> String:
	var ruta := _ruta_limpia("antigua.json")
	_escribir(ruta, '{"juego":"%s","version":1,"puntos":40}' % Partida.ID_JUEGO)
	var q := Partida.new(ruta)
	q.cargar()
	return A.primero([
		A.cierto(q.datos["puntos"] == 40, "debe conservar lo que tenía"),
		A.cierto(q.datos["misiones"] is Dictionary, "debe recibir los apartados que le faltan"),
	])


func test_lecciones_y_errores_sobreviven_al_guardado() -> String:
	var ruta := _ruta_limpia("avance.json")
	var p := Partida.new(ruta)
	var ganados := p.completar_leccion("a", 2, 3)
	var repetida := p.completar_leccion("a", 3, 3)
	p.registrar_error("tema")
	p.registrar_error("tema")
	var q := Partida.new(ruta)
	q.cargar()
	return A.primero([
		A.cierto(ganados == 30, "20 + 2 aciertos: %d" % ganados),
		A.cierto(repetida == 0, "repetir no debe sumar: %d" % repetida),
		A.cierto(q.datos["puntos"] == 30, "los puntos deben guardarse"),
		A.cierto(int(q.datos["lecciones"]["a"]["aciertos"]) == 3, "debe conservar el mejor resultado"),
		A.cierto(int(q.datos["errores"]["tema"]["fallos"]) == 2, "debe contar los fallos"),
	])


func test_minijuego_solo_suma_estrellas_nuevas() -> String:
	var ruta := _ruta_limpia("minijuego.json")
	var p := Partida.new(ruta)
	var primera := p.registrar_minijuego("simbolos", 2)
	var igual := p.registrar_minijuego("simbolos", 2)
	var peor := p.registrar_minijuego("simbolos", 1)
	var mejor := p.registrar_minijuego("simbolos", 3)
	var q := Partida.new(ruta)
	q.cargar()
	return A.primero([
		A.cierto(primera == 20, "2 estrellas nuevas: %d" % primera),
		A.cierto(igual == 0 and peor == 0, "repetir o bajar no debe sumar"),
		A.cierto(mejor == 10, "1 estrella nueva: %d" % mejor),
		A.cierto(q.datos["puntos"] == 30, "los puntos deben guardarse"),
		A.cierto(int(q.datos["minijuegos"]["simbolos"]["estrellas"]) == 3, "debe guardar el mejor resultado"),
		A.cierto(int(q.datos["minijuegos"]["simbolos"]["partidas"]) == 4, "debe contar las partidas"),
	])


func test_progreso_hacia_el_rango_siguiente() -> String:
	var rangos := [{"nombre": "A", "puntos": 0}, {"nombre": "B", "puntos": 500}, {"nombre": "C", "puntos": 1500}]
	var p := Partida.new(_ruta_limpia("progreso.json"))
	var inicio := p.progreso_rango(rangos)
	p.datos["puntos"] = 250
	var mitad := p.progreso_rango(rangos)
	p.datos["puntos"] = 1000
	var segundo := p.progreso_rango(rangos)
	p.datos["puntos"] = 9000
	var fin := p.progreso_rango(rangos)
	return A.primero([
		A.cierto(is_equal_approx(inicio, 0.0), "sin puntos: %f" % inicio),
		A.cierto(is_equal_approx(mitad, 0.5), "a mitad del primer tramo: %f" % mitad),
		A.cierto(is_equal_approx(segundo, 0.5), "a mitad del segundo tramo: %f" % segundo),
		A.cierto(is_equal_approx(fin, 1.0), "en el último rango: %f" % fin),
	])


func test_rangos_segun_puntos() -> String:
	var rangos := [{"nombre": "Cadete", "puntos": 0}, {"nombre": "3ra", "puntos": 500}]
	var p := Partida.new(_ruta_limpia("rango.json"))
	var inicio := p.rango(rangos)
	p.datos["puntos"] = 500
	return A.primero([
		A.cierto(inicio == "Cadete", "debe empezar en el primer rango"),
		A.cierto(p.rango(rangos) == "3ra", "500 puntos alcanza el segundo rango"),
	])
