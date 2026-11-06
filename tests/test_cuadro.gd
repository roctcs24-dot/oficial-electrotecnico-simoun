extends RefCounted
## Pantalla del cuadro principal: mandos, lecturas y avisos sobre la simulación real.

const A := preload("res://tests/ayuda_sim.gd")
const RUTA_PARTIDA := "user://pruebas_cuadro.json"


func _raiz() -> Raiz:
	for sufijo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(RUTA_PARTIDA + sufijo):
			DirAccess.remove_absolute(RUTA_PARTIDA + sufijo)
	var raiz: Raiz = load("res://ui/raiz.tscn").instantiate()
	raiz.ruta_partida = RUTA_PARTIDA
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)
	raiz.ir_a("cuadro", {"id": 1})
	return raiz


func test_todos_los_eventos_tienen_explicacion() -> String:
	var textos: Dictionary = Contenido.new().leer("cuadro.json")["consecuencias"]
	for e in ["cierre_sincronizado", "cierre_barra_muerta", "cierre_brusco", "cierre_fuera_de_fase", "generador_danado", "disparo_potencia_inversa", "disparo_preferente", "carga_desconectada", "parada_por_sobrecarga", "disparo_minima_tension", "disparo_cortocircuito", "disparo_instantaneo", "disparo_sobrecarga_generador", "alarma_aislamiento", "arranque_automatico", "pms_arranque", "pms_sincronizacion_fallida"]:
		if not textos.has(e) or textos[e]["texto"].is_empty():
			return "falta explicar %s" % e
	return ""


func test_el_sistema_1_abre_el_cuadro() -> String:
	var raiz := _raiz()
	raiz.volver()
	raiz.ir_a("sistema", {"id": 1})
	raiz.pantalla_actual()._abrir_modo("taller")
	var abierta: bool = raiz.pantalla_actual().get_script().resource_path.ends_with("cuadro.gd")
	raiz.free()
	return A.cierto(abierta, "el Taller del sistema 1 debe abrir el cuadro")


func test_arrancar_y_cerrar_desde_los_mandos() -> String:
	var raiz := _raiz()
	var p = raiz.pantalla_actual()
	p._alternar_diesel("G1")
	p.sim.avanzar_tiempo(10.0)
	p._alternar_acb("G1")
	p.sim.avanzar_tiempo(2.0)
	p._revisar_eventos()
	p._comprobar_firma()
	p._actualizar()
	var cerrado: bool = p.sim.componente("Q1").cerrado()
	var aviso: bool = p._avisos.get_child_count() == 1
	var v: float = p._instrumentos["bp_v"].valor
	raiz.free()
	return A.primero([
		A.cierto(cerrado, "Q1 debe cerrar"),
		A.cierto(aviso, "debe explicar el cierre en barra muerta"),
		A.cerca(v, 440.0, 0.02, "el voltímetro de barras"),
	])


func test_cierre_rechazado_se_explica() -> String:
	var raiz := _raiz()
	var p = raiz.pantalla_actual()
	p._alternar_acb("G2")
	var aviso: String = p._avisos.get_child(0).get_meta("titulo", "") if p._avisos.get_child_count() > 0 else ""
	raiz.free()
	return A.cierto(aviso == "No cierra", "debe explicar por qué no cierra: %s" % aviso)


func test_mandos_de_velocidad_y_tension() -> String:
	var raiz := _raiz()
	var p = raiz.pantalla_actual()
	var g: SimGenerador = p.sim.componente("G2")
	var f_antes: float = g.estado["f_ref"]
	p._velocidad("G2", 1.0)
	p._tension("G2", 1.0)
	var f_despues: float = g.estado["f_ref"]
	var v_ref: float = g.estado["v_ref"]
	raiz.free()
	return A.primero([
		A.cerca(f_despues - f_antes, 0.1, 0.01, "un toque sube 0,1 Hz"),
		A.cerca(v_ref, 442.0, 0.001, "un toque sube 2 V la consigna"),
	])


func _botones(nodo: Node, lista: Array[String]) -> void:
	if nodo is Button:
		lista.append(nodo.text)
	for hijo in nodo.get_children():
		_botones(hijo, lista)


