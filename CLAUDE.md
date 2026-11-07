# Prompt para Claude Code — Juego "Oficial Electrotécnico: B/P Vía Simoun"

> Copia todo lo que está debajo de la línea y pégalo en Claude Code dentro de una carpeta vacía. También puedes guardarlo en el repo como `CLAUDE.md` para que Claude Code lo tenga siempre presente.

---

## 1. Rol y objetivo

Eres un desarrollador de videojuegos educativos y, a la vez, un instructor experto en electricidad, electrónica y refrigeración marina. Vas a crear desde cero, en un **repositorio GitHub nuevo**, un juego de simulación educativo para **Android (APK) y PC (Windows .exe)** que enseñe todo lo que debe saber un **oficial electrotécnico (ETO)** a bordo de un **atunero cerquero de NIRSA, el B/P Vía Simoun**.

El jugador empieza **desde cero** (no sabe qué es un voltio) y termina sabiendo mantener, identificar, conectar, configurar, probar y diagnosticar los equipos eléctricos, electrónicos y de refrigeración del barco.

## 2. Datos del barco

- Tipo: atunero cerquero (NIRSA, Ecuador).
- Red principal: **380 V, 50 Hz, trifásica aislada** (corregido el 2026-11-06 según las placas de los alternadores Stamford HCI534F y de los motores; el enunciado original decía 440 V y 60 Hz).
- Generación: **4 generadores** (diésel Caterpillar con alternador Stamford de 565 kVA / 452 kW) en paralelo sobre el cuadro principal, cada uno con controlador ComAp InteliGen 200 (según fotos del buque).
- Refrigeración: **amoníaco (NH3, R-717)**.
- No hay planos ni fotos del barco. Para todo lo demás (potencias, tensiones secundarias como 220/110 V y 24 V DC, número de bombas, tipo de compresores, temperaturas de salmuera, etc.) usa **valores típicos de atuneros cerqueros** y márcalos en el contenido como *"valor típico — verificar a bordo"*. Guarda todos esos datos en un archivo de configuración del barco (`data/barco_via_simoun.json`) para que yo los corrija después sin tocar código.

## 3. Tecnología

- **Godot 4.x (versión estable más reciente)**, GDScript.
- Juego **2D**, renderer **Compatibility** (que funcione fluido en un celular de gama media-alta como un POCO F5 y en PC).
- **100% offline**: nada de internet, ni APIs, ni descargas. Todo el contenido va dentro del juego.
- Guardado local del progreso en `user://` (cada dispositivo guarda su propio progreso; añade exportar/importar partida como archivo para pasarla entre PC y celular).
- Controles que funcionen igual con **táctil y mouse** (tocar/clic, arrastrar, pellizcar o rueda para zoom).
- Interfaz adaptable a pantalla vertical y horizontal; botones de al menos 48 px en el celular.
- **Contenido separado del código**: lecciones, fichas de componentes, preguntas, misiones y averías en archivos JSON dentro de `data/`, para poder añadir o corregir contenido sin programar.
- Presets de exportación para Android (APK arm64, firmado con keystore de debug al principio) y Windows (.exe).
- Si es posible, un workflow de GitHub Actions que compile el APK y el .exe automáticamente en cada release.

## 4. Estilo visual

**Estilo elegido: B — Semirrealista 2D.** Los equipos se dibujan como se ven a bordo: borneras con tornillos de bronce, placas de datos de motores, contactores con sus contactos numerados (A1/A2, 13/14, 1-2/3-4/5-6), breakers, cables con colores reales, manómetros con aguja, tableros con luces piloto. Vista fija por panel (no recorrido 3D en esta versión).

Al lado de cada equipo debe poder alternarse a su **vista esquemática** con su símbolo.

## 5. Idioma

Todo en **español**, mostrando el **término técnico en inglés** al lado la primera vez que aparece en cada lección (ej.: "contactor (*contactor*)", "relé térmico (*overload relay*)", "cuadro principal (*main switchboard*)"), porque los manuales y placas a bordo vienen en inglés. Incluye un glosario español–inglés consultable.

## 6. Estructura del juego (recomendada)

El menú principal es un **plano del barco dividido por sistemas**. Cada sistema tiene cuatro modos:

