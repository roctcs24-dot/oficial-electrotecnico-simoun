"""Dibujos de la neumática (etapa 46): piezas del atlas en art/equipos, esquemas ISO 1219 de la
pestaña «Conexión» en art/esquemas y símbolos ISO 1219-1 neumáticos en art/simbolos/iso1219.

Usa las piezas comunes de svg_hidraulica.py. En neumática los triángulos de los símbolos van
huecos (aire); en hidráulica, llenos (aceite).

Uso, desde la raíz del repositorio:  python tools/svg_neumatica.py"""
import math, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import svg_hidraulica as H
from svg_hidraulica import (svg, hexagono, perno, allen, boca, chapa, brillo, sombra_suelo, linea, polilinea, triangulo, muelle,
                            flecha_ajuste, estrangulador_sim, antirretorno_sim, manometro_sim, resalte, escribir, TINTA, G)

DEFS = H.DEFS + '''
<linearGradient id="vaso" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8fa6b4" stop-opacity="0.75"/><stop offset="0.3" stop-color="#e8f4fb" stop-opacity="0.55"/><stop offset="0.65" stop-color="#cfe2ec" stop-opacity="0.45"/><stop offset="1" stop-color="#6f8796" stop-opacity="0.8"/></linearGradient>
<linearGradient id="agua" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9fd6ff"/><stop offset="1" stop-color="#2f7fbf"/></linearGradient>
<linearGradient id="aceiteL" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f3d27a"/><stop offset="1" stop-color="#b8861c"/></linearGradient>
<linearGradient id="azulRacor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7fb8ef"/><stop offset="0.5" stop-color="#2f78c4"/><stop offset="1" stop-color="#174a80"/></linearGradient>
<linearGradient id="bronce" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6a4a1a"/><stop offset="0.4" stop-color="#d9a85a"/><stop offset="0.6" stop-color="#f2cf8a"/><stop offset="1" stop-color="#6a4a1a"/></linearGradient>
<linearGradient id="amarillo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffe27a"/><stop offset="0.5" stop-color="#f2b81f"/><stop offset="1" stop-color="#9a6a00"/></linearGradient>
<linearGradient id="gris" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6a7580"/><stop offset="0.5" stop-color="#3c454e"/><stop offset="1" stop-color="#20262c"/></linearGradient>
<linearGradient id="crema" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f4f1e8"/><stop offset="0.6" stop-color="#d8d3c4"/><stop offset="1" stop-color="#a9a393"/></linearGradient>
<linearGradient id="pantalla" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#20302a"/><stop offset="1" stop-color="#0b1410"/></linearGradient>
<radialGradient id="ledAmbar" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#fff1b0"/><stop offset="0.5" stop-color="#ffc23a"/><stop offset="1" stop-color="#8a5a00"/></radialGradient>
'''

PIEZAS = {}


def racor_rapido(x, y, hacia_arriba=True, r=9):
    """Racor de enchufe rápido (push-in) con su anillo azul, saliendo hacia arriba o hacia abajo."""
    alto = 18
    y0 = y if hacia_arriba else y - alto
    s = f'<rect x="{x - r}" y="{y0}" width="{2 * r}" height="{alto}" rx="2" fill="url(#cromoV)" stroke="#3b4247" stroke-width="1"/>'
    ya = y0 - 7 if hacia_arriba else y0 + alto
    s += f'<rect x="{x - r - 2}" y="{ya}" width="{2 * r + 4}" height="7" rx="2" fill="url(#azulRacor)" stroke="#123766" stroke-width="1"/>'
    yt = ya - 14 if hacia_arriba else ya + 7
    s += f'<rect x="{x - r * 0.6:.1f}" y="{yt}" width="{r * 1.2:.1f}" height="14" fill="#1f5fa6" opacity="0.85"/>'
    return s


def silenciador(x, y, hacia_abajo=True):
    s = f'<rect x="{x - 5}" y="{y}" width="10" height="6" fill="url(#cromoV)" stroke="#3b4247"/>'
    y0 = y + 6 if hacia_abajo else y - 24
    s += f'<rect x="{x - 9}" y="{y0}" width="18" height="24" rx="6" fill="url(#bronce)" stroke="#4a3210" stroke-width="1"/>'
    for k in range(4, 22, 4):
        s += f'<path d="M{x - 8},{y0 + k} H{x + 8}" stroke="#7a5a20" stroke-width="0.7" opacity="0.7"/>'
    return s


def manometro_frente(cx, cy, r, valor=0.6):
    """Manómetro visto de frente: bisel, esfera, escala y aguja (fracción de la escala)."""
    s = f'<circle cx="{cx}" cy="{cy}" r="{r + 4}" fill="url(#acero)" stroke="#2d3236" stroke-width="1.2"/>'
    s += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#f6f6f0"/>'
    for i in range(11):
        a = math.radians(225 - i * 27)
        r1 = r - (5 if i % 5 == 0 else 3)
        s += f'<path d="M{cx + math.cos(a) * r1:.1f},{cy - math.sin(a) * r1:.1f} L{cx + math.cos(a) * (r - 1):.1f},{cy - math.sin(a) * (r - 1):.1f}" stroke="#20262c" stroke-width="1"/>'
    a = math.radians(225 - valor * 270)
    s += f'<path d="M{cx},{cy} L{cx + math.cos(a) * (r - 4):.1f},{cy - math.sin(a) * (r - 4):.1f}" stroke="#c0281f" stroke-width="2" stroke-linecap="round"/>'
    s += f'<circle cx="{cx}" cy="{cy}" r="2.5" fill="#20262c"/>'
    s += f'<ellipse cx="{cx - r * 0.3:.1f}" cy="{cy - r * 0.45:.1f}" rx="{r * 0.5:.1f}" ry="{r * 0.2:.1f}" fill="#fff" opacity="0.5"/>'
    return s


