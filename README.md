# Oficial Electrotécnico: B/P Vía Simoun

Juego educativo de simulación para Android y Windows que enseña, desde cero, lo que debe saber un oficial electrotécnico (ETO) a bordo de un atunero cerquero. Funciona 100 % sin conexión.

Estado: **etapa 1**, motor de simulación con pruebas, todavía sin pantallas de juego. Los requisitos completos están en [CLAUDE.md](CLAUDE.md).

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
| `data/` | Contenido editable en JSON. `barco_via_simoun.json` guarda los datos del barco y `circuitos/` las plantillas de circuitos |
| `sim/` | Motor de simulación: `solver.gd`, `simulacion.gd`, `components/` e `instruments/` |
| `ui/` | Pantallas |
| `tests/` | Pruebas sin pantalla |
| `game/`, `art/` | Lógica de juego y dibujos (se añaden en etapas siguientes) |

Para corregir un dato del barco, edita `data/barco_via_simoun.json` y vuelve a exportar. No hace falta tocar código. El formato de las lecciones y cómo añadir nuevas se documentará aquí en la etapa 3.

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