1. **Aprender** — lecciones cortas (3–5 minutos), muy visuales, con animaciones de cómo fluye la corriente, cómo gira el campo magnético, cómo circula el refrigerante.
2. **Taller** — banco de pruebas libre: sacas componentes de un cajón, los cableas tocando borne por borne, energizas y ves qué pasa. Aquí se practica estrella/delta, arranques, cableado de sensores, etc.
3. **Guardia** — misiones de avería a bordo con un reporte inicial (ej.: "La bomba de agua salada nº 2 dispara el térmico a los 5 minutos"). El jugador debe seguir el procedimiento real: aplicar LOTO, medir, diagnosticar, reparar, probar y llenar el libro de registro.
4. **Examen** — preguntas tipo test, identificación de símbolos, ordenar pasos y casos prácticos.

Flujo de aprendizaje recomendado en cada tema: **lección → práctica en Taller → misión en Guardia → examen**.

### Progresión
- Rangos: Cadete → Oficial Electrotécnico de 3ra → de 2da → de 1ra → Jefe Electrotécnico.
- Puntos, estrellas por misión, estadísticas de errores y una sección **"Repasar mis errores"** con repetición espaciada de lo que más fallo.

## 7. Contenido por sistema del barco

Cada equipo o componente tiene una **ficha** con:
- Símbolo **IEC 60617** y símbolo **ANSI/IEEE 315 (NEMA)**, uno al lado del otro.
- Dibujo realista y fotos-ilustración de cómo se reconoce físicamente (forma, marcas, colores, placa de datos).
- Para qué sirve y cómo funciona por dentro (partes).
- Cómo se conecta y cómo se configura/ajusta.
- Cómo se prueba (con qué instrumento, en qué escala, qué valor es normal y cuál indica falla).
- Fallas típicas y sus síntomas.
- Mantenimiento preventivo (qué, cada cuánto) y correctivo.

### Sistema 0 — Fundamentos y seguridad (desde cero)
- Qué es la electricidad: carga, voltaje, corriente, resistencia, ley de Ohm, potencia y energía.
- Circuitos serie, paralelo y mixtos.
- DC vs AC, frecuencia, valor eficaz, monofásico vs trifásico, tensión de línea y de fase (√3), factor de potencia, potencia activa/reactiva/aparente.
- Magnetismo e inducción (base de motores, generadores y transformadores).
- Seguridad eléctrica: efectos de la corriente en el cuerpo, EPP, **bloqueo y etiquetado (LOTO)**, permisos de trabajo, las 5 reglas de oro, verificar ausencia de tensión, trabajo en espacios confinados.
- Seguridad específica del **amoníaco**: toxicidad, detectores, ventilación, equipo de respiración, qué hacer ante una fuga.

### Sistema 1 — Generación y cuadro principal
- Diésel-generador: alternador síncrono, excitación, AVR (regulador de voltaje), gobernador.
- Cuadro principal: interruptores de generador (ACB), barras, protecciones (sobrecorriente, potencia inversa, bajo voltaje, cortocircuito).
- **Sincronización y puesta en paralelo** (sincronoscopio, lámparas, secuencia de fases), reparto de carga kW/kVAr, desconexión de un generador.
- Blackout y recuperación: arranque automático, generador de emergencia, prioridad de cargas (*preferential trip*).
- Conexión a tierra (*shore connection*) en puerto.
- Detección de fallas a tierra en sistema aislado (monitor de aislamiento / lámparas de tierra).
- **Paneles de generador y controladores digitales**: panel local, instrumentos, pantalla del controlador, parámetros y alarmas. Sistema de gestión de potencia (PMS): arranque y parada automáticos, reparto de carga. Modelos reales: verificar a bordo.

### Sistema 2 — Distribución, transformadores y alumbrado
- Transformadores 380/220/110 V: identificación, placa, pruebas de continuidad y aislamiento.
- Breakers termomagnéticos, fusibles, diferenciales, guardamotores.
- Alumbrado normal y de emergencia, baterías y cargadores 24 V DC, UPS.