def bobina(x, y, w=74, h=56, led=True):
    """Bobina de solenoide negra con conector DIN encima (tornillo central y LED)."""
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="url(#negro)" stroke="#0b0c0d" stroke-width="1.4"/>'
    s += brillo(x + 5, y + 4, w - 10, 5, 2, 0.18)
    s += f'<rect x="{x + 10}" y="{y - 34}" width="{w - 20}" height="36" rx="4" fill="url(#gris)" stroke="#0b0c0d" stroke-width="1.2"/>'
    s += f'<circle cx="{x + w / 2}" cy="{y - 20}" r="5" fill="url(#acero)" stroke="#2d3236"/>'
    if led:
        s += f'<circle cx="{x + w / 2}" cy="{y - 6}" r="3.6" fill="url(#ledAmbar)"/>'
    s += f'<rect x="{x - 8}" y="{y - 22}" width="12" height="12" rx="2" fill="url(#negro)" stroke="#0b0c0d"/>'  # prensaestopas
    return s


# ----------------------------------------------------------------------------- piezas
def unidad_fr():
    w, h = 460, 340
    s = sombra_suelo(230, 318, 190, 12)
    # Tres módulos en línea: filtro (F), regulador (R) y lubricador (L), con sus abrazaderas
    for x0 in (64, 182, 300):
        s += f'<rect x="{x0}" y="78" width="96" height="66" rx="8" fill="url(#alu)" stroke="#3b4247" stroke-width="1.6"/>'
        s += brillo(x0 + 6, 82, 84, 6)
    for xm in (160, 278):
        s += f'<rect x="{xm}" y="84" width="22" height="54" rx="3" fill="url(#negro)" stroke="#0b0c0d"/>'
        s += allen(xm + 11, 96, 4) + allen(xm + 11, 126, 4)
    # Bocas de entrada y salida con racor
    s += '<rect x="30" y="96" width="36" height="30" rx="3" fill="url(#cromo)" stroke="#3b4247"/>' + boca(36, 111, 8)
    s += '<rect x="394" y="96" width="36" height="30" rx="3" fill="url(#cromo)" stroke="#3b4247"/>' + boca(424, 111, 8)
    # Filtro: vaso transparente con guarda, cartucho, agua y purga
    s += '<path d="M76,144 L148,144 L140,282 Q112,298 84,282 Z" fill="url(#vaso)" stroke="#3b4247" stroke-width="1.6"/>'
    s += '<path d="M81,250 L143,250 L140,282 Q112,298 84,282 Z" fill="url(#agua)" opacity="0.85"/>'
    s += '<rect x="98" y="152" width="28" height="72" rx="4" fill="url(#crema)" stroke="#6a6450"/>'
    for y in range(158, 222, 7):
        s += f'<path d="M100,{y} H124" stroke="#8a836a" stroke-width="0.8"/>'
    s += '<rect x="80" y="150" width="5" height="128" fill="url(#cromoV)" opacity="0.8"/><rect x="139" y="150" width="5" height="128" fill="url(#cromoV)" opacity="0.8"/>'
    s += '<rect x="104" y="292" width="16" height="16" rx="3" fill="url(#negro)" stroke="#0b0c0d"/>'
    # Regulador: pomo arriba, manómetro al frente
    s += '<rect x="214" y="56" width="32" height="24" rx="2" fill="url(#alu)" stroke="#3b4247"/>'
    s += '<rect x="200" y="16" width="60" height="42" rx="10" fill="url(#negro)" stroke="#0b0c0d" stroke-width="1.4"/>'
    for x in range(206, 256, 6):
        s += f'<path d="M{x},20 V54" stroke="#4a5257" stroke-width="1.4"/>'
    s += manometro_frente(230, 112, 22, 0.6)
    s += '<rect x="200" y="144" width="60" height="70" rx="10" fill="url(#alu)" stroke="#3b4247" stroke-width="1.4"/>'
    s += brillo(206, 148, 10, 60, 4, 0.3)
    # Lubricador: cúpula de goteo y vaso con aceite
    s += '<rect x="332" y="50" width="32" height="30" rx="8" fill="url(#vaso)" stroke="#3b4247"/>'
    s += '<circle cx="348" cy="70" r="3" fill="url(#aceiteL)"/><rect x="342" y="40" width="12" height="12" rx="2" fill="url(#negro)"/>'
    s += '<path d="M312,144 L384,144 L376,268 Q348,282 320,268 Z" fill="url(#vaso)" stroke="#3b4247" stroke-width="1.6"/>'
    s += '<path d="M316,200 L380,200 L376,268 Q348,282 320,268 Z" fill="url(#aceiteL)" opacity="0.85"/>'
    PIEZAS["unidad_fr"] = {
        "tamano": [w, h], "bocas": {"1": [36, 111], "2": [424, 111]},
        "marcas": {"entrada": [36, 111], "vaso": [112, 190], "purga": [112, 300], "pomo": [230, 30], "manometro": [230, 112], "lubricador": [348, 230], "salida": [424, 111]},
        "etiquetas": [{"texto": "1", "x": 36, "y": 78, "tam": 14}, {"texto": "2", "x": 424, "y": 78, "tam": 14},
                      {"texto": "F", "x": 112, "y": 96, "tam": 13}, {"texto": "L", "x": 348, "y": 96, "tam": 13}],
    }
    return svg(w, h, s, DEFS)


def secador_frigorifico():
    w, h = 420, 360
    s = sombra_suelo(210, 342, 170, 12)
    # Armario con panel frontal
    s += '<rect x="70" y="70" width="280" height="262" rx="8" fill="url(#crema)" stroke="#59626a" stroke-width="1.8"/>'
    s += brillo(76, 74, 268, 7)
    # Rejilla del condensador
    for y in range(206, 318, 9):
        s += f'<rect x="96" y="{y}" width="150" height="5" rx="2" fill="url(#gris)"/>'
    # Panel: pantalla del punto de rocío, interruptor y lámparas
    s += '<rect x="264" y="96" width="70" height="100" rx="6" fill="url(#gris)" stroke="#0b0c0d"/>'
    s += '<rect x="272" y="106" width="54" height="26" rx="3" fill="url(#pantalla)" stroke="#000"/>'
    s += '<circle cx="284" cy="150" r="6" fill="#2fbf5a" stroke="#0b0c0d"/><circle cx="314" cy="150" r="6" fill="#5a2020" stroke="#0b0c0d"/>'
    s += '<rect x="282" y="166" width="34" height="20" rx="4" fill="url(#negro)" stroke="#0b0c0d"/><rect x="300" y="168" width="13" height="16" rx="2" fill="#c0392b"/>'
    s += chapa(96, 100, 120, 60)
    # Tubos de entrada y salida arriba, con bridas roscadas
    for x in (130, 290):
        s += f'<rect x="{x - 14}" y="26" width="28" height="46" rx="3" fill="url(#cromoV)" stroke="#3b4247"/>'
        s += f'<polygon points="{hexagono(x, 26, 18, 30)}" fill="url(#acero)" stroke="#2d3236" stroke-width="1.2" transform="scale(1,0.5) translate(0,26)"/>'
    # Purgador electrónico abajo a la derecha
    s += '<rect x="350" y="296" width="24" height="10" fill="url(#cromo)" stroke="#3b4247"/>'
    s += '<rect x="368" y="278" width="38" height="44" rx="5" fill="url(#gris)" stroke="#0b0c0d"/><circle cx="387" cy="292" r="4" fill="#2fbf5a"/>'
    PIEZAS["secador_frigorifico"] = {
        "tamano": [w, h], "bocas": {"IN": [130, 18], "OUT": [290, 18], "DR": [387, 322]},
        "marcas": {"entrada": [130, 40], "salida": [290, 40], "pantalla": [299, 119], "interruptor": [299, 176], "condensador": [170, 262], "purgador": [387, 300], "chapa": [156, 130]},
        "etiquetas": [{"texto": "IN", "x": 130, "y": 4, "tam": 13}, {"texto": "OUT", "x": 290, "y": 4, "tam": 13},
                      {"texto": "3 °C", "x": 299, "y": 120, "tam": 13, "color": "#7dff9a"}],
    }
    return svg(w, h, s, DEFS)


