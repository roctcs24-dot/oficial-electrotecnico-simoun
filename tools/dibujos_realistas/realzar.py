"""Prepara los dibujos realistas de los equipos: imágenes WebP en art/realista/, con el mismo encuadre
que su SVG, que el juego muestra en lugar del SVG (VistaSvg). Godot solo dibuja degradados en un SVG;
aquí Chrome añade texturas, relieve con luz y sombras difuminadas.

Uso, desde la raíz del repositorio:
    python tools/dibujos_realistas/realzar.py electricidad          # la tanda del módulo 7
    python tools/dibujos_realistas/realzar.py todas                 # los dibujos de todas las fichas
    python tools/dibujos_realistas/realzar.py faltan                # solo los que aún no tienen imagen
    python tools/dibujos_realistas/realzar.py art/equipos/rele_termico.svg ...

Un dibujo con guion propio en a_mano/<nombre>.py (ANCHO, ALTO y CUERPO) se toma de allí; los demás
reciben el acabado automático sobre su SVG: relieve en cada pieza, textura fina y sombra.
Necesita Chrome y Godot 4.7.2 en sus rutas de siempre."""
import importlib, json, os, subprocess, sys
import xml.etree.ElementTree as ET

AQUI = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(AQUI))
sys.path.insert(0, AQUI)
import comun as C

SVG = "http://www.w3.org/2000/svg"
XLINK = "http://www.w3.org/1999/xlink"
ET.register_namespace("", SVG)
ET.register_namespace("xlink", XLINK)
ESCALA = 2.0
GODOT = os.path.join(os.environ.get("LOCALAPPDATA", ""), "Programs", "Godot", "Godot_v4.7.2-stable_win64_console.exe")
TEMPORAL = os.path.join(REPO, "build", "dibujos_realistas")

FILTROS_AUTO = '''
<filter id="rz_bisel" x="-8%" y="-8%" width="116%" height="116%">
 <feGaussianBlur in="SourceAlpha" stdDeviation="1.5" result="b"/>
 <feSpecularLighting in="b" surfaceScale="3" specularConstant="0.8" specularExponent="20" lighting-color="#ffffff" result="s">
  <feDistantLight azimuth="235" elevation="42"/></feSpecularLighting>
 <feComposite in="s" in2="SourceAlpha" operator="in" result="s2"/>
 <feDiffuseLighting in="b" surfaceScale="3" diffuseConstant="1" lighting-color="#ffffff" result="d"><feDistantLight azimuth="235" elevation="55"/></feDiffuseLighting>
 <feComposite in="SourceGraphic" in2="d" operator="arithmetic" k1="1.08" k2="0" k3="0" k4="0" result="m"/>
 <feComposite in="m" in2="SourceAlpha" operator="in" result="m2"/>
 <feComposite in="m2" in2="s2" operator="arithmetic" k1="0" k2="1" k3="0.42" k4="0"/>
</filter>
<filter id="rz_textura" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="1.4" numOctaves="2" seed="5" result="n"/>
 <feDiffuseLighting in="n" surfaceScale="0.55" diffuseConstant="1.03" lighting-color="#ffffff" result="l"><feDistantLight azimuth="235" elevation="60"/></feDiffuseLighting>
 <feComposite in="SourceGraphic" in2="l" operator="arithmetic" k1="1.02" k2="0" k3="0" k4="0" result="m"/>
 <feComposite in="m" in2="SourceAlpha" operator="in"/>
</filter>
<filter id="rz_sombra" x="-10%" y="-10%" width="120%" height="125%">
 <feGaussianBlur in="SourceAlpha" stdDeviation="5" result="b"/>
 <feOffset in="b" dx="1.5" dy="5" result="o"/>
 <feFlood flood-color="#000" flood-opacity="0.55"/>
 <feComposite in2="o" operator="in"/>
</filter>
'''


def _local(etiqueta):
    return etiqueta.split("}")[-1]


def _lleva_relieve(e):
    """Piezas rellenas que no son sombras ni trazos sueltos."""
    if _local(e.tag) in ("defs", "text", "line", "polyline", "title", "desc", "style"):
        return False
    if e.get("filter"):
        return False
    if e.get("fill") == "none" and _local(e.tag) not in ("g", "use"):
        return False
    for clave in ("opacity", "fill-opacity"):
        try:
            if float(e.get(clave, "1")) < 0.6:
                return False
        except ValueError:
            pass
    return True


