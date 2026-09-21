# -*- coding: utf-8 -*-
# Facturas y detalles. Los montos de encabezado se calculan a partir de las lineas
# para garantizar coherencia aritmetica exacta (subtotal, impuesto 13%, total).
from decimal import Decimal, ROUND_HALF_UP

TASA_IVA = Decimal("0.13")

# Detalles: (id, id_factura, id_servicio, id_medicamento, cantidad, precio_unitario, descuento_pct)
DETALLES = [
    (1,  1,  1,    None, 1, 18500.00,  0.00),
    (2,  1,  None, 12,   1, 5200.00,   0.00),
    (3,  2,  3,    None, 1, 16000.00,  0.00),
    (4,  3,  1,    None, 1, 18500.00, 10.00),
    (5,  3,  14,   None, 1, 28000.00, 10.00),
    (6,  4,  5,    None, 1, 9500.00,   0.00),
    (7,  5,  12,   None, 1, 15000.00,  5.00),
    (8,  5,  None, 18,   1, 11500.00,  0.00),
    (9,  5,  None, 3,    1, 12500.00,  0.00),
    (10, 6,  9,    None, 1, 250000.00, 0.00),
    (11, 6,  18,   None, 3, 45000.00,  0.00),
    (12, 7,  1,    None, 1, 18500.00,  0.00),
    (13, 7,  None, 1,    1, 6500.00,   0.00),
    (14, 8,  12,   None, 1, 15000.00,  0.00),
    (15, 9,  14,   None, 1, 28000.00,  0.00),
    (16, 10, 10,   None, 1, 55000.00,  0.00),
    (17, 11, 9,    None, 1, 250000.00, 0.00),
    (18, 11, 18,   None, 1, 45000.00,  0.00),
    (19, 12, 1,    None, 1, 18500.00,  0.00),
    (20, 13, 15,   None, 1, 32000.00,  0.00),
    (21, 14, 3,    None, 1, 16000.00,  5.00),
    (22, 15, 1,    None, 1, 18500.00,  0.00),
    (23, 16, 1,    None, 1, 18500.00,  0.00),
    (24, 17, None, 17,   2, 13500.00,  0.00),
    (25, 18, None, 4,    1, 28000.00,  0.00),
    (26, 19, 11,   None, 1, 22000.00,  5.00),
    (27, 20, None, 5,    1, 32000.00,  0.00),
]

# Encabezados sin montos: (id, id_cliente, id_empleado, fecha_emision, estado_pago)
FACTURAS_BASE = [
    (1,  1,  41, "2026-06-01 10:15", "Pagada"),
    (2,  2,  42, "2026-06-02 11:10", "Pagada"),
    (3,  3,  41, "2026-06-03 09:45", "Pagada"),
    (4,  4,  42, "2026-06-04 14:40", "Pagada"),
    (5,  5,  41, "2026-06-05 12:05", "Pagada"),
    (6,  6,  43, "2026-06-11 16:30", "Pagada"),
    (7,  8,  42, "2026-06-09 16:20", "Pagada"),
    (8,  9,  41, "2026-06-10 10:50", "Pagada"),
    (9,  10, 42, "2026-06-11 10:15", "Pagada"),
    (10, 11, 41, "2026-06-12 13:55", "Pagada"),
    (11, 3,  43, "2026-06-16 17:10", "Pendiente"),
    (12, 13, 42, "2026-06-16 17:00", "Pagada"),
    (13, 15, 41, "2026-06-18 12:20", "Pagada"),
    (14, 16, 42, "2026-06-22 09:40", "Pagada"),
    (15, 19, 41, "2026-06-25 15:25", "Pagada"),
    (16, 7,  42, "2026-07-06 10:45", "Pagada"),
    (17, 12, 41, "2026-07-08 15:40", "Pendiente"),
    (18, 16, 42, "2026-07-10 11:20", "Anulada"),
    (19, 17, 41, "2026-07-11 10:30", "Pagada"),
    (20, 20, 42, "2026-07-15 14:10", "Pagada"),
]


def redondear(valor):
    """Convierte cualquier numero a Decimal con dos decimales (redondeo comercial)."""
    return Decimal(str(valor)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def subtotal_linea(cantidad, precio, descuento):
    """Monto de una linea: cantidad por precio menos el porcentaje de descuento."""
    bruto = Decimal(cantidad) * redondear(precio)
    return redondear(bruto - bruto * redondear(descuento) / Decimal(100))


def facturas_calculadas():
    """Devuelve facturas con subtotal, impuesto (13%) y total calculados de sus lineas."""
    por_factura = {}
    for (_, id_factura, _, _, cantidad, precio, descuento) in DETALLES:
        por_factura.setdefault(id_factura, Decimal("0.00"))
        por_factura[id_factura] += subtotal_linea(cantidad, precio, descuento)
    resultado = []
    for (id_factura, id_cliente, id_empleado, fecha, estado) in FACTURAS_BASE:
        subtotal = redondear(por_factura[id_factura])
        impuesto = redondear(subtotal * TASA_IVA)
        resultado.append((id_factura, id_cliente, id_empleado, fecha,
                          subtotal, impuesto, redondear(subtotal + impuesto), estado))
    return resultado


def detalles_calculados():
    """Devuelve las lineas de detalle con su subtotal de linea ya calculado."""
    resultado = []
    for (id_detalle, id_factura, id_servicio, id_medicamento,
         cantidad, precio, descuento) in DETALLES:
        resultado.append((id_detalle, id_factura, id_servicio, id_medicamento,
                          cantidad, redondear(precio), redondear(descuento),
                          subtotal_linea(cantidad, precio, descuento)))
    return resultado
