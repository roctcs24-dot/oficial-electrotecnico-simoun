"""Fondo realista del frente de cada tablero (data/tableros/<id>.json): la chapa de acero inoxidable
cepillado o pintada, los bordes doblados, los tornillos, los rótulos grabados y los recuadros, más una
sombra bajo cada luz, pulsador, selector y seta. VistaTablero dibuja encima, en vivo, lo que se mueve.

Uso, desde la raíz del repositorio:
    python tools/dibujos_realistas/tableros.py            # todos
    python tools/dibujos_realistas/tableros.py bombas_mp  # uno
Escribe art/realista/tableros/<id>.webp con el mismo encuadre que frente.tamano."""
import glob, html, json, os, subprocess, sys

AQUI = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(AQUI))
sys.path.insert(0, AQUI)
import comun as C
import realzar as R

ESCALA = 1.25
ACABADOS = {"inox": ("#c3c8cb", "#a9afb3", "#7d8488"), "gris": ("#c9cbc6", "#b9bbb6", "#8c8e8a"), "blanco": ("#e6e4dc", "#d8d6ce", "#a6a49c")}
REDONDOS = ("luz", "pulsador", "selector", "seta")


def tornillo(x, y, r=9):
    return (f'<g filter="url(#biselFuerte)"><circle cx="{x}" cy="{y}" r="{r}" fill="url(#acero)"/></g>'
            f'<path d="M{x - r * .55},{y} H{x + r * .55} M{x},{y - r * .55} V{y + r * .55}" stroke="#3a3e41" stroke-width="{r * .28:.1f}" stroke-linecap="round"/>')


def fondo(datos):
    fr = datos["frente"]
    w, h = fr["tamano"]
    acabado = fr.get("acabado", "inox")
    claro, medio, borde = ACABADOS.get(acabado, ACABADOS["inox"])
    s = ['<defs>' + C.FILTROS + f'''
<radialGradient id="acero" cx="0.36" cy="0.3" r="0.85"><stop offset="0" stop-color="#ffffff"/><stop offset="0.45" stop-color="#c3c8cb"/><stop offset="1" stop-color="#5a6064"/></radialGradient>
<linearGradient id="chapa" x1="0" y1="0" x2="0.25" y2="1"><stop offset="0" stop-color="{claro}"/><stop offset="0.55" stop-color="{medio}"/><stop offset="1" stop-color="{claro}"/></linearGradient>
<linearGradient id="suciedad" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.12"/><stop offset="0.2" stop-color="#fff" stop-opacity="0"/><stop offset="0.75" stop-color="#3a2a10" stop-opacity="0"/><stop offset="1" stop-color="#3a2a10" stop-opacity="0.16"/></linearGradient>
<radialGradient id="ao" cx="0.5" cy="0.5" r="0.5"><stop offset="0.55" stop-color="#000" stop-opacity="0.55"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>
</defs>''']
    # Chapa con el borde doblado
    s.append(f'<g filter="url(#biselFuerte)"><rect x="0" y="0" width="{w}" height="{h}" rx="6" fill="{borde}"/></g>')
    textura = "cepillado" if acabado == "inox" else "plastico"
    s.append(f'<g filter="url(#{textura})"><rect x="14" y="14" width="{w - 28}" height="{h - 28}" rx="3" fill="url(#chapa)"/></g>')
    s.append(f'<rect x="14" y="14" width="{w - 28}" height="{h - 28}" rx="3" fill="url(#suciedad)"/>')
    s.append(f'<rect x="14.5" y="14.5" width="{w - 29}" height="{h - 29}" rx="3" fill="none" stroke="#000" stroke-opacity="0.35" stroke-width="2"/>')
    s.append(f'<path d="M16,15.5 H{w - 16}" stroke="#fff" stroke-opacity="0.7" stroke-width="1.5"/>')
    for x, y in ((34, 34), (w - 34, 34), (34, h - 34), (w - 34, h - 34)):
        s.append(tornillo(x, y))
    for e in fr["elementos"]:
        x, y = e.get("x", 0), e.get("y", 0)
        if e["tipo"] == "recuadro":
            a, b = e["ancho"], e["alto"]
            s.append(f'<g filter="url(#bisel)"><rect x="{x - a / 2 - 3}" y="{y - b / 2 - 3}" width="{a + 6}" height="{b + 6}" rx="3" fill="#8a9094"/></g>')
            s.append(f'<rect x="{x - a / 2}" y="{y - b / 2}" width="{a}" height="{b}" fill="{e.get("color", "#1b1d1f")}"/>')
            s.append(f'<rect x="{x - a / 2}" y="{y - b / 2}" width="{a}" height="10" fill="#000" opacity="0.4"/>')
        elif e["tipo"] in REDONDOS:
            # Sombra de contacto del aparato sobre la chapa
            s.append(f'<circle cx="{x + 2}" cy="{y + 5}" r="46" fill="url(#ao)"/>')
    svg = "".join(s)
    # Rótulos grabados en placas de plástico laminado, encima del SVG
    capas = ""
    for e in fr["elementos"]:
        if e["tipo"] != "rotulo":
            continue
        tam = float(e.get("tam", 16))
        fondo_c = e.get("fondo", "#f4f4f0")
        tinta = e.get("tinta", "#15171a")
        texto = "<br>".join(html.escape(l) for l in str(e["texto"]).split("\n"))
        capas += (f'<div style="position:absolute;left:{e["x"]}px;top:{e["y"]}px;transform:translate(-50%,-50%);white-space:nowrap;'
                  f'font:500 {tam}px Plex;line-height:1.31;text-align:center;color:{tinta};padding:{tam * .15:.1f}px {tam * .4:.1f}px;'
                  f'background:linear-gradient({fondo_c},{fondo_c} 60%,rgba(0,0,0,.06)),{fondo_c};border:{max(1, tam * .06):.1f}px solid #2a2c2e;border-radius:2px;'
                  f'box-shadow:0 2px 3px rgba(0,0,0,.45),inset 0 1px 0 rgba(255,255,255,.7),inset 0 -1px 0 rgba(0,0,0,.18);'
                  f'text-shadow:0 1px 0 rgba(255,255,255,.35)">{texto}</div>')
    return w, h, svg, capas