def automatico(ruta_svg):
    raiz = ET.parse(ruta_svg).getroot()
    caja = [float(v) for v in raiz.get("viewBox", "0 0 %s %s" % (raiz.get("width"), raiz.get("height"))).replace(",", " ").split()]
    ancho, alto = caja[2], caja[3]
    defs = ""
    piezas = ""
    for e in list(raiz):
        if _local(e.tag) == "defs":
            defs += "".join(ET.tostring(h, encoding="unicode") for h in e)
            continue
        if _lleva_relieve(e):
            e.set("filter", "url(#rz_bisel)")
        piezas += ET.tostring(e, encoding="unicode")
    cuerpo = (f'<defs>{FILTROS_AUTO}{defs}<g id="rz_todo">{piezas}</g></defs>'
              '<use xlink:href="#rz_todo" filter="url(#rz_sombra)"/>'
              '<g filter="url(#rz_textura)"><use xlink:href="#rz_todo"/></g>')
    # ElementTree escribe el espacio de nombres en cada elemento; el SVG en línea no lo necesita.
    cuerpo = cuerpo.replace(f' xmlns="{SVG}"', "").replace(f' xmlns:xlink="{XLINK}"', "")
    return ancho, alto, cuerpo


def preparar(relativa):
    """relativa: art/equipos/<nombre>.svg. Devuelve la ruta del WebP escrito."""
    nombre = os.path.splitext(os.path.basename(relativa))[0]
    if os.path.exists(os.path.join(AQUI, "a_mano", nombre + ".py")):
        m = importlib.import_module("a_mano." + nombre)
        ancho, alto, cuerpo = m.ANCHO, m.ALTO, m.CUERPO
    else:
        ancho, alto, cuerpo = automatico(os.path.join(REPO, relativa))
    os.makedirs(TEMPORAL, exist_ok=True)
    png = C.render(nombre, int(ancho), int(alto), cuerpo, ESCALA, TEMPORAL)
    destino = os.path.join(REPO, "art", "realista", os.path.splitext(relativa[len("art/"):])[0] + ".webp")
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    return png, destino


def tanda_electricidad():
    sistemas = json.load(open(os.path.join(REPO, "data", "sistemas.json"), encoding="utf-8"))
    modulo = [s for s in sistemas["escuela"] if s["id"] == 7][0]
    rutas = []
    for i in modulo["modos"]["aprender"]["atlas"]:
        a = json.load(open(os.path.join(REPO, "data", "atlas", i + ".json"), encoding="utf-8"))
        ficha = json.load(open(os.path.join(REPO, "data", "fichas", a.get("ficha", i) + ".json"), encoding="utf-8"))
        for d in [ficha["dibujo"]] + ficha.get("dibujos_extra", []):
            r = d["svg"].replace("res://", "")
            if r not in rutas:
                rutas.append(r)
    return rutas


def todas():
    """Los dibujos de todas las fichas, con sus dibujos extra."""
    rutas = []
    carpeta = os.path.join(REPO, "data", "fichas")
    for f in sorted(os.listdir(carpeta)):
        if f.endswith(".json"):
            ficha = json.load(open(os.path.join(carpeta, f), encoding="utf-8"))
            for d in [ficha["dibujo"]] + ficha.get("dibujos_extra", []):
                r = d["svg"].replace("res://", "")
                if r not in rutas:
                    rutas.append(r)
    return rutas


def main(argumentos):
    rutas = []
    for x in argumentos:
        if x == "electricidad":
            rutas += tanda_electricidad()
        elif x == "todas":
            rutas += todas()
        elif x == "faltan":
            rutas += [r for r in todas() if not os.path.exists(os.path.join(REPO, "art", "realista", os.path.splitext(r[len("art/"):])[0] + ".webp"))]
        else:
            rutas.append(x.replace("\\", "/"))
    pares = [preparar(r) for r in rutas]
    # Godot pasa los PNG a WebP con pérdida: unos 100 KB por dibujo.
    lista = []
    for png, destino in pares:
        lista += [png, destino]
    subprocess.run([GODOT, "--headless", "--path", REPO, "--script", os.path.join(AQUI, "a_webp.gd"), "--"] + lista, check=True)
    print("%d dibujos en art/realista/" % len(pares))


if __name__ == "__main__":
    main(sys.argv[1:])
