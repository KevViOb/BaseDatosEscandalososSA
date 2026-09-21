# -*- coding: utf-8 -*-
# Genera los cuatro diagramas del proyecto en PNG a partir de la definicion
# unica del esquema: conceptual mejorado, logico relacional, version final
# y fisico normalizado. Requiere Graphviz instalado (comando dot).
# Uso: python src/gen_diagramas.py
import html
import subprocess
import tempfile
from pathlib import Path

from schema_def import SCHEMA, ORDEN_CREACION, INDICES

RAIZ = Path(__file__).resolve().parent.parent
CARPETA_PNG = RAIZ / "diagramas"
DPI = 140

COLOR_ENCABEZADO = "#1F4E5F"
COLOR_HERENCIA = "#7A3E2E"
GRUPO_HERENCIA = {"Persona", "Cliente", "Empleado", "Veterinario"}

# Relaciones 1:N (padre, hijo, verbo). La cardinalidad se dibuja en pata de gallo
RELACIONES = [
    ("Cliente", "Mascota", "posee"),
    ("Mascota", "Cita", "asiste a"),
    ("Veterinario", "Cita", "atiende"),
    ("Servicio", "Cita", "se brinda en"),
    ("Mascota", "HistorialMedico", "acumula"),
    ("Veterinario", "HistorialMedico", "registra"),
    ("HistorialMedico", "Tratamiento", "origina"),
    ("HistorialMedico", "Prescripcion", "emite"),
    ("Medicamento", "Prescripcion", "se receta en"),
    ("Proveedor", "Medicamento", "suministra"),
    ("Medicamento", "Inventario", "se almacena en"),
    ("Puesto", "Empleado", "clasifica"),
    ("Cliente", "Factura", "recibe"),
    ("Empleado", "Factura", "emite"),
    ("Factura", "DetalleFactura", "contiene"),
    ("Servicio", "DetalleFactura", "aparece en"),
    ("Medicamento", "DetalleFactura", "aparece en"),
    ("Mascota", "Hospitalizacion", "ingresa a"),
    ("Veterinario", "Hospitalizacion", "es supervisada por"),
]

# Jerarquia de herencia (subtipo, supertipo)
HERENCIA = [("Cliente", "Persona"), ("Empleado", "Persona"), ("Veterinario", "Empleado")]

# Cada diagrama: (estilo de las entidades, titulo, nombre del archivo)
DIAGRAMAS = [
    ("conceptual", "Diagrama Entidad-Relacion Conceptual Mejorado (con herencia)",
     "diagrama_er_conceptual_mejorado.png"),
    ("logico", "Diagrama Logico Relacional Mejorado",
     "diagrama_logico_relacional_mejorado.png"),
    ("conceptual", "Diagrama Entidad-Relacion, Version Final",
     "diagrama_er_version_final.png"),
    ("fisico", "Diagrama Entidad-Relacion Fisico Normalizado (3FN)",
     "diagrama_er_fisico_normalizado.png"),
]


def fila_html(texto, negrita=False, size=10, color="black"):
    """Fila de la tabla HTML que Graphviz dibuja dentro de cada entidad."""
    contenido = html.escape(texto)
    if negrita:
        contenido = f"<B>{contenido}</B>"
    return (f'<TR><TD ALIGN="LEFT" BALIGN="LEFT">'
            f'<FONT POINT-SIZE="{size}" COLOR="{color}">{contenido}</FONT></TD></TR>')


def marca_clave(clave):
    """Prefijo PK, FK o UQ segun el tipo de clave de la columna."""
    if "PK" in clave and "FK" in clave:
        return "PK, FK  "
    if "PK" in clave:
        return "PK  "
    if "FK" in clave:
        return "FK  "
    if "UQ" in clave:
        return "UQ  "
    return ""


def texto_columna(columna, estilo):
    """Texto de una columna segun el nivel de detalle del diagrama."""
    (nombre, tipo, nulo, clave, _desc) = columna
    marca = marca_clave(clave)
    if estilo == "conceptual":
        return f"{marca}{nombre}"
    if estilo == "logico":
        return f"{marca}{nombre} : {tipo}"
    nulidad = "NOT NULL" if nulo == "NO" else "NULL"
    return f"{marca}{nombre} : {tipo} {nulidad}"


