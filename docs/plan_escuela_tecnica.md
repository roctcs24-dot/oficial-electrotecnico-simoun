# Plan 5.0: interfaz más clara y «Escuela técnica»

Estilo visual elegido por el usuario entre maquetas (2026-11-15): variante «Oscuro» con color por área.

Plan redactado por Claude Fable a petición del usuario (2026-11-15) y revisado por Claude Opus contra el código. Aprobado por el usuario el 2026-11-15; en ejecución desde la etapa 30.

## A. Interfaz: qué falla hoy y qué cambia

**Lo que hay hoy**
- La aplicación abre directamente en el plano del barco, sin bienvenida ni indicación de por dónde empezar.
- El inicio mezcla con el mismo peso visual 7 sistemas, 5 exámenes, el repaso, el progreso y el glosario. No hay «continuar donde lo dejó».
- En el celular, las zonas del plano miden unos 67 × 18 pt: por debajo de los 48 px táctiles. Las pruebas no lo detectan.
- El progreso es solo texto. Las lecciones hechas no llevan marca y los modos que no existen aparecen como «Próximamente».
- Se navega solo con «‹ Volver»: desde una lección hay tres niveles hasta el inicio.

**Cambios (mismo estilo sobrio, azul y dorado)**
1. **Tema y filas:** tarjetas, chips de estado, marca de «hecho» con forma además de color, barras de avance, iconos por tipo y letra de las notas más grande.
2. **Inicio nuevo**, de arriba abajo:
   - rango y barra de avance;
   - tarjeta «Continuar» con la siguiente lección pendiente;
   - tarjeta «Repaso de hoy»;
   - tres accesos grandes: **Escuela técnica**, **El buque** y **Pañol**;
   - Mi progreso y Glosario.
3. **El buque:** el plano, con nombre y avance en cada zona y áreas táctiles de al menos 48 pt.
4. **Barra de navegación** Inicio · Escuela · Buque · Pañol · Progreso, solo en las pantallas principales. En las profundas, un botón «Inicio».
5. **Sistema y Aprender:** se ocultan los modos que no existen, cada modo muestra su avance y la siguiente lección queda resaltada.
6. **Bienvenida** de tres páginas la primera vez, que se puede volver a abrir.
7. **Tamaño de texto** normal, grande o muy grande, y contraste comprobado por prueba.

## B. Organización

Los apartados nuevos son módulos de la **Escuela**, con su progreso, repaso, examen y puntos como los sistemas del buque:

| Nº | Módulo | Cubre |
|---|---|---|
| 7 | Electricidad desde cero | electricidad |
| 8 | Electrónica desde cero | electrónica |
| 9 | Hidráulica y neumática | hidráulica y neumática |
| 10 | Válvulas y líneas | válvula abierta o cerrada; seguir líneas |
| 11 | Pañol: herramientas, llaves y racores | llaves en mm y pulgadas; racores y medidas |

El **Pañol** es también una consulta rápida para usar a bordo, sin puntos: catálogos de herramientas, válvulas y racores, tablas de medidas y glosario.

## C. Temario

**7 · Electricidad desde cero (9 lecciones):**
1. Unidades y prefijos.
2. Serie y paralelo.
3. Caída de tensión y sección del cable.
4. Magnetismo y relé.
5. Inducción.
6. Condensador y bobina en alterna; factor de potencia.
7. Tierra, masa y red aislada.
8. Cables, terminales y bornes.
9. Cómo leer un esquema.

Con animaciones de serie y paralelo y de caída de tensión, y una práctica en el Taller.

**8 · Electrónica desde cero (11 lecciones):**
1. Señal y potencia.
2. Resistencias y código de colores.
3. Condensador.
4. Diodo y LED.
5. Rectificador y fuentes.
6. Transistor como interruptor.
7. Relé, optoacoplador, relé de estado sólido, tiristor y triac.
8. Señales de 4-20 mA, PT100 y termocupla.
9. Lógica digital y binario.
10. Amplificador operacional como comparador.
11. Trabajo seguro en tarjetas.

Con cinco animaciones y tres prácticas en el Taller.

**9 · Hidráulica (9 lecciones) y neumática (8 lecciones):**
- Hidráulica: presión, fuerza y caudal; el aceite; bombas; cilindros y motores; válvulas de presión, de caudal y de retención; esquemas ISO 1219; acumuladores; diagnóstico.
- Neumática: aire comprimido; secado y filtrado; cilindros; válvulas 3/2, 5/2 y 5/3; control de velocidad; electroneumática; actuadores y posicionadores; fugas y seguridad.

Con animaciones de la prensa, del circuito hidráulico y del cilindro neumático, y un minijuego de símbolos ISO 1219.