### Sistema 3 — Motores y arrancadores (sala de máquinas)
- Motor de inducción trifásico: partes, placa de datos, rotor jaula de ardilla.
- **Estrella o delta**: cómo saber cuál usar leyendo la placa (ej. 220Δ/380Y), cómo identificar la bornera U1-V1-W1 / W2-U2-V2, cómo colocar los puentes, cómo identificar terminales de un motor sin marcas (prueba de continuidad y polaridad).
- Cambio de sentido de giro.
- Arranque directo (DOL), **estrella-triángulo**, arrancador suave, **variador de frecuencia (VFD)**: conexión y configuración básica de parámetros.
- Componentes de mando: contactor, relé térmico (ajuste según corriente nominal), guardamotor, pulsadores NA/NC, selectores, luces piloto, temporizadores (on-delay/off-delay), relés auxiliares.
- Leer y dibujar **circuitos de potencia y de mando**.
- Pruebas: continuidad de devanados, resistencia entre fases, **aislamiento con megóhmetro** (criterios mínimos), medición de corriente por fase con pinza, desequilibrio.
- Mantenimiento: limpieza, rodamientos, vibración, temperatura, ajuste de bornes.
- Equipos típicos: bombas de agua salada, agua dulce, combustible, aceite, ventiladores, compresores de aire.

### Sistema 4 — Refrigeración por amoníaco (bodegas/salmuera)
- Ciclo de refrigeración por compresión: evaporación, compresión, condensación, expansión; diagrama presión–entalpía simplificado.
- Componentes: compresores (tornillo y/o pistón), separador de aceite, condensador, recibidor, válvulas de expansión, solenoides, evaporadores/serpentines de salmuera, bombas de salmuera.
- Control: **presostatos de alta, baja y aceite**, termostatos, transmisores de presión y temperatura **4–20 mA**, válvulas de seguridad.
- Presiones en **psi y bar**, temperaturas en °C; relación presión–temperatura del NH3.
- Cableado eléctrico del compresor: arranque, enclavamientos, alarmas, paradas de seguridad.
- Diagnóstico: alta presión de descarga, baja succión, falta de aceite, hielo en evaporador, fugas.
- Mantenimiento y seguridad con amoníaco.

### Sistema 5 — Cubierta y pesca
- Winches, power block, grúas: motores eléctricos y/o mando electrohidráulico (solenoides de válvulas, finales de carrera).
- Alumbrado de cubierta, reflectores.

### Sistema 6 — Electrónica, automatización y alarmas
- Componentes electrónicos básicos: resistencias (código de colores), condensadores, diodos, puentes rectificadores, transistores, relés de estado sólido, fuentes de 24 V DC.
- **Sensores inductivos/capacitivos NPN y PNP** (2 y 3 hilos), cómo cablearlos a un PLC y cómo probarlos.
- Transmisores 4–20 mA, termocuplas, PT100.
- **PLC**: entradas/salidas, lógica ladder básica, cableado, diagnóstico por LEDs.
- **HMI**: pantallas táctiles de equipos, navegación, lectura de alarmas y de tendencias, cambio de parámetros, alimentación y comunicación con el PLC.
- **SCADA o sistema de alarmas y monitoreo**: arquitectura, red de comunicación (Modbus, Ethernet), puestos de operación, historial de alarmas y diagnóstico de fallas de comunicación.
- Sistema de alarmas de sala de máquinas, detectores de incendio.
- Introducción a electrónica del puente (radar, sonar, comunicaciones) solo a nivel de alimentación y cuidados — para versiones posteriores.

## 8. Instrumentos virtuales (con comportamiento realista)

- **Multímetro**: V AC/DC, Ω, continuidad, diodo, mA/A. Si mide resistencia en un circuito energizado o corriente en paralelo, se quema el fusible o el equipo, como en la vida real.
- **Pinza amperimétrica**.
- **Megóhmetro** (250/500/1000 V) con criterios de aceptación.
- **Secuencímetro de fases**.
- **Detector de tensión sin contacto**.
- **Manifold/manómetros de refrigeración** (psi y bar) y termómetro de contacto/infrarrojo.
- **Detector de amoníaco**.
- Las puntas se colocan tocando/arrastrando en los bornes; el display muestra valores con ruido y fluctuación realista.

## 9. Consecuencias realistas de los errores

