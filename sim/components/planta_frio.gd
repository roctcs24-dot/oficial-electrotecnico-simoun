class_name SimPlantaFrio
extends SimComponente
## Planta de frío por amoníaco para salmuera: compresor, condensador de agua de mar y
## evaporador sumergido en la salmuera de las cubas. No tiene bornes: el compresor es un motor del
## circuito (params compresor), y los presostatos leen sus presiones.
##
## Dos tipos de compresor, como a bordo: de tornillo con corredera de capacidad continua (los
## MYCOM) o de pistón por etapas, con solenoides de descarga de cilindros y cabezas refrigeradas
## por agua (los Vilter). Dos formas de alimentar el evaporador: con válvula de expansión, o por
## recirculación con bombas, como en el buque: una botella de baja separa el líquido, una
## solenoide controlada por interruptores de nivel la rellena y una bomba de amoníaco lo envía al
## evaporador.
##
## Modelo concentrado para enseñar, no para dimensionar. La temperatura de evaporación sale del
## balance entre lo que el evaporador toma de la salmuera y lo que aspira el compresor; la de
## condensación, del balance entre lo que el compresor descarga y lo que se lleva el agua de mar.
## Las presiones son las de saturación del NH3 a esas temperaturas (SimNH3).
## La salmuera se enfría mucho más deprisa que a bordo, para que se vea en minutos. Todos los
## valores son típicos de atuneros cerqueros: verificar a bordo.

const T_ABSOLUTA := 273.15
const TE_MINIMA := -60.0
## La corredera de capacidad del tornillo: sube despacio en marcha y vuelve al mínimo al parar.
const CAPACIDAD_MINIMA := 0.1
const CAPACIDAD_SUBE_S := 0.01
const CAPACIDAD_BAJA_S := 0.05
const LIMITE_MOTOR := 0.95
## Pistón: con las dos solenoides sin tensión trabaja con la mitad de los cilindros. Etapas del
## Vilter del buque (75 % y 100 %); la base del 50 % es un valor típico: verificar a bordo.
const ETAPA_BASE := 0.5
const ETAPA_75 := 0.75
## Histéresis del automático del pistón, en grados de salmuera por encima de la consigna.
const ETAPA_75_K := 1.0
const ETAPA_100_K := 2.5
const ETAPA_RETARDO_S := 20.0
const CABEZAS_TAU_S := 120.0
## Recirculación: por debajo de este nivel la bomba de amoníaco cavita y para por baja presión.
const NIVEL_CAVITACION := 0.12
const HIELO_MAXIMO := 3.0
## 1 kg de amoníaco gaseoso ocupa unos 1,41 m³ a 20 °C.
const M3_POR_KG_NH3 := 1.41


func tipo() -> String:
	return "planta_frio"


func paso_maximo() -> float:
	return 0.5


func _params_por_defecto() -> Dictionary:
	return {
		"compresor": "M1",
		"bomba_agua_mar": "",
		"bomba_salmuera": "",
		"q_nominal_kw": 220.0,
		"te_nominal": -25.0,
		"tc_nominal": 35.0,
		"eficiencia_carnot": 0.55,
		"ua_evaporador_kw_k": 32.0,
		"ua_condensador_kw_k": 52.0,
		"ua_cubas_kw_k": 1.5,
		"c_evaporador_kj_k": 400.0,
		"c_condensador_kj_k": 600.0,
		"c_salmuera_kj_k": 5000.0,
		"t_agua_mar": 29.0,
		"t_ambiente": 30.0,
		"consigna_salmuera": -15.0,
		"banda_capacidad_k": 3.0,
		"congelacion_salmuera": -21.0,
		"dp_aceite_nominal_bar": 3.0,
		"masa_nh3_kg": 500.0,
		"volumen_sala_m3": 400.0,
		"renovaciones_h": 10.0,
		"renovaciones_emergencia_h": 30.0,
		"alarma_ppm": 25.0,
		"alarma_alta_ppm": 150.0,
		"valvula_seguridad_bar": 20.0,
		# Averías: se cambian desde las misiones.
		"suciedad_condensador": 0.0,
		"obstruccion_filtro_aceite": 0.0,
		"nivel_aceite": 1.0,
		"fuga_kg_h": 0.0,
		# Tipo de compresor: tornillo (corredera continua) o piston (etapas por solenoides).
		"tipo_compresor": "tornillo",
		# Alimentación del evaporador: expansion (válvula de expansión) o bombeo (recirculación).
		"alimentacion": "expansion",
		"masa_botella_kg": 200.0,
		"caudal_solenoide_kg_s": 0.4,
		"calor_latente_kj_kg": 1300.0,
		"nivel_bajo": 0.35,
		"nivel_medio": 0.5,
		"nivel_alto": 0.8,
		"t_cabezas_max": 120.0,
		# Averías: solenoide de nivel cerrada o abierta (pegada).
		"averia_solenoide_nivel": "",
	}


