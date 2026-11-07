# Oficial Electrotécnico: B/P Vía Simoun

Juego educativo de simulación para Android y Windows que enseña, desde cero, lo que debe saber un oficial electrotécnico (ETO) a bordo de un atunero cerquero. Funciona 100 % sin conexión.

Estado: **v3.3**, con la v1, la v2 y la v3 completas y adaptadas a los equipos reales del buque. Incluye:

- 20 lecciones de fundamentos, seguridad (también con amoníaco), motores, arrancadores, tableros de bombas e instrumentos.
- 8 lecciones de generación: alternador, AVR, gobernador, cuadro principal, sincronización, reparto de carga, blackout y red aislada.
- 8 lecciones de refrigeración: ciclo de compresión, presión y temperatura del NH3, diagrama presión–entalpía, compresores, componentes, control y protecciones, cableado del compresor y diagnóstico.
- Fichas de los equipos de los sistemas 1, 3 y 4, entre ellas la del generador de emergencia y la del detector de amoníaco, con simbología IEC y ANSI, y un minijuego de símbolos por sistema.
- Cuadro principal con los cuatro generadores del buque (380 V, 50 Hz), paneles al estilo de sus módulos de sincronismo, PMS, protecciones, lámparas de tierra R-S-T y cuadro de emergencia con su generador.
- Taller con multímetro, megóhmetro y pinza amperimétrica, y seis tableros reales del buque que se manejan desde su frente, con su interior en la mesa del Taller: bombas de la máquina principal, hidróforo de agua salada, purificadora nº 1, controlador del servotimón nº 1 con su variador Danfoss, y tableros de 110 V de habitabilidad y de 220 V de distribución. Tienen una marca amarilla en su lugar del plano del barco.
- 5 misiones de Guardia de motores y tableros (dos de ellas frente al tablero: lámpara de tierra apagada e hidróforo sin una fase) y 4 del cuadro principal: puesta en paralelo, blackout, falla a tierra y potencia inversa.
- 5 misiones de Guardia de la planta de frío: alta presión de descarga, hielo en el evaporador, presión de aceite en el Vilter nº 5, fuga de amoníaco con evacuación y nivel alto en la botella de baja.
- Exámenes de la v1, la v2 y la v3, rangos, repaso de errores y traspaso de partida.
- Planta de frío por amoníaco en el Taller del sistema 4: esquema del ciclo, manómetros en bar y psi, termómetro, presostatos, bombas, diagrama presión–entalpía y detector de amoníaco.
- Glosario y plano del barco.

Los requisitos completos están en [CLAUDE.md](CLAUDE.md). La v2, de generadores, paneles y cuadro principal, y la v3, de refrigeración por amoníaco, están completas. La siguiente es la v4: electrónica, sensores, PLC, HMI y SCADA.

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

Con `lecciones`, `fichas`, `taller`, `guardia`, `progresion`, `cuadro`, `guardia_cuadro`, `planta` o `guardia_planta` detrás de la carpeta captura solo esa parte. En `lecciones` y `fichas`, un número más elige el sistema; por ejemplo, `-- carpeta fichas 1`.

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
| `data/` | Contenido editable en JSON: datos del barco, sistemas, rangos, glosario, `fichas/`, `circuitos/`, `lecciones/`, `misiones/` y `examenes/` |
| `art/` | Dibujos SVG de `barco/`, `equipos/`, `esquemas/`, `iconos/`, `seguridad/`, `simbolos/` y `taller/`, y la fuente en `fuentes/` |
| `sim/` | Motor de simulación: `solver.gd`, `simulacion.gd`, `components/` e `instruments/` |
| `game/` | Carga de contenido, partida guardada, términos técnicos, mesa del Taller, misiones, examen y banco de repaso |
| `ui/` | `raiz.gd` (navegación y escala), `pantalla.gd` (base), `pantalla_banco.gd` (base del Taller y de las misiones), `pantalla_preguntas.gd` (base del examen y del repaso), `screens/` y `widgets/` |
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

Las animaciones están en `ui/animaciones/`: `circuito_ohm`, `onda_alterna`, `fasores`, `estrella`, `escala_corriente`, `conexion_motor`, `banco_arranque` y `banco_generadores`. Esta última usa la simulación del cuadro principal con `"params": { "escenario": "sincronizar" }` o `"reparto"`. Para crear otra, añade `<id>.gd` heredando de `Animacion`.

**Fichas:** cada `data/fichas/<id>.json` tiene el dibujo, los símbolos IEC y ANSI, el banco de prueba y las secciones `funcion`, `partes`, `conexion`, `ajuste`, `pruebas`, `fallas` y `mantenimiento`, además de `para_saber_mas`. Para publicar una, añade su id a `modos.aprender.fichas` del sistema. Las pruebas comprueban que esté completa y que sus referencias existan.

Una ficha puede añadir vistas con `dibujos_extra`, como la placa y la bornera del motor. Sus `simbolos` pueden ser `iec` y `ansi` propios, o una `lista` de ids de `data/simbolos.json`.

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

**Exámenes:** cada `data/examenes/<id>.json` se publica en `modos.examen.examenes` de un sistema, y aparece también en la pantalla de inicio y en Mi progreso. `sistema_simbolos` elige de qué sistema son los símbolos que pregunta. Cada examen define `minimo` (porcentaje para aprobar), `composicion` (cuántas preguntas de cada tipo: `quiz`, `caso`, `ordenar`, `simbolo`) y el banco `preguntas`. Para que el examen varíe, el banco debe tener al menos el doble de lo que se pregunta, y una prueba lo comprueba. Las de tipo `caso` añaden un texto `caso`; cada pregunta lleva un `tema` que no se repite en ninguna lección ni en otro examen. En las de tipo `ordenar`, los pasos deben tener un único orden posible.

**Repaso:** cada fallo guarda su `tema` en la partida. `game/banco_repaso.gd` busca la pregunta de ese tema en las lecciones, en el examen, en `preguntas` de `data/guardia.json` (faltas, accidentes e incidentes), en el diagnóstico y el libro de las misiones, y en los símbolos. Cada acierto aleja el tema 1, 3, 7, 14 y 30 días; un fallo lo reinicia. **Cada falta o accidente nuevo necesita su pregunta**, y una prueba lo comprueba.

**Rangos:** `data/rangos.json`. Las pruebas exigen que el rango más alto se pueda alcanzar con el contenido publicado, y que no baste sin misiones o sin examen. Al añadir contenido, suba los valores.

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
- **Multímetro:** `vdc` con signo, `diodo` con la caída real, y `ma`, miliamperios en continua en serie. La entrada de mA tiene un fusible de 0,4 A. En serie, el multímetro cierra el circuito y los componentes reajustan su estado, como un transmisor que empieza a regular.
- Las pruebas están en `tests/test_sim_electronica.gd`.

**PLC (v4, en desarrollo):**

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
- **Elementos del frente añadidos:** `recuadro` (placa de fondo), `rotulo` con `fondo` y `tinta` (como la etiqueta roja de 380VAC), `luz` con `texto` grabado en la lente, `seccionador` con `estilo` `negro` y `pantalla_vlt`, el teclado y la pantalla del variador Danfoss, que lee el contactor que hace de variador, su motor y su horómetro. Los tableros pueden mostrar `lecturas` del proceso en la pestaña Mando, como la presión del hidróforo o el ángulo del timón.
