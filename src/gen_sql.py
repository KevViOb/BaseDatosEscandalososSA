# -*- coding: utf-8 -*-
# Genera Escandalosos_Avance2.sql y Escandalosos_Final.sql a partir de la
# definicion unica del esquema y de los datos, para que tablas, diagramas y
# diccionario de datos coincidan exactamente.
# Uso: python src/gen_sql.py
from pathlib import Path

from schema_def import SCHEMA, ORDEN_CREACION, INDICES
from data_def import (PERSONAS, CLIENTES, PUESTOS, EMPLEADOS, VETERINARIOS,
                      PROVEEDORES, SERVICIOS, MEDICAMENTOS, INVENTARIO, MASCOTAS,
                      CITAS, HISTORIALES, TRATAMIENTOS, PRESCRIPCIONES,
                      HOSPITALIZACIONES)
from facturas_def import facturas_calculadas, detalles_calculados

RAIZ = Path(__file__).resolve().parent.parent
CARPETA_SQL = RAIZ / "sql"
ARCHIVO_AVANCE2 = CARPETA_SQL / "Escandalosos_Avance2.sql"
ARCHIVO_FINAL = CARPETA_SQL / "Escandalosos_Final.sql"

# Se escribe con BOM para que SSMS lea bien las tildes y las enes de los datos
CODIFICACION = "utf-8-sig"


def sql_val(valor):
    """Convierte un valor de Python a su literal de SQL Server."""
    if valor is None:
        return "NULL"
    if isinstance(valor, int):
        return str(valor)
    if isinstance(valor, float):
        return f"{valor:.2f}"
    if valor.__class__.__name__ == "Decimal":
        return f"{valor:.2f}"
    texto = str(valor).replace("'", "''")
    return f"N'{texto}'"


def pk_col(tabla):
    """Nombre de la columna que es clave primaria de la tabla."""
    for columna in SCHEMA[tabla]["cols"]:
        if "PK" in columna[3]:
            return columna[0]
    raise ValueError(f"La tabla {tabla} no tiene clave primaria definida")


def ddl_tabla(nombre):
    """CREATE TABLE con PK, FK, UNIQUE y CHECK explicitos y con nombre."""
    tabla = SCHEMA[nombre]
    lineas = []
    foraneas = []
    for (col, tipo, nulo, clave, _desc) in tabla["cols"]:
        nulidad = "NOT NULL" if nulo == "NO" else "NULL"
        lineas.append(f"    {col} {tipo} {nulidad}")
        if "FK->" in clave:
            foraneas.append((col, clave.split("FK->")[1]))
    lineas.append(f"    CONSTRAINT PK_{nombre} PRIMARY KEY ({pk_col(nombre)})")
    for (col, destino) in foraneas:
        lineas.append(
            f"    CONSTRAINT FK_{nombre}_{destino} FOREIGN KEY ({col}) "
            f"REFERENCES {destino} ({pk_col(destino)})")
    for (col, _tipo, _nulo, clave, _d) in tabla["cols"]:
        if "UQ" in clave:
            lineas.append(f"    CONSTRAINT UQ_{nombre}_{col} UNIQUE ({col})")
    for unico in tabla.get("uniques", []):
        columnas = unico.replace("UNIQUE", "").strip(" ()").replace(" ", "")
        lineas.append(f"    CONSTRAINT UQ_{nombre}_{columnas.replace(',', '_')} {unico}")
    for numero, restriccion in enumerate(tabla.get("checks", []), start=1):
        lineas.append(f"    CONSTRAINT CK_{nombre}_{numero:02d} {restriccion}")
    return f"CREATE TABLE {nombre} (\n" + ",\n".join(lineas) + "\n);"


def bloque_insert(tabla, filas, comentario, columnas=None):
    """INSERT multifila con lista explicita de columnas."""
    if columnas is None:
        columnas = [c[0] for c in SCHEMA[tabla]["cols"]]
    valores = ",\n".join("    (" + ", ".join(sql_val(v) for v in fila) + ")"
                         for fila in filas)
    return (f"-- {comentario}\n"
            f"INSERT INTO {tabla} ({', '.join(columnas)}) VALUES\n{valores};\n")