func _estado_inicial() -> Dictionary:
	return {
		"te": -1.0, "tc": 29.0, "ts": -1.0, "capacidad": CAPACIDAD_MINIMA, "automatico": true,
		"capacidad_manual": 1.0, "carga_refrigerante": 1.0, "hielo": 0.0, "dp_aceite": 0.0,
		"ppm_sala": 0.0, "ventilacion_emergencia": false, "carga_pescado_kw": 0.0,
		"bomba_agua_mar": true, "bomba_salmuera": true,
		"q_kw": 0.0, "w_kw": 0.0, "q_condensador_kw": 0.0, "alarma": "", "valvula_abierta": false,
		"solenoide_75": false, "solenoide_100": false, "bomba_cabezas": true, "t_cabezas": 30.0, "etapa_s": 0.0,
		"nivel_botella": 0.5, "solenoide_nivel": false, "bomba_amoniaco": true,
	}


# --- Lecturas ---

## Presión relativa en bar: succion, descarga o aceite (diferencial de aceite sobre la succión).
func presion(punto: String) -> float:
	match punto:
		"succion":
			return SimNH3.p_sat_rel(estado["te"])
		"descarga":
			return SimNH3.p_sat_rel(estado["tc"])
		"aceite":
			return estado["dp_aceite"]
	push_error("Punto de presión desconocido: %s" % punto)
	return 0.0


func temperatura(punto: String) -> float:
	match punto:
		"evaporacion":
			return estado["te"]
		"condensacion":
			return estado["tc"]
		"salmuera":
			return estado["ts"]
		"agua_mar":
			return params["t_agua_mar"]
		"cabezas":
			return estado["t_cabezas"]
	push_error("Punto de temperatura desconocido: %s" % punto)
	return 0.0


## Puntos de tubería donde se puede medir con el termómetro de contacto o infrarrojo.
const TUBERIAS := ["descarga", "liquido", "succion", "salmuera", "agua_mar_entrada", "agua_mar_salida"]


## Temperatura de la superficie de una tubería, en °C. En marcha, la descarga sale muy caliente
## por la compresión, el líquido algo subenfriado y la succión algo recalentada; parado, todo se
## acerca a su temperatura de saturación. Valores típicos de un tornillo con inyección de aceite:
## verificar con la planta.
func temperatura_tuberia(punto: String) -> float:
	var marcha := compresor_en_marcha()
	match punto:
		"descarga":
			if not marcha:
				return estado["tc"]
			var relacion := SimNH3.p_sat_abs(estado["tc"]) / SimNH3.p_sat_abs(estado["te"])
			if piston():
				# Sin inyección de aceite, la descarga del pistón sale más caliente, y más aún con
				# las cabezas sin refrigerar.
				return estado["tc"] + 45.0 + 5.0 * relacion + maxf(estado["t_cabezas"] - 60.0, 0.0)
			return estado["tc"] + 20.0 + 3.0 * relacion
		"liquido":
			return estado["tc"] - (3.0 if marcha else 0.0)
		"succion":
			# Con recirculación el vapor sale de la botella saturado, casi sin recalentamiento.
			var recalentamiento := 1.0 if bombeo() else 6.0
			return estado["te"] + (recalentamiento if marcha else 0.0)
		"salmuera":
			return estado["ts"]
		"agua_mar_entrada":
			return params["t_agua_mar"]
		"agua_mar_salida":
			if not bomba_en_marcha("bomba_agua_mar"):
				return params["t_agua_mar"]
			return params["t_agua_mar"] + 4.0 * estado["q_condensador_kw"] / 320.0
	push_error("Punto de tubería desconocido: %s" % punto)
	return 0.0


