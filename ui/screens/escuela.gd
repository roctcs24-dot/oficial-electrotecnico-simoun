extends Pantalla
## Escuela técnica: la ruta desde cero, en orden. El primer paso son los fundamentos del
## sistema 0; después, los módulos de electricidad industrial, electrónica, hidráulica y
## neumática, válvulas y líneas, y herramientas y racores. Un módulo sin contenido todavía
## aparece como «En preparación».


func construir() -> void:
	_cabecera("Escuela técnica", "Desde cero, en orden: aprenda, practique y compruébelo")
	var desplazable := _desplazable()
	add_child(desplazable)
	var lista := _columna(10)
	desplazable.add_child(_ancho_lectura(lista))
	var c := raiz.contenido
	var paso := 1
	lista.add_child(_fila_paso(paso, c.sistema(0), "sistema_0"))
	for m: Dictionary in c.modulos_escuela():
		paso += 1
		lista.add_child(_fila_paso(paso, m, str(m.get("icono", "aprender"))))
	lista.add_child(_etiqueta("Cada módulo tendrá un atlas de componentes con cinco vistas: qué es, cómo funciona, cómo se conecta, cómo se mide, y fallas y mantenimiento.", "Nota"))


func _fila_paso(numero: int, s: Dictionary, icono: String) -> FilaMenu:
	var activo: bool = s.get("estado", "") == "activo"
	var color := Tema.color_area(s)
	var titulo := "%d · %s" % [numero, s.get("nombre", "")]
	if not activo:
		return _fila(titulo, s.get("resumen", ""), func() -> void: pass, icono, "En preparación", false, {"color": color})
	var parte := Avance.sistema(s, raiz.partida)
	var opciones := {"color": color, "avance": Avance.fraccion(parte), "hecho": parte[1] > 0 and parte[0] == parte[1]}
	return _fila(titulo, s.get("resumen", ""), raiz.ir_a.bind("sistema", {"id": int(s["id"])}), icono, "%d de %d" % parte, true, opciones)