ENCABEZADO = """/*
Proyecto Integrador del curso de Bases de Datos
Sistema de gestion de base de datos para Escandalosos S.A.
Universidad Latinoamericana de Ciencia y Tecnologia (ULACIT)

Autor: Kevin Villalobos Obando
Desarrollado con el apoyo de Claude (Anthropic)
Motor: Microsoft SQL Server
{etapa}

Escandalosos S.A. es una empresa ficticia creada con fines academicos y
todos los datos de este script son inventados.

El script se ejecuta de inicio a fin en una instancia de SQL Server.
El orden de las secciones respeta las dependencias de claves foraneas:
primero los supertipos de la jerarquia de herencia, luego los subtipos
y por ultimo las tablas transaccionales que dependen de ellos.
*/
"""

CREACION_BD = """
-- Si la base ya existe se elimina para poder ejecutar el script completo
-- las veces que sea necesario durante las pruebas
USE master;
GO
IF DB_ID('EscandalososSA') IS NOT NULL
BEGIN
    ALTER DATABASE EscandalososSA SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE EscandalososSA;
END
GO

-- Creacion de la base de datos del proyecto
CREATE DATABASE EscandalososSA;
GO
USE EscandalososSA;
GO
"""

COMENTARIOS_TABLA = {
    "Persona": "Supertipo de la jerarquia de herencia. Antes los datos personales se repetian en Cliente, Empleado y Veterinario; ahora se definen una unica vez aqui. La columna tipo_persona funciona como discriminador del subtipo.",
    "Puesto": "Catalogo de puestos de trabajo. Se crea antes que Empleado porque este la referencia.",
    "Cliente": "Subtipo de Persona. Su clave primaria es a la vez clave foranea hacia el supertipo, que es la forma estandar de implementar herencia en el modelo relacional.",
    "Empleado": "Subtipo de Persona con los datos laborales. Igual que Cliente, comparte identificador con el supertipo.",
    "Veterinario": "Subtipo de Empleado. La jerarquia completa es Persona, luego Empleado y luego Veterinario, por lo que un veterinario hereda tanto los datos personales como los laborales.",
    "Proveedor": "Empresas que suministran medicamentos a la clinica.",
    "Servicio": "Catalogo de servicios con su precio base en colones.",
    "Medicamento": "Catalogo de medicamentos. Referencia al proveedor que lo suministra.",
    "Mascota": "Pacientes de la clinica. Cada mascota pertenece a un cliente.",
    "Cita": "Agenda de la clinica. Une mascota, veterinario y servicio en una fecha y hora concreta.",
    "HistorialMedico": "Expediente clinico. La columna notas usa VARCHAR(MAX) en lugar del tipo TEXT del modelo inicial, porque TEXT esta en desuso en SQL Server.",
    "Tratamiento": "Tratamientos indicados a partir de una consulta del historial.",
    "Prescripcion": "Recetas emitidas en una consulta. Une el historial con el medicamento.",
    "Inventario": "Existencias por lote. La restriccion unica sobre medicamento y lote evita registrar dos veces el mismo lote.",
    "Factura": "Encabezado de facturacion. El impuesto corresponde al IVA del 13 por ciento.",
    "DetalleFactura": "Lineas de factura. La restriccion CK garantiza que cada linea sea de un servicio o de un medicamento, pero nunca de ambos ni de ninguno.",
    "Hospitalizacion": "Internamientos. La fecha de egreso admite nulos porque el paciente puede seguir internado.",
}


