"""Piezas comunes de los dibujos realistas (tools/dibujos_realistas): filtros de textura, relieve y sombra, y el render con
Chrome a PNG transparente. Estos dibujos se preparan fuera del juego y se guardan como imagen."""
import os, subprocess

AQUI = os.path.dirname(os.path.abspath(__file__))
CH = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
FUENTE = "file:///C:/Users/Jonathan/Documents/oficial-electrotecnico-simoun/art/fuentes/IBMPlexSans.ttf"

FILTROS = '''
<filter id="bisel" x="-10%" y="-10%" width="120%" height="120%">
 <feGaussianBlur in="SourceAlpha" stdDeviation="1.6" result="b"/>
 <feSpecularLighting in="b" surfaceScale="3" specularConstant="0.9" specularExponent="22" lighting-color="#ffffff" result="s">
  <feDistantLight azimuth="235" elevation="42"/></feSpecularLighting>
 <feComposite in="s" in2="SourceAlpha" operator="in" result="s2"/>
 <feComposite in="SourceGraphic" in2="s2" operator="arithmetic" k1="0" k2="1" k3="0.55" k4="0"/>
</filter>
<filter id="biselFuerte" x="-10%" y="-10%" width="120%" height="120%">
 <feGaussianBlur in="SourceAlpha" stdDeviation="2.4" result="b"/>
 <feSpecularLighting in="b" surfaceScale="5" specularConstant="1.1" specularExponent="18" lighting-color="#ffffff" result="s">
  <feDistantLight azimuth="235" elevation="38"/></feSpecularLighting>
 <feComposite in="s" in2="SourceAlpha" operator="in" result="s2"/>
 <feDiffuseLighting in="b" surfaceScale="5" diffuseConstant="1" lighting-color="#ffffff" result="d"><feDistantLight azimuth="235" elevation="50"/></feDiffuseLighting>
 <feComposite in="SourceGraphic" in2="d" operator="arithmetic" k1="1.15" k2="0" k3="0" k4="0" result="m"/>
 <feComposite in="m" in2="SourceAlpha" operator="in" result="m2"/>
 <feComposite in="m2" in2="s2" operator="arithmetic" k1="0" k2="1" k3="0.5" k4="0"/>
</filter>
<filter id="fundicion" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="1.5" numOctaves="2" seed="7" result="n"/>
 <feDiffuseLighting in="n" surfaceScale="0.75" diffuseConstant="1.04" lighting-color="#ffffff" result="l"><feDistantLight azimuth="235" elevation="55"/></feDiffuseLighting>
 <feComposite in="SourceGraphic" in2="l" operator="arithmetic" k1="1.05" k2="0" k3="0" k4="0" result="m"/>
 <feComposite in="m" in2="SourceAlpha" operator="in"/>
</filter>
<filter id="plastico" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="1.6" numOctaves="2" seed="3" result="n"/>
 <feDiffuseLighting in="n" surfaceScale="0.7" diffuseConstant="1.02" lighting-color="#ffffff" result="l"><feDistantLight azimuth="235" elevation="60"/></feDiffuseLighting>
 <feComposite in="SourceGraphic" in2="l" operator="arithmetic" k1="1.02" k2="0" k3="0" k4="0" result="m"/>
 <feComposite in="m" in2="SourceAlpha" operator="in"/>
</filter>
<filter id="cepillado" x="0" y="0" width="100%" height="100%">
 <feTurbulence type="fractalNoise" baseFrequency="0.004 0.9" numOctaves="2" seed="11" result="n"/>
 <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.5  0 0 0 0 0.5  0 0 0 0 0.5  0 0 0 0.9 0" result="g"/>
 <feComposite in="g" in2="SourceAlpha" operator="in" result="g2"/>
 <feBlend in="SourceGraphic" in2="g2" mode="overlay"/>
</filter>
<filter id="sombra" x="-20%" y="-20%" width="140%" height="160%"><feGaussianBlur stdDeviation="7"/></filter>
<filter id="sombraCorta" x="-20%" y="-20%" width="140%" height="160%"><feGaussianBlur stdDeviation="2.2"/></filter>
<filter id="desenfoque" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="1.2"/></filter>
'''

def render(nombre, w, h, cuerpo, escala=2.0, carpeta=AQUI):
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>@font-face{{font-family:Plex;src:url("{FUENTE}")}}'
            f'html,body{{margin:0;padding:0;background:transparent;width:{w}px;height:{h}px;overflow:hidden}}'
            'text{font-family:Plex}</style></head><body>'
            f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            + cuerpo + '</svg></body></html>')
    ruta = os.path.join(carpeta, nombre + ".html")
    open(ruta, "w", encoding="utf-8").write(html)
    png = os.path.join(carpeta, nombre + ".png")
    subprocess.run([CH, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                    "--default-background-color=00000000", "--user-data-dir=" + os.path.join(carpeta, "perfil"),
                    f"--force-device-scale-factor={escala}", f"--window-size={w},{h}", "--screenshot=" + png,
                    "file:///" + ruta.replace("\\", "/")], timeout=120, capture_output=True)
    print(png, os.path.exists(png))
    return png