func piston() -> bool:
	return params["tipo_compresor"] == "piston"


func bombeo() -> bool:
	return params["alimentacion"] == "bombeo"


## Fracción de su velocidad nominal a la que gira el compresor.
func giro_compresor() -> float:
	var m: SimMotorTrifasico = sim().componente(params["compresor"])
	return clampf(absf(m.rpm()) / float(m.params["rpm"]), 0.0, 1.0)


func compresor_en_marcha() -> bool:
	return giro_compresor() > 0.5


func bomba_en_marcha(nombre: String) -> bool:
	# Las bombas sin motor en el circuito, como la de amoníaco o la de cabezas, van por su estado.
	var id: String = params.get(nombre, "")
	if id.is_empty():
		return estado[nombre]
	var m: SimMotorTrifasico = sim().componente(id)
	return absf(m.rpm()) > float(m.params["rpm"]) * 0.8


# --- Modelo ---

## Capacidad del compresor a estas temperaturas, en kW frigoríficos: la masa aspirada sigue a la
## densidad del vapor de succión, y el rendimiento volumétrico baja con la relación de presiones.
func capacidad_kw(te: float, tc: float) -> float:
	var giro := giro_compresor()
	if giro <= 0.0:
		return 0.0
	var densidad := _densidad_relativa(te) / _densidad_relativa(params["te_nominal"])
	var rendimiento := _rendimiento_volumetrico(te, tc) / _rendimiento_volumetrico(params["te_nominal"], params["tc_nominal"])
	return params["q_nominal_kw"] * estado["capacidad"] * giro * densidad * rendimiento


func _densidad_relativa(te: float) -> float:
	return SimNH3.p_sat_abs(te) / (te + T_ABSOLUTA)


func _rendimiento_volumetrico(te: float, tc: float) -> float:
	var relacion := SimNH3.p_sat_abs(tc) / SimNH3.p_sat_abs(te)
	return clampf(1.0 - 0.03 * (relacion - 1.0), 0.2, 1.0)


## Con poca carga de refrigerante, el evaporador trabaja medio vacío: tiene menos superficie útil
## y la succión baja.
func estado_carga() -> float:
	return clampf((estado["carga_refrigerante"] - 0.4) / 0.4, 0.1, 1.0)


## Potencia en el eje: la del frío entre el COP real, una fracción del de Carnot.
func potencia_kw(q: float, te: float, tc: float) -> float:
	if q <= 0.0:
		return 0.0
	var cop: float = params["eficiencia_carnot"] * (te + T_ABSOLUTA) / maxf(tc - te, 5.0)
	return q / cop


