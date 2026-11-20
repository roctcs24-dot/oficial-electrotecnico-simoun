# Oficial Electrotécnico: B/P Vía Simoun

Juego educativo de simulación para Android y Windows que enseña, desde cero, lo que debe saber un oficial electrotécnico (ETO) a bordo de un atunero cerquero. Funciona 100 % sin conexión.

Estado: **v5.4**, con el plan completo:

- la v1 a la v5 de la hoja de ruta: los siete sistemas del buque están abiertos, con lecciones y examen, y Taller y Guardia en los seis sistemas de equipos;
- la Escuela técnica con sus cinco módulos (electricidad industrial, electrónica, hidráulica y neumática, válvulas y líneas, herramientas y racores) y sus exámenes v6 y v7;
- seis rangos, de Aspirante a Jefe Electrotécnico.

Incluye:

- 21 lecciones de fundamentos, seguridad (también con amoníaco), motores, arrancadores (también el arrancador suave), tableros de bombas e instrumentos.
- 8 lecciones de generación: alternador, AVR, gobernador, cuadro principal, sincronización, reparto de carga, blackout y red aislada.
- 8 lecciones de refrigeración: ciclo de compresión, presión y temperatura del NH3, diagrama presión–entalpía, compresores, componentes, control y protecciones, cableado del compresor y diagnóstico.
- Sistema 2, distribución y alumbrado (completo): 4 lecciones (transformadores de 380/220/110 V, interruptores automáticos con su curva de disparo animada, fusibles y diferenciales en la red aislada, alumbrado normal y de emergencia, baterías y cargadores de 24 V DC y SAI), 4 fichas (transformador, interruptor automático, diferencial y banco de 24 V), los tableros de 220 V y 110 V en el Taller (el de 110 V con tres circuitos F1, F2 y F3 y averías de corto, fuga a masa y sobrecarga), 3 misiones de Guardia (pasillo a oscuras por un corto, lámpara de tierra S apagada y sobrecarga de la cocina) y el minijuego de símbolos de distribución. El componente `interruptor_automatico` (`sim/components/interruptor_automatico.gd`) tiene `in_a`, `curva` B, C o D (disparo magnético a 4, 7,5 y 15 × In) y de 1 a 3 `polos`; pruebas en `tests/test_sim_distribucion.gd`. El `consumidor` (`sim/components/consumidor.gd`) es una carga monofásica A-B con su PE, con `ohm`, `fuga_ohm` a la carcasa y `corto`. Las misiones de tablero aceptan una prueba de circuito: `"prueba": {"interruptores", "medir", "observar_s", "superada", "condiciones"}`, con condiciones de tensión (`a`, `b`, `min`), de parámetro (`componente`, `param`, `min`) o de corriente (`corriente_max`), cada una con su texto de `falla`; y `"bloqueo"` limita el bloqueo exigido a esos aisladores. Pruebas en `tests/test_guardia_distribucion.gd`.
- Sistema 5, cubierta y pesca (completo): 3 lecciones (central hidráulica y maquinaria de pesca, mando electrohidráulico con la válvula direccional animada y finales de carrera, alumbrado de cubierta y reflectores), 3 fichas (válvula direccional, final de carrera y reflector), el tablero de mando del power block en el Taller, 2 misiones de Guardia (bobina de virar cortada y bobina de arriar en corto) y el minijuego de símbolos de cubierta. El examen de la v5 cubre los sistemas 2 y 5. El componente `power_block` (`sim/components/power_block.gd`) tiene dos bobinas de 24 V DC, Y1 virar y Y2 arriar, con averías `averia_y1`/`averia_y2` (`abierta` o `corto`) y `presion`; pruebas en `tests/test_sim_cubierta.gd`.
- Sistema 6, electrónica, PLC y alarmas (completo): 6 lecciones (sensores de proximidad PNP y NPN, su cableado al PLC, red RS-485 y Modbus RTU con tramas animadas, pantallas HMI y puesto de alarmas y detección de incendios); la ficha del sensor; en el Taller, la red Modbus con el puesto de alarmas y la pantalla Omron del MYCOM nº 3, el banco de sensores con PLC y el PLC de la bomba de achique; 4 misiones de Guardia en la red y la pantalla del MYCOM (dirección repetida, terminador mal puesto, sentina sin comunicación y límite de alarma subido); el examen de la v4 y el minijuego de símbolos de electrónica; y en el cajón, fuente de 24 V DC, sensores PNP y NPN, relé de 24 V, luz de 24 V y PLC.
- Fichas de los equipos de los sistemas 1, 3, 4 y 6, entre ellas la del generador de emergencia y la del detector de amoníaco, con simbología IEC y ANSI, y un minijuego de símbolos por sistema.
- Cuadro principal con los cuatro generadores del buque (380 V, 50 Hz), paneles al estilo de sus módulos de sincronismo, PMS, protecciones, lámparas de tierra R-S-T y cuadro de emergencia con su generador.
- Taller con multímetro, megóhmetro y pinza amperimétrica, y siete tableros reales del buque que se manejan desde su frente, con su interior en la mesa del Taller: bombas de la máquina principal, con arrancadores suaves SIRIUS 3RW40 en las de enfriamiento, hidróforo de agua salada, purificadora nº 1, controlador del servotimón nº 1 con su variador Danfoss, tableros de 110 V de habitabilidad y de 220 V de distribución, y el de compresores NH3, con los compresores nº 3 y nº 4 y su arrancador suave, amperímetros de aguja y las tres bombas de amoníaco. Tienen una marca amarilla en su lugar del plano del barco.
- 5 misiones de Guardia de motores y tableros (dos de ellas frente al tablero: lámpara de tierra apagada e hidróforo sin una fase) y 4 del cuadro principal: puesta en paralelo, blackout, falla a tierra y potencia inversa.
- 6 misiones de Guardia de la planta de frío: alta presión de descarga, hielo en el evaporador, presión de aceite en el Vilter nº 5, fuga de amoníaco con evacuación, nivel alto en la botella de baja y, frente al tablero de compresores, la bomba de amoníaco nº 1 sin luces.
- Exámenes de la v1 a la v7 (los dos últimos, de la Escuela técnica), seis rangos de Aspirante a Jefe, repaso de errores y traspaso de partida.
- Planta de frío por amoníaco en el Taller del sistema 4: esquema del ciclo, manómetros en bar y psi, termómetro, presostatos, bombas, diagrama presión–entalpía y detector de amoníaco.
- Inicio con la lección recomendada, el repaso pendiente y una tarjeta de color por sistema; barra de navegación (Inicio, Escuela técnica, Buque, Pañol, Progreso), bienvenida la primera vez y tamaño de letra ajustable; estilo oscuro elegido por el usuario. Glosario y plano del barco.
- Escuela técnica: nueve lecciones de electricidad desde cero en el módulo 7 (unidades y prefijos, serie y paralelo con práctica en el Taller, caída de tensión y sección, magnetismo y relé, inducción, condensador y bobina en alterna, tierra y red aislada, cables y bornes, y cómo leer un esquema), y atlas de componentes de electricidad industrial (módulo 7) con fichas visuales de cinco pestañas: qué es, cómo funciona (corte animado que se maneja con el dedo), cómo se conecta (esquema con bornes que se iluminan también en el dibujo), cómo se mide (lecturas calculadas con la simulación) y fallas con su mantenimiento. Incluye el contactor, el relé térmico y el guardamotor (mando y motor) y, de protección, el interruptor automático, el diferencial, el fusible, el interruptor seccionador, el relé de control de fases y el monitor de aislamiento; y, de mando, el relé auxiliar, el temporizador, el pulsador, el selector, la luz piloto, la seta de emergencia, el final de carrera, el presostato, el termostato y el interruptor de nivel; y, de potencia y medida, el transformador, el transformador de intensidad, el motor trifásico, los arrancadores estrella-triángulo y suave, el variador de frecuencia, la resistencia de caldeo, los condensadores de compensación, el amperímetro, el voltímetro, el analizador de red, el horómetro y la bornera. El módulo 8, electrónica, estrena su atlas con la resistencia y su código de colores, el potenciómetro, los termistores NTC y PTC, el varistor, el condensador (de marcha y electrolítico), el diodo, el diodo Zener, el LED y el puente rectificador, y sigue con el transistor bipolar, el MOSFET, el tiristor, el triac, el optoacoplador, el relé de estado sólido, el regulador de tensión, la fuente conmutada, el amplificador operacional como comparador y las puertas lógicas; sus fichas también se publican en el sistema 6. Desde la versión 4.18.0, el módulo 8 tiene además once lecciones de electrónica desde cero (`el1` a `el11`): señal y potencia; resistencias y código de colores; condensador; diodo y LED; rectificador y fuentes; transistor como interruptor; relé, optoacoplador, relé de estado sólido, tiristor y triac; señales de 4-20 mA, PT100 y termocupla; lógica digital y binario; el operacional como comparador, y trabajo seguro en tarjetas. Llevan cinco animaciones nuevas (`codigo_colores`, `carga_condensador`, `rectificador` con osciloscopio, `transistor_llave` y `lazo_4_20`) y tres prácticas en el Taller (el LED con su resistencia, el rectificador con filtro y el transistor que manda un relé). Las pruebas están en `tests/test_electronica_lecciones.gd`, y las capturas se hacen con `godot --path . --script res://tests/capturar.gd -- build/capturas_f electronica`.

Los requisitos completos están en [CLAUDE.md](CLAUDE.md). Están completas la v2 (generadores, paneles y cuadro principal), la v3 (refrigeración por amoníaco), la v4 (electrónica, sensores, PLC, red Modbus, HMI, puesto de alarmas y detección de incendios) y la v5 (distribución, alumbrado, baterías y cubierta). La v6 de la hoja de ruta, una vista 3D con recorrido por el buque, no está empezada: cambia el tipo de juego (2D) y requiere decidir antes su alcance. El Main Engine Control Panel de la máquina principal (Wabtec 16V250 con MEC2+) está en el sistema 6, con su frente y los valores de la pantalla tomados de un vídeo del buque; su interior y su lógica son típicos.

> Es material de formación. No sustituye los procedimientos ni los manuales del barco. Los datos marcados `"verificar": true` son valores típicos que hay que comprobar a bordo. El estado del contenido de seguridad está en [docs/revision_seguridad.md](docs/revision_seguridad.md).

## Abrir el proyecto