**10 · Válvulas (8 lecciones) y líneas (6 lecciones):**
- Válvulas:
  - partes de una válvula;
  - **cuarto de vuelta** (bola y mariposa): la maneta alineada con el tubo indica abierta, y el vástago lleva una ranura;
  - **multivuelta** (compuerta, globo, aguja): vástago ascendente o no ascendente;
  - retención;
  - tres vías;
  - válvulas actuadas;
  - seguridad y reductoras;
  - maniobra segura.
- Líneas: tipos de plano; símbolos P&ID; colores ISO 14726; método para seguir una línea a bordo; servicios del buque; aislar un equipo.

Con un minijuego «¿Abierta o cerrada?», una animación del corte de la válvula y ejercicios de seguir una línea con el dedo sobre un esquema, empezando por la purificadora.

**11 · Herramientas (9 lecciones) y racores (8 lecciones):**
- Herramientas:
  - familias de llaves: de boca, de estrella, mixta, ajustable, Stillson, dado y carraca, Allen, Torx, de gancho, dinamométrica;
  - medidas en mm y en pulgadas, y equivalencias;
  - tornillería métrica y UNC/UNF;
  - destornilladores aislados de 1000 V;
  - alicates y crimpadoras;
  - calibre y micrómetro;
  - par de apriete;
  - herramienta de tubería;
  - cuidado y seguridad.
- Racores:
  - cómo sella una unión;
  - roscas BSPP, BSPT y NPT;
  - racores hidráulicos JIC 37°, ORFS, DIN 24° y SAE;
  - compresión, abocardado y enchufes rápidos;
  - mangueras SAE 100R;
  - bridas DN/PN, ANSI y JIS;
  - DN frente a NPS;
  - cómo identificar un racor desconocido.

Con minijuegos «Identifique la herramienta» y «Elija el racor», ejercicios de emparejar mm con pulgadas y DN con NPS, y una animación de la llave sobre la tuerca.

Irán marcados «verificar» todos los datos normativos: colores, roscas, bridas, mangueras, medidas entre caras DIN e ISO, pares de apriete y nombres locales de las herramientas.

## D. Piezas nuevas

- **Datos:**
  - catálogos (`data/catalogos/`);
  - tablas de medidas (`data/tablas/`);
  - esquemas de líneas (`data/lineas/`);
  - colores de tubería (`data/tuberias.json`);
  - minijuegos (`data/minijuegos.json`).
- **Bloques de lección nuevos:** pregunta con dibujo, emparejar y seguir línea.
- **Pantallas nuevas:**
  - inicio y bienvenida;
  - Escuela y Pañol;
  - prácticas;
  - catálogo;
  - tabla con conversor;
  - minijuego de identificación.
- **Widgets nuevos:** barra de navegación y vista de líneas.
- **Lógica nueva:** ruta recomendada, juego de identificación y trazado de líneas.

## E. Etapas (un commit, una versión y sus pruebas en cada una)

Reordenadas el 2026-11-15 tras la petición del usuario: primero la interfaz y el atlas de componentes, empezando por la electricidad industrial.