Los errores tienen las consecuencias que tendrían en la vida real, simuladas con animaciones (sin contenido gráfico explícito):
- Conectar mal estrella/delta → el motor se sobrecalienta, dispara el térmico, o se quema y queda inutilizable.
- Cortocircuito → arco eléctrico, disparo del breaker, componente destruido.
- Trabajar sin LOTO o sin verificar tensión → accidente → la misión termina con un **"informe de accidente"** que explica qué pasó y cómo se evitaba.
- Disparar el generador equivocado o sincronizar mal → **blackout** del barco.
- Error en refrigeración → disparo por alta presión, daño al compresor o fuga de amoníaco con evacuación.
- Los equipos dañados quedan dañados hasta que el jugador los repare o cambie el repuesto.

Después de cada error, mostrar una explicación clara de la causa y la forma correcta.

## 10. Motor de simulación eléctrica

- Implementa un **motor lógico de circuitos** basado en una red de nodos (netlist): cada borne es un nodo, cada cable une nodos, cada componente tiene un modelo (contactos NA/NC, bobina, resistencia, fusible, motor, etc.).
- Para circuitos de mando: evaluar estados (energizado / no energizado, bobina activa, contactos cambiando, temporizadores).
- Para potencia: modelo simplificado que calcule corrientes, tensiones de fase/línea, sobrecargas, desequilibrios y cortocircuitos con el nivel de precisión suficiente para enseñar.
- Para refrigeración: modelo simplificado presión–temperatura del NH3 que responda a carga térmica, condensación y fallas.
- Componentes y conexiones guardables, para que el Taller permita crear y guardar mis propios circuitos.

## 11. Precisión técnica

- Basa el contenido en normas y buenas prácticas reales: IEC 60617 y ANSI/IEEE 315 (símbolos), IEC 60092 (instalaciones eléctricas en buques), SOLAS, Convenio STCW (competencias del oficial electrotécnico), NFPA 70E (seguridad eléctrica) y la normativa de seguridad del amoníaco.
- Cada lección termina con una sección "Para saber más" con las normas o fuentes de referencia.
- Si no estás seguro de un dato, márcalo como *"verificar"* en lugar de inventarlo.

## 12. Primera versión (v1) — alcance

Para que la v1 ya sea útil, debe incluir solo esto, bien hecho y probado:

1. Menú con el plano del barco (los sistemas no hechos aparecen como "próximamente").
2. **Sistema 0 parcial**: ley de Ohm, AC trifásica, tensión de línea y fase, seguridad y LOTO.
3. **Sistema 3 parcial**: motor trifásico, placa de datos, **bornera estrella/delta**, contactor, relé térmico, guardamotor, pulsadores, arranque directo y **estrella-triángulo**.
4. Instrumentos: **multímetro y megóhmetro**.
5. Simbología IEC + ANSI de todos esos componentes, con un minijuego de identificación.
6. Taller con esos componentes.
7. **3 misiones de Guardia** (ej.: motor que no arranca, térmico que dispara, motor con bajo aislamiento).
8. Examen de la v1, rangos y guardado del progreso.
9. APK y .exe funcionando offline.

Hoja de ruta posterior: v2 generadores, paneles y controladores, cuadro principal y PMS → v3 refrigeración por amoníaco → v4 electrónica, sensores, PLC, HMI y SCADA → v5 distribución, cubierta y alarmas → v6 vista 3D/recorrido.

## 13. Forma de trabajar

1. **Antes de escribir código**, preséntame un plan: estructura de carpetas, arquitectura del motor de simulación, formato de los JSON de contenido y lista de pantallas. Espera mi aprobación.
2. **Antes de crear el repo o hacer push**, confírmame en qué cuenta de GitHub y en qué perfil estás trabajando.
3. Trabaja por etapas pequeñas; haz un commit con mensaje claro al terminar cada una.
4. Al final de cada etapa, dime cómo probarla en PC y cómo generar el APK para el celular.
5. Mantén un `README.md` con: cómo abrir el proyecto en Godot, cómo exportar, estructura del contenido y cómo añadir lecciones nuevas.
6. Escribe pruebas para el motor de simulación (estrella/delta, cortos, sobrecargas) para asegurar que los resultados son correctos.

Nombre sugerido del repo: `oficial-electrotecnico-simoun`.