def _cuerpo_valvula(x, y, w, h):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="5" fill="url(#alu)" stroke="#3b4247" stroke-width="1.8"/>'
    s += brillo(x + 6, y + 4, w - 12, 6)
    s += f'<rect x="{x + 10}" y="{y + h / 2 - 6}" width="{w - 20}" height="12" rx="4" fill="url(#gris)" opacity="0.45"/>'
    return s


def valvula_52():
    w, h = 470, 280
    s = sombra_suelo(240, 262, 190, 10)
    s += _cuerpo_valvula(150, 100, 190, 70)
    # Piloto con mando manual amarillo y bobina con conector
    s += '<rect x="128" y="104" width="24" height="62" rx="4" fill="url(#negro)" stroke="#0b0c0d"/>'
    s += '<circle cx="140" cy="148" r="6" fill="url(#amarillo)" stroke="#5a4310"/>'
    s += bobina(56, 106, 72, 58)
    # Tapa del muelle a la derecha
    s += '<rect x="340" y="110" width="40" height="50" rx="8" fill="url(#alu)" stroke="#3b4247" stroke-width="1.4"/>'
    s += allen(352, 122, 4) + allen(352, 148, 4)
    # Racores 4 y 2 arriba; 5, 1 y 3 abajo
    s += racor_rapido(215, 82) + racor_rapido(275, 82)
    s += '<rect x="206" y="82" width="18" height="18" fill="url(#cromoV)"/><rect x="266" y="82" width="18" height="18" fill="url(#cromoV)"/>'
    s += racor_rapido(245, 188, False) + '<rect x="236" y="170" width="18" height="18" fill="url(#cromoV)"/>'
    s += silenciador(200, 170) + silenciador(290, 170)
    PIEZAS["valvula_52"] = {
        "tamano": [w, h], "bocas": {"1": [245, 228], "2": [275, 42], "3": [290, 200], "4": [215, 42], "5": [200, 200], "Y1": [92, 86]},
        "marcas": {"bobina": [92, 140], "conector": [92, 86], "manual": [140, 148], "cuerpo": [245, 135], "muelle": [360, 135], "racor": [215, 56], "silenciador": [200, 188]},
        "etiquetas": [{"texto": "4", "x": 215, "y": 20, "tam": 14}, {"texto": "2", "x": 275, "y": 20, "tam": 14}, {"texto": "1", "x": 245, "y": 252, "tam": 14},
                      {"texto": "5", "x": 176, "y": 206, "tam": 14}, {"texto": "3", "x": 314, "y": 206, "tam": 14}, {"texto": "Y1", "x": 92, "y": 136, "tam": 14}],
    }
    return svg(w, h, s, DEFS)


def valvula_53():
    w, h = 560, 280
    s = sombra_suelo(280, 262, 230, 10)
    s += _cuerpo_valvula(190, 100, 180, 70)
    for x in (168, 370):
        s += f'<rect x="{x}" y="104" width="24" height="62" rx="4" fill="url(#negro)" stroke="#0b0c0d"/>'
        s += f'<circle cx="{x + 12}" cy="148" r="6" fill="url(#amarillo)" stroke="#5a4310"/>'
    s += bobina(94, 106, 74, 58) + bobina(394, 106, 74, 58)
    s += racor_rapido(250, 82) + racor_rapido(310, 82)
    s += '<rect x="241" y="82" width="18" height="18" fill="url(#cromoV)"/><rect x="301" y="82" width="18" height="18" fill="url(#cromoV)"/>'
    s += racor_rapido(280, 188, False) + '<rect x="271" y="170" width="18" height="18" fill="url(#cromoV)"/>'
    s += silenciador(235, 170) + silenciador(325, 170)
    PIEZAS["valvula_53"] = {
        "tamano": [w, h], "bocas": {"1": [280, 228], "2": [310, 42], "3": [325, 200], "4": [250, 42], "5": [235, 200], "Y1": [131, 86], "Y2": [431, 86]},
        "marcas": {"bobina_y1": [131, 140], "bobina_y2": [431, 140], "manual": [180, 148], "cuerpo": [280, 135], "racor": [250, 56], "silenciador": [235, 188]},
        "etiquetas": [{"texto": "4", "x": 250, "y": 20, "tam": 14}, {"texto": "2", "x": 310, "y": 20, "tam": 14}, {"texto": "1", "x": 280, "y": 252, "tam": 14},
                      {"texto": "5", "x": 211, "y": 206, "tam": 14}, {"texto": "3", "x": 349, "y": 206, "tam": 14},
                      {"texto": "Y1", "x": 131, "y": 136, "tam": 14}, {"texto": "Y2", "x": 431, "y": 136, "tam": 14}],
    }
    return svg(w, h, s, DEFS)