func avanzar(dt: float, _sol: SimSolver.Solucion) -> void:
	if sim() == null:
		return
	_mover_capacidad(dt)
	var te: float = estado["te"]
	var tc: float = estado["tc"]
	var ts: float = estado["ts"]
	var q := capacidad_kw(te, tc)
	var w := potencia_kw(q, te, tc)
	estado["q_kw"] = q
	estado["w_kw"] = w
	_cargar_motor(w)
	# Evaporador: sin bomba de salmuera casi no hay intercambio, y el hielo aísla los tubos.
	var ua_e: float = params["ua_evaporador_kw_k"] * estado_carga() / (1.0 + estado["hielo"])
	if not bomba_en_marcha("bomba_salmuera"):
		ua_e *= 0.15
	# Con recirculación, sin la bomba de amoníaco el evaporador se queda sin líquido.
	if bombeo() and not estado["bomba_amoniaco"]:
		ua_e *= 0.15
	var q_evaporador := ua_e * (ts - te)
	estado["te"] = maxf(te + (q_evaporador - q) / params["c_evaporador_kj_k"] * dt, TE_MINIMA)
	# Condensador: sin agua de mar solo queda la convección natural.
	var ua_c: float = params["ua_condensador_kw_k"] * (1.0 - params["suciedad_condensador"])
	if not bomba_en_marcha("bomba_agua_mar"):
		ua_c *= 0.05
	var q_condensador := ua_c * (tc - float(params["t_agua_mar"]))
	estado["q_condensador_kw"] = q_condensador
	estado["tc"] = tc + (q + w - q_condensador) / params["c_condensador_kj_k"] * dt
	# Salmuera: entra el calor de las cubas y del pescado, sale el que toma el evaporador.
	var q_cubas: float = params["ua_cubas_kw_k"] * (params["t_ambiente"] - ts) + estado["carga_pescado_kw"]
	estado["ts"] = ts + (q_cubas - q_evaporador) / params["c_salmuera_kj_k"] * dt
	_formar_hielo(dt)
	_cabezas(dt)
	if bombeo():
		_botella(dt, q)
	_aceite(dt)
	_valvula_seguridad()
	_fuga(dt)


## En automático, la corredera sigue a la temperatura de la salmuera: descarga el compresor al
## acercarse a la consigna, y también si el motor pasa del 95 % de su potencia, como el limitador
## de corriente de una planta real. En manual no hay límite. Parado, vuelve al mínimo para el
## próximo arranque.
func _mover_capacidad(dt: float) -> void:
	if piston():
		_etapas(dt)
		return
	var objetivo := CAPACIDAD_MINIMA
	if compresor_en_marcha():
		if estado["automatico"]:
			objetivo = clampf(CAPACIDAD_MINIMA + (estado["ts"] - params["consigna_salmuera"]) / params["banda_capacidad_k"], CAPACIDAD_MINIMA, 1.0)
			var m: SimMotorTrifasico = sim().componente(params["compresor"])
			if estado["w_kw"] > LIMITE_MOTOR * float(m.params["p_kw"]):
				objetivo = minf(objetivo, maxf(estado["capacidad"] - 0.02, CAPACIDAD_MINIMA))
		else:
			objetivo = clampf(estado["capacidad_manual"], CAPACIDAD_MINIMA, 1.0)
	var actual: float = estado["capacidad"]
	if objetivo > actual:
		estado["capacidad"] = minf(actual + CAPACIDAD_SUBE_S * dt, objetivo)
	else:
		estado["capacidad"] = maxf(actual - CAPACIDAD_BAJA_S * dt, objetivo)