def seccion_ddl():
    """Seccion 1: tablas en orden de dependencias mas los indices."""
    partes = ["\n-- Seccion 1. Creacion de las tablas del modelo\n"]
    for tabla in ORDEN_CREACION:
        partes.append(f"-- {COMENTARIOS_TABLA[tabla]}")
        partes.append(ddl_tabla(tabla))
        partes.append("")
    partes.append("-- Indices no agrupados sobre las columnas que mas se usan en busquedas y joins")
    for (nombre, tabla, columnas) in INDICES:
        partes.append(f"CREATE NONCLUSTERED INDEX {nombre} ON {tabla} ({columnas});")
    partes.append("GO")
    return "\n".join(partes)


def seccion_inserts():
    """Seccion 2: carga de datos con identificadores explicitos."""
    partes = ["\n-- Seccion 2. Carga de datos iniciales",
              "-- Los identificadores se insertan de forma explicita para controlar",
              "-- la integridad referencial de la carga: personas 1 a 20 son clientes",
              "-- y de la 21 a la 45 son empleados, de los cuales 21 a 40 son veterinarios\n"]
    cargas = [
        ("Persona", PERSONAS, "Personas de la clinica: supertipo comun de clientes y empleados"),
        ("Puesto", PUESTOS, "Catalogo de puestos de trabajo de la clinica"),
        ("Cliente", CLIENTES, "Clientes: subtipo de Persona, comparten identificador con el supertipo"),
        ("Empleado", EMPLEADOS, "Empleados: subtipo de Persona con la informacion laboral"),
        ("Veterinario", VETERINARIOS, "Veterinarios: subtipo de Empleado con la informacion profesional"),
        ("Proveedor", PROVEEDORES, "Proveedores de medicamentos y suministros"),
        ("Servicio", SERVICIOS, "Catalogo de servicios con precios en colones"),
        ("Medicamento", MEDICAMENTOS, "Catalogo de medicamentos con su proveedor"),
        ("Inventario", INVENTARIO, "Existencias por lote con stock minimo y vencimiento"),
        ("Mascota", MASCOTAS, "Mascotas registradas, cada una asociada a su dueno"),
        ("Cita", CITAS, "Agenda de citas de junio y julio de 2026"),
        ("HistorialMedico", HISTORIALES, "Expedientes clinicos de las consultas atendidas"),
        ("Tratamiento", TRATAMIENTOS, "Tratamientos derivados de los registros del historial"),
        ("Prescripcion", PRESCRIPCIONES, "Recetas emitidas en las consultas"),
        ("Factura", facturas_calculadas(), "Facturas emitidas: el subtotal es la suma de sus lineas y el impuesto es el 13 por ciento"),
        ("DetalleFactura", detalles_calculados(), "Lineas de factura: cada una corresponde a un servicio o a un medicamento"),
        ("Hospitalizacion", HOSPITALIZACIONES, "Internamientos historicos y actuales"),
    ]
    for (tabla, filas, comentario) in cargas:
        partes.append(bloque_insert(tabla, filas, comentario))
    partes.append("GO")
    return "\n".join(partes)


