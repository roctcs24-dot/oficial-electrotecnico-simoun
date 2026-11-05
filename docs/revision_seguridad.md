# Revisión del contenido de seguridad

Revisión de las lecciones `l0_trifasica`, `l0_peligros` y `l0_loto`, y de la ficha `contactor`, contrastada con fuentes públicas (fabricantes, guías técnicas y organismos).

**Alcance y límite:** no se consultó el texto completo de las normas, que son de pago, y esta revisión no sustituye a la de una persona cualificada. A bordo prevalecen los procedimientos del buque.

## Corregido

| Lección | Afirmación anterior | Corrección | Fuente |
|---|---|---|---|
| Peligros | En red aislada, "una carcasa puede estar con tensión" tras una primera falla | Las fases sanas quedan a la tensión de línea respecto al casco. La carcasa solo queda con tensión si falla su conexión a masa | [Electrical Installation Guide](https://www.electrical-installation.org/enwiki/IT_system_-_Fault_protection), [Industrial Monitor Direct](https://industrialmonitordirect.com/blogs/knowledgebase/insulated-earth-system-voltage-measurement-analysis) |
| Trifásica | "No suponga que tocar una sola fase es seguro", sin dar el motivo | Se explica la subida a 440 V tras la falla y el retorno por la capacitancia de la red | [Electrical Installation Guide](https://www.electrical-installation.org/enwiki/IT_system_-_Fault_protection) |
| LOTO | Ausencia de tensión con "instrumento adecuado" | Debe ser de contacto: un detector sin contacto no basta en sistemas de hasta 1000 V | [EC&M](https://www.ecmweb.com/safety/article/20902603/establishing-an-electrically-safe-work-condition) |
| LOTO | Puesta a tierra "cuando el procedimiento lo requiera" | Se aclara: obligatoria en alta tensión y según el riesgo en baja tensión | [NEN 3140](https://nen.sulerr.com/en/guides/nen-3140/loto-5-stappen), [ABB](https://www.manualslib.com/manual/2108300/Abb-Mns-Up.html?page=11) |
| Peligros | Guantes siempre con protector de cuero | Salvo que el fabricante indique lo contrario; se añade revisar la fecha del último ensayo | [Power and Cables](https://www.powerandcables.com/?p=16627) |
| Peligros | Fibrilación "desde unos 50 mA" y "muy probable desde 200 mA" | Lesiones graves desde 40-50 mA durante un segundo; el valor de 200 mA pasa a ser orientativo, sin decir "muy probable" | [Schneider](https://storage.electrika.com/manu/man-0100/pdftech/0100-easy9-resi9-15-a-025-026.pdf) |

## Confirmado

| Contenido | Fuente |
|---|---|
| Las 5 reglas y su orden | [DEHN](https://www.dehn-international.com/en/work-according-five-safety-rules) |
| Guantes clase 00 hasta 500 V AC y clase 0 hasta 1000 V AC | [Power and Cables](https://www.powerandcables.com/?p=16627) |
| Comprobación de guantes por inflado antes de usarlos (descripción de un fabricante, no el texto de la norma) | [CATU](https://www.slideshare.net/slideshow/catu-insulating-rubber-gloves-53927041/53927041) |
| Primera falla en red aislada: no dispara; requiere vigilancia del aislamiento | [Electrical Installation Guide](https://www.electrical-installation.org/enwiki/IT_system_-_Principle) |
| Probar, medir, probar; descarga de energía almacenada; bloqueo | [Electrical Safety Forum](https://electricityforum.com/iep/arc-flash/to-verify-an-electrically-safe-work-condition) |
| Umbral de "no poder soltar" cerca de 10 mA; diferenciales de 30 mA | [IPD](https://ipd.com.au/why-30ma-and-300ms), [Electrician Courses](https://electriciancourses4u.co.uk/?p=906) |
| Fibrilación como principal causa de muerte | [IEC 60479-1, vista previa](https://webstore.ansi.org/preview-pages/IEC/preview_iec60479-1%7Bed4.1%7Den.pdf) |
| Bobina de contactor: cierre entre 85 % y 110 %. La caída depende del modelo | [Rockwell](https://www.rockwellautomation.com/en-us/products/details.104-K12B02.html), [ABB](https://resources.ipd.com.au/Flipbook/Contactor/files/basic-html/page318.html) |

## Sin confirmar con una fuente

Siguen en las lecciones como valores orientativos o a verificar:

- Resistencia del cuerpo de unos 1000 Ω.
- Percepción en 0,5 mA y 1 mA.
- Dificultad respiratoria cerca de 30 mA.
- Efecto de cientos de mA.
- Multímetro CAT III o CAT IV según IEC 61010.
- Requisitos de ropa resistente al arco según NFPA 70E.
- Tiempo de descarga de condensadores de un variador.
- Permisos de trabajo según el Código IGS.

## Pendiente de una persona cualificada

- Verificar los umbrales contra IEC 60479-1:2018, ya que IEC/TS 60479-1:2005 fue retirada.
- Contrastar los pasos de LOTO con el sistema de gestión de seguridad del Vía Simoun.
- Confirmar si la red del barco es realmente aislada y qué EPP exige.