def render(id_, w, h, svg, capas):
    os.makedirs(R.TEMPORAL, exist_ok=True)
    doc = (f'<!doctype html><html><head><meta charset="utf-8"><style>@font-face{{font-family:Plex;src:url("{C.FUENTE}")}}'
           f'html,body{{margin:0;padding:0;background:transparent;width:{w}px;height:{h}px;overflow:hidden;position:relative}}</style></head><body>'
           f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{w}" height="{h}" viewBox="0 0 {w} {h}" style="position:absolute;left:0;top:0">{svg}</svg>'
           f'{capas}</body></html>')
    ruta = os.path.join(R.TEMPORAL, "tablero_" + id_ + ".html")
    open(ruta, "w", encoding="utf-8").write(doc)
    png = os.path.join(R.TEMPORAL, "tablero_" + id_ + ".png")
    subprocess.run([C.CH, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                    "--default-background-color=00000000", "--user-data-dir=" + os.path.join(R.TEMPORAL, "perfil"),
                    f"--force-device-scale-factor={ESCALA}", f"--window-size={w},{h}", "--screenshot=" + png,
                    "file:///" + ruta.replace("\\", "/")], timeout=120, capture_output=True)
    print(png, os.path.exists(png))
    return png


def main(ids):
    lista = []
    for f in sorted(glob.glob(os.path.join(REPO, "data", "tableros", "*.json"))):
        datos = json.load(open(f, encoding="utf-8"))
        if ids and datos["id"] not in ids:
            continue
        png = render(datos["id"], *fondo(datos))
        destino = os.path.join(REPO, "art", "realista", "tableros", datos["id"] + ".webp")
        os.makedirs(os.path.dirname(destino), exist_ok=True)
        lista += [png, destino]
    subprocess.run([R.GODOT, "--headless", "--path", REPO, "--script", os.path.join(AQUI, "a_webp.gd"), "--"] + lista, check=True)


if __name__ == "__main__":
    main(sys.argv[1:])