## Pistón: en automático las solenoides de 75 % y 100 % cargan cilindros de una en una según la
## salmuera, con un retardo entre etapas como el temporizador del control real. Solo carga una
## etapa si el motor la soporta, y la descarga enseguida si pasa del 95 % de su potencia. En manual
## las fija el operador con los selectores. Parado, arranca siempre descargado, con la base.
func _etapas(dt: float) -> void:
	if not compresor_en_marcha():
		if estado["automatico"]:
			estado["solenoide_75"] = false
			estado["solenoide_100"] = false
		estado["etapa_s"] = 0.0
		estado["capacidad"] = ETAPA_BASE
		return
	estado["etapa_s"] = estado.get("etapa_s", 0.0) + dt
	if estado["automatico"]:
		var exceso: float = estado["ts"] - float(params["consigna_salmuera"])
		var m: SimMotorTrifasico = sim().componente(params["compresor"])
		var limite: float = LIMITE_MOTOR * float(m.params["p_kw"])
		var cap: float = estado["capacidad"]
		if estado["w_kw"] > limite and cap > ETAPA_BASE:
			_cambiar_etapa(-1)
		elif estado["etapa_s"] >= ETAPA_RETARDO_S:
			var deseada := ETAPA_BASE
			if exceso > ETAPA_100_K:
				deseada = 1.0
			elif exceso > ETAPA_75_K:
				deseada = ETAPA_75
			elif cap > ETAPA_BASE and exceso > ETAPA_75_K - 1.0:
				deseada = minf(cap, ETAPA_75)
			if deseada > cap:
				var siguiente := ETAPA_75 if cap < ETAPA_75 else 1.0
				if estado["w_kw"] * siguiente / cap < limite * 0.97:
					_cambiar_etapa(1)
			elif deseada < cap:
				_cambiar_etapa(-1)
	if estado["solenoide_100"]:
		estado["capacidad"] = 1.0
	elif estado["solenoide_75"]:
		estado["capacidad"] = ETAPA_75
	else:
		estado["capacidad"] = ETAPA_BASE


## Sube o baja una etapa: base, 75 % y 100 %.
func _cambiar_etapa(sentido: int) -> void:
	estado["etapa_s"] = 0.0
	if sentido > 0:
		if estado["solenoide_75"]:
			estado["solenoide_100"] = true
		else:
			estado["solenoide_75"] = true
	elif estado["solenoide_100"]:
		estado["solenoide_100"] = false
	else:
		estado["solenoide_75"] = false


## Cabezas del pistón: el agua salada de refrigeración se lleva el calor de la compresión. Sin
## ella, se calientan hasta dar alarma. En el tornillo no aplica.
func _cabezas(dt: float) -> void:
	var objetivo: float = params["t_ambiente"]
	if piston() and compresor_en_marcha():
		objetivo = float(params["t_agua_mar"]) + 15.0 if estado["bomba_cabezas"] else 150.0
	var antes: float = estado["t_cabezas"]
	estado["t_cabezas"] += (objetivo - antes) * (1.0 - exp(-dt / CABEZAS_TAU_S))
	var maxima: float = params["t_cabezas_max"]
	if antes < maxima and estado["t_cabezas"] >= maxima:
		avisar("alta_temperatura_cabezas", {"temperatura": estado["t_cabezas"]})


## Botella de baja con recirculación: la solenoide de líquido, mandada por los interruptores de
## nivel, abre por debajo del nivel bajo y cierra en el medio. El evaporador consume el líquido
## que se evapora. Un nivel muy alto puede mandar líquido al compresor: lo vigila el interruptor
## de nivel alto, en serie con su mando. Un nivel muy bajo hace cavitar la bomba de amoníaco, que
## para por baja presión diferencial.
func _botella(dt: float, q: float) -> void:
	var nivel: float = estado["nivel_botella"]
	# solenoide_nivel es la orden del control, lo que indica la luz del panel. Una válvula
	# averiada deja pasar o no según su avería, sea cual sea la orden.
	if nivel < float(params["nivel_bajo"]):
		estado["solenoide_nivel"] = true
	elif nivel >= float(params["nivel_medio"]):
		estado["solenoide_nivel"] = false
	var pasa: bool = estado["solenoide_nivel"]
	match params["averia_solenoide_nivel"]:
		"abierta":
			pasa = true
		"cerrada":
			pasa = false
	var entra: float = params["caudal_solenoide_kg_s"] if pasa else 0.0
	var sale: float = maxf(q, 0.0) / float(params["calor_latente_kj_kg"])
	var nuevo := clampf(nivel + (entra - sale) / float(params["masa_botella_kg"]) * dt, 0.0, 1.0)
	estado["nivel_botella"] = nuevo
	var alto: float = params["nivel_alto"]
	if nivel < alto and nuevo >= alto:
		avisar("alto_nivel_botella", {"nivel": nuevo})
	if estado["bomba_amoniaco"] and nuevo < NIVEL_CAVITACION:
		estado["bomba_amoniaco"] = false
		avisar("baja_presion_bomba_nh3", {"nivel": nuevo})


