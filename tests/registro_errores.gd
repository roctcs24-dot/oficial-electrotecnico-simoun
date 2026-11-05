extends Logger
## Cuenta los errores de script. Hace falta porque una función "-> String" que revienta
## devuelve "", y el ejecutor lo tomaría por una prueba aprobada.

var _cerrojo := Mutex.new()
var _errores: Array[String] = []


func _log_error(_funcion: String, archivo: String, linea: int, codigo: String, motivo: String, _avisar_editor: bool, tipo: int, _pilas: Array[ScriptBacktrace]) -> void:
	if tipo == ERROR_TYPE_WARNING:
		return
	_cerrojo.lock()
	_errores.append("%s:%d %s" % [archivo, linea, motivo if not motivo.is_empty() else codigo])
	_cerrojo.unlock()


## Devuelve los errores acumulados desde la última llamada y vacía la lista.
func recoger() -> Array[String]:
	_cerrojo.lock()
	var lista := _errores
	_errores = []
	_cerrojo.unlock()
	return lista