def resumen_fisico(nombre):
    """Linea extra del diagrama fisico con restricciones e indices de la tabla."""
    tabla = SCHEMA[nombre]
    extras = []
    if tabla.get("checks"):
        extras.append(f"{len(tabla['checks'])} restriccion(es) CHECK")
    if tabla.get("uniques") or any("UQ" in c[3] for c in tabla["cols"]):
        extras.append("restriccion UNIQUE")
    indices = [i[0] for i in INDICES if i[1] == nombre]
    if indices:
        extras.append("indice " + ", ".join(indices))
    return "; ".join(extras)


def nodo_entidad(nombre, estilo):
    """Nodo de Graphviz con la tabla HTML de una entidad."""
    color = COLOR_HERENCIA if nombre in GRUPO_HERENCIA else COLOR_ENCABEZADO
    filas = [f'<TR><TD BGCOLOR="{color}" ALIGN="CENTER">'
             f'<FONT COLOR="white" POINT-SIZE="12"><B>{nombre}</B></FONT></TD></TR>']
    for columna in SCHEMA[nombre]["cols"]:
        filas.append(fila_html(texto_columna(columna, estilo),
                               negrita=columna[3].startswith("PK")))
    if estilo == "fisico":
        extra = resumen_fisico(nombre)
        if extra:
            filas.append(fila_html(extra, size=8, color="#555555"))
    return (f'{nombre} [label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" '
            f'CELLPADDING="3" BGCOLOR="white">{"".join(filas)}</TABLE>>];')


def armar_dot(estilo, titulo):
    """Construye el texto DOT completo de un diagrama."""
    lineas = [
        "digraph ER {",
        f'  graph [label="{titulo}\\nSistema de gestion de base de datos para Escandalosos S.A.", '
        'labelloc="t", fontsize=20, fontname="Helvetica-Bold", '
        'rankdir=TB, splines=true, overlap=false, nodesep=0.55, ranksep=1.05, pad=0.4];',
        '  node [shape=plaintext, fontname="Helvetica"];',
        '  edge [fontname="Helvetica", fontsize=9, color="#444444"];',
    ]
    for tabla in ORDEN_CREACION:
        lineas.append("  " + nodo_entidad(tabla, estilo))
    for (subtipo, supertipo) in HERENCIA:
        lineas.append(
            f'  {subtipo} -> {supertipo} [arrowhead=onormal, arrowsize=1.6, penwidth=1.4, '
            f'color="{COLOR_HERENCIA}", label="es un", fontcolor="{COLOR_HERENCIA}", style=bold];')
    for (padre, hijo, verbo) in RELACIONES:
        etiqueta = verbo if estilo == "conceptual" else ""
        lineas.append(
            f'  {padre} -> {hijo} [dir=both, arrowtail=teetee, arrowhead=crowtee, '
            f'label="{etiqueta}", labeldistance=2, taillabel="1", headlabel="N", '
            f'labelfontsize=9];')
    lineas.append("}")
    return "\n".join(lineas)


def generar(estilo, titulo, archivo):
    """Escribe el DOT temporal y lo convierte a PNG con Graphviz."""
    CARPETA_PNG.mkdir(parents=True, exist_ok=True)
    salida = CARPETA_PNG / archivo
    with tempfile.NamedTemporaryFile("w", suffix=".dot", delete=False, encoding="utf-8") as dot:
        dot.write(armar_dot(estilo, titulo))
        ruta_dot = dot.name
    subprocess.run(["dot", "-Tpng", f"-Gdpi={DPI}", ruta_dot, "-o", str(salida)], check=True)
    Path(ruta_dot).unlink()
    print("Generado:", salida)


def main():
    for (estilo, titulo, archivo) in DIAGRAMAS:
        generar(estilo, titulo, archivo)


if __name__ == "__main__":
    main()
