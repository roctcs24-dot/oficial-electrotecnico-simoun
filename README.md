# Oficial Electrotécnico: B/P Vía Simoun

Juego educativo de simulación para Android y Windows que enseña, desde cero, lo que debe saber un oficial electrotécnico (ETO) a bordo de un atunero cerquero. Funciona 100 % sin conexión.

Estado: **etapa 0**, proyecto base. Los requisitos completos están en [CLAUDE.md](CLAUDE.md).

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

El ejecutor carga cada `tests/test_*.gd`. Cada método `test_*` devuelve `""` si pasa, o el motivo del fallo.

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
| `data/` | Contenido editable en JSON. `barco_via_simoun.json` guarda los datos del barco |
| `ui/` | Pantallas |
| `tests/` | Pruebas sin pantalla |
| `sim/`, `game/`, `art/` | Motor de simulación, lógica de juego y dibujos (se añaden en etapas siguientes) |

Para corregir un dato del barco, edita `data/barco_via_simoun.json` y vuelve a exportar. No hace falta tocar código. El formato de las lecciones y cómo añadir nuevas se documentará aquí en la etapa 3.