def cilindro_neumatico():
    w, h = 580, 230
    s = sombra_suelo(290, 206, 260, 10)
    # Vástago y tuerca
    s += '<rect x="420" y="104" width="110" height="20" rx="3" fill="url(#cromo)" stroke="#3b4247" stroke-width="1.2"/>'
    s += f'<polygon points="{hexagono(540, 114, 16)}" fill="url(#acero)" stroke="#2d3236" stroke-width="1.2"/>'
    # Tubo de perfil con ranuras
    s += '<rect x="104" y="76" width="300" height="76" rx="3" fill="url(#alu)" stroke="#3b4247" stroke-width="1.6"/>'
    for y in (84, 140):
        s += f'<rect x="112" y="{y}" width="284" height="5" fill="#59636b" opacity="0.7"/>'
    s += brillo(110, 92, 290, 6, 2, 0.4)
    # Culatas negras con tornillos y tornillo de amortiguación
    for x in (66, 402):
        s += f'<rect x="{x}" y="66" width="40" height="96" rx="4" fill="url(#gris)" stroke="#0b0c0d" stroke-width="1.4"/>'
        s += allen(x + 8, 74, 4) + allen(x + 32, 74, 4) + allen(x + 8, 154, 4) + allen(x + 32, 154, 4)
        s += f'<circle cx="{x + 20}" cy="132" r="5" fill="url(#laton)" stroke="#5a4310"/>'
    s += '<rect x="442" y="98" width="10" height="32" rx="2" fill="url(#negro)"/>'
    # Bocas A y B con racor rápido en cada culata
    s += racor_rapido(86, 66) + racor_rapido(422, 66)
    # Detectores magnéticos B1 y B2 en la ranura, con su cable y LED
    for x in (150, 336):
        s += f'<rect x="{x - 14}" y="80" width="28" height="9" rx="2" fill="url(#negro)" stroke="#0b0c0d"/>'
        s += f'<circle cx="{x + 9}" cy="84.5" r="2.4" fill="url(#ledAmbar)"/>'
        s += f'<path d="M{x - 14},84 Q{x - 34},84 {x - 40},52" fill="none" stroke="#1b1e21" stroke-width="3.5"/>'
    s += chapa(200, 112, 110, 24)
    PIEZAS["cilindro_neumatico"] = {
        "tamano": [w, h], "bocas": {"A": [86, 28], "B": [422, 28], "B1": [150, 84], "B2": [336, 84]},
        "marcas": {"culata_trasera": [86, 146], "perfil": [256, 124], "detector": [150, 100], "amortiguacion": [422, 132], "vastago": [480, 114], "tuerca": [540, 114], "rascador": [447, 114]},
        "etiquetas": [{"texto": "A", "x": 86, "y": 8, "tam": 14}, {"texto": "B", "x": 422, "y": 8, "tam": 14},
                      {"texto": "B1", "x": 112, "y": 46, "tam": 13}, {"texto": "B2", "x": 298, "y": 46, "tam": 13}],
    }
    return svg(w, h, s, DEFS)


def regulador_caudal():
    w, h = 380, 300
    s = sombra_suelo(190, 280, 120, 10)
    # Rosca macho abajo, hexágono, anillo banjo giratorio con racor rápido y pomo moleteado arriba
    s += '<rect x="166" y="222" width="48" height="44" rx="3" fill="url(#cromoV)" stroke="#3b4247" stroke-width="1.2"/>'
    for y in range(226, 264, 5):
        s += f'<path d="M166,{y} H214" stroke="#59636a" stroke-width="0.8"/>'
    s += '<rect x="148" y="196" width="84" height="28" rx="3" fill="url(#acero)" stroke="#2d3236" stroke-width="1.3"/>'
    s += '<rect x="138" y="134" width="104" height="62" rx="12" fill="url(#gris)" stroke="#0b0c0d" stroke-width="1.4"/>'
    s += brillo(146, 138, 88, 6, 3, 0.2)
    s += '<rect x="240" y="148" width="36" height="34" rx="3" fill="url(#cromo)" stroke="#3b4247"/>'
    s += '<rect x="274" y="142" width="10" height="46" rx="2" fill="url(#azulRacor)" stroke="#123766"/>'
    s += '<rect x="284" y="152" width="60" height="26" fill="#1f5fa6" opacity="0.85"/>'
    # Símbolo grabado y pomo
    s += '<rect x="166" y="100" width="48" height="36" rx="3" fill="url(#cromoV)" stroke="#3b4247"/>'
    s += f'<polygon points="{hexagono(190, 92, 22, 30)}" fill="url(#acero)" stroke="#2d3236" stroke-width="1.2" transform="scale(1,0.5) translate(0,92)"/>'
    s += '<rect x="170" y="26" width="40" height="58" rx="6" fill="url(#negro)" stroke="#0b0c0d" stroke-width="1.3"/>'
    for x in range(174, 208, 5):
        s += f'<path d="M{x},30 V80" stroke="#4a5257" stroke-width="1.3"/>'
    PIEZAS["regulador_caudal"] = {
        "tamano": [w, h], "bocas": {"1": [340, 165], "2": [190, 262]},
        "marcas": {"pomo": [190, 50], "contratuerca": [190, 92], "cuerpo": [170, 165], "racor_rapido": [300, 165], "rosca": [190, 244], "hexagono": [150, 210]},
        "etiquetas": [{"texto": "1", "x": 346, "y": 140, "tam": 14}, {"texto": "2", "x": 236, "y": 252, "tam": 14}],
    }
    return svg(w, h, s, DEFS)


