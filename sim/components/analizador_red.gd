class_name SimAnalizadorRed
extends SimComponente
## Analizador de red (power meter) en una salida trifásica de tres hilos. Entra por L1, L2 y L3 y
## sale por T1, T2 y T3: dentro van sus transformadores de corriente, aquí de impedancia casi
## nula. La potencia se calcula con dos vatímetros (método de Aron), que vale en la red aislada
## sin neutro: S = U12·I1* + U32·I3*.

const FASES := [["L1", "T1"], ["L2", "T2"], ["L3", "T3"]]


func tipo() -> String:
	return "analizador_red"


func _params_por_defecto() -> Dictionary:
	return {"f_hz": SimRed.F_HZ}


func estampar(e: SimEstampa) -> void:
	for par in FASES:
		e.impedancia(n(par[0]), n(par[1]), R_CONTACTO)


func _corriente(sol: SimSolver.Solucion, i: int) -> Cx:
	return sol.entre(n(FASES[i][0]), n(FASES[i][1])).escala(1.0 / R_CONTACTO)


## Potencia aparente compleja en VA.
func potencia(sol: SimSolver.Solucion) -> Cx:
	var u12 := sol.entre(n("L1"), n("L2"))
	var u32 := sol.entre(n("L3"), n("L2"))
	return u12.por(_corriente(sol, 0).conjugado()).mas(u32.por(_corriente(sol, 2).conjugado()))


func factor_potencia(sol: SimSolver.Solucion) -> float:
	var s := potencia(sol)
	return absf(s.re) / s.modulo() if s.modulo() > 1.0 else 0.0


## Magnitudes: u12, u23, u31, i1, i2, i3, p, q, s, fp y f.
func leer(sol: SimSolver.Solucion, magnitud := "p") -> Dictionary:
	var s := potencia(sol)
	match magnitud if not magnitud.is_empty() else "p":
		"u12":
			return _l(tension(sol, "L1", "L2"), "V")
		"u23":
			return _l(tension(sol, "L2", "L3"), "V")
		"u31":
			return _l(tension(sol, "L3", "L1"), "V")
		"i1", "i2", "i3":
			return _l(_corriente(sol, int(magnitud.right(1)) - 1).modulo(), "A")
		"p":
			return _l(s.re / 1000.0, "kW")
		"q":
			return _l(s.im / 1000.0, "kvar")
		"s":
			return _l(s.modulo() / 1000.0, "kVA")
		"fp":
			var r := _l(factor_potencia(sol), "")
			r["texto"] = "%s %s" % [("%.2f" % r["valor"]).replace(".", ","), "ind" if s.im >= 0.0 else "cap"]
			return r
		"f":
			return _l(float(params["f_hz"]) if tension(sol, "L1", "L2") > 10.0 else 0.0, "Hz")
	return {"valor": 0.0, "unidad": "", "fuera_de_rango": false, "averia": "magnitud_desconocida"}


func _l(v: float, unidad: String) -> Dictionary:
	return {"valor": v, "unidad": unidad, "fuera_de_rango": false, "averia": ""}