CONSULTAS = """
-- Seccion 3. Consultas de verificacion y analisis

-- Consulta 3.1 Join de la jerarquia de herencia
-- Reconstruye la ficha completa de cada veterinario uniendo los tres niveles:
-- Persona aporta los datos personales, Empleado los laborales y Veterinario
-- los profesionales. Este join demuestra como se consulta la herencia
SELECT p.nombre, p.apellidos, pu.nombre_puesto, e.salario,
       v.numero_colegiado, v.especialidad
FROM Veterinario v
INNER JOIN Empleado e ON v.id_veterinario = e.id_empleado
INNER JOIN Persona p ON e.id_empleado = p.id_persona
INNER JOIN Puesto pu ON e.id_puesto = pu.id_puesto
ORDER BY p.apellidos;

-- Consulta 3.2 Agenda detallada de citas
-- Une cinco tablas para mostrar cada cita con la mascota, el dueno,
-- el veterinario asignado y el servicio que se brindara
SELECT c.fecha_hora, m.nombre AS mascota,
       pd.nombre + ' ' + pd.apellidos AS dueno,
       pv.nombre + ' ' + pv.apellidos AS veterinario,
       s.nombre_servicio, c.estado
FROM Cita c
INNER JOIN Mascota m ON c.id_mascota = m.id_mascota
INNER JOIN Persona pd ON m.id_cliente = pd.id_persona
INNER JOIN Veterinario v ON c.id_veterinario = v.id_veterinario
INNER JOIN Persona pv ON v.id_veterinario = pv.id_persona
INNER JOIN Servicio s ON c.id_servicio = s.id_servicio
ORDER BY c.fecha_hora;

-- Consulta 3.3 Left join de clientes y facturacion
-- Se usa LEFT JOIN para incluir tambien a los clientes que todavia
-- no tienen facturas, que con un INNER JOIN quedarian fuera
SELECT p.nombre + ' ' + p.apellidos AS cliente, cl.tipo_cliente,
       COUNT(f.id_factura) AS cantidad_facturas,
       COALESCE(SUM(f.total), 0) AS monto_total
FROM Cliente cl
INNER JOIN Persona p ON cl.id_cliente = p.id_persona
LEFT JOIN Factura f ON cl.id_cliente = f.id_cliente
    AND f.estado_pago <> 'Anulada'
GROUP BY p.nombre, p.apellidos, cl.tipo_cliente
ORDER BY monto_total DESC;

-- Consulta 3.4 Estado del inventario con SQL CASE
-- Clasifica cada lote segun su relacion con el stock minimo definido
SELECT med.nombre_comercial, i.lote, i.stock_actual, i.stock_minimo,
       CASE
           WHEN i.stock_actual = 0 THEN 'Agotado'
           WHEN i.stock_actual <= i.stock_minimo THEN 'Critico'
           WHEN i.stock_actual <= i.stock_minimo * 2 THEN 'Bajo'
           ELSE 'Normal'
       END AS estado_stock
FROM Inventario i
INNER JOIN Medicamento med ON i.id_medicamento = med.id_medicamento
ORDER BY i.stock_actual;

-- Consulta 3.5 Clasificacion de pacientes por edad con SQL CASE
-- Calcula la edad en anios y asigna la etapa de vida de cada mascota
SELECT m.nombre, m.especie,
       DATEDIFF(YEAR, m.fecha_nacimiento, GETDATE()) AS edad_anios,
       CASE
           WHEN DATEDIFF(YEAR, m.fecha_nacimiento, GETDATE()) < 1 THEN 'Cachorro'
           WHEN DATEDIFF(YEAR, m.fecha_nacimiento, GETDATE()) < 7 THEN 'Adulto'
           ELSE 'Senior'
       END AS etapa_vida
FROM Mascota m
ORDER BY edad_anios DESC;

-- Consulta 3.6 Funciones de agregacion por veterinario
-- Cuenta las citas asignadas a cada veterinario y cuantas fueron atendidas
SELECT p.nombre + ' ' + p.apellidos AS veterinario, v.especialidad,
       COUNT(c.id_cita) AS citas_asignadas,
       SUM(CASE WHEN c.estado = 'Atendida' THEN 1 ELSE 0 END) AS citas_atendidas
FROM Veterinario v
INNER JOIN Persona p ON v.id_veterinario = p.id_persona
LEFT JOIN Cita c ON v.id_veterinario = c.id_veterinario
GROUP BY p.nombre, p.apellidos, v.especialidad
HAVING COUNT(c.id_cita) > 0
ORDER BY citas_asignadas DESC;

-- Consulta 3.7 Ingresos por categoria de servicio
-- Suma lo facturado por categoria excluyendo facturas anuladas
-- y usa HAVING para mostrar solo categorias con ingresos relevantes
SELECT s.categoria,
       COUNT(df.id_detalle) AS lineas_facturadas,
       SUM(df.subtotal_linea) AS ingresos,
       AVG(df.subtotal_linea) AS promedio_por_linea
FROM DetalleFactura df
INNER JOIN Servicio s ON df.id_servicio = s.id_servicio
INNER JOIN Factura f ON df.id_factura = f.id_factura
WHERE f.estado_pago <> 'Anulada'
GROUP BY s.categoria
HAVING SUM(df.subtotal_linea) > 20000
ORDER BY ingresos DESC;

-- Consulta 3.8 Resumen salarial por puesto usando la herencia
-- Promedio, maximo y minimo de salarios reales contra el salario base del puesto
SELECT pu.nombre_puesto, pu.salario_base,
       COUNT(e.id_empleado) AS empleados,
       AVG(e.salario) AS salario_promedio,
       MAX(e.salario) AS salario_maximo,
       MIN(e.salario) AS salario_minimo
FROM Empleado e
INNER JOIN Puesto pu ON e.id_puesto = pu.id_puesto
GROUP BY pu.nombre_puesto, pu.salario_base
ORDER BY salario_promedio DESC;
GO
"""