def actuador_cuarto_vuelta():
    w, h = 500, 320
    s = sombra_suelo(250, 298, 210, 12)
    # Cuerpo de perfil de aluminio y tapas largas (muelles dentro: simple efecto)
    s += '<rect x="110" y="120" width="280" height="110" rx="10" fill="url(#alu)" stroke="#3b4247" stroke-width="1.8"/>'
    s += brillo(118, 126, 264, 8)
    for x in (52, 388):
        s += f'<rect x="{x}" y="112" width="60" height="126" rx="12" fill="url(#gris)" stroke="#0b0c0d" stroke-width="1.5"/>'
        for y in (124, 226):
            s += allen(x + 14, y, 4.5) + allen(x + 46, y, 4.5)
    s += chapa(150, 182, 120, 36)
    # Cara NAMUR con las bocas 2 y 4
    s += '<rect x="290" y="176" width="80" height="46" rx="4" fill="url(#aluH)" stroke="#3b4247"/>'
    s += boca(312, 199, 6) + boca(348, 199, 6)
    # Eje con indicador amarillo arriba
    s += '<rect x="234" y="96" width="32" height="26" fill="url(#cromoV)" stroke="#3b4247"/>'
    s += '<ellipse cx="250" cy="96" rx="44" ry="14" fill="url(#negro)" stroke="#0b0c0d" stroke-width="1.3"/>'
    s += '<path d="M214,92 L286,92 L282,100 L218,100 Z" fill="url(#amarillo)" stroke="#5a4310"/>'
    s += '<rect x="244" y="60" width="12" height="28" fill="url(#cromoV)" stroke="#3b4247"/>'
    PIEZAS["actuador_cuarto_vuelta"] = {
        "tamano": [w, h], "bocas": {"2": [312, 199], "4": [348, 199]},
        "marcas": {"cuerpo": [200, 150], "tapa_muelles": [82, 175], "indicador": [250, 96], "eje": [250, 70], "namur": [330, 182], "chapa": [210, 200]},
        "etiquetas": [{"texto": "2", "x": 312, "y": 248, "tam": 14}, {"texto": "4", "x": 348, "y": 248, "tam": 14}],
    }
    return svg(w, h, s, DEFS)


def posicionador():
    w, h = 420, 330
    s = sombra_suelo(210, 312, 160, 10)
    # Caja con tapa, pantalla, pulsadores y prensaestopas del lazo
    s += '<rect x="90" y="60" width="220" height="200" rx="14" fill="url(#gris)" stroke="#0b0c0d" stroke-width="1.8"/>'
    s += brillo(98, 66, 204, 8, 4, 0.18)
    s += '<rect x="118" y="88" width="120" height="50" rx="5" fill="url(#pantalla)" stroke="#000" stroke-width="1.4"/>'
    for i in range(3):
        s += f'<rect x="{122 + i * 40}" y="156" width="30" height="24" rx="5" fill="url(#negro)" stroke="#0b0c0d"/>'
    s += '<rect x="56" y="100" width="36" height="26" rx="4" fill="url(#cromoV)" stroke="#3b4247"/>'
    s += '<path d="M56,113 C30,113 22,90 6,86" fill="none" stroke="#1d4f8c" stroke-width="8" stroke-linecap="round"/>'
    # Manómetros de alimentación y salida a la derecha, con su bloque
    s += '<rect x="308" y="80" width="30" height="150" rx="4" fill="url(#alu)" stroke="#3b4247"/>'
    s += manometro_frente(366, 110, 22, 0.6) + manometro_frente(366, 190, 22, 0.3)
    s += '<rect x="336" y="104" width="10" height="12" fill="url(#cromo)"/><rect x="336" y="184" width="10" height="12" fill="url(#cromo)"/>'
    # Eje de realimentación abajo hacia el actuador
    s += '<rect x="186" y="260" width="28" height="40" fill="url(#cromoV)" stroke="#3b4247"/>'
    PIEZAS["posicionador"] = {
        "tamano": [w, h], "bocas": {"+": [56, 106], "-": [56, 122], "SUP": [366, 110], "OUT": [366, 190]},
        "marcas": {"pantalla": [178, 113], "pulsadores": [178, 168], "prensaestopas": [74, 113], "alimentacion": [366, 110], "salida": [366, 190], "realimentacion": [200, 280], "tapa": [270, 230]},
        "etiquetas": [{"texto": "50.0 %", "x": 178, "y": 114, "tam": 18, "color": "#9fffb0"}, {"texto": "SUP", "x": 366, "y": 146, "tam": 12}, {"texto": "OUT", "x": 366, "y": 226, "tam": 12}],
    }
    return svg(w, h, s, DEFS)


# ----------------------------------------------------------------------------- símbolos ISO 1219-1 (aire)
def hueco(cx, cy, tam, hacia):
    return triangulo(cx, cy, tam, hacia, "none")


def fuente_sim(cx, cy, r=18):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>' + hueco(cx, cy - 2, 8, (0, -1))


def compresor_sim(cx, cy, r=34):
    s = f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>' + hueco(cx, cy - r + 13, 12, (0, -1))
    s += linea(cx - r - 26, cy - 4, cx - r, cy - 4, 2) + linea(cx - r - 26, cy + 4, cx - r, cy + 4, 2)
    return s


def rombo(cx, cy, a=30):
    return f'<path d="M{cx},{cy - a} L{cx + a},{cy} L{cx},{cy + a} L{cx - a},{cy} Z" fill="none" stroke="{TINTA}" stroke-width="{G}" stroke-linejoin="round"/>'


def filtro_purga_sim(cx, cy, a=30):
    s = rombo(cx, cy, a) + linea(cx - a, cy, cx + a, cy, 2, True)
    s += linea(cx, cy + a, cx, cy + a + 12, 2) + linea(cx - 8, cy + a + 12, cx + 8, cy + a + 12, 2)  # purga manual
    s += triangulo(cx, cy + a - 9, 6, (0, 1))
    return s


def secador_sim(cx, cy, a=30):
    s = rombo(cx, cy, a) + linea(cx - a, cy, cx + a, cy, 2)
    s += triangulo(cx - 9, cy + 12, 6, (0, 1)) + triangulo(cx + 9, cy + 12, 6, (0, 1))
    return s


def lubricador_sim(cx, cy, a=30):
    return rombo(cx, cy, a) + linea(cx, cy + a - 4, cx, cy - 8, 2) + linea(cx - 8, cy - 8, cx + 8, cy - 8, 2)


def regulador_presion_sim(cx, cy):
    """Reductora con escape (alivio secundario): flecha alineada, muelle ajustable, piloto desde la salida."""
    a = 34
    s = f'<rect x="{cx - a}" y="{cy - a}" width="{2 * a}" height="{2 * a}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
    s += linea(cx, cy + a - 6, cx, cy - a + 14, 2.4) + hueco(cx, cy - a + 10, 9, (0, -1))
    s += linea(cx + 14, cy - 6, cx + 14, cy + a, 2) + hueco(cx + 14, cy + a + 6, 6, (0, 1))
    s += muelle(cx + a, cy, cx + a + 36, cy, 4, 8) + linea(cx + a + 8, cy + 14, cx + a + 30, cy - 14, 2) + triangulo(cx + a + 30, cy - 14, 7, (0.63, -0.77))
    s += polilinea([(cx, cy - a - 16), (cx - a - 16, cy - a - 16), (cx - a - 16, cy), (cx - a, cy)], 2, True)
    return s


