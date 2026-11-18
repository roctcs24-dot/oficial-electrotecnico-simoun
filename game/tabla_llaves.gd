class_name TablaLlaves
extends RefCounted
## Llaves en milímetros y en pulgadas: la medida entre caras de la tuerca y qué llave métrica le
## sirve. Las bocas de las llaves se fabrican algo mayores que su medida nominal (ISO 691), así que
## una llave «entra» si mide como mucho 0,06 mm menos que la tuerca y hasta 0,2 mm más; de 0,2 a
## 0,5 mm más queda «holgada» y más allá «redondea» la tuerca. Son valores de enseñanza: verificar
## con la llave y la tuerca reales.

const MM_POR_PULGADA := 25.4
const MENOS_ADMITIDO := 0.06
const HOLGURA_BUENA := 0.2
const HOLGURA_MAXIMA := 0.5
const ESTADOS := {"entra": "verde", "holgada": "ambar", "redondea": "rojo", "no_entra": "rojo"}
const NOMBRES := {"entra": "entra", "holgada": "holgada", "redondea": "redondea la tuerca", "no_entra": "no entra"}


## «3/4», «1-1/16» o «1» en milímetros.
static func a_mm(fraccion: String) -> float:
	var texto := fraccion.replace("\"", "").strip_edges()
	var entero := 0.0
	if texto.contains("-"):
		entero = texto.get_slice("-", 0).to_float()
		texto = texto.get_slice("-", 1)
	elif not texto.contains("/"):
		return texto.to_float() * MM_POR_PULGADA
	var partes := texto.split("/")
	return (entero + partes[0].to_float() / partes[1].to_float()) * MM_POR_PULGADA


static func estado(llave_mm: float, tuerca_mm: float) -> String:
	var d := llave_mm - tuerca_mm
	if d < -MENOS_ADMITIDO:
		return "no_entra"
	if d <= HOLGURA_BUENA:
		return "entra"
	return "holgada" if d <= HOLGURA_MAXIMA else "redondea"


## La llave métrica más pequeña que no se queda corta para la tuerca, de la lista dada.
static func mejor_metrica(tuerca_mm: float, llaves: Array) -> int:
	for m: int in llaves:
		if estado(float(m), tuerca_mm) != "no_entra":
			return m
	return 0


## Medidas en pulgadas que tienen una llave métrica que entra bien.
static func con_equivalente(pulgadas: Array, llaves: Array) -> Array:
	return pulgadas.filter(func(p: String) -> bool:
		var t := a_mm(p)
		return estado(float(mejor_metrica(t, llaves)), t) == "entra")


static func numero(v: float, decimales := 2) -> String:
	return (("%." + str(decimales) + "f") % v).replace(".", ",")