## El par del motor sigue a la potencia que pide el compresor, más un poco de rozamiento.
func _cargar_motor(w: float) -> void:
	var m: SimMotorTrifasico = sim().componente(params["compresor"])
	var p_motor: float = m.params["p_kw"]
	m.params["carga"] = clampf((w + 0.05 * p_motor) / p_motor, 0.0, 1.6)


## Si la pared de los tubos queda por debajo de la congelación de la salmuera, se forma hielo.
## Su espesor tiene un límite: con mucho hielo el evaporador ya casi no toma calor.
func _formar_hielo(dt: float) -> void:
	var pared: float = (estado["te"] + estado["ts"]) / 2.0
	var margen: float = params["congelacion_salmuera"] - pared
	if margen > 0.0:
		estado["hielo"] = minf(estado["hielo"] + 0.002 * margen * dt, HIELO_MAXIMO)
	else:
		estado["hielo"] = maxf(estado["hielo"] - 0.01 * dt, 0.0)


## Presión diferencial de aceite: la da la bomba de aceite del compresor en marcha.
func _aceite(dt: float) -> void:
	var objetivo := 0.0
	if compresor_en_marcha():
		var nivel := clampf(float(params["nivel_aceite"]) / 0.3, 0.0, 1.0)
		objetivo = params["dp_aceite_nominal_bar"] * (1.0 - params["obstruccion_filtro_aceite"]) * nivel
	estado["dp_aceite"] += (objetivo - estado["dp_aceite"]) * (1.0 - exp(-dt / 1.0))


## La válvula de seguridad del lado de alta descarga a la atmósfera: limita la presión y pierde
## refrigerante.
func _valvula_seguridad() -> void:
	var tarado: float = params["valvula_seguridad_bar"]
	if presion("descarga") > tarado:
		estado["tc"] = SimNH3.t_sat_rel(tarado)
		estado["carga_refrigerante"] = maxf(estado["carga_refrigerante"] - 0.0005, 0.0)
		if not estado["valvula_abierta"]:
			estado["valvula_abierta"] = true
			avisar("valvula_seguridad", {"bar": tarado})
	elif presion("descarga") < tarado * 0.9:
		estado["valvula_abierta"] = false


## Una fuga vacía la carga y llena de amoníaco la sala de máquinas, que la ventilación renueva.
func _fuga(dt: float) -> void:
	var fuga: float = params["fuga_kg_h"]
	if fuga > 0.0:
		estado["carga_refrigerante"] = maxf(estado["carga_refrigerante"] - fuga / params["masa_nh3_kg"] / 3600.0 * dt, 0.0)
	var volumen: float = params["volumen_sala_m3"]
	var entra := fuga / 3600.0 * M3_POR_KG_NH3 / volumen * 1e6
	var renovaciones: float = params["renovaciones_emergencia_h"] if estado["ventilacion_emergencia"] else params["renovaciones_h"]
	var ppm: float = estado["ppm_sala"]
	ppm = maxf(ppm + (entra - ppm * renovaciones / 3600.0) * dt, 0.0)
	estado["ppm_sala"] = ppm
	var alarma := ""
	if ppm >= params["alarma_alta_ppm"]:
		alarma = "alta"
	elif ppm >= params["alarma_ppm"]:
		alarma = "aviso"
	if alarma != estado["alarma"] and not alarma.is_empty():
		avisar("alarma_nh3_alta" if alarma == "alta" else "alarma_nh3", {"ppm": ppm})
	estado["alarma"] = alarma