def solenoide(xs, cy):
    return f'<rect x="{xs}" y="{cy - 12}" width="24" height="24" fill="none" stroke="{TINTA}" stroke-width="2.4"/>' + linea(xs + 4, cy + 10, xs + 20, cy - 10, 2)


def escape(x, y):
    return hueco(x, y + 6, 6, (0, 1))


def casilla(x, cy, c):
    return f'<rect x="{x}" y="{cy - c / 2}" width="{c}" height="{c}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'


def tapon(x, y, arriba=True):
    d = 1 if arriba else -1
    return linea(x, y, x, y + 9 * d, 2.2) + linea(x - 6, y + 9 * d, x + 6, y + 9 * d, 2.2)


def via(x1, y1, x2, y2):
    """Paso por dentro de una casilla, con flecha hueca en el extremo 2."""
    dx, dy = x2 - x1, y2 - y1
    l = math.hypot(dx, dy)
    ux, uy = dx / l, dy / l
    return linea(x1, y1, x2 - ux * 6, y2 - uy * 6, 2.2) + hueco(x2 - ux * 8, y2 - uy * 8, 7, (ux, uy))


def valvula_32_sim(cx, cy, c=44):
    """3/2 normalmente cerrada, solenoide y retorno por muelle. Abajo 1 (presión) y 3 (escape), arriba 2."""
    x0 = cx - c
    s = casilla(x0, cy, c) + casilla(x0 + c, cy, c)
    a, b = 0.3 * c, 0.7 * c
    # Casilla izquierda (bobina activa): 1→2
    s += via(x0 + a, cy + c / 2, x0 + a, cy - c / 2) + tapon(x0 + b, cy + c / 2, False)
    # Casilla derecha (reposo): 2→3 y 1 cerrada
    s += tapon(x0 + c + a, cy + c / 2, False) + via(x0 + c + a, cy - c / 2, x0 + c + b, cy + c / 2)
    s += solenoide(x0 - 24, cy) + muelle(x0 + 2 * c, cy, x0 + 2 * c + 30, cy, 3, 7)
    return s


def valvula_52_sim(cx, cy, c=44):
    """5/2 monoestable: arriba 4 y 2, abajo 5, 1 y 3."""
    x0 = cx - c
    s = casilla(x0, cy, c) + casilla(x0 + c, cy, c)
    # Izquierda (Y1): 1→4, 2→3
    x = x0
    s += via(x + c / 2, cy + c / 2, x + 0.25 * c, cy - c / 2) + via(x + 0.75 * c, cy - c / 2, x + 0.85 * c, cy + c / 2)
    s += tapon(x + 0.15 * c, cy + c / 2, False)
    # Derecha (reposo): 1→2, 4→5
    x = x0 + c
    s += via(x + c / 2, cy + c / 2, x + 0.75 * c, cy - c / 2) + via(x + 0.25 * c, cy - c / 2, x + 0.15 * c, cy + c / 2)
    s += tapon(x + 0.85 * c, cy + c / 2, False)
    s += solenoide(x0 - 24, cy) + muelle(x0 + 2 * c, cy, x0 + 2 * c + 30, cy, 3, 7)
    return s


def valvula_53_sim(cx, cy, c=40):
    x0 = cx - 1.5 * c
    s = casilla(x0, cy, c) + casilla(x0 + c, cy, c) + casilla(x0 + 2 * c, cy, c)
    x = x0
    s += via(x + c / 2, cy + c / 2, x + 0.25 * c, cy - c / 2) + via(x + 0.75 * c, cy - c / 2, x + 0.85 * c, cy + c / 2)
    x = x0 + c
    for xx in (x + 0.25 * c, x + 0.75 * c):
        s += tapon(xx, cy - c / 2, True)
    for xx in (x + 0.15 * c, x + 0.5 * c, x + 0.85 * c):
        s += tapon(xx, cy + c / 2, False)
    x = x0 + 2 * c
    s += via(x + c / 2, cy + c / 2, x + 0.75 * c, cy - c / 2) + via(x + 0.25 * c, cy - c / 2, x + 0.15 * c, cy + c / 2)
    s += solenoide(x0 - 24, cy) + muelle(x0 - 54, cy, x0 - 24, cy, 3, 7)
    s += solenoide(x0 + 3 * c, cy) + muelle(x0 + 3 * c + 24, cy, x0 + 3 * c + 54, cy, 3, 7)
    return s


def cilindro_amortiguado_sim(x, y, w=150, h=46, vastago=46):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
    xp = x + w * 0.4
    s += linea(xp, y, xp, y + h) + linea(xp, y + h / 2, x + w + vastago, y + h / 2, 4)
    # Amortiguación regulable en los dos extremos
    s += f'<rect x="{xp - 18}" y="{y + h / 2 - 7}" width="18" height="14" fill="none" stroke="{TINTA}" stroke-width="2"/>'
    s += f'<rect x="{xp}" y="{y + h / 2 - 7}" width="18" height="14" fill="none" stroke="{TINTA}" stroke-width="2"/>'
    s += linea(x + 6, y + h - 4, x + 30, y + 6, 1.6) + triangulo(x + 30, y + 6, 6, (0.7, -0.7))
    s += linea(x + w - 30, y + h - 4, x + w - 6, y + 6, 1.6) + triangulo(x + w - 6, y + 6, 6, (0.7, -0.7))
    return s


def regulador_caudal_sim(cx, cy):
    s = estrangulador_sim(cx, cy) + linea(cx, cy - 80, cx, cy - 23) + linea(cx, cy + 23, cx, cy + 80)
    s += polilinea([(cx, cy - 56), (cx + 70, cy - 56), (cx + 70, cy - 14)]) + antirretorno_sim(cx + 70, cy, 11, False) + polilinea([(cx + 70, cy + 14), (cx + 70, cy + 56), (cx, cy + 56)])
    s += f'<rect x="{cx - 36}" y="{cy - 70}" width="136" height="140" fill="none" stroke="{TINTA}" stroke-width="1.6" stroke-dasharray="5 4"/>'
    return s


