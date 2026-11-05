# Revisión del contenido de seguridad

Revisión de las lecciones `l0_trifasica`, `l0_peligros` y `l0_loto`, y de la ficha `contactor`, contrastada con fuentes públicas (fabricantes, guías técnicas y organismos).

**Alcance y límite:** no se consultó el texto completo de las normas, que son de pago, y esta revisión no sustituye a la de una persona cualificada. A bordo prevalecen los procedimientos del buque.

## Corregido

| Lección | Afirmación anterior | Corrección | Fuente |
|---|---|---|---|
| Peligros | En red aislada, "una carcasa puede estar con tensión" tras una primera falla | Las fases sanas quedan a la tensión de línea respecto al casco. La carcasa solo queda con tensión si falla su conexión a masa | [Electrical Installation Guide](https://www.electrical-installation.org/enwiki/IT_system_-_Fault_protection), [Industrial Monitor Direct](https://industrialmonitordirect.com/blogs/knowledgebase/insulated-earth-system-voltage-measurement-analysis) |
| Trifásica | "No suponga que tocar una sola fase es seguro", sin dar el motivo | Se explica la subida a 440 V tras la falla y el retorno por la capacitancia de la red | [Electrical Installation Guide](https://www.electrical-installation.org/enwiki/IT_system_-_Fault_protection) |
| LOTO | Ausencia de tensión con "instrumento adecuado" | Se indica usar instrumento de contacto, no un detector sin contacto. Es la opción conservadora; ver "Sin confirmar con una fuente" | Sin fuente abierta |
| LOTO | Puesta a tierra "cuando el procedimiento lo requiera" | Se aclara: obligatoria en alta tensión y según el riesgo en baja tensión | [NEN 3140](https://nen.sulerr.com/en/guides/nen-3140/loto-5-stappen), [ABB](https://www.manualslib.com/manual/2108300/Abb-Mns-Up.html?page=11) |
| Peligros | Guantes siempre con protector de cuero | Salvo que el fabricante indique lo contrario; se añade revisar la fecha del último ensayo | [Clase 0 con protector recomendado](https://www.powerandcables.com/?p=16627), [guantes compuestos sin protector](https://www.powerandcables.com/?p=16621) |
| Peligros | Fibrilación "desde unos 50 mA" y "muy probable desde 200 mA" | Lesiones graves desde 40-50 mA durante un segundo; el valor de 200 mA pasa a ser orientativo, sin decir "muy probable" | [Schneider](https://storage.electrika.com/manu/man-0100/pdftech/0100-easy9-resi9-15-a-025-026.pdf) |

## Confirmado

| Contenido | Fuente |
|---|---|
| Las 5 reglas y su orden | [DEHN](https://www.dehn-international.com/en/work-according-five-safety-rules) |
| Guantes clase 00 hasta 500 V AC y clase 0 hasta 1000 V AC | [Power and Cables](https://www.powerandcables.com/?p=16627) |
| Comprobación de guantes por inflado antes de usarlos (descripción de un fabricante, no el texto de la norma) | [CATU](https://www.slideshare.net/slideshow/catu-insulating-rubber-gloves-53927041/53927041) |
| Primera falla en red aislada: no dispara; requiere vigilancia del aislamiento | [Electrical Installation Guide](https://www.electrical-installation.org/enwiki/IT_system_-_Principle) |
| Medir entre fases y de cada fase a tierra | [EC&M](https://www.ecmweb.com/safety/article/20902603/establishing-an-electrically-safe-work-condition) |
| Bloqueo y etiquetado en todos los puntos de desconexión, y descarga de energía almacenada | [Electricity Forum](https://electricityforum.com/iep/arc-flash/to-verify-an-electrically-safe-work-condition) |
| Umbral de "no poder soltar" cerca de 10 mA; diferenciales de 30 mA | [IPD](https://ipd.com.au/why-30ma-and-300ms), [Electrician Courses](https://electriciancourses4u.co.uk/?p=906) |
| Fibrilación como principal causa de muerte | [IEC 60479-1, vista previa](https://webstore.ansi.org/preview-pages/IEC/preview_iec60479-1%7Bed4.1%7Den.pdf) |
| Bobina de contactor: cierre entre 85 % y 110 %. La caída depende del modelo | [Rockwell](https://www.rockwellautomation.com/en-us/products/details.104-K12B02.html), [ABB](https://resources.ipd.com.au/Flipbook/Contactor/files/basic-html/page318.html) |

## Revisión del cierre de la v1

Se contrastaron con fuentes públicas los datos de motores, protecciones e instrumentos que más pesan en las misiones y el examen. Ninguna es el texto de la norma: son fabricantes, guías técnicas y foros profesionales.

| Dato | Resultado | Fuentes |
|---|---|---|
| Aislamiento mínimo del devanado | **Corregido.** Antes decía 1 MΩ. IEEE 43 recomienda 5 MΩ en devanados de menos de 1 kV, a 500 V DC; el valor de kV + 1 MΩ es para devanados antiguos. Se cambió en lecciones, ficha, misión, examen y megóhmetro | [EASA](https://easa.com/resources/resource-library/whats-new-in-the-ieee-43-insulation-resistance-testing-standard-1), [Open Exam Prep](https://open-exam-prep.com/study-guides/neta-ett-level-ii/insulation-resistance-testing/ir-test-voltages-ieee-43-minimums), [TestGuy](https://wiki.testguy.net/t/field-testing-of-motors/249) |
| Clase 10: de 4 a 10 s a 7,2 × Ir, en frío; no dispara a 1,05 × Ir | Confirmado | [Schneider](https://www.se.com/vn/en/faqs/FA286067), [Siemens 3RU11](https://www.manualslib.com/manual/2997046/Siemens-3ru11.html?page=39) |
| Disparo magnético del guardamotor de unas 13 veces el máximo del rango | Confirmado como valor habitual; otras series usan de 12 a 21 veces | [Rockwell 140M](https://configurator.rockwellautomation.com/api/Product/140M-C2E-C32/cutsheet), [Omron J7MN](https://manualmachine.com/omron/j7mn/10123057-datasheet) |
| Estrella-triángulo: corriente y par de arranque a cerca de un tercio | Confirmado | [Electrical4U](https://www.electrical4u.com/star-delta-starter/), [EEPower](https://eepower.com/technical-articles/motor-starters-part-3-pros-and-cons-of-the-star-delta-configuration/) |
| Polaridad de un motor sin marcas con pila y voltímetro | Práctica habitual, pero algunas fuentes prefieren baja tensión alterna. Se añadió esa advertencia a la lección | [Industrial Monitor Direct](https://industrialmonitordirect.com/blogs/knowledgebase/determining-three-phase-motor-lead-polarity-with-unidentified-leads), [Eng-Tips](https://eng-tips.com/threads/how-to-determine-polarity-on-three-phase-motor.153197/page-2), [EASA](https://easa.com/resources/trade_press/identifying-unmarked-leads-of-6-lead-motors-with-1-or-2-windings) |
| Unos 220 V entre la fase perdida y las sanas, con el motor parado | Comprobado en el motor de simulación, con una prueba | Modelo del juego |

## Sin confirmar con una fuente

Siguen en las lecciones como valores orientativos o a verificar:

- Que NFPA 70E no admite detectores sin contacto para verificar ausencia de tensión hasta 1000 V: lo indicó un resumen de búsqueda, pero no se pudo abrir la fuente.
- Probar el instrumento en una fuente conocida antes y después de medir: se confirmó solo en resúmenes de búsqueda, sin abrir la fuente.
- Resistencia del cuerpo de unos 1000 Ω.
- Percepción en 0,5 mA y 1 mA.
- Dificultad respiratoria cerca de 30 mA.
- Efecto de cientos de mA.
- Multímetro CAT III o CAT IV según IEC 61010.
- Requisitos de ropa resistente al arco según NFPA 70E.
- Tiempo de descarga de condensadores de un variador.
- Permisos de trabajo según el Código IGS.

## Contenido sin contrastar todavía

Lo siguiente se redactó sin contrastarlo con fuentes y lleva marcas de "verificar" en los puntos sensibles:

- Fichas de motor trifásico, relé térmico, guardamotor y pulsadores, salvo los datos de la tabla anterior.
- Lecciones de motores, arrancadores, multímetro y megóhmetro, incluido el procedimiento de polaridad de un motor sin marcas.
- Esquemas de arranque directo y estrella-triángulo: coinciden con las plantillas del motor de simulación, pero no con planos reales del buque.
- Explicaciones de consecuencias del Taller, en `data/taller.json`.
- Banco del examen, en `data/examenes/v1.json`, y preguntas de repaso de `data/guardia.json`. Se redactaron a partir de las lecciones, sin contrastarlos por separado.
- Misiones de Guardia y sus informes de accidente, en `data/misiones/` y `data/guardia.json`: reportes, averías, secuencia del procedimiento, y el secado de devanados. El umbral de 30 V para considerar que hay tensión es un criterio del juego.
- Los 12 símbolos de `data/simbolos.json`. No se pudo abrir la comparativa de referencia entre NEMA e IEC, y la simbología ANSI del guardamotor varía según el fabricante.

Solo la forma de los equipos se comparó con fotos de productos reales.

## Pendiente de una persona cualificada

- Verificar los umbrales contra IEC 60479-1:2018, ya que IEC/TS 60479-1:2005 fue retirada.
- Contrastar los pasos de LOTO con el sistema de gestión de seguridad del Vía Simoun.
- Confirmar si la red del barco es realmente aislada y qué EPP exige.