func test_panel_de_sincronizacion_tiene_sus_mandos() -> String:
	var raiz := _raiz()
	var p = raiz.pantalla_actual()
	var textos: Array[String] = []
	_botones(p, textos)
	p._alternar_diesel("G1")
	p.sim.avanzar_tiempo(10.0)
	p._alternar_acb("G1")
	p._alternar_diesel("G2")
	p.sim.avanzar_tiempo(10.0)
	p.sincronizar_automaticamente()
	var cancelar: Array[String] = []
	_botones(p, cancelar)
	p.sim.avanzar_tiempo(40.0)
	var cerrado: bool = p.sim.componente("Q2").cerrado()
	raiz.free()
	return A.primero([
		A.cierto(textos.has("Sincronizar automáticamente"), "debe estar el botón de sincronizar: %s" % str(textos)),
		A.cierto(textos.has("Cerrar Q2") and textos.has("Velocidad + G2"), "deben estar el cierre y la velocidad del entrante"),
		A.cierto(cancelar.has("Cancelar sincronización"), "mientras sincroniza debe poder cancelarse"),
		A.cierto(cerrado, "el sincronizador debe cerrar Q2"),
	])


func test_el_sincronoscopio_cambia_de_entrante() -> String:
	var raiz := _raiz()
	var p = raiz.pantalla_actual()
	p._elegir_sincronizar("G3")
	var hacia_g3 := false
	var hacia_g2 := false
	for c: Array in p.sim.cables:
		if c[0] == "SY.G1" and c[1] == "G3.L1":
			hacia_g3 = true
		if c[0] == "SY.G1" and c[1] == "G2.L1":
			hacia_g2 = true
	raiz.free()
	return A.cierto(hacia_g3 and not hacia_g2, "el sincronoscopio debe medir G3")


func test_conserva_la_simulacion_al_girar() -> String:
	var raiz := _raiz()
	var p = raiz.pantalla_actual()
	var sim: SimSimulacion = p.sim
	p._alternar_diesel("G1")
	raiz.vertical = not raiz.vertical
	raiz.reconstruir()
	var q = raiz.pantalla_actual()
	var igual: bool = q.sim == sim
	raiz.free()
	return A.cierto(igual and sim.componente("G1").en_marcha(), "girar el celular no debe perder la práctica")


func test_recorre_pestanas_en_ambas_orientaciones() -> String:
	var raiz := _raiz()
	for vertical in [true, false]:
		raiz.vertical = vertical
		raiz.reconstruir()
		var p = raiz.pantalla_actual()
		for id in (["barras", "G1", "G2", "G3"] if vertical else ["G1", "G2", "G3"]):
			p._elegir_pestana(id)
			p._actualizar()
	raiz.free()
	return ""


func test_cuadro_de_emergencia_en_la_practica() -> String:
	var raiz := _raiz()
	var p = raiz.pantalla_actual()
	var textos: Array[String] = []
	_botones(p, textos)
	p._alternar_diesel("G1")
	p.sim.avanzar_tiempo(10.0)
	p._alternar_acb("G1")
	p.sim.avanzar_tiempo(1.0)
	p._alternar_interruptor_id("QT")
	p._alternar_arranque_automatico("GE")
	p.sim.avanzar_tiempo(2.0)
	p._actualizar()
	var v_be: float = p._instrumentos["be_v"].valor
	var texto: String = p._textos["emergencia"].text
	p._alternar_acb("G1")
	p.sim.avanzar_tiempo(25.0)
	p._actualizar()
	var por_ge: String = p._textos["emergencia"].text
	raiz.free()
	return A.primero([
		A.cierto(textos.has("Cerrar el enlace QT") and textos.has("Arrancar GE") and textos.has("GE en manual: pasar a automático"), "mandos de emergencia: %s" % str(textos)),
		A.cerca(v_be, 440.0, 0.05, "con QT cerrado, el cuadro de emergencia tiene tensión"),
		A.cierto(texto.contains("desde el cuadro principal"), "debe decir de dónde se alimenta: %s" % texto),
		A.cierto(por_ge.contains("generador de emergencia"), "tras perder el principal, lo alimenta GE: %s" % por_ge),
	])
