# -*- coding: utf-8 -*-
# Valida los datos de carga antes de generar los scripts: integridad
# referencial, herencia, aritmetica de facturas, arco exclusivo, choques de
# agenda y minimo de registros por tabla. Termina con codigo 1 si hay errores.
# Uso: python src/validar_datos.py
import sys
from pathlib import Path

from data_def import (PERSONAS, CLIENTES, PUESTOS, EMPLEADOS, VETERINARIOS,
                      PROVEEDORES, SERVICIOS, MEDICAMENTOS, INVENTARIO, MASCOTAS,
                      CITAS, HISTORIALES, TRATAMIENTOS, PRESCRIPCIONES,
                      HOSPITALIZACIONES)
from facturas_def import facturas_calculadas, detalles_calculados

MINIMO_REGISTROS = 20
RAIZ = Path(__file__).resolve().parent.parent


def ids(filas):
    """Conjunto de identificadores (primera columna) de una lista de filas."""
    return {fila[0] for fila in filas}


def validar_herencia():
    """Cada subtipo debe existir en su supertipo con el discriminador correcto."""
    errores = []
    tipo = {p[0]: p[8] for p in PERSONAS}
    for cliente in CLIENTES:
        if tipo.get(cliente[0]) != "Cliente":
            errores.append(f"Cliente {cliente[0]} sin Persona de tipo Cliente")
    for empleado in EMPLEADOS:
        if tipo.get(empleado[0]) != "Empleado":
            errores.append(f"Empleado {empleado[0]} sin Persona de tipo Empleado")
        if empleado[1] not in ids(PUESTOS):
            errores.append(f"Empleado {empleado[0]} con puesto inexistente")
    for veterinario in VETERINARIOS:
        if veterinario[0] not in ids(EMPLEADOS):
            errores.append(f"Veterinario {veterinario[0]} sin fila en Empleado")
    return errores


def validar_referencias():
    """Toda clave foranea de las tablas transaccionales debe apuntar a un registro real."""
    errores = []
    clientes, vets = ids(CLIENTES), ids(VETERINARIOS)
    mascotas, servicios = ids(MASCOTAS), ids(SERVICIOS)
    meds, historiales = ids(MEDICAMENTOS), ids(HISTORIALES)
    for m in MASCOTAS:
        if m[1] not in clientes:
            errores.append(f"Mascota {m[0]} con cliente inexistente")
    for c in CITAS:
        if c[1] not in mascotas or c[2] not in vets or c[3] not in servicios:
            errores.append(f"Cita {c[0]} con clave foranea invalida")
    for h in HISTORIALES:
        if h[1] not in mascotas or h[2] not in vets:
            errores.append(f"Historial {h[0]} con clave foranea invalida")
    for t in TRATAMIENTOS:
        if t[1] not in historiales:
            errores.append(f"Tratamiento {t[0]} con historial inexistente")
    for p in PRESCRIPCIONES:
        if p[1] not in historiales or p[2] not in meds:
            errores.append(f"Prescripcion {p[0]} con clave foranea invalida")
    for i in INVENTARIO:
        if i[1] not in meds:
            errores.append(f"Inventario {i[0]} con medicamento inexistente")
    for m in MEDICAMENTOS:
        if m[7] not in ids(PROVEEDORES):
            errores.append(f"Medicamento {m[0]} con proveedor inexistente")
    for h in HOSPITALIZACIONES:
        if h[1] not in mascotas or h[2] not in vets:
            errores.append(f"Hospitalizacion {h[0]} con clave foranea invalida")
    return errores


def validar_facturacion():
    """Aritmetica de facturas, referencias del detalle y arco exclusivo servicio/medicamento."""
    errores = []
    facturas = facturas_calculadas()
    ids_factura = ids(facturas)
    for f in facturas:
        if f[1] not in ids(CLIENTES) or f[2] not in ids(EMPLEADOS):
            errores.append(f"Factura {f[0]} con clave foranea invalida")
        if f[6] != f[4] + f[5]:
            errores.append(f"Factura {f[0]} con total inconsistente")
    for d in detalles_calculados():
        if d[1] not in ids_factura:
            errores.append(f"Detalle {d[0]} con factura inexistente")
        if d[2] is not None and d[2] not in ids(SERVICIOS):
            errores.append(f"Detalle {d[0]} con servicio inexistente")
        if d[3] is not None and d[3] not in ids(MEDICAMENTOS):
            errores.append(f"Detalle {d[0]} con medicamento inexistente")
        if (d[2] is None) == (d[3] is None):
            errores.append(f"Detalle {d[0]} viola el arco exclusivo")
    return errores


def validar_agenda():
    """Ningun veterinario puede tener dos citas en el mismo horario."""
    errores = []
    vistos = set()
    for c in CITAS:
        clave = (c[2], c[4])
        if clave in vistos:
            errores.append(f"Cita {c[0]} choca con otra en la agenda {clave}")
        vistos.add(clave)
    return errores


def conteos():
    """Cantidad de registros por tabla."""
    return {
        "Persona": len(PERSONAS), "Puesto": len(PUESTOS), "Cliente": len(CLIENTES),
        "Empleado": len(EMPLEADOS), "Veterinario": len(VETERINARIOS),
        "Proveedor": len(PROVEEDORES), "Servicio": len(SERVICIOS),
        "Medicamento": len(MEDICAMENTOS), "Inventario": len(INVENTARIO),
        "Mascota": len(MASCOTAS), "Cita": len(CITAS),
        "HistorialMedico": len(HISTORIALES), "Tratamiento": len(TRATAMIENTOS),
        "Prescripcion": len(PRESCRIPCIONES), "Factura": len(facturas_calculadas()),
        "DetalleFactura": len(detalles_calculados()),
        "Hospitalizacion": len(HOSPITALIZACIONES),
    }


def validar_conteos(cantidades):
    """Cada tabla debe tener al menos el minimo de registros pedido."""
    return [f"{tabla} tiene solo {n} registros" for tabla, n in cantidades.items()
            if n < MINIMO_REGISTROS]


def validar_scripts():
    """Si los scripts ya existen, no deben contener lineas divisorias de guiones."""
    errores = []
    for archivo in (RAIZ / "sql").glob("*.sql"):
        contenido = archivo.read_text(encoding="utf-8-sig")
        if "-----" in contenido:
            errores.append(f"{archivo.name} contiene lineas divisorias de guiones")
    return errores


def main():
    cantidades = conteos()
    errores = (validar_herencia() + validar_referencias() + validar_facturacion()
               + validar_agenda() + validar_conteos(cantidades) + validar_scripts())
    print("Registros por tabla:", cantidades)
    print("Total de registros:", sum(cantidades.values()))
    if errores:
        print("ERRORES:")
        for error in errores:
            print(" ", error)
        sys.exit(1)
    print("Validacion correcta: sin errores")


if __name__ == "__main__":
    main()
