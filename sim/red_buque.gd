class_name SimRed
extends RefCounted
## Red principal del B/P Vía Simoun: trifásica aislada de 380 V y 50 Hz, según las placas de los
## alternadores Stamford HCI534F y de los motores. Todos los componentes toman de aquí sus
## valores por defecto, así un cambio de red se hace en un solo sitio y en
## data/barco_via_simoun.json.

const V_LINEA := 380.0
const F_HZ := 50.0
## Tensión de mando de los contactores. Valor típico: verificar a bordo.
const V_MANDO := 110.0
