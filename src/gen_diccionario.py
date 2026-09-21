# -*- coding: utf-8 -*-
# Genera docs/DICCIONARIO_DE_DATOS.md a partir de la definicion unica del
# esquema, por lo que siempre coincide con el script SQL.
# Uso: python src/gen_diccionario.py
from pathlib import Path

from schema_def import SCHEMA, ORDEN_CREACION, INDICES

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "docs" / "DICCIONARIO_DE_DATOS.md"


def texto_clave(clave):
    """Clave legible: PK, FK hacia otra tabla, UNIQUE o vacio."""
    if not clave:
        return ""
    return clave.replace("->", " hacia ").replace("PK,FK", "PK, FK").replace("UQ", "UNIQUE")


def tabla_columnas(nombre):
    """Tabla Markdown con las columnas de una entidad."""
    lineas = ["| Columna | Tipo de dato | Nulo | Clave | Descripcion |",
              "| --- | --- | --- | --- | --- |"]
    for (col, tipo, nulo, clave, desc) in SCHEMA[nombre]["cols"]:
        lineas.append(f"| {col} | {tipo} | {nulo} | {texto_clave(clave)} | {desc} |")
    return "\n".join(lineas)


def restricciones(nombre):
    """Lista de restricciones CHECK y UNIQUE compuestas de una entidad."""
    tabla = SCHEMA[nombre]
    items = [c.replace("CHECK ", "CHECK: ", 1) for c in tabla.get("checks", [])]
    items += [f"{u}" for u in tabla.get("uniques", [])]
    if not items:
        return ""
    return "\nRestricciones adicionales:\n\n" + "\n".join(f"* `{i}`" for i in items) + "\n"


def seccion_entidad(numero, nombre):
    """Bloque completo de una entidad del diccionario."""
    return (f"### {numero}. {nombre}\n\n{SCHEMA[nombre]['desc']}\n\n"
            f"{tabla_columnas(nombre)}\n{restricciones(nombre)}")


def seccion_indices():
    """Tabla de indices no agrupados."""
    lineas = ["| Indice | Tabla | Columnas |", "| --- | --- | --- |"]
    for (nombre, tabla, columnas) in INDICES:
        lineas.append(f"| {nombre} | {tabla} | {columnas} |")
    return "\n".join(lineas)


def contenido():
    """Documento completo del diccionario de datos."""
    partes = [
        "# Diccionario de datos de Escandalosos S.A.\n",
        "Documento generado con `python src/gen_diccionario.py` a partir de "
        "`src/schema_def.py`, la misma definicion que produce el script SQL y "
        "los diagramas. Comprende las 17 entidades del modelo logico.\n",
        "## Entidades\n",
    ]
    for numero, nombre in enumerate(ORDEN_CREACION, start=1):
        partes.append(seccion_entidad(numero, nombre))
    partes.append("## Tabla de apoyo del modelo fisico\n")
    partes.append("`AuditoriaPrecioServicio` no forma parte de las 17 entidades logicas. "
                  "La usa el trigger `trg_Servicio_AuditarPrecio` para registrar los cambios "
                  "de precio de los servicios.\n")
    partes.append("| Columna | Tipo de dato | Nulo | Clave | Descripcion |\n"
                  "| --- | --- | --- | --- | --- |\n"
                  "| id_auditoria | INT IDENTITY(1,1) | NO | PK | Identificador autoincremental |\n"
                  "| id_servicio | INT | NO | FK hacia Servicio | Servicio cuyo precio cambio |\n"
                  "| precio_anterior | DECIMAL(10,2) | NO |  | Precio antes del cambio |\n"
                  "| precio_nuevo | DECIMAL(10,2) | NO |  | Precio despues del cambio |\n"
                  "| fecha_cambio | DATETIME | NO |  | Fecha del cambio, por defecto GETDATE() |\n"
                  "| usuario | VARCHAR(100) | NO |  | Usuario que hizo el cambio, por defecto SYSTEM_USER |\n")
    partes.append("## Indices no agrupados\n")
    partes.append(seccion_indices() + "\n")
    return "\n".join(partes)


def main():
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    SALIDA.write_text(contenido(), encoding="utf-8")
    print("Generado:", SALIDA)


if __name__ == "__main__":
    main()