def silenciador_sim(cx, cy):
    s = linea(cx, cy - 70, cx, cy - 22)
    s += f'<rect x="{cx - 26}" y="{cy - 22}" width="52" height="40" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
    for k in range(-14, 16, 8):
        s += linea(cx + k - 6, cy + 14, cx + k + 6, cy - 18, 1.6)
    return s


def actuador_giratorio_sim(cx, cy, r=34):
    s = f'<path d="M{cx},{cy - r} A{r},{r} 0 0 1 {cx},{cy + r} Z" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
    s += hueco(cx + 10, cy, 9, (1, 0))
    s += f'<path d="M{cx + r + 12},{cy - 22} A26,26 0 0 1 {cx + r + 12},{cy + 22}" fill="none" stroke="{TINTA}" stroke-width="2"/>'
    s += triangulo(cx + r + 11, cy - 24, 7, (-0.6, -0.8)) + triangulo(cx + r + 11, cy + 24, 7, (-0.6, 0.8))
    s += linea(cx - 50, cy, cx, cy) + muelle(cx - 20, cy - 26, cx - 20, cy + 26, 3, 6)
    return s


def presostato_sim(cx, cy):
    s = f'<rect x="{cx - 30}" y="{cy - 30}" width="60" height="60" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
    s += linea(cx - 14, cy + 12, cx + 14, cy - 12, 2.2) + f'<circle cx="{cx - 14}" cy="{cy + 12}" r="3" fill="{TINTA}"/>' + linea(cx + 14, cy + 12, cx + 22, cy + 12, 2)
    s += polilinea([(cx - 30, cy), (cx - 54, cy), (cx - 54, cy + 70)], 2, True)
    s += muelle(cx + 30, cy - 16, cx + 64, cy - 16, 3, 6) + linea(cx + 36, cy - 4, cx + 58, cy - 28, 1.6)
    return s


def frl_sim(cx, cy, largo=110):
    """Unidad de mantenimiento: filtro, regulador con manómetro y lubricador en un recuadro de trazos."""
    s = f'<rect x="{cx - 70}" y="{cy - 40}" width="140" height="80" fill="none" stroke="{TINTA}" stroke-width="1.6" stroke-dasharray="6 4"/>'
    s += rombo(cx - 44, cy, 18) + linea(cx - 62, cy, cx - 26, cy, 1.6, True)
    s += f'<rect x="{cx - 14}" y="{cy - 14}" width="28" height="28" fill="none" stroke="{TINTA}" stroke-width="2.2"/>' + linea(cx, cy + 10, cx, cy - 4, 1.8) + hueco(cx, cy - 7, 5, (0, -1))
    s += rombo(cx + 44, cy, 18) + linea(cx + 44, cy + 12, cx + 44, cy - 4, 1.6)
    s += linea(cx - largo, cy, cx - 62, cy) + linea(cx - 26, cy, cx - 14, cy) + linea(cx + 14, cy, cx + 26, cy) + linea(cx + 62, cy, cx + largo, cy)
    s += linea(cx, cy - 14, cx, cy - 26, 1.8) + manometro_sim(cx, cy - 34, 8)
    return s


def posicionador_sim(cx, cy):
    s = f'<rect x="{cx - 40}" y="{cy - 30}" width="80" height="60" fill="none" stroke="{TINTA}" stroke-width="{G}"/>'
    s += linea(cx - 40, cy + 30, cx + 40, cy - 30, 1.6)
    s += polilinea([(cx - 100, cy), (cx - 40, cy)], 2, True)  # señal eléctrica, a trazos
    s += linea(cx, cy + 30, cx, cy + 74) + linea(cx + 40, cy, cx + 90, cy)
    return s


SIMBOLOS = {
    "fuente_aire": (lambda: fuente_sim(120, 100, 26) + linea(120, 74, 120, 24), []),
    "compresor": (lambda: compresor_sim(130, 104) + linea(130, 70, 130, 22), []),
    "secador": (lambda: secador_sim(120, 100) + linea(60, 100, 90, 100) + linea(150, 100, 180, 100), []),
    "filtro_purga": (lambda: filtro_purga_sim(120, 92) + linea(60, 92, 90, 92) + linea(150, 92, 180, 92), []),
    "lubricador": (lambda: lubricador_sim(120, 100) + linea(60, 100, 90, 100) + linea(150, 100, 180, 100), []),
    "regulador_presion": (lambda: regulador_presion_sim(104, 104) + linea(104, 138, 104, 186) + linea(104, 70, 104, 18), []),
    "unidad_frl": (lambda: frl_sim(120, 110), []),
    "valvula_32": (lambda: _sim_valvula(valvula_32_sim, 120, 100, 56, arriba=[0.3], abajo=[0.3], escapes=[0.7]), []),
    "valvula_52": (lambda: _sim_valvula(valvula_52_sim, 120, 100, 56, arriba=[0.25, 0.75], abajo=[0.5], escapes=[0.15, 0.85]), []),
    "valvula_53": (lambda: _sim_valvula(valvula_53_sim, 120, 100, 44, arriba=[0.25, 0.75], abajo=[0.5], escapes=[0.15, 0.85], casillas=3), []),
    "cilindro_amortiguado": (lambda: cilindro_amortiguado_sim(24, 70) + linea(44, 116, 44, 160) + linea(154, 116, 154, 160), []),
    "regulador_caudal": (lambda: regulador_caudal_sim(90, 100), []),
    "silenciador": (lambda: silenciador_sim(120, 120), []),
    "actuador_giratorio": (lambda: actuador_giratorio_sim(120, 100), []),
    "presostato": (lambda: presostato_sim(110, 80), []),
    "posicionador": (lambda: posicionador_sim(130, 90), [{"texto": "I/P", "x": 130, "y": 90, "tam": 20}]),
}


def _sim_valvula(dibujo, cx, cy, c, arriba, abajo, escapes, casillas=2):
    """Válvula con sus líneas exteriores en la casilla de reposo (la del muelle, o la central)."""
    s = dibujo(cx, cy, c)
    x = cx if casillas == 2 else cx - c / 2
    for f in arriba:
        s += linea(x + f * c, cy - c / 2, x + f * c, cy - c / 2 - 50)
    for f in abajo:
        s += linea(x + f * c, cy + c / 2, x + f * c, cy + c / 2 + 50)
    for f in escapes:
        s += linea(x + f * c, cy + c / 2, x + f * c, cy + c / 2 + 16) + escape(x + f * c, cy + c / 2 + 16)
    return s