OBJETOS_FINALES = """
-- Seccion 4. Vistas del modelo fisico

-- Vista 4.1 Agenda de citas pendientes
-- Simplifica la consulta diaria de recepcion: muestra las citas programadas
-- con todos los nombres ya resueltos para no repetir el join en cada consulta
GO
CREATE VIEW vw_AgendaCitas AS
SELECT c.id_cita, c.fecha_hora, m.nombre AS mascota, m.especie,
       pd.nombre + ' ' + pd.apellidos AS dueno, pd.telefono,
       pv.nombre + ' ' + pv.apellidos AS veterinario,
       s.nombre_servicio, c.motivo, c.estado
FROM Cita c
INNER JOIN Mascota m ON c.id_mascota = m.id_mascota
INNER JOIN Persona pd ON m.id_cliente = pd.id_persona
INNER JOIN Veterinario v ON c.id_veterinario = v.id_veterinario
INNER JOIN Persona pv ON v.id_veterinario = pv.id_persona
INNER JOIN Servicio s ON c.id_servicio = s.id_servicio;
GO

-- Vista 4.2 Expediente clinico completo
-- Une el historial con la mascota, el dueno y el veterinario que atendio
CREATE VIEW vw_ExpedienteClinico AS
SELECT h.id_historial, h.fecha_consulta, m.nombre AS mascota, m.especie,
       pd.nombre + ' ' + pd.apellidos AS dueno,
       pv.nombre + ' ' + pv.apellidos AS veterinario,
       h.diagnostico, h.temperatura, h.peso_consulta
FROM HistorialMedico h
INNER JOIN Mascota m ON h.id_mascota = m.id_mascota
INNER JOIN Persona pd ON m.id_cliente = pd.id_persona
INNER JOIN Veterinario v ON h.id_veterinario = v.id_veterinario
INNER JOIN Persona pv ON v.id_veterinario = pv.id_persona;
GO

-- Vista 4.3 Stock critico
-- Lotes en o por debajo del minimo, con el proveedor al que hay que pedir
CREATE VIEW vw_StockCritico AS
SELECT med.nombre_comercial, i.lote, i.stock_actual, i.stock_minimo,
       i.fecha_vencimiento, pr.nombre_empresa AS proveedor, pr.telefono
FROM Inventario i
INNER JOIN Medicamento med ON i.id_medicamento = med.id_medicamento
INNER JOIN Proveedor pr ON med.id_proveedor = pr.id_proveedor
WHERE i.stock_actual <= i.stock_minimo * 2;
GO

-- Vista 4.4 Resumen de facturacion por cliente
CREATE VIEW vw_FacturacionClientes AS
SELECT cl.id_cliente, p.nombre + ' ' + p.apellidos AS cliente,
       cl.tipo_cliente,
       COUNT(f.id_factura) AS facturas,
       COALESCE(SUM(f.total), 0) AS total_facturado,
       COALESCE(SUM(CASE WHEN f.estado_pago = 'Pendiente' THEN f.total ELSE 0 END), 0) AS saldo_pendiente
FROM Cliente cl
INNER JOIN Persona p ON cl.id_cliente = p.id_persona
LEFT JOIN Factura f ON cl.id_cliente = f.id_cliente
    AND f.estado_pago <> 'Anulada'
GROUP BY cl.id_cliente, p.nombre, p.apellidos, cl.tipo_cliente;
GO

-- Vista 4.5 Planilla de empleados
-- Recorre la jerarquia de herencia para entregar la planilla completa
CREATE VIEW vw_PlanillaEmpleados AS
SELECT e.id_empleado, p.identificacion,
       p.nombre + ' ' + p.apellidos AS empleado,
       pu.nombre_puesto, pu.departamento, e.salario, e.jornada, e.estado,
       CASE WHEN v.id_veterinario IS NULL THEN 'No' ELSE 'Si' END AS es_veterinario
FROM Empleado e
INNER JOIN Persona p ON e.id_empleado = p.id_persona
INNER JOIN Puesto pu ON e.id_puesto = pu.id_puesto
LEFT JOIN Veterinario v ON e.id_empleado = v.id_veterinario;
GO

-- Seccion 5. Procedimientos almacenados

-- Procedimiento 5.1 Registro de un cliente nuevo
-- Como Cliente hereda de Persona, el alta implica insertar en dos tablas.
-- La transaccion garantiza que se creen ambas filas o ninguna
CREATE PROCEDURE sp_RegistrarCliente
    @identificacion VARCHAR(20),
    @nombre VARCHAR(80),
    @apellidos VARCHAR(100),
    @telefono VARCHAR(20),
    @correo VARCHAR(100),
    @direccion VARCHAR(200),
    @fecha_nacimiento DATE,
    @tipo_cliente VARCHAR(20),
    @preferencia_contacto VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @nuevo_id INT;
        SELECT @nuevo_id = ISNULL(MAX(id_persona), 0) + 1 FROM Persona;

        INSERT INTO Persona (id_persona, identificacion, nombre, apellidos,
                             telefono, correo, direccion, fecha_nacimiento, tipo_persona)
        VALUES (@nuevo_id, @identificacion, @nombre, @apellidos,
                @telefono, @correo, @direccion, @fecha_nacimiento, 'Cliente');

        INSERT INTO Cliente (id_cliente, fecha_registro, tipo_cliente,
                             preferencia_contacto, acepta_promociones,
                             referido_por, notas, estado)
        VALUES (@nuevo_id, CAST(GETDATE() AS DATE), @tipo_cliente,
                @preferencia_contacto, 1, NULL, NULL, 'Activo');

        COMMIT TRANSACTION;
        SELECT @nuevo_id AS id_cliente_creado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedimiento 5.2 Agendamiento de citas
-- Valida que el veterinario no tenga otra cita activa en la misma fecha y hora
-- antes de insertar, que era uno de los problemas de la agenda fisica
CREATE PROCEDURE sp_AgendarCita
    @id_mascota INT,
    @id_veterinario INT,
    @id_servicio INT,
    @fecha_hora DATETIME,
    @motivo VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Cita
               WHERE id_veterinario = @id_veterinario
                 AND fecha_hora = @fecha_hora
                 AND estado <> 'Cancelada')
    BEGIN
        RAISERROR('El veterinario ya tiene una cita activa en ese horario.', 16, 1);
        RETURN;
    END

    DECLARE @nueva_cita INT;
    SELECT @nueva_cita = ISNULL(MAX(id_cita), 0) + 1 FROM Cita;

    INSERT INTO Cita (id_cita, id_mascota, id_veterinario, id_servicio,
                      fecha_hora, motivo, estado, observaciones)
    VALUES (@nueva_cita, @id_mascota, @id_veterinario, @id_servicio,
            @fecha_hora, @motivo, 'Programada', NULL);

    SELECT @nueva_cita AS id_cita_creada;
END;
GO

-- Procedimiento 5.3 Reporte de ingresos por periodo
-- Entrega los ingresos por categoria de servicio entre dos fechas,
-- una de las metricas que la administracion no podia obtener antes
CREATE PROCEDURE sp_ReporteIngresosPeriodo
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.categoria,
           COUNT(df.id_detalle) AS lineas,
           SUM(df.subtotal_linea) AS ingresos
    FROM DetalleFactura df
    INNER JOIN Servicio s ON df.id_servicio = s.id_servicio
    INNER JOIN Factura f ON df.id_factura = f.id_factura
    WHERE f.estado_pago <> 'Anulada'
      AND f.fecha_emision >= @fecha_inicio
      AND f.fecha_emision < DATEADD(DAY, 1, @fecha_fin)
    GROUP BY s.categoria
    ORDER BY ingresos DESC;
END;
GO

-- Seccion 6. Triggers

-- Tabla de apoyo del modelo fisico para la auditoria de precios.
-- No forma parte del modelo logico de 17 entidades: existe solo para
-- que el trigger de auditoria tenga donde registrar los cambios
CREATE TABLE AuditoriaPrecioServicio (
    id_auditoria INT IDENTITY(1,1) NOT NULL,
    id_servicio INT NOT NULL,
    precio_anterior DECIMAL(10,2) NOT NULL,
    precio_nuevo DECIMAL(10,2) NOT NULL,
    fecha_cambio DATETIME NOT NULL DEFAULT GETDATE(),
    usuario VARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    CONSTRAINT PK_AuditoriaPrecioServicio PRIMARY KEY (id_auditoria),
    CONSTRAINT FK_Auditoria_Servicio FOREIGN KEY (id_servicio) REFERENCES Servicio (id_servicio)
);
GO

-- Trigger 6.1 Descuento automatico de inventario
-- Al facturar un medicamento descuenta el stock del lote correspondiente.
-- Si no hay existencias suficientes revierte la operacion completa,
-- que era justo el descuadre que ocurria con las hojas de Excel
CREATE TRIGGER trg_DetalleFactura_DescontarStock
ON DetalleFactura
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN Inventario inv ON i.id_medicamento = inv.id_medicamento
               WHERE i.id_medicamento IS NOT NULL
                 AND inv.stock_actual < i.cantidad)
    BEGIN
        RAISERROR('No hay stock suficiente para facturar el medicamento.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE inv
    SET inv.stock_actual = inv.stock_actual - i.cantidad
    FROM Inventario inv
    INNER JOIN inserted i ON inv.id_medicamento = i.id_medicamento
    WHERE i.id_medicamento IS NOT NULL;
END;
GO

-- Trigger 6.2 Bloqueo de la doble reserva
-- Segunda linea de defensa ademas del procedimiento de agendamiento:
-- aunque alguien inserte directo en la tabla, el choque de agenda se rechaza
CREATE TRIGGER trg_Cita_EvitarDobleReserva
ON Cita
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1
               FROM Cita c
               INNER JOIN inserted i ON c.id_veterinario = i.id_veterinario
                   AND c.fecha_hora = i.fecha_hora
                   AND c.id_cita <> i.id_cita
               WHERE c.estado <> 'Cancelada' AND i.estado <> 'Cancelada')
    BEGIN
        RAISERROR('Choque de agenda: el veterinario ya tiene una cita en ese horario.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger 6.3 Auditoria de cambios de precio
-- Cada actualizacion del precio base de un servicio queda registrada
-- con el valor anterior, el nuevo, la fecha y el usuario que lo cambio
CREATE TRIGGER trg_Servicio_AuditarPrecio
ON Servicio
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(precio_base)
    BEGIN
        INSERT INTO AuditoriaPrecioServicio (id_servicio, precio_anterior, precio_nuevo)
        SELECT d.id_servicio, d.precio_base, i.precio_base
        FROM deleted d
        INNER JOIN inserted i ON d.id_servicio = i.id_servicio
        WHERE d.precio_base <> i.precio_base;
    END
END;
GO

-- Seccion 7. Pruebas de los objetos del modelo fisico

-- Prueba de las cinco vistas
SELECT * FROM vw_AgendaCitas WHERE estado = 'Programada' ORDER BY fecha_hora;
SELECT * FROM vw_ExpedienteClinico ORDER BY fecha_consulta DESC;
SELECT * FROM vw_StockCritico ORDER BY stock_actual;
SELECT * FROM vw_FacturacionClientes ORDER BY total_facturado DESC;
SELECT * FROM vw_PlanillaEmpleados ORDER BY salario DESC;
GO

-- Prueba del registro de cliente: crea la persona y el cliente en una transaccion
EXEC sp_RegistrarCliente
    @identificacion = '1-1502-0339',
    @nombre = 'Rebeca',
    @apellidos = 'Sanabria Ledezma',
    @telefono = '8611-2074',
    @correo = 'rebeca.sanabria@example.com',
    @direccion = 'Ipis de Guadalupe, Goicoechea, San Jose',
    @fecha_nacimiento = '1998-04-12',
    @tipo_cliente = 'Regular',
    @preferencia_contacto = 'WhatsApp';
GO

-- Prueba del agendamiento valido: horario libre, la cita se crea
EXEC sp_AgendarCita
    @id_mascota = 12,
    @id_veterinario = 31,
    @id_servicio = 1,
    @fecha_hora = '2026-07-27 10:00',
    @motivo = 'Control de peso del sindrome braquiocefalico';
GO

-- Prueba del reporte de ingresos del mes de junio de 2026
EXEC sp_ReporteIngresosPeriodo @fecha_inicio = '2026-06-01', @fecha_fin = '2026-06-30';
GO

-- Prueba del trigger de auditoria: se ajusta el precio de la consulta general
-- y se verifica que el cambio quedo registrado
UPDATE Servicio SET precio_base = 19500.00 WHERE id_servicio = 1;
SELECT * FROM AuditoriaPrecioServicio;
GO

-- Prueba del trigger de inventario: se factura un medicamento y el stock baja.
-- Antes de la venta el lote L-2026-0180 de Bravecto tiene 18 unidades
SELECT stock_actual FROM Inventario WHERE id_medicamento = 5;
INSERT INTO Factura (id_factura, id_cliente, id_empleado, fecha_emision,
                     subtotal, impuesto, total, estado_pago)
VALUES (21, 5, 41, GETDATE(), 32000.00, 4160.00, 36160.00, 'Pagada');
INSERT INTO DetalleFactura (id_detalle, id_factura, id_servicio, id_medicamento,
                            cantidad, precio_unitario, descuento, subtotal_linea)
VALUES (28, 21, NULL, 5, 1, 32000.00, 0.00, 32000.00);
SELECT stock_actual FROM Inventario WHERE id_medicamento = 5;
GO

/*
Prueba negativa del trigger de doble reserva. Se deja comentada para que el
script completo corra sin errores; al ejecutarla aparte, SQL Server rechaza
la insercion porque el veterinario 22 ya tiene cita el 1 de junio a las 9:00

INSERT INTO Cita (id_cita, id_mascota, id_veterinario, id_servicio,
                  fecha_hora, motivo, estado, observaciones)
VALUES (99, 2, 22, 1, '2026-06-01 09:00', 'Prueba de choque de agenda', 'Programada', NULL);
*/
"""


def generar(etapa, incluir_objetos, salida):
    """Arma el script completo de una etapa y lo escribe en disco."""
    partes = [ENCABEZADO.format(etapa=etapa), CREACION_BD,
              seccion_ddl(), seccion_inserts(), CONSULTAS]
    if incluir_objetos:
        partes.append(OBJETOS_FINALES)
    salida.parent.mkdir(parents=True, exist_ok=True)
    with open(salida, "w", encoding=CODIFICACION) as archivo:
        archivo.write("\n".join(partes))
    print("Generado:", salida)


def main():
    generar("Etapa: Avance 2", False, ARCHIVO_AVANCE2)
    generar("Etapa: Entrega Final y Defensa", True, ARCHIVO_FINAL)


if __name__ == "__main__":
    main()