| Nº | Versión | Contenido |
|---|---|---|
| 30 | 4.3.0 | Tema, filas con marca y barra; avance en Sistema y Aprender |
| 31 | 4.4.0 | Inicio nuevo con «Continuar», barra de navegación, plano con zonas de 48 pt o más |
| 32 | 4.5.0 | Escuela y Pañol navegables, bienvenida y tamaño de texto |
| 33 | 4.6.0 | Ficha visual de componente con cinco pestañas (qué es, cómo funciona, cómo se conecta, cómo se mide, fallas y mantenimiento) en `data/atlas/<id>.json`; se estrena con el contactor, el relé térmico y el guardamotor y abre el módulo 7 |
| 34 | 4.7.0 | Electricidad industrial I, protección: interruptor automático, diferencial, fusible y portafusible, seccionador, relé de control de fases y de tensión, monitor de aislamiento. Hecha: fichas nuevas del fusible, el seccionador y el relé de fases; componentes de simulación del diferencial y del relé de fases, y sus piezas en el Taller |
| 35 | 4.8.0 | Electricidad industrial II, mando: relé auxiliar, temporizadores a la conexión y a la desconexión, pulsadores, selectores, pilotos, seta, finales de carrera, presostato, termostato, interruptor de nivel. Hecha: un corte genérico de mando, fichas nuevas de siete equipos y simulación del final de carrera y del termostato |
| 36 | 4.9.0 | Electricidad industrial III, potencia y medida: transformador y transformador de intensidad, motor, arrancador estrella-triángulo, arrancador suave, variador, resistencia de caldeo, condensadores de compensación, amperímetro y voltímetro, analizador de red, horómetro, borneras. Hecha: trece equipos; simulación del transformador de intensidad, el amperímetro, el voltímetro, el analizador de red, los condensadores, la resistencia de caldeo, la bornera y el variador, con el motor a frecuencia variable; fichas nuevas de diez equipos y seis cortes animados |
| 37 | 4.10.0 | Lecciones de electricidad desde cero (9). Hecha: lecciones `ec1` a `ec9` en el módulo 7, animaciones `serie_paralelo` y `caida_tension`, y práctica de serie y paralelo en el Taller con el bloque de lección `taller` |
| 38 | 4.11.0 | Electrónica I: resistencia, potenciómetro, NTC/PTC, varistor, condensador, diodo, zener, LED, puente rectificador. Hecha: módulo 8 activo con nueve equipos en su atlas; simulación del potenciómetro, los termistores, el varistor, el condensador, el Zener y la potencia de la resistencia; puente con averías y prueba de diodos; capacímetro en el multímetro; nueve cortes animados, nueve fichas y seis símbolos nuevos |
| 39 | 4.12.0 | Electrónica II: transistor BJT y MOSFET, tiristor, triac, optoacoplador, relé de estado sólido, regulador, fuente conmutada, amplificador operacional, puertas lógicas. Hecha: diez equipos más en el atlas del módulo 8 (19 en total); simulación del transistor, el MOSFET, el tiristor, el triac, el optoacoplador, el regulador, el operacional y las puertas lógicas; diez cortes animados, diez fichas y once símbolos nuevos |
| R-A | 4.13.0 | Rediseño visual A, marco de simulador para Guardia y Taller (estilo ARI, elegido por el usuario el 2026-11-16). Hecha: barra superior con el código del panel, columna de accesos por grupo, panel derecho plegable con la generación en kW, los consejos y las alarmas, barra de eventos con reloj, lecturas LCD de siete segmentos, índice de paneles (`data/paneles.json`) y leyenda; en vertical, tira de accesos y hoja que sube desde el pie |
| R-B | 4.14.0 | Rediseño visual B: tableros, cuadro principal, planta de frío, PLC, red de alarmas y misiones dibujados en el marco (casillas de motor, megóhmetro R-S-T, misiones que empiezan tocando la alarma). Hecha: tema ARI para el contenido del marco; mímico de siete tableros con casillas de arrancador y megóhmetro, al lado del frente y del interior; grupos del cuadro como casillas; esquema de frío con los colores de la leyenda; frente del PLC con sus LED; puesto de alarmas con cabecera roja; avisos ARI; alarmas que llevan a su panel o a su misión; Guardia como tabla de averías; en el celular apaisado, panel derecho plegado que flota al abrirlo |
| R-C | 4.15.0 | Rediseño visual C: inicio con el buque visto desde arriba y Escuela con camino de lecciones. Hecha: buque visto desde arriba con una zona por sistema (datos en `planta` de `data/sistemas.json`) y lámpara de estado verde, ámbar, roja o apagada; seguridad como medalla; placa del rango con visor de puntos, «Continuar» con botón redondo, botón de avería que lleva a la Guardia y repaso con insignia; Escuela con medallas de módulo, placa con «Empezar», camino de lecciones en serpentina con el examen al final y cajón de piezas del atlas; barra de navegación con relieve |
| R-D | 4.16.0 | Rediseño visual D: fichas con el dibujo grande, marcas numeradas y pestañas con iconos. Hecha: ficha de equipo y atlas con el dibujo en un visor hundido con luz de foco; marcas numeradas con relieve que se tocan y abren un bocadillo con la parte, enlazadas con la lista de partes; marcas de las 19 fichas sin atlas en `data/marcas_fichas.json` (valores típicos — verificar a bordo); pestañas con iconos (Partes, Funciona, Conexión, Prueba y Fallas en la ficha; las cinco vistas en el atlas, con lámpara verde en las ya vistas); placa de datos como chapa remachada; lecturas en visores verdes o rojos; fallas con lámpara roja y mantenimiento con casillas de relieve |
| R-E | 4.17.0 | Rediseño visual E: lección, examen, repaso y pantalla «Buque» con relieve. Hecha: lección con la cabecera de la ficha y una moneda por página, texto en placas con las fórmulas en un visor ámbar, animaciones e imágenes en un visor hundido, en apaisado texto a la izquierda y lo que se toca a la derecha; preguntas con teclas de letra que se encienden en verde o rojo y la explicación en un visor; resultado con medalla, una lámpara por pregunta, visores de aciertos y puntos, «Para saber más» en papel y la siguiente lección como moneda del camino; examen con contador, tira de lámparas de las preguntas, símbolo en papel dentro del visor y caso práctico en una hoja del libro de guardia; calificación con anillo, estrellas y lámpara de aprobado; repaso con las cajas de 1, 3, 7, 14 y 30 días; lista de exámenes en placas; «Buque» con el buque visto desde arriba y las capas Sistemas y Tableros, marcas de los lugares con paneles (datos en `planta.lugares` de `data/sistemas.json`, esquemáticos — verificar a bordo) y lámpara roja donde hay una avería pendiente |
| 40 | 4.18.0 | Lecciones de electrónica desde cero (11). Hecha: lecciones `el1` a `el11` en el módulo 8; animaciones `codigo_colores`, `carga_condensador`, `rectificador` (osciloscopio), `transistor_llave` y `lazo_4_20`; prácticas en el Taller del LED, del rectificador con filtro y del transistor con relé; 11 términos nuevos en el glosario; valores de a bordo marcados «verificar» |
| 41 | 4.19.0 | Válvulas: catálogo, lecciones y minijuego «¿Abierta o cerrada?» |
| 42 | 4.20.0 | Pañol: herramientas y tabla de llaves mm↔pulgadas, minijuego |
| 43 | 4.21.0 | Racores: catálogo, tablas de roscas, DN↔NPS y mangueras, minijuego |
| 44 | 4.22.0 | Seguir líneas: esquema interactivo y colores de tubería |
| 45 | 4.23.0 | Hidráulica: componentes en atlas y lecciones |
| 46 | 4.24.0 | Neumática: componentes en atlas y lecciones |
| 47 | 5.1.0 | Exámenes v6 y v7, rango «Aspirante», calibración final, README |