def simbolo_svg(id_):
    return svg(240, 200, SIMBOLOS[id_][0](), "")


# ----------------------------------------------------------------------------- esquemas de «Conexión»
ESQUEMAS = {}


def _base_aire(con_secador=False):
    """Fuente, (secador) y unidad FRL a lo largo de y=250; devuelve el extremo de la línea regulada."""
    s = fuente_sim(30, 250, 14) + linea(44, 250, 60, 250)
    x = 60
    if con_secador:
        s += secador_sim(86, 250, 22) + linea(108, 250, 124, 250)
        x = 124
    s += frl_sim(x + 80, 250, 80)
    return s, (x + 160, 250)


def esquema_valvulas(foco):
    s, (xr, yr) = _base_aire()
    bornes = {}
    if foco == "valvula_53":
        s += valvula_53_sim(290, 196, 32)
        c = 32
        xc = 290 - c / 2
        p1, p4, p2 = (290, 196 + c / 2), (xc + 0.25 * c, 196 - c / 2), (xc + 0.75 * c, 196 - c / 2)
        s += polilinea([(xr, yr), (p1[0], yr), p1]) + escape(xc + 0.15 * c, 196 + c / 2) + escape(xc + 0.85 * c, 196 + c / 2)
        s += resalte(184, 170, 212, 52)
        bornes = {"1": [p1[0], 216], "4": [p4[0], 176], "2": [p2[0], 176], "Y1": [230, 196], "Y2": [350, 196]}
    else:
        c = 40
        s += valvula_52_sim(290, 196, c)
        p1 = (290 + 0.5 * c, 196 + c / 2)
        p4, p2 = (290 + 0.25 * c, 196 - c / 2), (290 + 0.75 * c, 196 - c / 2)
        p5, p3 = (290 + 0.15 * c, 196 + c / 2), (290 + 0.85 * c, 196 + c / 2)
        s += polilinea([(xr, yr), (p1[0], yr), p1]) + escape(p5[0], 211) + escape(p3[0], 211)
        if foco == "valvula_52":
            s += resalte(220, 168, 146, 58)
            bornes = {"1": [p1[0], 220], "4": [p4[0], 172], "2": [p2[0], 172], "5": [p5[0], 228], "3": [p3[0], 228], "Y1": [238, 196]}
    # Cilindro arriba, con un regulador de caudal en cada boca
    s += cilindro_amortiguado_sim(220, 30, 120, 34, 30)
    xa, xb = 236, 324
    s += polilinea([(p4[0], p4[1]), (p4[0], 150), (xa, 150), (xa, 130)]) + polilinea([(p2[0], p2[1]), (p2[0], 140), (xb, 140), (xb, 130)])
    for x in (xa, xb):
        s += estrangulador_sim(x, 108, True, 26) + linea(x, 95, x, 64)
    if foco == "cilindro_neumatico":
        s += resalte(208, 18, 190, 58)
        bornes = {"A": [xa, 70], "B": [xb, 70], "B1": [244, 26], "B2": [318, 26]}
        s += f'<rect x="236" y="22" width="14" height="8" fill="{TINTA}"/><rect x="312" y="22" width="14" height="8" fill="{TINTA}"/>'
    if foco == "regulador_caudal":
        s += resalte(212, 84, 48, 48) + resalte(300, 84, 48, 48)
        bornes = {"1": [xb, 126], "2": [xb, 90]}
    return s, bornes


def esquema_aire(foco):
    s, (xr, yr) = _base_aire(con_secador=True)
    s += linea(xr, yr, 380, yr)
    bornes = {}
    if foco == "secador_frigorifico":
        s += resalte(62, 222, 48, 56)
        bornes = {"IN": [64, 250], "OUT": [108, 250], "DR": [86, 274]}
    else:
        s += resalte(122, 206, 144, 88)
        bornes = {"1": [124, 250], "2": [264, 250]}
    # Consumidores aguas abajo
    s += linea(330, 250, 330, 160) + valvula_52_sim(330, 130, 26) + linea(318, 117, 318, 70) + linea(344, 117, 344, 70)
    s += f'<rect x="300" y="30" width="80" height="40" fill="none" stroke="{TINTA}" stroke-width="2.4"/>'
    return s, bornes


def esquema_posicionador(foco):
    s, (xr, yr) = _base_aire()
    s += polilinea([(xr, yr), (300, yr), (300, 214)])
    s += posicionador_sim(300, 184)
    s += actuador_giratorio_sim(300, 90, 26)
    s += polilinea([(300, 154), (300, 140), (250, 140), (250, 90), (274, 90)])
    s += linea(340, 184, 372, 184, 2) + linea(372, 184, 372, 90, 2) + linea(372, 90, 348, 90, 2)  # realimentación mecánica
    s += polilinea([(200, 184), (130, 184)], 2, True)
    if foco == "posicionador":
        s += resalte(254, 148, 92, 72)
        bornes = {"+": [200, 184], "SUP": [300, 222], "OUT": [300, 150]}
    else:
        s += resalte(236, 54, 112, 74)
        bornes = {"2": [262, 90], "4": [330, 118]}
    return s, bornes


def esquema(id_):
    if id_ in ("valvula_52", "valvula_53", "cilindro_neumatico", "regulador_caudal"):
        cuerpo, bornes = esquema_valvulas(id_)
    elif id_ in ("unidad_fr", "secador_frigorifico"):
        cuerpo, bornes = esquema_aire(id_)
    else:
        cuerpo, bornes = esquema_posicionador(id_)
    ESQUEMAS[id_] = bornes
    return svg(400, 290, cuerpo, "")


FUNCIONES = [unidad_fr, secador_frigorifico, valvula_52, valvula_53, cilindro_neumatico, regulador_caudal, actuador_cuarto_vuelta, posicionador]


def generar():
    for f in FUNCIONES:
        escribir(f"art/equipos/{f.__name__}.svg", f())
        escribir(f"art/esquemas/atlas_{f.__name__}.svg", esquema(f.__name__))
    for id_ in SIMBOLOS:
        escribir(f"art/simbolos/iso1219/{id_}.svg", simbolo_svg(id_))


if __name__ == "__main__":
    generar()
    import json
    print(json.dumps({"esquemas": ESQUEMAS}, ensure_ascii=False))
