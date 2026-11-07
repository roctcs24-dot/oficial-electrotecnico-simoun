class_name SimInterruptorNivel
extends SimPresostato
## Interruptor de nivel alto de la botella de baja (float switch), como los Parker LLSS del
## buque: un flotador cierra o abre un contacto cuando el líquido llega a su altura. Va en serie
## con la bobina del contactor del compresor, como los presostatos: con la botella demasiado
## llena, el compresor podría aspirar líquido, así que se para. Rearma solo al bajar el nivel.
## El nivel se mide de 0 (vacía) a 1 (llena). Cableado de la etiqueta del LLSS: gris común,
## negro NA, rojo NC y verde tierra.


func tipo() -> String:
	return "interruptor_nivel"


func _params_por_defecto() -> Dictionary:
	var p := super()
	p.merge({"punto": "nivel_botella", "tipo": "alta", "corte_bar": 0.8, "diferencial_bar": 0.1, "rearme": "automatico"}, true)
	return p


## El «corte» es aquí un nivel, no una presión.
func _presion() -> float:
	return _planta().estado["nivel_botella"]