## G. Atlas de componentes (añadido a petición del usuario)

El usuario pidió conocer **todos los componentes de electricidad industrial, cómo funcionan, cómo se conectan y cómo se miden, de manera visual**, y lo mismo en electrónica, hidráulica y neumática.

Hoy hay 32 fichas en `data/fichas/` con texto (función, partes, conexión, ajuste, pruebas, fallas, mantenimiento) y símbolos IEC y ANSI. Solo la del contactor tiene un banco interactivo.

Cada componente del atlas tiene cinco pestañas visuales (la quinta, fallas y mantenimiento, añadida a petición del usuario):

1. **Qué es:**
   - dibujo realista con sus partes señaladas;
   - símbolos IEC y ANSI;
   - placa o marcas y dónde se encuentra a bordo.
2. **Cómo funciona:** vista en corte animada que se maneja con el dedo. Ejemplos:
   - se energiza la bobina y cierran los contactos;
   - el bimetal se curva y dispara;
   - la corriente se va a tierra y el diferencial abre.

   Se ve el camino de la corriente, del aceite o del aire.
3. **Cómo se conecta:** esquema interactivo con sus bornes numerados. Al tocar un borne se ilumina en el dibujo real y en el esquema. Un botón abre una práctica en el Taller con el componente ya montado.
4. **Cómo se mide:** el instrumento virtual sobre el componente:
   - qué instrumento y en qué escala;
   - dónde se ponen las puntas;
   - el valor normal y el de cada falla típica, medidos en la simulación y no escritos a mano.

5. **Fallas y mantenimiento:** botones de las fallas típicas con su síntoma, qué se mide (con valores), causa y reparación; debajo, el mantenimiento preventivo mensual, semestral y anual como lista para marcar.

Hecho en la etapa 33: formato `data/atlas/<id>.json` (descrito en el README), pantalla `ui/screens/atlas.gd`, cortes animados `corte_contactor`, `corte_rele_termico` y `corte_guardamotor`, y lecturas calculadas con la simulación en `game/atlas_medidas.gd`.

Las fichas existentes se pasan al formato nuevo. Los componentes nuevos se añaden por familias, en las etapas 34 a 36 (electricidad industrial), 38 y 39 (electrónica) y 45 y 46 (hidráulica y neumática). En cada uno, los valores que no salgan de las fotos del buque se marcan «valor típico — verificar a bordo».

## F. Decisiones del usuario

1. **Dibujos:** hacen falta unos 120 dibujos nuevos de herramientas, válvulas en dos estados, racores y esquemas. ¿Dibujos esquemáticos uniformes, o fotos del buque para calcarlos?
2. **Normas del buque:** ¿bridas JIS, DIN o ANSI? ¿Código de colores de tuberías propio? ¿Cómo se llaman las llaves a bordo?
3. **Rangos:** con unas 70 lecciones nuevas hay que subir los puntos. Propuesta: añadir el rango «Aspirante» y recalibrar.
4. **Arranque:** el plano deja de ser la primera pantalla y pasa a ser la tarjeta «El buque» del inicio.
5. **Orden:** primero la interfaz y el atlas de electricidad industrial y de electrónica, después válvulas, pañol, racores y líneas, y al final hidráulica y neumática.