1. Instala [Godot 4.7.2](https://godotengine.org/) (versión estándar, no .NET).
2. En el gestor de proyectos, elige **Importar** y selecciona `project.godot`.
3. Pulsa **F5** para ejecutar.

## Probar la versión

- **En PC:** ejecute `OficialElectrotecnico.exe`. No necesita instalación ni conexión.
- **En Android:** instale `OficialElectrotecnico.apk`. Es un APK arm64 firmado con un keystore de depuración, así que Android pedirá permitir la instalación desde esa fuente. No pide ningún permiso, ni siquiera internet.
- **Tabletas:** el mismo APK sirve para tabletas Android. La interfaz se mide en puntos según la densidad de la pantalla: en una tableta con una densidad creíble (200 ppp o más) el lado corto puede llegar a 900 puntos; si la densidad parece mal informada, se limita a 600, como en un celular. Se revisó con capturas de 600×960, 960×600, 800×1280 y 1280×800, y de 900×1440 y 1440×900, que es lo que corresponde a una Lenovo Yoga Tab Plus (2944×1840, unos 273 ppp). No se ha probado en una tableta real.
- **Partida:** para pasarla de un dispositivo a otro, abra **Mi progreso** en la pantalla de inicio.

## Pruebas

```bash
godot --headless --path . --import
```

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

El ejecutor carga cada `tests/test_*.gd`. Cada método `test_*` devuelve `""` si pasa, o el motivo del fallo. Cualquier error de script durante una prueba también la hace fallar, porque una función `-> String` que revienta devuelve `""` y parecería aprobada.

Si añades una clase con `class_name`, repite primero el `--import`.

El ejecutor aborta con error si tarda más de 300 s, incluso si una prueba entra en un bucle infinito. El límite se cambia con la variable `LIMITE_PRUEBAS_S`; en GitHub Actions es de 600 s. En Windows, `tools\correr_pruebas.ps1` añade un segundo límite desde fuera, de 600 s por defecto, y guarda la salida en `build\pruebas\`. Con el PC normal, las pruebas tardan unos 150 s:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File tools\correr_pruebas.ps1
```

Con la variable `PRUEBAS_SOLO` se ejecutan solo los archivos cuyo nombre la contiene; por ejemplo, `PRUEBAS_SOLO=guardia_planta`.

Para revisar el aspecto de las pantallas sin tener que navegar por ellas, este comando guarda imágenes de cada una en varios tamaños:

```bash
godot --path . --script res://tests/capturar.gd -- carpeta/de/salida
```

Con `lecciones`, `fichas`, `atlas`, `taller`, `guardia`, `progresion`, `cuadro`, `guardia_cuadro`, `planta` o `guardia_planta` detrás de la carpeta captura solo esa parte. En `lecciones` y `fichas`, un número más elige el sistema; por ejemplo, `-- carpeta fichas 1`. En `atlas`, la variable `CAPTURA_MODULO` elige el módulo de la Escuela (7 si no se dice) y `CAPTURA_ATLAS` limita los equipos, separados por comas.

## Exportar

Necesitas las plantillas de exportación de Godot 4.7.2. Para Android también necesitas JDK 17 y el Android SDK con `platform-tools`, `build-tools;35.0.1` y `platforms;android-35`.

Las variables `ANDROID_HOME` y `JAVA_HOME` indican a Godot dónde están. El keystore se indica con:

| Variable | Valor |
|---|---|
| `GODOT_ANDROID_KEYSTORE_RELEASE_PATH` | Ruta del keystore |
| `GODOT_ANDROID_KEYSTORE_RELEASE_USER` | `androiddebugkey` |
| `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` | `android` |

```bash
godot --headless --path . --export-release "Windows" build/windows/OficialElectrotecnico.exe
```

```bash
godot --headless --path . --export-release "Android" build/android/OficialElectrotecnico.apk
```

El APK usa la plantilla de release, firmada con un keystore de depuración. **Hay que firmar siempre con el mismo keystore**: Android no deja actualizar una app con otra firma, y desinstalarla borra el progreso guardado.

## Compilación automática

`.github/workflows/build.yml` hace dos cosas:

- Ejecuta las pruebas en cada push a `main` y en cada pull request.
- Compila el `.exe` y el APK en cada release, y los adjunta a ese release. También se puede lanzar a mano desde la pestaña Actions.

La compilación necesita el secreto `ANDROID_DEBUG_KEYSTORE_BASE64` con el keystore en base64.

## Estructura

| Carpeta | Contenido |
|---|---|
| `data/` | Contenido editable en JSON: datos del barco, sistemas, rangos, glosario, `fichas/` (y sus marcas en `marcas_fichas.json`), `atlas/`, `circuitos/`, `lecciones/`, `misiones/` y `examenes/` |
| `art/` | Dibujos SVG de `barco/`, `equipos/`, `esquemas/`, `iconos/`, `seguridad/`, `simbolos/` y `taller/`, y la fuente en `fuentes/` |
| `sim/` | Motor de simulación: `solver.gd`, `simulacion.gd`, `components/` e `instruments/` |
| `game/` | Carga de contenido, partida guardada, términos técnicos, mesa del Taller, misiones, examen y banco de repaso |
| `ui/` | `raiz.gd` (navegación y escala), `marco_ari.gd` (marco de simulador de Guardia y Taller), `pantalla.gd` (base), `pantalla_banco.gd` (base del Taller y de las misiones), `pantalla_preguntas.gd` (base del examen y del repaso), `screens/` y `widgets/` |
| `tests/` | Pruebas sin pantalla y captura de pantallas |
| `tools/` | Ejecutor de pruebas con límite de tiempo |

Para corregir un dato del barco, edita `data/barco_via_simoun.json` y vuelve a exportar. No hace falta tocar código.

## Contenido

**Sistemas:** `data/sistemas.json` define cada sistema, su `estado` (`activo` o `proximamente`), su `zona` en el plano y sus `modos`.

**Lecciones:** para añadir una, crea `data/lecciones/<id>.json` y añade su id a `modos.aprender.lecciones` del sistema, en el orden deseado. Las pruebas validan que esté bien formada. Debe durar de 3 a 5 minutos y tener al menos una pregunta:

```json
{
  "id": "l0_ejemplo",
  "titulo": "Título",
  "resumen": "Una línea para la lista.",
  "minutos": 4,
  "paginas": [
    {
      "titulo": "Título de la página",
      "bloques": [
        { "tipo": "texto", "texto": "Admite [b]negrita[/b] y términos como {{voltaje}}." },
        { "tipo": "animacion", "id": "circuito_ohm", "params": {}, "pie": "Texto opcional." },
        { "tipo": "imagen", "svg": "res://art/seguridad/loto.svg", "tamano": [420, 360], "etiquetas": [], "pie": "Texto opcional." },
        {
          "tipo": "quiz", "tema": "id_unico_para_el_repaso", "pregunta": "¿...?",
          "opciones": ["A", "B", "C"], "correcta": 1, "explicacion": "Por qué."
        },
        {
          "tipo": "ordenar", "tema": "otro_id_unico", "pregunta": "Toca en orden:",
          "pasos": ["Primero", "Segundo", "Tercero"], "explicacion": "Por qué."
        }
      ]
    }
  ],
  "para_saber_mas": ["Norma o fuente de referencia."]
}
```

Los pasos de `ordenar` se escriben en su orden correcto: el juego los mezcla. No se puede avanzar de página sin contestar, y los fallos se guardan por `tema` para el repaso.

Un bloque `{ "tipo": "taller", "plantilla": "serie_paralelo", "texto": "...", "boton": "..." }` muestra un texto y un botón que abre esa plantilla de `data/circuitos/` en el Taller, para practicar lo aprendido.

Las animaciones están en `ui/animaciones/`: `circuito_ohm`, `onda_alterna`, `fasores`, `estrella`, `escala_corriente`, `serie_paralelo` (tres luces de 24 V en serie, paralelo o mixto), `caida_tension` (cable trifásico con su longitud, sección y corriente), `conexion_motor`, `banco_arranque` y `banco_generadores`. Esta última usa la simulación del cuadro principal con `"params": { "escenario": "sincronizar" }` o `"reparto"`. Para crear otra, añade `<id>.gd` heredando de `Animacion`. Los cortes del atlas son `corte_contactor`, `corte_rele_termico`, `corte_guardamotor` (también el interruptor automático, con `"tipo": "interruptor"`), `corte_diferencial`, `corte_fusible`, `corte_seccionador`, `corte_rele_fases` y `corte_monitor`. Los del diferencial, el relé de fases y el monitor funcionan sobre circuitos de la simulación. `corte_mando` sirve a varios aparatos de mando según su `"tipo"` (pulsador, seta, selector, final_carrera, presostato, termostato, nivel o rele), con sus `contactos` y ajustes en los `params`; `corte_temporizador` y `corte_piloto` completan el mando. De potencia y medida: `corte_ti` (transformador de intensidad con su puente), `corte_variador`, `corte_caldeo`, `corte_compensacion` (`"tipo": "compensacion"` o `"analizador"`), `corte_aparato` (`"tipo": "amperimetro"`, `"voltimetro"` u `"horometro"`) y `corte_bornera`; el transformador, el motor y los arrancadores usan `transformador_relacion`, `conexion_motor` y `banco_arranque`. De electrónica: `corte_resistor` (valor por bandas, I y P con su potencia nominal), `corte_potenciometro` (consigna de un variador, con la pista gastada), `corte_termistor` (curvas de la NTC y de las PTC con el relé de termistores), `corte_varistor` (picos recortados y desgaste hasta el corto), `corte_condensador` (carga, carga guardada y descarga), `corte_diodo` (la unión PN en directa y al revés), `corte_zener` (regulación frente a la entrada y la carga), `corte_led` (corriente según la resistencia; se funde por encima de 30 mA) y `corte_puente` (qué pareja de diodos conduce, filtro y media onda). De la electrónica II: `corte_transistor` (saturación según la resistencia de base y el pico sin diodo supresor), `corte_mosfet` (tensión de puerta: apagado, a medias y pleno), `corte_tiristor` (disparo y enclavamiento), `corte_triac` (onda lenta y apagado en el paso por cero), `corte_optoacoplador` (aislamiento frente a un pico), `corte_ssr` (fuga y tensión fantasma), `corte_regulador` (calor y corte térmico), `corte_fuente` (etapas y protección), `corte_operacional` (alarma de temperatura) y `corte_puertas` (símbolos IEC y ANSI con su tabla de verdad).

**Fichas:** cada `data/fichas/<id>.json` tiene el dibujo, los símbolos IEC y ANSI, el banco de prueba y las secciones `funcion`, `partes`, `conexion`, `ajuste`, `pruebas`, `fallas` y `mantenimiento`, además de `para_saber_mas`. Para publicar una, añade su id a `modos.aprender.fichas` del sistema. Las pruebas comprueban que esté completa y que sus referencias existan.

Una ficha puede añadir vistas con `dibujos_extra`, como la placa y la bornera del motor. Sus `simbolos` pueden ser `iec` y `ansi` propios, o una `lista` de ids de `data/simbolos.json`.

**Marcas numeradas de las fichas:** salen de las `partes` con `marca` del atlas que usa el dibujo de la ficha. Las fichas sin atlas las toman de `data/marcas_fichas.json`: `{"fichas": {"<id>": [{"nombre", "texto", "marca": [x, y]}]}}`, en coordenadas del dibujo (`tamano` de la ficha), de tres a cinco por ficha. Son posiciones y textos típicos: verificar a bordo. `tests/test_rediseno_d.gd` comprueba que todas las fichas tengan marcas y que caigan dentro del dibujo.

**Atlas de la Escuela:** cada componente del atlas es `data/atlas/<id>.json`, y se publica añadiendo su id a `modos.aprender.atlas` de un módulo de la Escuela en `data/sistemas.json`. No hace falta código nuevo salvo la animación del corte, si el componente necesita una propia. El dibujo y los símbolos se toman de `data/fichas/<ficha>.json`. Las pruebas de `tests/test_atlas.gd` comprueban que esté bien formado.

| Campo | Contenido |
|---|---|
| `ficha`, `titulo`, `termino`, `icono`, `resumen` | Ficha de la que salen el dibujo y los símbolos; título; id del glosario cuyo inglés va en la cabecera; icono de `art/iconos/` |
| `bornes_dibujo` | Posición de cada borne en el dibujo del equipo, en coordenadas del SVG |
| `que_es` | `texto`, `partes` (texto y `marca` opcional [x, y] para el número sobre el dibujo), `placa` y `a_bordo` (con «verificar a bordo») |
| `funciona` | `animacion` de `ui/animaciones/` con sus `params`, tres `pasos` y, si la animación tiene interruptor de tensión, `pasos_sin` |
| `conexion` | `esquema` (SVG con `etiquetas`), `bornes_esquema` (posición de cada borne en el esquema), `bornes` (qué le llega a cada uno), `grupos` (chips con `nombre`, `bornes` y `texto`) y `taller` (opcional: circuito que se monta en el Taller; todas sus piezas deben estar en el cajón de `data/taller.json`) |
| `medir` | `grupos` con `instrumento` (`multimetro`, `megohmetro` o `pinza`), `escala`, puntas `roja` y `negra`, `como`, `nota`, `titulo_tabla`, `columna`, la `medida` base y sus `filas` (`estado`, `cambios`, `hacer`, `bien`); `nota` y `taller` (circuito para medirlo uno mismo) |
| `fallas` | `lista` de fallas (`nombre`, `sintoma`, `mide`, `causa`, `reparacion`), `mantenimiento` (`periodo` y `tarea`) y `nota_mantenimiento` |
| `para_saber_mas` | Normas y fuentes |

Una medida dice qué circuito de `data/circuitos/` montar, qué cambiar en él y con qué medir: `{"circuito": "medir_contactor", "estado": {"K1": {"bobina_quemada": true}}, "params": {...}, "segundos": 0.2, "instrumento": "multimetro", "modo": "ohm", "a": "K1.A1", "b": "K1.A2"}`. La pinza lleva `cable` (o `cables`, varios a la vez); `pinza_fugas` da en mA lo que no vuelve por los conductores abrazados; el megóhmetro lleva `v_prueba`; `monitor` lee el monitor de aislamiento `id` de la propia red; `aparato` lee la aguja o la pantalla del componente `id` (amperímetro, voltímetro, analizador de red, horómetro, variador o arrancador suave), con su `magnitud` si tiene varias (`u12`, `i1`, `p`, `q`, `s`, `fp`, `f`, `bus`, `pantalla`...). Los `cambios` de una fila se mezclan con la medida del grupo. Las lecturas de «Medir» salen siempre de la simulación (`game/atlas_medidas.gd`); solo las fallas admiten un `valor` escrito para lo que la simulación no modela.

**Símbolos:** cada entrada de `data/simbolos.json` tiene `id`, `nombre`, `sistema`, `similares` y sus dibujos `iec` y `ansi`. Cada minijuego pregunta los de su sistema, y un examen solo los del sistema de su `sistema_simbolos`. `similares` lista los que comparten dibujo en alguna norma, para no ofrecerlos juntos como opciones.

**Taller:** `data/taller.json` define el catálogo del cajón, con el tipo de componente, su dibujo y la posición de cada borne, además de las plantillas y las explicaciones de cada consecuencia. Cada evento nuevo del motor de simulación necesita su explicación en `consecuencias`. La forma de cada cable (curva, ángulos o recta, y su acomodo) se guarda con el circuito, pero no afecta a la simulación. Los circuitos del jugador se guardan en `user://circuitos/`, con sus daños incluidos, y la última mesa en `user://taller_ultimo.json`.

**Misiones:** para añadir una, crea `data/misiones/<id>.json` y añade su id a `modos.guardia.misiones` del sistema. Las pruebas de `tests/test_guardia.gd` comprueban que esté bien formada; añade también una que la complete de principio a fin. Cada misión tiene:

| Campo | Contenido |
|---|---|
| `reporte` | `de`, `texto` y `nota`, con los valores típicos marcados |
| `circuito`, `posiciones` | La red con la avería en sus `params` o `estado`, y dónde se dibuja cada pieza |
| `averias_ocultas` | Piezas cuyo daño no debe verse en la mesa: hay que encontrarlo midiendo |
| `monitor` | Opcional: muestra el monitor de aislamiento, con `resto_mohm` para el resto de la red |
| `verificacion` | `fuente_conocida` y los `puntos` donde verificar la ausencia de tensión |
| `evidencias`, `remediciones` | Mediciones o acciones que respaldan el diagnóstico, y las que deben repetirse tras reparar (`despues_de`) |
| `pistas`, `diagnostico`, `libro` | Ayudas, causas posibles con su explicación, y campos del libro de registro |
| `acciones` | Trabajos sobre el equipo. `efecto` cambia la simulación con `param`, `reemplazar`, `conectar` o `desconectar`; `pone`, `necesita` e `impide` encadenan pasos; `innecesaria` los anota como falta |
| `prueba` | Motor, relé y contactor que se observan, durante cuánto tiempo y la velocidad mínima |
| `accidentes` | Opcional: sustituye los textos comunes de `data/guardia.json` |

Las lecturas y las consecuencias salen de la simulación. Todos los aisladores (guardamotores) del circuito deben quedar bloqueados: trabajar sin bloqueo o sin verificar termina la misión con el informe de accidente. Una falta baja la calificación, y un equipo dañado sigue así en el siguiente intento, hasta cambiar el repuesto.

**Misiones del cuadro principal:** llevan `"tipo": "cuadro"` y se juegan en la pantalla del cuadro, con una pestaña Misión. La lógica está en `game/mision_cuadro.gd`, y lo común a las dos clases de misión en `game/mision_base.gd`. Las prueba `tests/test_guardia_cuadro.gd`. Sus campos:

| Campo | Contenido |
|---|---|
| `cuadro` | `cargas` (las salidas, con `id`, `nombre`, `params` y `estado`) y `ajustes` (parámetros de otros componentes, por id). Una salida con `falla_mohm` y `falla_fase` tiene una falla a tierra |
| `preparar` | Órdenes que dejan el cuadro como dice el reporte: `arrancar`, `cerrar`, `abrir`, `avanzar`, `centrar`, `normalizar_emergencia`, `pms`, `sincronizar`, `conectar`, `desconectar`, `parada`, `disparado`, `param` y `estado`. `normalizar_emergencia` deja el cuadro de emergencia alimentado por el enlace QT y su generador parado en automático; necesita las barras principales con tensión |
| `pasos`, `bloqueables` | Botones del procedimiento que ponen marcas, como `aviso`, y los grupos o salidas que el jugador puede bloquear |
| `reglas`, `eventos` | Faltas por maniobra (`al: desconectar`, con `sin` la marca que faltaba) o por evento (`evento`, con `si_conectada` opcional). `eventos` cambia la falta de un evento de la simulación |
| `evidencias` | Condiciones que deben mantenerse `durante_s` segundos, o acciones hechas, antes del diagnóstico |
| `acciones` | Como en las misiones de motores, con `bloqueo` (equipo que debe estar bloqueado y, salvo `"verificar": false`, verificado) y `medir` (megóhmetro sobre una salida, con `{mohm}` en el texto) |
| `prueba` | `objetivos` (condiciones con su `texto`), `mantener_s` y el texto `superada` |

Las condiciones son `cerrado` y `abierto` (con `id` de un generador, o `interruptor` con el id de cualquier interruptor, como `QT`), `en_marcha`, `parado`, `conectada`, `desconectada`, `frecuencia`, `tension`, `reparto`, `aislamiento`, `pms`, `param` y `sin_bloqueos`. Dejar las barras sin tensión o cerrar fuera de fase termina la misión con un informe de incidente, cuyos textos están en `incidentes` de `data/guardia.json`.

**Misiones de la planta de frío:** llevan `"tipo": "planta"` y se juegan en la pantalla de la planta, con una pestaña Misión. La lógica está en `game/mision_planta.gd`, y la pestaña Misión, común con las del cuadro, en `ui/panel_mision.gd`. Las prueba `tests/test_guardia_planta.gd`. Tienen los mismos campos que las del cuadro, salvo `cuadro` y `reglas`, y además:

| Campo | Contenido |
|---|---|
| `preparar` | `param`, `estado` (de cualquier componente, como `PLANTA`), `disparado` (un presostato), `marcha` (pulsa S1) y `avanzar` (segundos de planta, en pasos de 1 s) |
| `bloqueables` | `Q1`, el guardamotor del compresor, o el arrancador de una bomba: `bomba_agua_mar` o `bomba_salmuera` |
| `eventos`, `repetidos` | Falta por un evento de la simulación. Los disparos de presostato llevan el punto: `disparo_presostato_descarga`. En `repetidos` la falta cuenta desde la segunda vez, porque el primer disparo sirve para ver la avería |
| `verificar_en_sala` | Con `true`, verificar la ausencia de tensión también es entrar en la sala |
| `acciones` | Como en las del cuadro, y además `en_sala` (con amoníaco por encima del aviso, exige las marcas `era` y `companero`, o es accidente), `abre_circuito` (exige la marca `aislado`, o es accidente), `requiere` (condiciones de la planta con su texto `si_no`), `comprobar` (condiciones que, si no se cumplen, dan la falta `falta`), `quita` (marcas que borra) y `medicion` (anota el texto en el libro). El texto puede citar lecturas: `{ppm}`, `{aceite}`, `{succion}`, `{descarga}`, `{salmuera}`, `{condensacion}` y `{hielo}` |

Las condiciones son `en_marcha`, `parado`, `presion` y `temperatura` (con `punto`), `planta` (un valor de su estado, como `hielo` o `ppm_sala`), `estado` (igual a `valor`), `param`, `presostatos` (los tres cerrados), `bomba` y `bomba_parada`, `automatico`, `marca` y `sin_marca`, `medido` (un punto medido con el termómetro) y `sin_bloqueos`. Arrancar con la marca `aislado` o que abra la válvula de seguridad termina la misión con un informe de incidente.

**Exámenes:** cada `data/examenes/<id>.json` se publica en `modos.examen.examenes` de un sistema, y aparece también en la pantalla de inicio y en Mi progreso. Los de la Escuela técnica se publican igual en sus módulos (`escuela` de `data/sistemas.json`) y cierran el camino de lecciones del módulo. `sistema_simbolos` elige de qué sistema son los símbolos que pregunta. Cada examen define `minimo` (porcentaje para aprobar), `composicion` (cuántas preguntas de cada tipo: `quiz`, `caso`, `ordenar`, `simbolo` y `simbolo_iso`, este último de la ISO 1219 con tres opciones de su misma familia) y el banco `preguntas`. Para que el examen varíe, el banco debe tener al menos el doble de lo que se pregunta, y una prueba lo comprueba. Las de tipo `caso` añaden un texto `caso`; cada pregunta lleva un `tema` que no se repite en ninguna lección ni en otro examen. En las de tipo `ordenar`, los pasos deben tener un único orden posible.

**Repaso:** cada fallo guarda su `tema` en la partida. `game/banco_repaso.gd` busca la pregunta de ese tema en las lecciones, en el examen, en `preguntas` de `data/guardia.json` (faltas, accidentes e incidentes), en el diagnóstico y el libro de las misiones, y en los símbolos. Cada acierto aleja el tema 1, 3, 7, 14 y 30 días; un fallo lo reinicia. **Cada falta o accidente nuevo necesita su pregunta**, y una prueba lo comprueba.

**Rangos:** `data/rangos.json`, cada uno con `nombre`, `puntos` y `galones` (cómo se dibuja su pala: -1 nada, 0 el distintivo de cadete, 1 a 4 galones). `PuntosJuego.maximos` (`game/puntos_juego.gd`) suma lo que da todo el contenido, buque y Escuela. Las pruebas exigen que el rango más alto se pueda alcanzar, que no baste sin misiones o sin examen, que solo con lecciones no se llegue a Oficial de 1ra y que el más alto no quede regalado. Al añadir contenido, suba los valores.

**Tableros:** cada `data/tableros/<id>.json` reproduce un tablero del buque y se publica en `modos.taller.tableros` de un sistema. Lleva `circuito` (un archivo de `data/circuitos/`), `alimentacion` (su interruptor con candado, de tipo `seccionador`), `frente` con su `tamano` en unidades del panel, `acabado` (`inox`, `gris` o `blanco`) y `elementos`, `interior` (posición de cada componente en la mesa), `senales` (órdenes de otros equipos, con un `selector`) y `averias` de práctica (`componente`, `param` y `valor`). Los elementos del frente son `rotulo` (con `
` para varias líneas), `luz` (`color` y `estilo` `plana` o `domo`), `pulsador` (con `luz` si es luminoso), `selector`, `seta`, `seccionador`, `horometro` y `cerradura`, con su `x`, `y` y su `componente`. Un elemento sin componente se dibuja apagado, como la reserva. Una prueba comprueba que todo lo que nombra el tablero existe en su circuito.

**Misiones frente a un tablero:** con `"tablero": "<id>"` la misión usa el circuito y el interior de ese tablero, y su pantalla empieza frente a él. `aisladores` fija los puntos de bloqueo (un guardamotor, un `seccionador` o la fuente) y `nombres_aisladores` cómo se llaman en los botones. `params_iniciales` y `estado_inicial` ponen la avería con que empieza, como `{"Q0": {"polo_danado": "5-6"}}` o relés ya disparados.

**Términos:** en los textos se escriben `{{id}}`, con el id definido en `data/glosario.json`. La primera vez que aparece en cada ficha se muestra también en inglés. Al empezar una frase o una viñeta se usa mayúscula inicial: `{{Estator}}`. No se le pegan letras detrás: `{{devanado}}s` queda mal escrito, y una prueba lo detecta.

**Datos sin confirmar:** todo valor típico debe indicar en el texto `valor típico — verificar a bordo`.

**Redacción:** tono de instructor técnico. Las instrucciones van con "usted" ("abra el aislador", "verifique la ausencia de tensión") y las explicaciones en tercera persona, sin humor ni frases ingeniosas.

**Dibujos:** Godot no dibuja el texto de los SVG, así que las letras van en `etiquetas` del JSON, en coordenadas del dibujo. Cada SVG necesita al lado un archivo `<nombre>.svg.import` con este contenido, para que se exporte tal cual y se pueda dibujar a la resolución de cada pantalla:

```text
[remap]

importer="keep"
```

**Partida:** se guarda en `user://partida.json`, con una copia de la anterior en `.bak`. Si el archivo está dañado se recupera la copia y se avisa al jugador. En **Mi progreso** se exporta o importa como archivo, con el selector nativo del sistema, o como texto copiado y pegado. Importar pide confirmación antes de reemplazar el progreso.

## Marco de simulador (Guardia y Taller)

Desde la versión 4.13.0, las pantallas de Guardia y Taller se muestran dentro de un marco al estilo de los simuladores de sala de máquinas. Las pantallas que lo usan son las de `Raiz.PANTALLAS_ARI`. La Escuela, las fichas y el inicio siguen con el tema oscuro, con el relieve de la sección «Inicio y Escuela».

- **Partes** (`ui/marco_ari.gd`, `MarcoAri`):
  - barra superior con la placa del panel (código en ámbar, título y lugar o nota) y los botones Volver, ?, ‹, › e Inicio;
  - columna de accesos por grupo, con el Índice y la Leyenda;
  - panel derecho plegable con GENERACIÓN, ALARMAS (con ACK) y CONSEJOS;
  - barra inferior con el reloj, el último evento y el escenario.
- **En vertical:** los accesos van en una tira que se desliza. El panel derecho sube como hoja desde los botones de generación y alarmas. Los botones ‹ y › pasan a la fila de abajo.
- **Disposición:** plegar el panel derecho da su ancho a la pantalla. Si la pantalla queda con menos de 696 puntos de ancho, usa su disposición en una columna (`Raiz.ancho_contenido()`).
- **Índice de paneles** en `data/paneles.json`:
  - `grupos`: id de una letra, nombre, nombre corto, color e icono;
  - `paneles`: código `G-11`, grupo, título, lugar, pantalla, `args` y hasta tres consejos. Un panel sin `pantalla` sale en gris como «próximamente».
  - `pantallas`: placa y consejos de las pantallas sin código propio, como la Guardia o una avería.
  - Para añadir un panel, basta con una entrada nueva; las pruebas comprueban que el código sea único y que la pantalla exista.
- **Generación:** una pantalla con simulación propia la entrega con `generacion_marco()`, como el cuadro principal. Si no, se usa `escenario_marco` de `data/barco_via_simoun.json` (valor típico — verificar a bordo).
- **Eventos y alarmas:** `Raiz.eventos` (`EventosBuque`) guarda los de la sesión. `_mostrar_aviso(titulo, texto, "alarma")` pone una consecuencia de la simulación en la lista roja; los demás avisos van solo a la barra de eventos. Una misión en curso sale como alarma (`alarmas_marco()`).
- **Piezas reutilizables:**
  - `DibujoAri`: degradados con varias paradas, relieve, sombras y siete segmentos;
  - `BotonAri`, `PanelAri`, `LecturaLcd`, `FondoAri`, `PerfilBuque` y `MuestraLeyenda`.
- **Pruebas** en `tests/test_marco_ari.gd`. Con `ari` detrás de la carpeta, el comando de capturas guarda el marco en 960×432 y 432×960.

### Contenido del marco (versión 4.14.0)

- **Tema:** dentro del marco, los botones, las tarjetas y las pestañas toman el tema de `Tema.crear_ari()`. Los botones son azules con brillo y la pestaña elegida es ámbar. El fondo es `EstiloAri`, un `StyleBox` dibujado con polígonos.
- **Mímico de los tableros:** un tablero con bloque `mimico` en su JSON se abre en la vista **Mímico**. La barra de arriba cambia entre Mímico, Frente (el dibujo fiel a las fotos) e Interior (la mesa para medir).
  - `alimentacion`: interruptor general (`componente`), lámparas de tierra (`tierra`), pulsador de prueba (`test`) y los dos nodos cuya tensión se lee (`medida`).
  - `casillas`: una por arrancador, con `titulo`, `franja` (verde, azul, cian, rojo, amarillo, gris, lila o naranja), `motor`, `proteccion`, `termico`, `arrancador`, `marcha`, `paro`, `luz_marcha`, `luz_paro`, `luz_falla` y `selector`. Todo es opcional menos el título. Una casilla con `"tipo": "mando"` lleva `elementos` (selector, pulsador, seta, luz o lectura).
  - `megohmetro`: añade el megóhmetro con el selector de fase R-S-T. Prueba de la fase elegida del motor (`U1`, `V1` o `W1`) a `masa`, como al medir en la bornera, y las misiones lo registran igual.
  - El dibujo está en `CasillaAri` y `PiezasAri`, y la rejilla en `VistaMimico`. Los pulsadores se aprietan al mantener el dedo 0,12 s, para que arrastrar la lista no arranque un motor.
- **Cuadro principal:** los grupos G1 a G4 van como casillas (`CasillaGenerador`). Tocar STOP/START arranca o para el diésel, los botones I y O maniobran el interruptor y el resto de la casilla abre el detalle del grupo.
- **Planta, PLC y puesto de alarmas:** el esquema de frío usa los colores de la leyenda, con tuberías con relieve, flechas de sentido y presiones en visores. El PLC muestra su frente con los LED (`ModuloPlc`).
- **Avisos:** dentro del marco, `_mostrar_aviso` pone una tarjeta `AvisoAri` centrada sobre toda la pantalla. La cabecera es roja si es una alarma y ámbar si es un evento, y la tarjeta tiene botón ACK. Los avisos siguen saliendo de uno en uno.
- **Alarmas que se tocan:** una alarma registrada en otro panel lleva a ese panel. La Guardia muestra las averías sin terminar como una tabla y como alarmas; al tocarlas se abre la misión (`alarmas_marco_detalle()` con `abrir`).
- **Panel derecho en un celular apaisado:** con menos de 560 puntos de alto empieza plegado, y al abrirlo flota sobre el contenido sin estrecharlo (`MarcoAri.panel_superpuesto()`). En PC y tableta sigue fijo y plegable.
- **Acabado (4.14.1):**
  - los rótulos de sección son barras con brillo (variación «Rotulo» del tema);
  - las zonas desplazables de los tableros, la planta, el PLC y la red van sobre una chapa (`Pantalla._chapa_zona`);
  - los instrumentos de aguja van en chapa azul con rótulo grabado y la lectura en un visor de siete segmentos, verde o ámbar si pasa de la zona roja;
  - la red RS-485 se dibuja como un mímico. La pantalla MYCOM sigue clara, como la pantalla táctil real del compresor.
- **Pruebas** en `tests/test_rediseno_b.gd`.

## Inicio y Escuela (versión 4.15.0)

El inicio y la Escuela siguen con el tema oscuro y el color por área, pero dibujados con relieve: placas con bisel, medallas, monedas y lámparas con halo (`ui/widgets/relieve.gd`, `Relieve`).

- **Inicio:** el buque visto desde arriba (`PlantaBuque`). En apaisado la proa queda a la derecha; en vertical, arriba.
  - Cada sistema del buque es una zona que se toca y abre el sistema. La seguridad (sistema 0) va aparte, como una medalla en el agua.
  - Las zonas están en `data/sistemas.json`, en el bloque `planta`: `sistema`, `nombre`, `u` (de popa, 0, a proa, 1000) y `v` (de babor, 0, a estribor, 300). La disposición es esquemática: verificar a bordo. El casco, las cubas, la parrilla de máquinas y la superestructura se dibujan en el código.
  - La lámpara de cada zona sale de `Avance.estado()`: verde si todo está hecho, ámbar si hay algo hecho, roja si una misión dejó un equipo dañado y apagada si no se ha empezado.
  - Al lado (o debajo, en vertical) van la placa del rango con los puntos en un visor de siete segmentos, «Continuar» con un botón redondo (`BotonPlay`), el botón rojo de avería, que lleva a la Guardia de ese sistema, y el repaso con su insignia.
- **Escuela:** cada módulo es una medalla con un anillo de avance (`MedallaModulo`). Van en una tira arriba en vertical y en una columna en apaisado. Los módulos en preparación salen con candado.
  - El módulo elegido muestra su placa con la siguiente lección y «Empezar», el **camino de lecciones** (`CaminoLecciones`) y el **cajón de piezas** con las fichas de su atlas (`PiezaAtlas`).
  - El camino va en serpentina; si las monedas caben en una fila, va en una sola. Las hechas llevan una marca, la siguiente es ámbar y brilla, y las pendientes van numeradas. El examen del módulo, si lo tiene, va al final. Ninguna lección queda cerrada.
  - Sin `modulo` en los argumentos, la Escuela abre el primer módulo con algo por hacer.
- **Toques:** los dibujos que se tocan heredan de `ControlToque`, que distingue un toque de un arrastre como `FilaMenu`, así las listas se desplazan aunque el dedo empiece encima.
- **Barra de navegación:** con relieve y una barra ámbar encendida sobre la sección activa.
- **Pruebas** en `tests/test_rediseno_c.gd`. Las capturas se hacen con `godot --path . --script res://tests/capturar.gd -- build/capturas_c inicio`.

## Fichas y atlas (versión 4.16.0)

La ficha de equipo (`ui/screens/ficha.gd`) y el atlas (`ui/screens/atlas.gd`) siguen con el tema oscuro y el color por área, con el relieve de la Escuela.

- **Cabecera** (`CabeceraFicha`): placa con el botón de volver, la medalla del área y el título. En el atlas, el anillo de la medalla y las cinco lámparas de VISTAS dicen cuántas vistas se han visto.
- **Visor** (`VisorFicha`): hueco oscuro con luz de foco y tornillos. Lleva el dibujo grande del equipo; en el atlas, también el corte animado, el esquema y la medida, sobre una hoja de papel (`Relieve.estilo_papel`).
- **Marcas numeradas** (`DibujoMarcas`, que hereda de `VistaBornes`): monedas ámbar con relieve (`Relieve.marca`). Tocar una la enciende y abre un bocadillo con la parte, unido a la marca con una línea guía. El bocadillo va a la derecha en apaisado y debajo en vertical, y su sitio se reserva para que el dibujo no salte. La lista de partes (`FilaParte`) se enlaza con las marcas en los dos sentidos.
- **Pestañas con iconos** (`PestanaIcono.tira`): la elegida se enciende en ámbar con una barra de luz; las ya vistas llevan una lámpara verde.
  - En la ficha: Partes, Funciona, Conexión, Prueba y Fallas. Las secciones de la ficha se reparten por su título (`pestana_de_seccion`) y cambiar de pestaña no reconstruye la pantalla, así el banco de prueba sigue en marcha.
  - En el atlas: Qué es, Funciona, Conexión, Medir y Fallas.
- **Vistas del equipo en la ficha:** Equipo, Símbolos y los dibujos extra, con teclas en el visor. La nota del dibujo va al final de la hoja Partes.
- **Atlas:** placa de datos como una chapa remachada; pasos de la animación como monedas que se encienden; lecturas de Medir y de Fallas en visores negros, verdes si son normales y rojas si indican falla; fallas con su lámpara roja (`BotonAri.lampara`) y mantenimiento con casillas de relieve.
- **Pruebas** en `tests/test_rediseno_d.gd`. Las capturas se hacen con `godot --path . --script res://tests/capturar.gd -- build/capturas_d fichas_d`.

## Lección, examen, repaso y Buque (versión 4.17.0)

La lección, el examen, el repaso y la pantalla «Buque» siguen con el tema oscuro y el color por área, con el relieve de la Escuela y de las fichas. Las piezas comunes están en `ui/widgets/piezas_leccion.gd` (`PiezasLeccion`), `TeclaOpcion` y `FilaPlaca`.

- **Lección** (`ui/screens/leccion.gd`):
  - cabecera de la ficha (`CabeceraFicha`) con la medalla del área y una moneda por página (`PiezasLeccion.MonedasPaginas`): verde la hecha, ámbar la actual y hundida la pendiente;
  - el texto va en placas. Un párrafo que sea solo una fórmula centrada en negrita, como `[center][b]V = I × R[/b][/center]`, sale en un visor con letras ámbar (`partir_formulas`), sin cambiar los JSON;
  - las animaciones y las imágenes van dentro de un visor hundido (`VisorFicha`); las imágenes, en papel;
  - en apaisado (desde 720 puntos de ancho), el texto va a la izquierda y lo que se toca a la derecha: animación, imagen, pregunta, ordenar o práctica. En vertical, una sola columna;
  - «Anterior» oscuro y «Siguiente» ámbar; mientras falte contestar, «Siguiente» queda oscuro con la lámpara apagada;
  - al final: medalla con el anillo de aciertos, una lámpara por pregunta, visores de aciertos y puntos, los temas fallados con lámpara roja, «Para saber más» en papel y la siguiente lección como moneda del camino.
- **Preguntas** (`BloqueQuiz` y `BloqueOrdenar`): una placa con su rótulo y una tecla por opción con la moneda de su letra (`TeclaOpcion`). Al contestar, la correcta se enciende en verde, la elegida mal en rojo y las demás se apagan; la explicación sale en un visor con «CORRECTO» o «INCORRECTO». El caso práctico va en una hoja rayada del libro de guardia. En ordenar, los pasos ya puestos son filas numeradas.
- **Examen y repaso** (`ui/pantalla_preguntas.gd`):
  - contador de la pregunta en un visor ámbar y, en el examen, una lámpara por pregunta (`TiraPreguntas`);
  - en el repaso, las cinco cajas de la repetición espaciada (1, 3, 7, 14 y 30 días), con la del tema en ámbar (`CajasRepaso`);
  - el símbolo va en papel dentro de un visor, al lado de la pregunta en apaisado;
  - calificación del examen con el anillo del porcentaje, las tres estrellas dibujadas (la fuente no tiene ★), la lámpara de APROBADO y los visores de aciertos y puntos;
  - la lista de exámenes y minijuegos de cada sistema (`examen.gd`) va en placas con filas `FilaPlaca`.
- **Buque** (`ui/screens/plano_barco.gd`): el buque visto desde arriba (`PlantaBuque`) con dos capas que se eligen arriba a la izquierda.
  - **Tableros** (la de inicio): cada lugar con paneles lleva una marca ámbar con el rayo, el número de paneles y una lámpara roja si alguno tiene una avería pendiente (una misión que dejó un equipo dañado). Al tocarla, al lado salen sus paneles con el código en un visor ámbar; tocar uno lo abre en el marco.
  - **Sistemas**: las zonas abren su sistema, como en el inicio, y al lado va la lista de sistemas con su medalla, su avance y su lámpara de estado.
  - Los lugares están en `data/sistemas.json`, bloque `planta.lugares`: `lugar` (el mismo texto que el campo `lugar` de `data/paneles.json`), `u` y `v`. La posición es esquemática: verificar a bordo. Un panel nuevo sale solo en su lugar; las pruebas comprueban que todos los paneles tengan uno.
  - `Paneles.codigo_mision()` da el panel de una misión, y `Paneles.por_lugar()` agrupa los paneles por lugar.
- **Pruebas** en `tests/test_rediseno_e.gd`. Las capturas se hacen con `godot --path . --script res://tests/capturar.gd -- build/capturas_e rediseno_e`.

## Válvulas (versión 4.19.0)

El módulo 10, «Válvulas y líneas», está activo con ocho lecciones de válvulas (`va1` a `va8`): partes, cuarto de vuelta (bola, mariposa y macho), multivuelta (compuerta, globo y aguja), retención, tres vías, actuadas, de seguridad y reductoras, y maniobra segura. Las líneas llegarán en la etapa 44.

- **Dibujo** (`ui/widgets/dibujo_valvula.gd`, `DibujoValvula`): once tipos dibujados con relieve sobre su tubo, en cualquier apertura de 0 (cerrada) a 1 (abierta). El estado se ve como a bordo: la maneta en línea con el tubo o cruzada, la ranura del macho, el vástago que asoma por encima del volante, el indicador amarillo del actuador o la salida de la tres vías (`via`). Con `flujo` se ve el agua y con `rotulo`, la chapa del servicio.
- **Catálogo** (`data/catalogos/valvulas.json`, pantalla `catalogo`): para cada tipo, el nombre en español e inglés, la familia, cómo saber si está abierta, cómo funciona, el uso a bordo, para qué no se usa, las fallas y el mantenimiento. Se abre desde el Pañol. Los datos del buque son valores típicos — verificar a bordo. Para añadir un tipo, basta con una entrada nueva con un `dibujo` de `DibujoValvula.TIPOS`.
- **Minijuego «¿Abierta o cerrada?»** (pantalla `abierta_cerrada`, `JuegoValvulas`): diez válvulas del catálogo en un estado al azar, con la chapa de un servicio. Las preguntas, las opciones y los estados salen del campo `minijuego` de cada tipo. Las estrellas se guardan como `abierta_cerrada` y el minijuego sale en el Pañol y en la evaluación del módulo 10.
- **Animaciones:** `corte_valvula` (el corte de la válvula de bola, que se cierra un poco antes de los 90°) y `valvula_estado` (cualquier tipo del catálogo, que se abre, se cierra o cambia de vía; `params.tipo`).
- **Pañol:** las filas van ahora en placas (`FilaPlaca`), con el catálogo de válvulas y el minijuego.
- **Pruebas** en `tests/test_valvulas.gd`. Las capturas se hacen con `godot --path . --script res://tests/capturar.gd -- build/capturas_g valvulas`.

## Herramientas y llaves (versión 4.20.0)

El módulo 11, «Herramientas y racores», está activo con nueve lecciones de herramientas (`he1` a `he9`): familias de llaves, milímetros y pulgadas, tornillería métrica y UNC/UNF, destornilladores de 1000 V, alicates y crimpado, calibre y micrómetro, par de apriete, herramienta de tubería y cuidado y seguridad. Los racores se añadieron en la etapa 43 (versión 4.21.0).

- **Dibujo** (`ui/widgets/dibujo_herramienta.gd`, `DibujoHerramienta`): 16 herramientas dibujadas con relieve (cromadas, pavonadas o con mangos aislados). `medida` se graba en el cuerpo de las llaves.
- **Catálogo** (`data/catalogos/herramientas.json`): nombre en español e inglés, familia, para qué sirve, cómo se usa, lo que no se debe hacer, cuidado y revisión, y `similares` (los nombres que el minijuego ofrece como trampa). Usa la misma pantalla `catalogo` que las válvulas, con su configuración en `CATALOGOS`.
- **Tabla de llaves** (`data/tablas/llaves.json`, `TablaLlaves`, pantalla `tabla_llaves`): cada medida en pulgadas en mm y la llave métrica que le sirve, con lámpara verde (entra), ámbar (holgada) o roja; el conversor dibuja la llave y muestra los visores.
  - Criterio: una llave entra si mide como mucho 0,06 mm menos y hasta 0,2 mm más que la tuerca, porque las bocas se fabrican algo mayores que su medida (ISO 691). De 0,2 a 0,5 mm más queda holgada, y más, redondea la tuerca: entonces la tabla dice «use la de pulgadas».
  - Son valores de enseñanza: verificar con la llave y la tuerca reales.
- **Minijuego «Identifique la herramienta»** (`JuegoHerramientas`, pantalla `identifique_herramienta`): siete herramientas para nombrar y tres rondas de llaves («¿qué llave métrica entra en una tuerca de 3/4"?»). Registro `identifique_herramienta`; sale en el Pañol y en la evaluación del módulo 11.
- **Animaciones:** `herramienta` (las herramientas de `params.tipos`, con su nombre y uso) y `llave_tuerca` (la llave sobre la tuerca, con la holgura exagerada para verla).
- **Pruebas** en `tests/test_herramientas.gd`. Las capturas se hacen con `godot --path . --script res://tests/capturar.gd -- build/capturas_h herramientas`.

## Código de colores de los cables (versión 5.4.0)

Cada cable de la mesa y de los tableros lleva el color de su conductor (`MesaTaller.conductor_cable`, tabla `MesaTaller.CONDUCTORES`). Son valores típicos según IEC 60445 y, en el mando, IEC 60204-1: verificar a bordo.

| Conductor | Color |
|---|---|
| L1 · L2 · L3 (fases) | marrón · negro · gris |
| N (neutro) | azul claro |
| PE (tierra) | verde-amarillo |
| Mando en alterna | rojo |
| Mando en continua (+24 V y señales) | azul oscuro |
| 0 V de continua | azul con raya blanca |
| Enclavamiento con tensión externa | naranja |
| Hilos del propio cable de un sensor | BN marrón · BU azul · BK negro |

- **Cómo se decide**, por los bornes de los dos extremos y en este orden:
  1. lo que fije el tablero;
  2. un borne `PE`;
  3. los bornes BN, BU o BK de un sensor;
  4. una fase: `L1`, `L2` o `L3`; los bornes 1 a 6 y U1-V1-W1 de los aparatos con `"potencia"`; o los de `"fases"` del catálogo (en el interruptor automático y el diferencial, el polo 1-2 es L1 y el 3-4 es L2);
  5. un borne `N`;
  6. un borne de `"cero_v"` del catálogo (el `-` de la fuente, `M` y `1M` del PLC);
  7. un borne de `"cc"` del catálogo (`true` para toda la pieza, o la lista de sus bornes de continua);
  8. si no, mando en alterna.
- **Naranja y otros fijados:** `"colores"` en el JSON del tablero fija el conductor de un punto eléctrico por uno de sus nodos o por su número de hilo, como `{"Q1.14": "naranja"}` o `{"21": "naranja"}`. Admite las claves de `CONDUCTORES` y `naranja`, `rojo`, `azul_oscuro`, `azul_claro` y `verde_amarillo`.
- **Tablero D-51 (5.4.1):** el hilo del pulsador TEST de las lámparas de tierra al casco va en rojo con `"colores": {"ST.14": "rojo"}`. Es del circuito de prueba, no una tierra de protección. `"nota_colores"` explica el motivo en «Datos».
- **Dibujo:** el PE y el 0 V llevan la raya del aislante a lo largo del cable. El cuello de la puntera sigue la sección: azul en fases y tierra, rojo en el resto.
- **Interfaz:**
  - la ficha del hilo muestra una muestra del cable, qué conductor es y su color;
  - la pestaña «Datos» del tablero y el panel vacío del Taller muestran la leyenda (`MuestraCable`).
- **Pruebas** en `tests/test_colores_cables.gd`. Capturas: `godot --path . --script res://tests/capturar.gd -- build/capturas_colores colores`.

## Cables y bornes con aspecto real (versión 5.3.0)

La mesa del Taller y el interior de los tableros dibujan los cables y su conexión como se ven a bordo (`ui/widgets/vista_mesa.gd`).

- **Cable con volumen:** sombra sobre la placa, borde oscuro, color y un brillo. El cable tocado lleva un halo ámbar.
- **Salida del borne** (`MesaTaller.salida_borne`): cada cable sale recto `TRAMO_RECTO` (50 unidades) alejándose del aparato, hacia arriba o abajo según el lado del borne y hacia un costado en los bornes laterales. Luego sigue una curva de grado 4. El arrastre del mango y la caída del centro no tuercen esa salida.
- **Puntera:** tubo metálico desde el borne y cuello de color según la sección (DIN 46228). El cuello es rojo (1 mm²) en mando y azul (2,5 mm²) en potencia. Con dos o más cables en un borne, la puntera es doble.
- **Borne con cable:** silleta de apriete sobre la puntera y tornillo niquelado de cabeza combinada encima. **Borne libre:** tornillo suelto con un aro ámbar discontinuo.
- **Ordenar cables:** las esquinas se redondean (`RADIO_ESQUINA`). Si los dos bornes casi están alineados, el cable hace un desvío suave en S.
- **Manguitos:** van pasada la puntera, girados a lo largo del cable.
- **Pruebas** en `tests/test_cables_reales.gd`. Capturas: `godot --path . --script res://tests/capturar.gd -- build/capturas_cables cables`.

## Etiquetado de hilos en los tableros (versión 5.2.0)

En el interior de los tableros y en el Taller, cada cable lleva un manguito con su número de hilo en los dos extremos, junto al borne.

- **Numeración por potencial** (`MesaTaller.numero_hilo`): todos los cables unidos sin pasar por un aparato son el mismo punto eléctrico y llevan el mismo número.
  - `L1`, `L2` y `L3` si el punto toca una fase de la alimentación; `N` y `PE`, el neutro y la tierra;
  - `1U1`, `2V1`… los bornes del motor, con su número delante (M1 → 1);
  - `1L1`… `1L3` la potencia tras el aparato nº 1 (Q1, AS1…), con la fase de su borne (2, 4 o 6);
  - el resto, 1, 2, 3… en el orden de los cables.
- **Números reales:** `"hilos"` en el JSON del tablero fija el número de un punto por uno de sus nodos, como `{"Q1.14": "21"}`. Sin él, la numeración es de enseñanza: verificar contra el esquema del tablero.
- **En la mesa:** los marcadores se dibujan desde el zoom `ZOOM_ETIQUETAS` (0,6); al tocar un cable, todo su hilo se marca en ámbar y la pestaña «Equipo» muestra su número, desde y hasta. El botón «Etiquetas» («Hilos» en vertical) los apaga. En «Datos», la tabla de hilos lista cada número con sus bornes; tocar un renglón marca el hilo.
- **Pruebas** en `tests/test_hilos.gd`. Capturas: `godot --path . --script res://tests/capturar.gd -- build/capturas_hilos hilos`.

## Exámenes de la Escuela y rangos (versión 5.1.0)

- **Examen de la Escuela I** (`data/examenes/v6.json`), en los módulos 7 y 8: electricidad industrial y electrónica. 20 preguntas al azar (10 de concepto, 4 casos, 2 de ordenar y 4 símbolos IEC/ANSI del sistema 3) de un banco de 38.
- **Examen de la Escuela II** (`data/examenes/v7.json`), en los módulos 9 a 11: hidráulica, neumática, válvulas, líneas, herramientas y racores. Igual, pero los 4 símbolos son de la ISO 1219 (`simbolo_iso`), con su hoja «ISO 1219-1 · Hidráulica» o «Neumática». Banco de 36.
- **Repaso:** un símbolo ISO fallado se guarda con el tema `iso1219_<id>` y vuelve en «Repasar mis errores».
- **Rangos:** se añade **Aspirante** (0 puntos) antes de Cadete y se recalibra con todo el contenido (unos 7400 puntos): Cadete 300, Oficial de 3ra 1200, de 2da 2600, de 1ra 4200 y Jefe 6600. Una partida antigua conserva sus puntos, pero puede quedar en un rango más bajo con la escala nueva.
- **Mi progreso:** pala del rango actual (`PalaRango`, `ui/widgets/pala_rango.gd`), escalera de los seis rangos con sus galones y los puntos que da cada parte del juego.
- **Pruebas** en `tests/test_escuela_examenes.gd`; `tests/test_progresion.gd` recorre ya todo el contenido, Escuela incluida. Capturas: `godot --path . --script res://tests/capturar.gd -- build/capturas_fin cierre`.

## Hidráulica (versión 4.23.0)

El módulo 9, «Hidráulica y neumática», se abre con la parte de hidráulica. La neumática llegó en la etapa 46 (abajo).

- **Lecciones** `hi1` a `hi9`:
  - presión, fuerza y caudal;
  - el aceite;
  - bombas;
  - cilindros y motores;
  - válvulas de presión;
  - caudal y retención;
  - direccionales y esquemas ISO 1219;
  - acumuladores;
  - diagnóstico.
- **Atlas** de ocho piezas, con ficha y atlas (`data/fichas/<id>.json` y `data/atlas/<id>.json`): `bomba_engranajes`, `bomba_pistones`, `cilindro_hidraulico`, `motor_hidraulico`, `valvula_alivio`, `estranguladora`, `antirretorno_pilotada` y `acumulador`.
  - Sus fichas llevan un solo símbolo, `simbolos.iso`, según la ISO 1219-1, en lugar de la pareja IEC/ANSI.
  - En «Conexión» se habla de bocas: P, T, A, B, S, L, X, V, C y N₂.
- **Modelo hidráulico** `SimHidraulica` (`game/sim_hidraulica.gd`), en régimen estable. Resuelve un circuito con estos componentes:
  - motor eléctrico;
  - bomba fija con fuga interna que crece con la presión y el desgaste;
  - válvula de alivio (normal, pegada o con el asiento dañado);
  - direccional 4/3 de centro cerrado;
  - cilindro de doble efecto (avance, retroceso, a tope, junta gastada) o motor hidráulico (par, rpm y drenaje);
  - estranguladora a la salida (meter-out);
  - antirretorno pilotada (deriva);
  - acumulador de vejiga (ley de Boyle).

  Los valores por defecto son típicos y hay que verificarlos a bordo.
- **Lecturas de «Medir» y de las fallas:** una medida con `"hidraulica": "banco"` se calcula con el modelo. Lleva `"punto"` (`P`, `A`, `B`, `T`, `S`, `Q`, `Q_bomba` con `presion_prueba`, `Q_alivio`, `fuga_B`, `drenaje`, `rpm`, `deriva`, `gas`, `volumen_util` o `calor`) y `"params"` por componente. Los cambios de cada fila se mezclan como en los circuitos eléctricos. Instrumentos nuevos en `VistaMedida`:
  - `manometro`;
  - `caudalimetro`;
  - `comparador`, el reloj comparador.

  Se dibujan unidos a la pieza con un latiguillo de prueba.
- **Animaciones** (`ui/animaciones/`), con piezas comunes en `dibujo_hidraulico.gd`:
  - `prensa_hidraulica`: Pascal;
  - `corte_bomba`: engranajes o pistones, con rpm, presión, plato y desgaste;
  - `circuito_hidraulico`: bomba, alivio, manómetro, direccional y cilindro o motor. El `foco` puede ser `alivio`, `cilindro`, `motor`, `estranguladora` o `pilotada`;
  - `acumulador_vejiga`.
- **Minijuego «Símbolos ISO 1219»** (registro `simbolos_iso1219`): 18 símbolos en `data/simbolos_iso1219.json`, cada uno con nombre, término inglés, `familia`, la `pieza` del atlas si la tiene y su explicación. Cuatro rondas enseñan la pieza dibujada y se toca su símbolo entre cuatro. Las demás enseñan el símbolo y se elige su nombre. Está en la evaluación del módulo 9.
- **Dibujos:** `python tools/svg_hidraulica.py` regenera los SVG de las piezas (`art/equipos`), los esquemas de «Conexión» (`art/esquemas/atlas_<id>.svg`) y los símbolos (`art/simbolos/iso1219`). Después, `python tools/dibujos_realistas/realzar.py faltan` saca su versión realista.
- **Pruebas** en `tests/test_hidraulica.gd`. Capturas: `godot --path . --script res://tests/capturar.gd -- build/capturas_h hidraulica`.

## Neumática (versión 4.24.0)

El módulo 9 sigue con la neumática después de la hidráulica: 18 lecciones y 16 piezas en total.

- **Lecciones** `ne1` a `ne9`:
  - el aire comprimido a bordo (arranque, control y servicio);
  - agua y suciedad: punto de rocío, secadores y la ISO 8573-1;
  - la unidad FRL;
  - cilindros: fuerza, consumo, amortiguación y detectores;
  - válvulas 3/2, 5/2 y 5/3 con la numeración ISO 5599;
  - velocidad: reguladores de caudal en el escape;
  - electroneumática: bobinas, detectores y PLC;
  - actuadores de cuarto de vuelta, NAMUR y posicionadores de 4–20 mA;
  - fugas y seguridad.
- **Atlas** de ocho piezas: `unidad_fr`, `secador_frigorifico`, `valvula_52`, `valvula_53`, `cilindro_neumatico`, `regulador_caudal`, `actuador_cuarto_vuelta` y `posicionador`. Cada una con su símbolo ISO 1219-1 (el posicionador, con la caja I/P de los esquemas de instrumentación).
- **Modelo neumático** `SimNeumatica` (`game/sim_neumatica.gd`), en régimen estable:
  - red de aire de control, secador (punto de rocío) y fugas (caudal y kW de compresor);
  - unidad de filtro y regulador, con la caída del cartucho sucio cuando hay caudal;
  - válvula 5/2 monoestable o 5/3 de centro cerrado, con bobina quemada, corredera pegada o con fuga;
  - reguladores de caudal en los escapes (meter-out);
  - cilindro de doble efecto (fuerza, velocidad, consumo por ciclo, junta gastada, carga excesiva) y detectores B1 y B2;
  - posicionador de 4–20 mA sobre un actuador de simple efecto que cierra en falla (sin aire, sin señal, membrana con fuga, acción invertida).

  Una medida con `"neumatica": "banco"` se calcula con el modelo; `"punto"` puede ser `P_red`, `P_reg`, `dP_filtro`, `P_A`, `P_B`, `velocidad`, `tiempo`, `fuerza`, `consumo`, `fuga_escape`, `B1`, `B2`, `Y1`, `senal`, `P_salida`, `P_alim`, `posicion`, `rocio`, `fuga_Q` o `fuga_kW`. Instrumentos nuevos en `VistaMedida`: `higrometro` y `cronometro`. Los valores por defecto son típicos y hay que verificarlos a bordo.
- **Animaciones**, con piezas comunes en `dibujo_neumatico.gd`:
  - `circuito_neumatico`: secador, FR, válvula, reguladores y cilindro con B1 y B2. El `foco` puede ser `cilindro`, `regulador`, `52`, `53`, `fr` o `secador`;
  - `valvula_corte`: la 5/2 por dentro, con mando manual y bobina quemada;
  - `posicionador_lazo`: calibrador, posicionador, actuador y mariposa;
  - `fuga_aire`: caudal, kW y kWh al año de un agujero.
- **Minijuego «Símbolos de neumática»** (registro `simbolos_neumatica`): 16 símbolos con `familia: "neumatica"` en el mismo `data/simbolos_iso1219.json`. La pantalla `simbolos_iso1219` elige la familia por su registro (`JuegoIso1219.FAMILIAS`), así que los dos minijuegos guardan sus estrellas por separado.
- **Dibujos:** `python tools/svg_neumatica.py` (usa las piezas comunes de `svg_hidraulica.py`; en neumática los triángulos van huecos) y después `python tools/dibujos_realistas/realzar.py faltan`.
- **Pruebas** en `tests/test_neumatica.gd`. Capturas: `godot --path . --script res://tests/capturar.gd -- build/capturas_n neumatica`.

## Seguir líneas y colores de tubería (versión 4.22.0)

El módulo 10, «Válvulas y líneas», suma cuatro lecciones (`li1` a `li4`): planos P&ID, colores de tubería, seguir una línea y aislar un equipo.

- **Esquemas** (`data/lineas/<id>.json`, el primero `purificadora.json`): espacio `ancho` × `alto`; `equipos` (rectángulos o `forma: "bomba"`), `tramos` (id, `servicio`, `puntos`, nombre), `valvulas` (id, número, x, y, `vertical`, nombre), `flechas` de sentido y `ejercicios`:
  - `seguir`: `ruta` (tramos en orden) que se recorre con el dedo; tocar una línea que no es cuenta un error;
  - `aislar`: `valvulas` que hay que cerrar; se tocan y se pulsa COMPROBAR (las que faltan se marcan en ámbar y las que sobran, tachadas);
  - `servicio`: `tramo` marcado, `opciones` y `correcta`.
  El trazado de la purificadora es de enseñanza — verificar a bordo.
- **Colores** (`data/tuberias.json`): ISO 14726, con el aviso de que en el buque muchas líneas son blancas con bandas o rótulos.
- **Lógica** `JuegoLineas` (registro `seguir_lineas`), **widget** `VistaLineas` (dibujo y dedo) y **bloque** `BloqueLinea` (esquema más tarea; lo hecho a medias vive en args y sobrevive al giro).
- **Pantallas:** `seguir_lineas` (minijuego, args `esquema`) y `colores_tuberia`. Las dos salen en el Pañol; el minijuego, también en la evaluación del módulo 10.
- **Bloque de lección `linea`:** `{"tipo": "linea", "esquema": "purificadora", "ejercicio": "<id>", "tema": "<tema>"}`. Cuenta como pregunta.
- **Para añadir un esquema:** copie `purificadora.json`, dibuje con coordenadas en su espacio y abra el minijuego con `raiz.ir_a("seguir_lineas", {"esquema": "<id>"})`.
- **Pruebas** en `tests/test_lineas.gd`. Capturas: `godot --path . --script res://tests/capturar.gd -- build/capturas_l lineas`.

## Racores, roscas y mangueras (versión 4.21.0)

El módulo 11 suma ocho lecciones de racores (`ra1` a `ra8`): familias de racores, roscas BSP y NPT, DN y NPS, JIC/ORFS/DIN 24°, mangueras hidráulicas, el latiguillo prensado, compresión/banjo/bridas SAE y fugas y seguridad. Varias enseñan fotos tomadas a bordo.

- **Dibujo** (`ui/widgets/dibujo_racor.gd`, `DibujoRacor`): los 10 racores de `TIPOS` de lado, con hexágonos, roscas paralelas o cónicas, conos, tóricas, férulas y virolas. Con `rotulos = false` no escribe sus marcas (37°, 24°…), para el minijuego.
- **Catálogo** (`data/catalogos/racores.json`): nombre y nombre corto, inglés, familia, norma, cómo se reconoce, dónde sella, a bordo, lo que no se debe hacer, fallas, mantenimiento, `similares` (trampas del minijuego) y `pista` (la descripción de la ronda). Usa la pantalla `catalogo` con `{"catalogo": "racores"}`; si el racor tiene fotos, las enseña primero, con sus partes numeradas.
- **Tablas** (`data/tablas/roscas.json`):
  - `roscas`: BSP y NPT de 1/8" a 2", diámetro exterior e hilos por pulgada;
  - `dn`: DN15 a DN150 con su NPS y su exterior (ASME B36.10);
  - `mangueras` y `marcados`: tipos SAE/EN y ejemplos de marcado. Las presiones son valores típicos — verificar.
- **Pantallas:** `roscas_tuberia` (tabla de roscas y conversor DN ↔ NPS con `TuboDN`) y `mangueras` (marcado impreso con sus visores y la lista de tipos).
- **Minijuego «Elija el racor»** (`JuegoRacores`, pantalla `elija_racor`, registro `elija_racor`): racores dibujados sin rótulos con su pista, `RONDAS_DN` = 2 rondas de DN y NPS y hasta `FOTOS_RONDAS` = 2 fotos con pregunta propia (`pregunta`, `opciones`, `correcta` en `data/fotos_piezas.json`). Sale en el Pañol y en la evaluación del módulo 11.
- **Fotos:** las de racores (latiguillos del grupo generador, codo giratorio, rosca con teflón y marcado EN 856) están en `art/fotos/racores/`. Una foto puede traer `partes` (x, y en píxeles de la original, título y texto); `FotoPieza` las numera y, para no cortarlas, enseña la foto entera.
- **Bloque de lección `foto`:** `{"tipo": "foto", "id": "<id de data/fotos_piezas.json>", "pie": "…"}`.
- **Animaciones:** `racor` (`params.tipos`) y `tubo_dn` (`params.dn`).
- **Pruebas** en `tests/test_racores.gd`. Capturas: `godot --path . --script res://tests/capturar.gd -- build/capturas_r racores`.

## Fotos a bordo de las piezas (versión 4.20.1)

Las válvulas se ven también en fotos tomadas en el B/P Vía Simoun, no solo dibujadas.

- **Datos** (`data/fotos_piezas.json`): una entrada por foto con `pieza` (el `id` del catálogo), `estado` (`abierta`, `cerrada` o vacío si solo sirve para reconocerla), `tubo` (`vertical` u `horizontal`, para la pregunta), `rotulo`, `lugar`, `texto` (la explicación) y, en píxeles de la foto original, `recorte` y `halo` (el óvalo ámbar sobre la pieza que importa).
- **Preparar las fotos:** deje las originales en una carpeta (por ejemplo `fotos_via_simoun/piezas/valvulas/v03.jpg`), apunte `origen` relativo a esa carpeta y ejecute:
  ```bash
  godot --headless --path . --script res://tools/fotos/preparar_fotos.gd -- C:/ruta/fotos_via_simoun/piezas
  godot --headless --path . --import
  ```
  La herramienta recorta, reduce a 1024 px por el lado largo y guarda en WebP en `archivo` (dentro de `art/fotos/`), unos 50–120 KB por foto.
- **Minijuego «¿Abierta o cerrada?»:** hasta 4 de las 10 rondas (`JuegoValvulas.FOTOS_RONDAS`) son fotos con estado. La pregunta dice hacia dónde va el tubo y la foto no lleva rótulo ni lámpara, para no chivar la respuesta.
- **Catálogo de válvulas:** si la pieza tiene fotos, el visor empieza por la primera; los botones 1, 2, 3… cambian de foto y DIBUJO vuelve al dibujo. En el catálogo la foto sí lleva la lámpara de su estado.
- **Widget** `FotoPieza` (`ui/widgets/foto_pieza.gd`): llena su espacio centrado en el halo, con bisel, halo que late, rótulo y crédito.
- **Pruebas** en `tests/test_fotos_piezas.gd`. Capturas: `godot --path . --script res://tests/capturar.gd -- build/capturas_fotos fotos`.
- **Versión 4.23.1:** tres fotos más del taller de máquinas, con sus partes numeradas:
  - el acoplamiento de levas Dixon tipo D, con la pregunta de seguridad antes de soltar las palancas (`camlock_dixon`, pieza `enchufe_rapido`);
  - los adaptadores giratorios de 45° con los niples sellados con cinta y con sellador (`codo_niples`, pieza `bspt_npt`);
  - la válvula de bola NIBCO T-580 suelta, cerrada y con el agujero para el candado (`nibco_suelta`, pieza `bola`).

  La foto de la te de inoxidable 304 está movida y queda fuera hasta repetirla.

## Dibujos realistas de los equipos (versiones 4.16.2 a 4.16.6)

Godot solo dibuja degradados al leer un SVG. Para que los equipos se vean casi como una foto, sus dibujos se preparan fuera del juego con textura, relieve con luz y sombras difuminadas, y se guardan como imagen en `art/realista/` (por ejemplo, `art/equipos/contactor.svg` pasa a `art/realista/equipos/contactor.webp`).

- **En el juego:** `VistaSvg` muestra la imagen realista si existe; si no, el SVG. La imagen tiene el mismo encuadre que el SVG, el doble de grande, así que las etiquetas, los bornes, las marcas numeradas y el indicador siguen en su sitio. Los SVG se quedan como fuente y respaldo.
- **Importación:** compresión con pérdida (calidad 0,9) y mipmaps, en el `.import` de cada imagen. Unos 90 KB por dibujo dentro del juego.
- **Herramienta** (`tools/dibujos_realistas/`, necesita Chrome y Godot):
  - `python tools/dibujos_realistas/realzar.py todas` rehace los dibujos de todas las fichas (74); `taller`, los de la mesa; `faltan`, solo los que no tienen imagen; `electricidad`, la tanda del módulo 7;
  - `python tools/dibujos_realistas/realzar.py art/equipos/<nombre>.svg` rehace uno;
  - el acabado automático da relieve a cada pieza del SVG, una textura fina y la sombra;
  - todos los dibujos tienen guion propio en `a_mano/` (`<nombre>.py` para `art/equipos` y `taller_<nombre>.py` para `art/taller`, porque hay nombres repetidos), con `ANCHO`, `ALTO` y `CUERPO`. El motor trifásico y el contactor están redibujados enteros; los demás parten de su SVG con `realzar.automatico(svg, encima, defs)` y suman una capa de detalles (piezas comunes en `a_mano/_piezas.py`). Algunos guiones comparten piezas: las cápsulas TO-220 están en `mosfet.py` y las DIP en `operacional.py`;
  - `--png` solo hace el PNG de revisión en `build/dibujos_realistas/`, sin tocar `art/realista`: sirve para probar varios a la vez;
  - en la capa de detalles, un trazo recto (`M… H…` o `M… V…`) con un degradado o un filtro de caja propia no se dibuja, porque su caja tiene alto o ancho cero: use un `<rect>`. Muchos `<path>` sueltos dentro de un mismo grupo con filtro pueden dejar zonas sin pintar: agrúpelos en pocos `<path>`;
  - después de crear imágenes nuevas, importe el proyecto y ponga en su `.import` `compress/mode=1`, `compress/lossy_quality=0.9` y `mipmaps/generate=true`.
- **Si cambia un SVG**, vuelva a ejecutar la herramienta para ese dibujo: si no, el juego seguirá mostrando la imagen anterior.
- **Alcance:** todas las fichas y el atlas (74 dibujos) y las piezas de la mesa del Taller y del interior de los tableros (18 más; la mesa los toma en `VistaMesa._textura`).
- **Frente de los tableros:** `python tools/dibujos_realistas/tableros.py [id]` prepara `art/realista/tableros/<id>.webp`, con el encuadre de `frente.tamano` a 1,25 veces: la chapa (inoxidable cepillado o pintada), los bordes doblados, los tornillos, los rótulos grabados, los recuadros y la sombra bajo cada luz, pulsador, selector y seta. `VistaTablero` (con `id_tablero`) lo dibuja debajo y pinta encima, en vivo, las luces (con `PiezasAri.lampara`), los pulsadores, los selectores, las setas, los seccionadores y los indicadores. Si cambia el frente de un tablero en su JSON, vuelva a ejecutar la herramienta para ese tablero.
- **Mímico:** sigue como esquema del simulador, sin cambios.
- **Pruebas** en `tests/test_dibujos_realistas.gd`: cada imagen tiene su SVG y su mismo encuadre, todas las fichas tienen su dibujo realista, cada tablero tiene su fondo y la mesa usa las piezas realistas.

## Referencias

- **Datos del barco:** los campos de `registro` en `data/barco_via_simoun.json` provienen del [registro público de WCPFC](https://vessels.wcpfc.int/vessel/9770), actualizado en 2016, y van marcados para verificar.
- **Silueta del plano:** se dibujó tomando como referencia una [foto de un atunero francés de la misma época](https://commons.wikimedia.org/wiki/File:French_tuna_purse_seiner.jpg). No es el plano real ni incluye esa foto.
- **Fuente:** IBM Plex Sans, © 2017 IBM Corp., con licencia [SIL Open Font License 1.1](art/fuentes/OFL.txt).

## Motor de simulación

Cada borne es un nodo `ID.BORNE`, cada cable une dos nodos y `PE` es la tierra. `SimSimulacion.paso()` resuelve la red con análisis nodal de fasores (el mismo solver sirve para AC y para el óhmetro en DC), deja cerrar las bobinas hasta que nada cambie y avanza el tiempo 50 ms.

Los circuitos son JSON con `componentes` y `cables`, igual que lo que se guarda desde `a_dict()`:

```json
{
  "componentes": [
    { "id": "B", "tipo": "fuente_trifasica", "params": { "v_linea": 380 } },
    { "id": "R1", "tipo": "resistencia", "params": { "ohm": 100 } }
  ],
  "cables": [["B.L1", "R1.A"], ["B.L2", "R1.B"]]
}
```

El motor es un modelo simplificado para enseñar, no para dimensionar. Sus parámetros salen de la placa de datos y de valores típicos, que hay que verificar a bordo.

Para añadir un componente, crea una clase que herede de `SimComponente` en `sim/components/`, regístrala en `SimSimulacion.tipos()` y añade sus pruebas.

**Generación (v2):**

- **Generador** (`generador`): fuerza electromotriz con su propia frecuencia y ángulo detrás de una reactancia. Lleva gobernador con estatismo o isócrono, y AVR con estatismo de reactiva. Puede quedar bloqueado, parado por una alarma o con la consigna de velocidad a la deriva (`deriva_hz_s`).
- **Interruptor de generador** (`interruptor_generador`): comprueba el sincronismo al cerrar. Tiene protecciones de sobrecarga, cortocircuito, potencia inversa, mínima tensión y disparo preferente.
- **Otros componentes:**
  - `barras`.
  - `carga_trifasica`, esencial o no, con una falla a tierra opcional.
  - `sincronoscopio`.
  - `monitor_aislamiento`.
- **Instrumentos:** el secuencímetro `SimSecuencimetro` y la pinza amperimétrica `SimPinza`. La pinza mide la corriente de los cables que abraza resolviendo la red con esos cables sustituidos por una impedancia mínima (`SimSimulacion.resolver` con `excluir`), y suma sus corrientes: con las tres fases de un circuito marca casi cero.

El `pms` (gestión de potencia) en automático reparte la carga y mantiene 50 Hz, arranca y sincroniza un grupo de reserva con carga alta, y recupera las barras tras un blackout. Con `"sincronizador": false` arranca la reserva pero no la cierra.

El circuito `cuadro_principal` incluye el cuadro de emergencia: barras `BE`, enlace `QT` desde el principal, generador de emergencia `GE` de 75 kW con su interruptor `QE`, enclavados entre sí, y la salida `CE`. El selector AUTO de GE gobierna a la vez su arranque y el cierre automático de QE. En el circuito empieza en manual, con QT abierto, como al terminar una puesta en marcha.

`game/operador_cuadro.gd` reúne los mandos del cuadro sin interfaz. La práctica libre lo usa directamente, y las misiones del cuadro ofrecen los mismos mandos.

La pantalla `ui/screens/cuadro.gd` es la práctica libre del cuadro principal, en el modo Taller del sistema 1. Sus textos, grupos, salidas y explicaciones de cada evento están en `data/cuadro.json`.

Cada generador avanza a lo sumo 50 ms por paso: `SimSimulacion.paso()` divide los pasos más largos. El reparto de carga y la potencia inversa salen de la red; no hay reglas escritas aparte. La plantilla `data/circuitos/cuadro_principal.json` tiene los cuatro grupos del buque: alternadores Stamford HCI534F de 565 kVA y 452 kW. Las cargas y los ajustes de protección son típicos, a verificar.

**Red del buque:** `sim/red_buque.gd` (`SimRed`) fija la tensión, 380 V, y la frecuencia, 50 Hz, de las placas del buque. Todos los componentes la toman por defecto, y una prueba comprueba que coincide con `data/barco_via_simoun.json`.

**Refrigeración (v3):**

- **Amoníaco** (`SimNH3`, en `sim/frio/nh3.gd`): presión de saturación según la temperatura y al revés, interpolando el logaritmo de la presión en la tabla de `data/frio/nh3.json`. Da presiones absolutas y relativas, y pasa de bar a psi.
- **Planta de frío** (`planta_frio`): compresor, condensador de agua de mar y evaporador en la salmuera de las cubas, en un modelo concentrado. Con `tipo_compresor` es de pistón (etapas por solenoides de descarga y cabezas refrigeradas por agua, como todos los del buque) o de tornillo (corredera continua, que el buque no tiene). Las etapas del pistón salen de `etapa_base` y `etapa_media`: 50, 75 y 100 % en los Vilter nº 1, 2 y 5; un tercio, dos tercios y 100 % en los MYCOM 6WB nº 3 y nº 4. Con `"alimentacion": "bombeo"` el evaporador se alimenta por recirculación, como en el buque: botella de baja con su nivel, solenoide de líquido mandada por interruptores de nivel y bomba de amoníaco que para por baja presión si la botella se vacía. Las temperaturas de evaporación y de condensación salen de balances de calor, y las presiones son las de saturación a esas temperaturas. El compresor es un motor del circuito, y la planta le pone la carga según la potencia que pide. En automático, las etapas (o la corredera) siguen a la consigna de la salmuera y limitan la potencia del motor al 95 %.
- **Averías de la planta:** hielo en los tubos con la salmuera floja, falta de refrigerante, filtro de aceite obstruido, condensador sucio, bombas paradas, solenoide de nivel pegada (`averia_solenoide_nivel`), cabezas sin agua, fugas (con la concentración de NH3 en la sala) y apertura de la válvula de seguridad.
- **Tiempo:** la salmuera se enfría mucho más deprisa que a bordo, para verlo en minutos.
- **Presostato** (`presostato`): contacto 1-2 que se abre fuera de su corte. Puede ser de alta o de baja, con rearme manual o automático y con retardo. Puede vigilar solo con el compresor en marcha, como el de aceite; ese se rearma con el compresor parado, y su retardo cuenta desde el arranque.
- **Pantalla** `ui/screens/planta.gd`, en el Taller del sistema 4: esquema del ciclo (`EsquemaFrio`) con el termómetro sobre las tuberías, manómetros, mando eléctrico del compresor con sus presostatos, corredera de capacidad, bombas, diagrama presión–entalpía (`DiagramaPH`, con entalpías esquemáticas) y seguridad de la sala. Sus mandos están en `game/operador_planta.gd`, y sus textos y las explicaciones de cada evento, en `data/planta.json`. El tiempo se puede acelerar ×10.
- **Interruptor de nivel** (`interruptor_nivel`): un presostato que lee el nivel de la botella. Va en serie con los presostatos y para el compresor con la botella demasiado llena.
- **Circuitos** `planta_frio` (MYCOM 6WB nº 3, de pistón, con el motor WEG W22 de 90 kW en estrella) y `planta_frio_vilter` (Vilter nº 5, de pistón, con el motor WEG de 75 kW de su placa): arranque directo del compresor con los presostatos de alta, baja y aceite y el interruptor de nivel alto en serie con la bobina del contactor. La pantalla deja elegir el compresor (`compresores` de `data/planta.json`), y cada misión puede fijar el suyo con `"circuito"`. Sus valores coinciden con el apartado `refrigeracion` de `data/barco_via_simoun.json`, y una prueba lo comprueba: al corregir uno, corrija el otro.
- **Animaciones de las lecciones:** `banco_planta` usa la misma simulación de la planta con el tiempo ×5. El escenario `ciclo` arranca y para el compresor, y `presostatos` deja parar las bombas para ver qué presostato dispara y cómo se rearma. `saturacion_nh3` dibuja la curva de saturación con un deslizador de temperatura.
- **Símbolos:** los del sistema 4 llevan `"sistema": 4` en `data/simbolos.json`. IEC 60617 no cubre bien los equipos frigoríficos, así que siguen ISO 14617 e ISA 5.1, marcados para verificar.

**Electrónica en continua (v4, en desarrollo):**

- **Dos resoluciones:** la alterna y la continua se resuelven por separado y se suman. `SimEstampa` tiene tres modos: alterna; `dc` sin `continua`, lo que ve un óhmetro; y `dc` con `continua`, el punto de trabajo en continua, donde inyectan las `fuente_continua`. `Solucion.dc` guarda la continua, y `vdc()` y `entre_dc()` la leen con signo. Solo la calculan las redes con algún componente cuyo `usa_continua()` es true: los circuitos de alterna no cambian.
- **Componentes no lineales:** diodos, LEDs, sensores y transmisores eligen su tramo en `asentar`, como las bobinas: la simulación vuelve a resolver hasta que ninguno cambia. Con la corriente de prueba del óhmetro usan `ajustar_prueba` y `terminar_prueba`, así el multímetro mide la caída de un diodo.
- **Componentes:** `fuente_dc` (24 V, con entrada de alterna o `"entrada": "ninguna"`, limitación de corriente y `tension_pu` para una fuente degradada), `diodo`, `led`, `puente_rectificador` (modelado por su efecto, con o sin `filtro`), `rele_dc`, `rele_estado_solido`, `sensor_proximidad` (inductivo o capacitivo; PNP, NPN o de dos hilos; NA o NC), `transmisor_4_20`, `pt100` y `termocupla`. Los transmisores y sondas pueden leer un proceso con `origen`: `{"id": "PLANTA", "lectura": "presion", "punto": "succion"}`. Las luces piloto también se encienden en continua.
- **Electrónica I (etapa 38):** `resistencia` admite `w` (potencia nominal: por encima de 1,5 veces se calienta y se corta) y `factor` en el estado (valor cambiado); `potenciometro` (bornes 1-2-3, `posicion`, `cursor_sin_contacto`, `pista_cortada`); `termistor` (`tipo` `ntc`, con `r25` y `beta`, o `ptc`, con `tnf` y `sensores`, según los límites de DIN 44081; `temperatura_c`, `abierto`, `corto`); `varistor` (su fuga, `degradado_kohm`, `corto` y `abierto`; el recorte de los picos no se modela con valores eficaces y se ve en su corte); `condensador_electrico` (bornes + y −, `uf`, `polarizado`, `perdida`, `corto`, `abierto`; un electrolítico al revés o en alterna queda en corto); `zener` (tres tramos: corte, directa y ruptura a `vz`, y se quema por encima de `p_max`). El `puente_rectificador` admite `diodo_abierto` (media onda) y `diodo_corto` (cortocircuita la alterna), y el óhmetro ve sus cuatro diodos. Pruebas en `tests/test_sim_electronica_basica.gd`.
- **Electrónica II (etapa 39):** `transistor` NPN (bornes B, C, E; corte, saturación y activa con `beta`; el óhmetro ve sus dos uniones; `quemado` y `be_abierta`), `mosfet` de canal N (G, D, S; apagado, a medias con `r_media` o pleno según `vth` y `v_plena`; diodo interno; se quema por potencia; `puerta_perforada`), `tiristor` (A, K, G; se enclava y se apaga bajo `ih`), `triac` (A1, A2, G; conduce mientras la puerta, en continua o en alterna, pasa de `igt`), `optoacoplador` (1-2 LED, 4-3 salida, aislados), `regulador` (IN, GND, OUT; `vout`, `caida_min` y protección térmica con o sin `disipador`), `operacional` (patas de un 741, como comparador) y `puerta_logica` (A, B, Y, VCC, GND; `tipo` and, or, nand, nor, xor o not; entrada al aire indefinida). Pruebas en `tests/test_sim_electronica_potencia.gd`.
- **Multímetro:** `vdc` con signo, `diodo` con la caída real, `capacidad` en µF (inyecta una alterna de prueba sin tensión: en corto sale de escala y abierto marca 0) y `ma`, miliamperios en continua en serie. La entrada de mA tiene un fusible de 0,4 A. En serie, el multímetro cierra el circuito y los componentes reajustan su estado, como un transmisor que empieza a regular.
- Las pruebas están en `tests/test_sim_electronica.gd` y, para el banco de sensores con PLC (`data/circuitos/banco_sensores.json`, programa `data/plc/espejo_entradas.json`), en `tests/test_sim_sensores.gd`. Con `sensores` detrás de la carpeta, el comando de capturas guarda el Taller del sistema 6 y el banco.
- **Taller del sistema 6:** `modos.taller.practicas` lista prácticas preparadas, cada una con `titulo`, `detalle`, `pantalla` y `args`; el Taller acepta `{"plantilla": "<id>"}` para abrir con una plantilla montada. En el cajón, un PLC llega con el programa de `programa_de`. En la mesa se ven los LEDs del sensor, de la fuente, del relé y de las entradas y salidas del PLC, y la pestaña Pieza acerca la pieza al sensor y cambia el PLC a RUN o STOP y sus entradas a PNP o NPN.

**Red Modbus y puesto de alarmas (v4, en desarrollo; se abre desde el Taller del sistema 6):**

- **Red** (`sim/comunicaciones/red_modbus.gd`, `SimRedModbus`): bus RS-485 con el maestro en un extremo y los esclavos en el orden del cable, cada uno con `direccion`, `baudios`, `formato`, `terminacion`, `invertido` y `alimentado`. El maestro recorre su tabla `sondeo` con la función 03: cada petición termina `ok`, `sin_respuesta`, `crc` o `excepcion`, y tres fallos seguidos dan falla de comunicación. Un terminador que falta o sobra y el ruido deforman tramas al azar (con `semilla`, reproducible); `resistencia_a_b()` da lo que mide el multímetro entre A y B; `aplicar()` hace averías y reparaciones (`ajuste`, `corte`, `ruido`, `valor`, `rampa`, `hmi`).
- **Puesto de alarmas** (`sim/comunicaciones/sistema_alarmas.gd`, `SimSistemaAlarmas`): puntos `alta`, `baja`, `digital` y `comunicacion` con límite, histéresis y retardo; estados normal, activa, reconocida y retorno; bocina, silenciar, reconocer, historial con hora y extensión a camarotes a los 180 s.
- **Pantalla local** (`sim/comunicaciones/pantalla_hmi.gd`, `SimPantallaHMI`): lee su controlador por su propio cable, guarda la tendencia y tiene alarmas locales con ajustes protegidos por nivel de técnico.
- **Datos** en `data/redes/<id>.json`: `maestro` con su `sondeo` (cada dirección con `esperado`, `cantidad` y `canales` con `tag`, `unidad`, `decimales` y límites `alta`, `baja` o `digital` con `retardo_s`), `esclavos` con sus `registros` (`valor`, `escala`, `ruido`), `hmi` (campos, tendencia y ajustes) y `averias` de práctica. Se cargan con `Contenido.red(id)`.
- **Pantalla** `ui/screens/red_alarmas.gd`, con las pestañas Puesto de alarmas, Red RS-485 (`VistaRed`, ajustes de cada equipo, medida entre A y B y diagnóstico del maestro), Pantalla MYCOM (páginas Principal, Alarmas, Tendencia con `GraficoTendencia` y Ajustes) y Averías (concretas o al azar). Las misiones de la red la extienden.
- **Misiones de la red** (`"tipo": "red"`, `game/mision_red.gd`, `MisionRed`, pantalla `ui/screens/mision_red.gd`): el jugador usa los paneles del Taller y la pantalla avisa a la misión de cada acción con `registrar()` (pestaña vista, equipo seleccionado, medida entre A y B, ajuste de la red o de la HMI). En el JSON: `preparar` (operaciones de `SimRedModbus.aplicar` y `ajuste_hmi`), `preparar_s`, `pasos` con `pone`, `pasos_requeridos` (marca y falta si no se dio antes de observar), `evidencias` (`hecho`, `alguno` o `accion`), `acciones` con `efecto`, `ajustes_libres` (equipos que se pueden tocar aunque comuniquen) y `prueba` con objetivos `comunica`, `todos_comunican`, `terminadores`, `valor`, `sin_sin_reconocer`, `ajuste_hmi`, `sesion_cerrada`, `marca` y `sin_marca`. Cambiar un equipo que comunicaba bien es falta (`ajuste_red_innecesario`), igual que mover un límite de alarma hacia el lado inseguro (`limite_alarma_alterado`).
- Las pruebas están en `tests/test_red_modbus.gd` y `tests/test_guardia_red.gd`. Con `red` detrás de la carpeta, el comando de capturas guarda sus pestañas, una misión y el minijuego de símbolos de electrónica.

**PLC (v4, en desarrollo; se abre desde el Taller del sistema 6):**

- **Componente** `plc` (`sim/components/plc.gd`): alimentación L+ y M, entradas I0.0 a I0.7 con su común 1M (`"entradas": "pnp"` o `"npn"`), salidas Q0.0 a Q0.5 a relé con su común 1L o a transistor (`"salidas"`), y entrada analógica AI0 de 4–20 mA escalada a `%IW0` con `analogica`. En cada paso hace un scan: lee entradas, ejecuta el programa y escribe salidas. En STOP o con menos de 19 V abre las salidas.
- **Lenguaje ladder** (`sim/plc/ladder.gd`, `SimLadder`), con direcciones IEC 61131-3 genéricas: contactos `na`, `nc`, `flanco` y `cmp`, ramas en `paralelo`, y salidas `bobina`, `set`, `reset`, `ton`, `tof`, `ctu` y `rst`. El formato está descrito al principio del archivo.
- **Programas** en `data/plc/<id>.json`: `programa` y `etiquetas` (el nombre de cada dirección; el texto antes de « · » es el del dispositivo, como «S1»). En un circuito, `"programa_de": "<id>"` en los params del PLC carga ese programa.
- **Pantalla** `ui/screens/plc.gd`: el frente del PLC con sus LEDs, los mandos de campo y el programa en vivo (`EsquemaLadder`), con la señal en verde. El editor (`game/editor_ladder.gd`, `EditorLadder`) cambia un borrador; se transfiere con el PLC en STOP, como en un autómata real.
- Las pruebas están en `tests/test_plc.gd`. Con `plc` detrás de la carpeta, el comando de capturas guarda la pantalla del PLC.

**Números y unidades:** `TextoTecnico.unir_unidades()` pone un espacio que no se parte entre un número y su unidad (`16 bar`, `−21 °C`, `100 %`), para que no queden en líneas distintas. Se aplica a los textos de lecciones y fichas y a las preguntas. Una unidad nueva se añade a su expresión regular.

### Tableros del buque

- **Componentes de mando:** `selector` (posiciones con nombre, como MAN-OFF-AUT; contactos 13-14 y 23-24 que cierran en las posiciones de `contactos`; `retorno` para una posición con resorte, como START; `inicial`), `seta` (parada de emergencia que se enclava: abre 11-12 y cierra 13-14 hasta girarla), `seccionador` (interruptor general de tres polos con contacto 13-14; con `candado` no se puede cerrar) y `horometro` (A1-A2; cuenta las horas con tensión y, si es de `hz_nominal` 60 en la red de 50 Hz, atrasa una sexta parte). Las luces guardan en `relacion` su tensión respecto a la nominal, para dibujar su brillo.
- **Lámparas de tierra:** tres lámparas de 380 V en estrella, de cada fase a un punto común que el pulsador TEST une al casco. Alumbran igual a la tensión de fase; con una fase a masa y TEST pulsado, la de esa fase se apaga y las otras ven casi la tensión de línea.
- **Pantalla** `ui/screens/tablero.gd`: el frente (`VistaTablero`), dibujado con el aspecto del tablero real, con zoom y arrastre; al abrir la puerta, el mismo circuito en la mesa del Taller (`PantallaBanco`), con los instrumentos. Las pestañas Mando (alimentación con candado, protecciones disparadas, señales de otros equipos y averías de práctica), Medir, Equipo (estado y ajustes) y Datos.
- Las pruebas están en `tests/test_sim_tableros.gd` y `tests/test_tableros.gd`. Con `tablero` detrás de la carpeta, el comando de capturas guarda la lista, el frente y el interior.
- **Más componentes de tablero:** `hidroforo` (tanque con presostato 13-14 que arranca a 2,5 bar y para a 4 bar; las bombas de `bombas` suben la presión con el cuadrado de su velocidad), `timon` (válvulas de gobierno BR X1-X2 y ER X3-X4; mueven la pala unos 2,6 °/s mientras gira la bomba) y `carga_trifasica` como consumidores con `falla_mohm` a masa. El `seccionador` admite `polo_danado`, un polo quemado que no conduce, y el `selector` hasta tres contactos (13-14, 23-24 y 33-34).
- **Arrancador suave** (`arrancador_suave`, `sim/components/arrancador_suave.gd`): potencia 1-3-5 a 2-4-6, orden de marcha en A1-A2 a `v_mando`, salidas 13-14 (en marcha), 23-24 (bypass) y 95-96/98 (fallo). Los tiristores se modelan como una resistencia por fase que se recalcula en `asentar` para dar al motor la fracción `u` de la tensión, que sube de `u_inicial` a 1 en `rampa_s`, sin pasar de `limite_corriente` × `ie_a`. Al final de la rampa, con la corriente por debajo de 1,3 × Ie, cierra el bypass. Fallos: falta de fase y `t_max_arranque_s`; `rearmar()` los borra. Lo usan el compresor nº 3 de la planta (`planta_frio`), la plantilla `arranque_suave` y el tablero `compresores_nh3`. Pruebas en `tests/test_sim_arrancador.gd`.
- **Contactor:** el parámetro `espiras_en_corto` deja la bobina en unos pocos ohmios: no cierra y funde el fusible de mando.
- **Potencia y medida (etapa 36)**, con pruebas en `tests/test_sim_potencia.gd`:
  - `transformador_intensidad`: primario P1-P2 casi sin impedancia; el secundario S1-S2 es una fuente de corriente (relación `i_secundaria`/`i_primaria`) con la reactancia magnetizante `x_magnetizante` en paralelo. Abierto en servicio da cientos de voltios. Estado `puente` (cortocircuita S1-S2) y `secundario_cortado`.
  - `amperimetro` (bornes 1-2, `escala_a`, entrada de 5 A) y `voltimetro` (bornes 1-2, `escala_v`): `leer()` da la aguja; averías `bobina_cortada` y `aguja_pegada`.
  - `analizador_red`: entra por L1-L3 y sale por T1-T3; calcula P, Q, S y FP por el método de dos vatímetros, válido en la red aislada.
  - `condensadores`: batería en delta de `q_kvar` con sus resistencias de descarga; en continua solo quedan estas. Averías `perdida` (fracción de capacidad), `rama_abierta` y `descarga_cortada`.
  - `resistencia_caldeo` (bornes 1-2, `w`, `v`, aislamiento contra el casco) y `bornera` (bornes `nA`-`nB`; `flojos` con `r_flojo_ohm` y `sueltos`).
  - `variador`: rectifica L1-L3 a un bus DC+/DC- de 1,35 × la red y da en U-V-W la frecuencia `f`, que sigue en rampa a `consigna_hz` con V/f constante. Manda su frecuencia al motor `motor`, que cambia reactancias y velocidad síncrona en proporción (`f_alim`). Fallos F001 sobrecorriente, F003 subtensión del bus, F004 sobrecarga I²t y F005 temperatura (`ventilador_parado`); `marchar()`, `parar()` y `rearmar()`.
  - El `transformador_mando` admite `primario_cortado`, `secundario_cortado` y `aislamiento_mohm`; con el primario cortado, en un banco en delta las otras dos columnas siguen dando tensión.
- **Elemento `amperimetro`** del frente: instrumento de cuadro de 240° con `fondo` de escala, línea roja desde `nominal` y `lado` en unidades del panel; lee el arrancador suave o el relé térmico de `componente`.
- **Elementos del frente añadidos:** `recuadro` (placa de fondo), `rotulo` con `fondo` y `tinta` (como la etiqueta roja de 380VAC), `luz` con `texto` grabado en la lente, `seccionador` con `estilo` `negro` y `pantalla_vlt`, el teclado y la pantalla del variador Danfoss, que lee el contactor que hace de variador, su motor y su horómetro. Los tableros pueden mostrar `lecturas` del proceso en la pestaña Mando, como la presión del hidróforo o el ángulo del timón.
