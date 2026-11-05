# Oficial Electrotécnico: B/P Vía Simoun

Juego educativo de simulación para Android y Windows que enseña, desde cero, lo que debe saber un oficial electrotécnico (ETO) a bordo de un atunero cerquero. Funciona 100 % sin conexión.

Estado: **etapa 3**, 6 lecciones de fundamentos y seguridad con animaciones y preguntas, glosario, plano del barco, guardado de partida y ficha de muestra del contactor. Los requisitos completos están en [CLAUDE.md](CLAUDE.md).

> Es material de formación. No sustituye los procedimientos ni los manuales del barco. Los datos marcados `"verificar": true` son valores típicos que hay que comprobar a bordo.

## Abrir el proyecto

1. Instala [Godot 4.7.2](https://godotengine.org/) (versión estándar, no .NET).
2. En el gestor de proyectos, elige **Importar** y selecciona `project.godot`.
3. Pulsa **F5** para ejecutar.

## Pruebas

```bash
godot --headless --path . --import
```

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

El ejecutor carga cada `tests/test_*.gd`. Cada método `test_*` devuelve `""` si pasa, o el motivo del fallo. Cualquier error de script durante una prueba también la hace fallar, porque una función `-> String` que revienta devuelve `""` y parecería aprobada.

Si añades una clase con `class_name`, repite primero el `--import`.

El ejecutor aborta con error si tarda más de 300 s, incluso si una prueba entra en un bucle infinito. El límite se cambia con la variable `LIMITE_PRUEBAS_S`. En Windows, `tools\correr_pruebas.ps1` añade un segundo límite desde fuera y guarda la salida en `build\pruebas\`:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File tools\correr_pruebas.ps1
```

Para revisar el aspecto de las pantallas sin tener que navegar por ellas, este comando guarda imágenes de cada una en varios tamaños:

```bash
godot --path . --script res://tests/capturar.gd -- carpeta/de/salida
```

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
| `data/` | Contenido editable en JSON: datos del barco, sistemas, rangos, glosario, `fichas/` y `circuitos/` |
| `art/` | Dibujos SVG de `barco/`, `equipos/` y `simbolos/` |
| `sim/` | Motor de simulación: `solver.gd`, `simulacion.gd`, `components/` e `instruments/` |
| `game/` | Carga de contenido, partida guardada y términos técnicos |
| `ui/` | `raiz.gd` (navegación y escala), `pantalla.gd` (base), `screens/` y `widgets/` |
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

Las animaciones están en `ui/animaciones/`: `circuito_ohm`, `onda_alterna`, `fasores`, `estrella` y `escala_corriente`. Para crear otra, añade `<id>.gd` heredando de `Animacion`.

**Fichas:** cada `data/fichas/<id>.json` tiene el dibujo, los símbolos IEC y ANSI, el banco de prueba y las secciones `funcion`, `partes`, `conexion`, `ajuste`, `pruebas`, `fallas` y `mantenimiento`, además de `para_saber_mas`. Para publicar una, añade su id a `modos.aprender.fichas` del sistema. Las pruebas comprueban que esté completa y que sus referencias existan.

**Términos:** en los textos se escriben `{{id}}`, con el id definido en `data/glosario.json`. La primera vez que aparece en cada ficha se muestra también en inglés.

**Datos sin confirmar:** todo valor típico debe indicar en el texto `valor típico — verificar a bordo`.

**Dibujos:** Godot no dibuja el texto de los SVG, así que las letras van en `etiquetas` del JSON, en coordenadas del dibujo. Cada SVG necesita al lado un archivo `<nombre>.svg.import` con este contenido, para que se exporte tal cual y se pueda dibujar a la resolución de cada pantalla:

```text
[remap]

importer="keep"
```

**Partida:** se guarda en `user://partida.json`, con una copia de la anterior en `.bak`. Si el archivo está dañado se recupera la copia y se avisa al jugador. La pantalla para exportar e importar llega en la etapa 7; la lógica ya está en `game/partida.gd`.

## Motor de simulación

Cada borne es un nodo `ID.BORNE`, cada cable une dos nodos y `PE` es la tierra. `SimSimulacion.paso()` resuelve la red con análisis nodal de fasores (el mismo solver sirve para AC y para el óhmetro en DC), deja cerrar las bobinas hasta que nada cambie y avanza el tiempo 50 ms.

Los circuitos son JSON con `componentes` y `cables`, igual que lo que se guarda desde `a_dict()`:

```json
{
  "componentes": [
    { "id": "B", "tipo": "fuente_trifasica", "params": { "v_linea": 440 } },
    { "id": "R1", "tipo": "resistencia", "params": { "ohm": 100 } }
  ],
  "cables": [["B.L1", "R1.A"], ["B.L2", "R1.B"]]
}
```

El motor es un modelo simplificado para enseñar, no para dimensionar. Sus parámetros salen de la placa de datos y de valores típicos, que hay que verificar a bordo.

Para añadir un componente, crea una clase que herede de `SimComponente` en `sim/components/`, regístrala en `SimSimulacion._tipos()` y añade sus pruebas.
