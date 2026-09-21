/*
Proyecto Integrador del curso de Bases de Datos
Sistema de gestion de base de datos para Escandalosos S.A.
Universidad Latinoamericana de Ciencia y Tecnologia (ULACIT)

Autor: Kevin Villalobos Obando
Desarrollado con el apoyo de Claude (Anthropic)
Motor: Microsoft SQL Server
Etapa: Avance 2

Escandalosos S.A. es una empresa ficticia creada con fines academicos y
todos los datos de este script son inventados.

El script se ejecuta de inicio a fin en una instancia de SQL Server.
El orden de las secciones respeta las dependencias de claves foraneas:
primero los supertipos de la jerarquia de herencia, luego los subtipos
y por ultimo las tablas transaccionales que dependen de ellos.
*/


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


-- Seccion 1. Creacion de las tablas del modelo

-- Supertipo de la jerarquia de herencia. Antes los datos personales se repetian en Cliente, Empleado y Veterinario; ahora se definen una unica vez aqui. La columna tipo_persona funciona como discriminador del subtipo.
CREATE TABLE Persona (
    id_persona INT NOT NULL,
    identificacion VARCHAR(20) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    correo VARCHAR(100) NULL,
    direccion VARCHAR(200) NULL,
    fecha_nacimiento DATE NULL,
    tipo_persona VARCHAR(20) NOT NULL,
    CONSTRAINT PK_Persona PRIMARY KEY (id_persona),
    CONSTRAINT UQ_Persona_identificacion UNIQUE (identificacion),
    CONSTRAINT CK_Persona_01 CHECK (tipo_persona IN ('Cliente', 'Empleado'))
);

-- Catalogo de puestos de trabajo. Se crea antes que Empleado porque este la referencia.
CREATE TABLE Puesto (
    id_puesto INT NOT NULL,
    nombre_puesto VARCHAR(60) NOT NULL,
    departamento VARCHAR(60) NOT NULL,
    nivel VARCHAR(30) NOT NULL,
    salario_base DECIMAL(10,2) NOT NULL,
    descripcion VARCHAR(200) NULL,
    activo BIT NOT NULL,
    fecha_creacion DATE NOT NULL,
    CONSTRAINT PK_Puesto PRIMARY KEY (id_puesto),
    CONSTRAINT CK_Puesto_01 CHECK (salario_base > 0)
);

-- Subtipo de Persona. Su clave primaria es a la vez clave foranea hacia el supertipo, que es la forma estandar de implementar herencia en el modelo relacional.
CREATE TABLE Cliente (
    id_cliente INT NOT NULL,
    fecha_registro DATE NOT NULL,
    tipo_cliente VARCHAR(20) NOT NULL,
    preferencia_contacto VARCHAR(20) NOT NULL,
    acepta_promociones BIT NOT NULL,
    referido_por VARCHAR(80) NULL,
    notas VARCHAR(200) NULL,
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT PK_Cliente PRIMARY KEY (id_cliente),
    CONSTRAINT FK_Cliente_Persona FOREIGN KEY (id_cliente) REFERENCES Persona (id_persona),
    CONSTRAINT CK_Cliente_01 CHECK (tipo_cliente IN ('Regular', 'Frecuente', 'VIP')),
    CONSTRAINT CK_Cliente_02 CHECK (estado IN ('Activo', 'Inactivo'))
);

-- Subtipo de Persona con los datos laborales. Igual que Cliente, comparte identificador con el supertipo.
CREATE TABLE Empleado (
    id_empleado INT NOT NULL,
    id_puesto INT NOT NULL,
    salario DECIMAL(10,2) NOT NULL,
    fecha_ingreso DATE NOT NULL,
    tipo_contrato VARCHAR(30) NOT NULL,
    jornada VARCHAR(30) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    fecha_salida DATE NULL,
    CONSTRAINT PK_Empleado PRIMARY KEY (id_empleado),
    CONSTRAINT FK_Empleado_Persona FOREIGN KEY (id_empleado) REFERENCES Persona (id_persona),
    CONSTRAINT FK_Empleado_Puesto FOREIGN KEY (id_puesto) REFERENCES Puesto (id_puesto),
    CONSTRAINT CK_Empleado_01 CHECK (salario > 0),
    CONSTRAINT CK_Empleado_02 CHECK (estado IN ('Activo', 'Inactivo'))
);

-- Subtipo de Empleado. La jerarquia completa es Persona, luego Empleado y luego Veterinario, por lo que un veterinario hereda tanto los datos personales como los laborales.
CREATE TABLE Veterinario (
    id_veterinario INT NOT NULL,
    numero_colegiado VARCHAR(30) NOT NULL,
    especialidad VARCHAR(60) NOT NULL,
    universidad_titulo VARCHAR(100) NOT NULL,
    anios_experiencia INT NOT NULL,
    atiende_emergencias BIT NOT NULL,
    fecha_colegiatura DATE NOT NULL,
    observaciones VARCHAR(200) NULL,
    CONSTRAINT PK_Veterinario PRIMARY KEY (id_veterinario),
    CONSTRAINT FK_Veterinario_Empleado FOREIGN KEY (id_veterinario) REFERENCES Empleado (id_empleado),
    CONSTRAINT UQ_Veterinario_numero_colegiado UNIQUE (numero_colegiado),
    CONSTRAINT CK_Veterinario_01 CHECK (anios_experiencia >= 0)
);

-- Empresas que suministran medicamentos a la clinica.
CREATE TABLE Proveedor (
    id_proveedor INT NOT NULL,
    nombre_empresa VARCHAR(100) NOT NULL,
    contacto VARCHAR(80) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    correo VARCHAR(100) NULL,
    direccion VARCHAR(200) NULL,
    activo BIT NOT NULL,
    condicion_pago VARCHAR(60) NOT NULL,
    CONSTRAINT PK_Proveedor PRIMARY KEY (id_proveedor)
);

-- Catalogo de servicios con su precio base en colones.
CREATE TABLE Servicio (
    id_servicio INT NOT NULL,
    nombre_servicio VARCHAR(80) NOT NULL,
    categoria VARCHAR(40) NOT NULL,
    descripcion VARCHAR(200) NULL,
    precio_base DECIMAL(10,2) NOT NULL,
    duracion_estimada_min INT NOT NULL,
    requiere_veterinario BIT NOT NULL,
    activo BIT NOT NULL,
    CONSTRAINT PK_Servicio PRIMARY KEY (id_servicio),
    CONSTRAINT CK_Servicio_01 CHECK (precio_base >= 0),
    CONSTRAINT CK_Servicio_02 CHECK (duracion_estimada_min > 0)
);

-- Catalogo de medicamentos. Referencia al proveedor que lo suministra.
CREATE TABLE Medicamento (
    id_medicamento INT NOT NULL,
    nombre_comercial VARCHAR(100) NOT NULL,
    principio_activo VARCHAR(100) NOT NULL,
    presentacion VARCHAR(60) NOT NULL,
    unidad_medida VARCHAR(30) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    requiere_receta BIT NOT NULL,
    id_proveedor INT NOT NULL,
    CONSTRAINT PK_Medicamento PRIMARY KEY (id_medicamento),
    CONSTRAINT FK_Medicamento_Proveedor FOREIGN KEY (id_proveedor) REFERENCES Proveedor (id_proveedor),
    CONSTRAINT CK_Medicamento_01 CHECK (precio_unitario >= 0)
);

-- Pacientes de la clinica. Cada mascota pertenece a un cliente.
CREATE TABLE Mascota (
    id_mascota INT NOT NULL,
    id_cliente INT NOT NULL,
    nombre VARCHAR(60) NOT NULL,
    especie VARCHAR(40) NOT NULL,
    raza VARCHAR(60) NOT NULL,
    fecha_nacimiento DATE NULL,
    peso_kg DECIMAL(5,2) NOT NULL,
    sexo CHAR(1) NOT NULL,
    CONSTRAINT PK_Mascota PRIMARY KEY (id_mascota),
    CONSTRAINT FK_Mascota_Cliente FOREIGN KEY (id_cliente) REFERENCES Cliente (id_cliente),
    CONSTRAINT CK_Mascota_01 CHECK (peso_kg > 0),
    CONSTRAINT CK_Mascota_02 CHECK (sexo IN ('M', 'H'))
);

-- Agenda de la clinica. Une mascota, veterinario y servicio en una fecha y hora concreta.
CREATE TABLE Cita (
    id_cita INT NOT NULL,
    id_mascota INT NOT NULL,
    id_veterinario INT NOT NULL,
    id_servicio INT NOT NULL,
    fecha_hora DATETIME NOT NULL,
    motivo VARCHAR(200) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    observaciones VARCHAR(300) NULL,
    CONSTRAINT PK_Cita PRIMARY KEY (id_cita),
    CONSTRAINT FK_Cita_Mascota FOREIGN KEY (id_mascota) REFERENCES Mascota (id_mascota),
    CONSTRAINT FK_Cita_Veterinario FOREIGN KEY (id_veterinario) REFERENCES Veterinario (id_veterinario),
    CONSTRAINT FK_Cita_Servicio FOREIGN KEY (id_servicio) REFERENCES Servicio (id_servicio),
    CONSTRAINT CK_Cita_01 CHECK (estado IN ('Programada', 'Atendida', 'Cancelada', 'Ausente'))
);

-- Expediente clinico. La columna notas usa VARCHAR(MAX) en lugar del tipo TEXT del modelo inicial, porque TEXT esta en desuso en SQL Server.
CREATE TABLE HistorialMedico (
    id_historial INT NOT NULL,
    id_mascota INT NOT NULL,
    id_veterinario INT NOT NULL,
    fecha_consulta DATETIME NOT NULL,
    diagnostico VARCHAR(300) NOT NULL,
    temperatura DECIMAL(4,1) NULL,
    peso_consulta DECIMAL(5,2) NULL,
    notas VARCHAR(MAX) NULL,
    CONSTRAINT PK_HistorialMedico PRIMARY KEY (id_historial),
    CONSTRAINT FK_HistorialMedico_Mascota FOREIGN KEY (id_mascota) REFERENCES Mascota (id_mascota),
    CONSTRAINT FK_HistorialMedico_Veterinario FOREIGN KEY (id_veterinario) REFERENCES Veterinario (id_veterinario)
);

-- Tratamientos indicados a partir de una consulta del historial.
CREATE TABLE Tratamiento (
    id_tratamiento INT NOT NULL,
    id_historial INT NOT NULL,
    nombre_tratamiento VARCHAR(100) NOT NULL,
    descripcion VARCHAR(300) NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    costo DECIMAL(10,2) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT PK_Tratamiento PRIMARY KEY (id_tratamiento),
    CONSTRAINT FK_Tratamiento_HistorialMedico FOREIGN KEY (id_historial) REFERENCES HistorialMedico (id_historial),
    CONSTRAINT CK_Tratamiento_01 CHECK (costo >= 0),
    CONSTRAINT CK_Tratamiento_02 CHECK (estado IN ('En curso', 'Finalizado', 'Suspendido')),
    CONSTRAINT CK_Tratamiento_03 CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

-- Recetas emitidas en una consulta. Une el historial con el medicamento.
CREATE TABLE Prescripcion (
    id_prescripcion INT NOT NULL,
    id_historial INT NOT NULL,
    id_medicamento INT NOT NULL,
    dosis VARCHAR(80) NOT NULL,
    frecuencia VARCHAR(60) NOT NULL,
    duracion_dias INT NOT NULL,
    indicaciones VARCHAR(200) NULL,
    fecha_prescripcion DATE NOT NULL,
    CONSTRAINT PK_Prescripcion PRIMARY KEY (id_prescripcion),
    CONSTRAINT FK_Prescripcion_HistorialMedico FOREIGN KEY (id_historial) REFERENCES HistorialMedico (id_historial),
    CONSTRAINT FK_Prescripcion_Medicamento FOREIGN KEY (id_medicamento) REFERENCES Medicamento (id_medicamento),
    CONSTRAINT CK_Prescripcion_01 CHECK (duracion_dias > 0)
);

-- Existencias por lote. La restriccion unica sobre medicamento y lote evita registrar dos veces el mismo lote.
CREATE TABLE Inventario (
    id_inventario INT NOT NULL,
    id_medicamento INT NOT NULL,
    stock_actual INT NOT NULL,
    stock_minimo INT NOT NULL,
    fecha_ultima_entrada DATE NOT NULL,
    lote VARCHAR(40) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    ubicacion VARCHAR(60) NOT NULL,
    CONSTRAINT PK_Inventario PRIMARY KEY (id_inventario),
    CONSTRAINT FK_Inventario_Medicamento FOREIGN KEY (id_medicamento) REFERENCES Medicamento (id_medicamento),
    CONSTRAINT UQ_Inventario_id_medicamento_lote UNIQUE (id_medicamento, lote),
    CONSTRAINT CK_Inventario_01 CHECK (stock_actual >= 0),
    CONSTRAINT CK_Inventario_02 CHECK (stock_minimo >= 0)
);

-- Encabezado de facturacion. El impuesto corresponde al IVA del 13 por ciento.
CREATE TABLE Factura (
    id_factura INT NOT NULL,
    id_cliente INT NOT NULL,
    id_empleado INT NOT NULL,
    fecha_emision DATETIME NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    impuesto DECIMAL(10,2) NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    estado_pago VARCHAR(20) NOT NULL,
    CONSTRAINT PK_Factura PRIMARY KEY (id_factura),
    CONSTRAINT FK_Factura_Cliente FOREIGN KEY (id_cliente) REFERENCES Cliente (id_cliente),
    CONSTRAINT FK_Factura_Empleado FOREIGN KEY (id_empleado) REFERENCES Empleado (id_empleado),
    CONSTRAINT CK_Factura_01 CHECK (subtotal >= 0),
    CONSTRAINT CK_Factura_02 CHECK (estado_pago IN ('Pendiente', 'Pagada', 'Anulada'))
);

-- Lineas de factura. La restriccion CK garantiza que cada linea sea de un servicio o de un medicamento, pero nunca de ambos ni de ninguno.
CREATE TABLE DetalleFactura (
    id_detalle INT NOT NULL,
    id_factura INT NOT NULL,
    id_servicio INT NULL,
    id_medicamento INT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    descuento DECIMAL(5,2) NOT NULL,
    subtotal_linea DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_DetalleFactura PRIMARY KEY (id_detalle),
    CONSTRAINT FK_DetalleFactura_Factura FOREIGN KEY (id_factura) REFERENCES Factura (id_factura),
    CONSTRAINT FK_DetalleFactura_Servicio FOREIGN KEY (id_servicio) REFERENCES Servicio (id_servicio),
    CONSTRAINT FK_DetalleFactura_Medicamento FOREIGN KEY (id_medicamento) REFERENCES Medicamento (id_medicamento),
    CONSTRAINT CK_DetalleFactura_01 CHECK (cantidad > 0),
    CONSTRAINT CK_DetalleFactura_02 CHECK (descuento >= 0 AND descuento <= 100),
    CONSTRAINT CK_DetalleFactura_03 CHECK ((id_servicio IS NOT NULL AND id_medicamento IS NULL) OR (id_servicio IS NULL AND id_medicamento IS NOT NULL))
);

-- Internamientos. La fecha de egreso admite nulos porque el paciente puede seguir internado.
CREATE TABLE Hospitalizacion (
    id_hospitalizacion INT NOT NULL,
    id_mascota INT NOT NULL,
    id_veterinario INT NOT NULL,
    fecha_ingreso DATETIME NOT NULL,
    fecha_egreso DATETIME NULL,
    motivo_ingreso VARCHAR(200) NOT NULL,
    jaula_asignada VARCHAR(20) NOT NULL,
    costo_dia DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_Hospitalizacion PRIMARY KEY (id_hospitalizacion),
    CONSTRAINT FK_Hospitalizacion_Mascota FOREIGN KEY (id_mascota) REFERENCES Mascota (id_mascota),
    CONSTRAINT FK_Hospitalizacion_Veterinario FOREIGN KEY (id_veterinario) REFERENCES Veterinario (id_veterinario),
    CONSTRAINT CK_Hospitalizacion_01 CHECK (costo_dia >= 0),
    CONSTRAINT CK_Hospitalizacion_02 CHECK (fecha_egreso IS NULL OR fecha_egreso >= fecha_ingreso)
);

-- Indices no agrupados sobre las columnas que mas se usan en busquedas y joins
CREATE NONCLUSTERED INDEX IX_Mascota_Cliente ON Mascota (id_cliente);
CREATE NONCLUSTERED INDEX IX_Cita_Veterinario_Fecha ON Cita (id_veterinario, fecha_hora);
CREATE NONCLUSTERED INDEX IX_Cita_Mascota ON Cita (id_mascota);
CREATE NONCLUSTERED INDEX IX_Historial_Mascota ON HistorialMedico (id_mascota);
CREATE NONCLUSTERED INDEX IX_Prescripcion_Historial ON Prescripcion (id_historial);
CREATE NONCLUSTERED INDEX IX_Inventario_Medicamento ON Inventario (id_medicamento);
CREATE NONCLUSTERED INDEX IX_Factura_Cliente ON Factura (id_cliente);
CREATE NONCLUSTERED INDEX IX_DetalleFactura_Factura ON DetalleFactura (id_factura);
GO

-- Seccion 2. Carga de datos iniciales
-- Los identificadores se insertan de forma explicita para controlar
-- la integridad referencial de la carga: personas 1 a 20 son clientes
-- y de la 21 a la 45 son empleados, de los cuales 21 a 40 son veterinarios

-- Personas de la clinica: supertipo comun de clientes y empleados
INSERT INTO Persona (id_persona, identificacion, nombre, apellidos, telefono, correo, direccion, fecha_nacimiento, tipo_persona) VALUES
    (1, N'1-1123-0456', N'María José', N'Rodríguez Mora', N'8834-1290', N'mariajose.rodriguez@example.com', N'Purral de Guadalupe, Goicoechea, San José', N'1988-03-14', N'Cliente'),
    (2, N'1-0987-0234', N'Andrés', N'Vargas Jiménez', N'8712-4455', N'andres.vargas88@example.com', N'San Francisco de Dos Ríos, San José', N'1979-11-02', N'Cliente'),
    (3, N'1-1345-0789', N'Daniela', N'Rojas Castro', N'8990-1123', N'daniela.rojasc@example.com', N'Moravia centro, San José', N'1993-06-25', N'Cliente'),
    (4, N'1-0765-0912', N'Luis Fernando', N'Solano Araya', N'8456-7788', N'lf.solano@example.com', N'Zapote, San José', N'1975-01-30', N'Cliente'),
    (5, N'1-1567-0345', N'Carolina', N'Salas Campos', N'8321-9034', N'caro.salas@example.com', N'Sabanilla, Montes de Oca, San José', N'1996-09-12', N'Cliente'),
    (6, N'1-1098-0678', N'José Pablo', N'Brenes Quesada', N'8845-2211', N'jp.brenes@example.com', N'Curridabat centro, San José', N'1985-04-08', N'Cliente'),
    (7, N'1-1432-0110', N'Fernanda', N'Alfaro Chacón', N'8778-6690', N'fer.alfaro@example.com', N'Tibás, San José', N'1991-12-19', N'Cliente'),
    (8, N'1-0854-0567', N'Diego', N'Ulate Monge', N'8534-8812', N'diego.ulate@example.com', N'Desamparados centro, San José', N'1982-07-03', N'Cliente'),
    (9, N'1-1210-0893', N'Gabriela', N'Zúñiga Picado', N'8667-3345', N'gabyzuniga@example.com', N'Guadalupe centro, Goicoechea, San José', N'1994-02-27', N'Cliente'),
    (10, N'1-0932-0221', N'Marco Antonio', N'Cordero Sandí', N'8443-5567', N'marco.cordero@example.com', N'Hatillo 4, San José', N'1978-08-15', N'Cliente'),
    (11, N'1-1489-0654', N'Valeria', N'Fallas Elizondo', N'8890-2276', N'vale.fallas@example.com', N'San Pedro, Montes de Oca, San José', N'1997-05-21', N'Cliente'),
    (12, N'1-1076-0432', N'Esteban', N'Barrantes Segura', N'8556-9901', N'esteban.barrantes@example.com', N'Alajuelita centro, San José', N'1986-10-09', N'Cliente'),
    (13, N'1-1298-0765', N'Natalia', N'Villegas Calderón', N'8723-4410', N'nati.villegas@example.com', N'Coronado, San José', N'1992-03-06', N'Cliente'),
    (14, N'1-0812-0198', N'Ricardo', N'Madrigal Umaña', N'8398-6634', N'ricardo.madrigal@example.com', N'Pavas, San José', N'1973-06-18', N'Cliente'),
    (15, N'1-1354-0287', N'Silvia', N'Retana Bolaños', N'8812-7745', N'silvia.retana@example.com', N'La Uruca, San José', N'1989-01-24', N'Cliente'),
    (16, N'1-1187-0543', N'Jorge Luis', N'Picado Vargas', N'8645-3312', N'jorgel.picado@example.com', N'Escazú centro, San José', N'1984-09-30', N'Cliente'),
    (17, N'1-1421-0876', N'Melissa', N'Campos Rojas', N'8934-5578', N'meli.campos@example.com', N'Santa Ana, San José', N'1995-11-11', N'Cliente'),
    (18, N'1-0898-0321', N'Pablo', N'Quesada Solano', N'8467-8890', N'pablo.quesada@example.com', N'San Sebastián, San José', N'1981-04-17', N'Cliente'),
    (19, N'1-1265-0710', N'Karina', N'Araya Brenes', N'8701-2234', N'karina.araya@example.com', N'Mata Redonda, San José', N'1990-07-28', N'Cliente'),
    (20, N'1-1043-0587', N'Óscar', N'Jiménez Salas', N'8589-4467', N'oscar.jimenez@example.com', N'Purral arriba, Goicoechea, San José', N'1976-12-05', N'Cliente'),
    (21, N'1-0876-0143', N'Tatiana', N'Mora Villalobos', N'8823-6712', N'tatiana.mora@escandalosos.co.cr', N'Moravia, San José', N'1983-02-11', N'Empleado'),
    (22, N'1-0954-0398', N'Randall', N'Chaves Gamboa', N'8710-4489', N'randall.chaves@escandalosos.co.cr', N'Guadalupe, Goicoechea, San José', N'1980-05-27', N'Empleado'),
    (23, N'1-1132-0621', N'Priscila', N'Hernández Obando', N'8945-2290', N'priscila.hernandez@escandalosos.co.cr', N'Curridabat, San José', N'1987-08-19', N'Empleado'),
    (24, N'1-1087-0854', N'Greivin', N'Arguedas Rojas', N'8632-7745', N'greivin.arguedas@escandalosos.co.cr', N'Tibás, San José', N'1985-10-14', N'Empleado'),
    (25, N'1-1243-0176', N'Yorleny', N'Guzmán Salas', N'8578-9912', N'yorleny.guzman@escandalosos.co.cr', N'Desamparados, San José', N'1989-03-23', N'Empleado'),
    (26, N'1-0921-0489', N'Allan', N'Vargas Cordero', N'8867-3356', N'allan.vargas@escandalosos.co.cr', N'San Pedro, Montes de Oca, San José', N'1982-06-07', N'Empleado'),
    (27, N'1-1176-0712', N'Marcela', N'Castro Fallas', N'8734-5589', N'marcela.castro@escandalosos.co.cr', N'Zapote, San José', N'1990-09-16', N'Empleado'),
    (28, N'1-1058-0935', N'Fabián', N'Solís Barrantes', N'8412-6623', N'fabian.solis@escandalosos.co.cr', N'Sabanilla, Montes de Oca, San José', N'1986-12-01', N'Empleado'),
    (29, N'1-1312-0258', N'Susana', N'Picado Madrigal', N'8890-7734', N'susana.picado@escandalosos.co.cr', N'Coronado, San José', N'1992-01-29', N'Empleado'),
    (30, N'1-0989-0581', N'Mauricio', N'Umaña Retana', N'8556-1148', N'mauricio.umana@escandalosos.co.cr', N'Alajuelita, San José', N'1981-04-12', N'Empleado'),
    (31, N'1-1225-0804', N'Pamela', N'Bolaños Villegas', N'8623-9967', N'pamela.bolanos@escandalosos.co.cr', N'Hatillo 2, San José', N'1993-07-05', N'Empleado'),
    (32, N'1-1101-0127', N'Rodolfo', N'Calderón Zúñiga', N'8778-2281', N'rodolfo.calderon@escandalosos.co.cr', N'Pavas, San José', N'1979-10-20', N'Empleado'),
    (33, N'1-1367-0450', N'Ivannia', N'Sandí Quesada', N'8945-6614', N'ivannia.sandi@escandalosos.co.cr', N'La Uruca, San José', N'1988-02-08', N'Empleado'),
    (34, N'1-1034-0773', N'Gerardo', N'Monge Araya', N'8501-8837', N'gerardo.monge@escandalosos.co.cr', N'San Francisco de Dos Ríos, San José', N'1984-05-31', N'Empleado'),
    (35, N'1-1289-0096', N'Laura', N'Elizondo Chacón', N'8867-4452', N'laura.elizondo@escandalosos.co.cr', N'Escazú, San José', N'1991-08-26', N'Empleado'),
    (36, N'1-0967-0319', N'Cristian', N'Segura Ulate', N'8712-5578', N'cristian.segura@escandalosos.co.cr', N'Santa Ana, San José', N'1983-11-13', N'Empleado'),
    (37, N'1-1198-0642', N'Adriana', N'Rojas Campos', N'8834-9923', N'adriana.rojas@escandalosos.co.cr', N'Guadalupe, Goicoechea, San José', N'1994-04-02', N'Empleado'),
    (38, N'1-1076-0965', N'Minor', N'Salas Brenes', N'8445-1167', N'minor.salas@escandalosos.co.cr', N'Moravia, San José', N'1980-07-22', N'Empleado'),
    (39, N'1-1332-0288', N'Rebeca', N'Chacón Alfaro', N'8990-6634', N'rebeca.chacon@escandalosos.co.cr', N'Curridabat, San José', N'1989-10-10', N'Empleado'),
    (40, N'1-1009-0511', N'Johnny', N'Obando Solano', N'8567-2245', N'johnny.obando@escandalosos.co.cr', N'San Sebastián, San José', N'1977-01-15', N'Empleado'),
    (41, N'1-1256-0834', N'Grettel', N'Villalobos Mora', N'8623-7789', N'grettel.villalobos@escandalosos.co.cr', N'Purral de Guadalupe, Goicoechea, San José', N'1995-03-19', N'Empleado'),
    (42, N'1-1143-0157', N'Alonso', N'Gamboa Hernández', N'8778-4412', N'alonso.gamboa@escandalosos.co.cr', N'Tibás, San José', N'1992-06-04', N'Empleado'),
    (43, N'1-0898-0480', N'Vivian', N'Arguedas Chaves', N'8834-6656', N'vivian.arguedas@escandalosos.co.cr', N'Moravia, San José', N'1978-09-09', N'Empleado'),
    (44, N'1-1310-0703', N'Hugo', N'Guzmán Vargas', N'8945-8871', N'hugo.guzman@escandalosos.co.cr', N'Goicoechea, San José', N'1996-12-23', N'Empleado'),
    (45, N'1-1187-0026', N'Karla', N'Salazar Rojas', N'8512-3394', N'karla.salazar@escandalosos.co.cr', N'San Pedro, Montes de Oca, San José', N'1993-05-08', N'Empleado');

-- Catalogo de puestos de trabajo de la clinica
INSERT INTO Puesto (id_puesto, nombre_puesto, departamento, nivel, salario_base, descripcion, activo, fecha_creacion) VALUES
    (1, N'Veterinario General', N'Medicina Veterinaria', N'Profesional', 950000.00, N'Atiende consultas generales y vacunación', 1, N'2020-01-15'),
    (2, N'Veterinario Cirujano', N'Medicina Veterinaria', N'Profesional', 1250000.00, N'Realiza cirugías menores y mayores', 1, N'2020-01-15'),
    (3, N'Veterinario Dermatólogo', N'Medicina Veterinaria', N'Profesional', 1100000.00, N'Atiende casos de piel y alergias', 1, N'2020-06-01'),
    (4, N'Veterinario Internista', N'Medicina Veterinaria', N'Profesional', 1150000.00, N'Atiende medicina interna y hospitalización', 1, N'2020-06-01'),
    (5, N'Asistente Veterinario', N'Medicina Veterinaria', N'Tecnico', 520000.00, N'Apoya al veterinario en consulta y quirófano', 1, N'2020-01-15'),
    (6, N'Recepcionista', N'Servicio al Cliente', N'Operativo', 460000.00, N'Recibe clientes y gestiona la agenda de citas', 1, N'2020-01-15'),
    (7, N'Administrador General', N'Administración', N'Gerencial', 1500000.00, N'Dirige la operación completa de la clínica', 1, N'2020-01-15'),
    (8, N'Groomer', N'Estética', N'Tecnico', 480000.00, N'Realiza baños, cortes y estética canina y felina', 1, N'2020-03-01'),
    (9, N'Encargado de Bodega', N'Logística', N'Operativo', 470000.00, N'Controla existencias y entradas de producto', 1, N'2020-03-01'),
    (10, N'Auxiliar de Farmacia', N'Farmacia', N'Tecnico', 500000.00, N'Despacha medicamentos y controla recetas', 1, N'2020-08-01'),
    (11, N'Técnico de Laboratorio', N'Laboratorio', N'Tecnico', 620000.00, N'Procesa muestras y exámenes clínicos', 1, N'2021-01-10'),
    (12, N'Encargado de Hospitalización', N'Medicina Veterinaria', N'Tecnico', 560000.00, N'Supervisa pacientes internados', 1, N'2021-01-10'),
    (13, N'Contador', N'Administración', N'Profesional', 850000.00, N'Lleva la contabilidad y las obligaciones fiscales', 1, N'2021-05-01'),
    (14, N'Auxiliar de Limpieza', N'Servicios Generales', N'Operativo', 380000.00, N'Mantiene la limpieza de las instalaciones', 1, N'2020-01-15'),
    (15, N'Guarda de Seguridad', N'Servicios Generales', N'Operativo', 420000.00, N'Vigila las instalaciones de la clínica', 1, N'2020-01-15'),
    (16, N'Encargado de Mercadeo', N'Mercadeo', N'Profesional', 780000.00, N'Gestiona redes sociales y campañas', 1, N'2022-02-01'),
    (17, N'Mensajero', N'Logística', N'Operativo', 400000.00, N'Realiza entregas y trámites externos', 1, N'2022-02-01'),
    (18, N'Coordinador de Citas', N'Servicio al Cliente', N'Operativo', 490000.00, N'Confirma y reprograma citas con los clientes', 1, N'2022-08-01'),
    (19, N'Auxiliar Administrativo', N'Administración', N'Operativo', 450000.00, N'Apoya labores administrativas generales', 1, N'2023-01-15'),
    (20, N'Encargado de Compras', N'Logística', N'Profesional', 720000.00, N'Negocia con proveedores y gestiona pedidos', 1, N'2023-01-15');

-- Clientes: subtipo de Persona, comparten identificador con el supertipo
INSERT INTO Cliente (id_cliente, fecha_registro, tipo_cliente, preferencia_contacto, acepta_promociones, referido_por, notas, estado) VALUES
    (1, N'2023-02-10', N'Frecuente', N'WhatsApp', 1, N'Recomendación de un vecino', N'Prefiere citas en la mañana', N'Activo'),
    (2, N'2023-03-22', N'Regular', N'Telefono', 0, N'Redes sociales', NULL, N'Activo'),
    (3, N'2023-05-04', N'VIP', N'WhatsApp', 1, N'Campaña de vacunación 2023', N'Cliente con tres mascotas registradas', N'Activo'),
    (4, N'2023-06-15', N'Regular', N'Correo', 0, N'Pasaba por el local', NULL, N'Activo'),
    (5, N'2023-08-01', N'Frecuente', N'WhatsApp', 1, N'Recomendación de otro cliente', NULL, N'Activo'),
    (6, N'2023-09-12', N'Regular', N'Telefono', 1, N'Redes sociales', N'Consulta precios antes de agendar', N'Activo'),
    (7, N'2023-10-25', N'Regular', N'WhatsApp', 0, N'Búsqueda en Google', NULL, N'Activo'),
    (8, N'2023-11-30', N'Frecuente', N'Correo', 1, N'Feria de adopción de Goicoechea', NULL, N'Activo'),
    (9, N'2024-01-18', N'VIP', N'WhatsApp', 1, N'Recomendación de un familiar', N'Solicita siempre al mismo veterinario', N'Activo'),
    (10, N'2024-02-27', N'Regular', N'Telefono', 0, N'Pasaba por el local', NULL, N'Inactivo'),
    (11, N'2024-04-09', N'Regular', N'WhatsApp', 1, N'Redes sociales', NULL, N'Activo'),
    (12, N'2024-05-21', N'Frecuente', N'WhatsApp', 1, N'Recomendación de un vecino', N'Paga siempre con tarjeta', N'Activo'),
    (13, N'2024-07-02', N'Regular', N'Correo', 0, N'Búsqueda en Google', NULL, N'Activo'),
    (14, N'2024-08-14', N'Regular', N'Telefono', 1, N'Campaña de castración 2024', NULL, N'Activo'),
    (15, N'2024-09-26', N'Frecuente', N'WhatsApp', 1, N'Recomendación de otro cliente', NULL, N'Activo'),
    (16, N'2024-11-07', N'Regular', N'WhatsApp', 0, N'Redes sociales', N'Pide factura electrónica', N'Activo'),
    (17, N'2025-01-15', N'Regular', N'Correo', 1, N'Búsqueda en Google', NULL, N'Activo'),
    (18, N'2025-03-03', N'Regular', N'Telefono', 0, N'Pasaba por el local', NULL, N'Activo'),
    (19, N'2025-05-20', N'Frecuente', N'WhatsApp', 1, N'Recomendación de un familiar', NULL, N'Activo'),
    (20, N'2025-08-11', N'Regular', N'WhatsApp', 1, N'Feria de salud animal de Purral', NULL, N'Activo');

-- Empleados: subtipo de Persona con la informacion laboral
INSERT INTO Empleado (id_empleado, id_puesto, salario, fecha_ingreso, tipo_contrato, jornada, estado, fecha_salida) VALUES
    (21, 2, 1280000.00, N'2020-02-01', N'Indefinido', N'Completa', N'Activo', NULL),
    (22, 1, 960000.00, N'2020-02-01', N'Indefinido', N'Completa', N'Activo', NULL),
    (23, 3, 1120000.00, N'2020-07-15', N'Indefinido', N'Completa', N'Activo', NULL),
    (24, 1, 955000.00, N'2020-09-01', N'Indefinido', N'Completa', N'Activo', NULL),
    (25, 4, 1160000.00, N'2021-01-11', N'Indefinido', N'Completa', N'Activo', NULL),
    (26, 1, 965000.00, N'2021-03-01', N'Indefinido', N'Mixta', N'Activo', NULL),
    (27, 2, 1300000.00, N'2021-06-14', N'Indefinido', N'Completa', N'Activo', NULL),
    (28, 1, 950000.00, N'2021-09-01', N'Plazo fijo', N'Completa', N'Activo', NULL),
    (29, 3, 1105000.00, N'2022-01-10', N'Indefinido', N'Completa', N'Activo', NULL),
    (30, 1, 970000.00, N'2022-03-01', N'Indefinido', N'Media', N'Activo', NULL),
    (31, 4, 1170000.00, N'2022-05-16', N'Indefinido', N'Completa', N'Activo', NULL),
    (32, 1, 958000.00, N'2022-08-01', N'Indefinido', N'Completa', N'Activo', NULL),
    (33, 2, 1265000.00, N'2022-11-01', N'Indefinido', N'Completa', N'Activo', NULL),
    (34, 1, 962000.00, N'2023-01-16', N'Plazo fijo', N'Completa', N'Activo', NULL),
    (35, 3, 1115000.00, N'2023-04-03', N'Indefinido', N'Completa', N'Activo', NULL),
    (36, 1, 953000.00, N'2023-07-01', N'Indefinido', N'Mixta', N'Activo', NULL),
    (37, 4, 1155000.00, N'2023-10-02', N'Indefinido', N'Completa', N'Activo', NULL),
    (38, 1, 967000.00, N'2024-01-08', N'Indefinido', N'Completa', N'Activo', NULL),
    (39, 2, 1275000.00, N'2024-04-01', N'Indefinido', N'Completa', N'Activo', NULL),
    (40, 1, 951000.00, N'2024-07-01', N'Servicios', N'Media', N'Activo', NULL),
    (41, 6, 465000.00, N'2020-02-01', N'Indefinido', N'Completa', N'Activo', NULL),
    (42, 6, 462000.00, N'2021-08-02', N'Indefinido', N'Completa', N'Activo', NULL),
    (43, 7, 1520000.00, N'2020-01-20', N'Indefinido', N'Completa', N'Activo', NULL),
    (44, 5, 525000.00, N'2022-02-14', N'Indefinido', N'Completa', N'Activo', NULL),
    (45, 8, 485000.00, N'2023-03-06', N'Indefinido', N'Mixta', N'Activo', NULL);

-- Veterinarios: subtipo de Empleado con la informacion profesional
INSERT INTO Veterinario (id_veterinario, numero_colegiado, especialidad, universidad_titulo, anios_experiencia, atiende_emergencias, fecha_colegiatura, observaciones) VALUES
    (21, N'CMV-2145', N'Cirugía de tejidos blandos', N'Universidad Nacional de Costa Rica', 14, 1, N'2012-03-15', N'Jefe del área quirúrgica'),
    (22, N'CMV-2390', N'Medicina general', N'Universidad Nacional de Costa Rica', 12, 1, N'2014-06-20', NULL),
    (23, N'CMV-2511', N'Dermatología veterinaria', N'Universidad VERITAS', 10, 0, N'2016-02-11', NULL),
    (24, N'CMV-2678', N'Medicina general', N'Universidad Técnica Nacional', 9, 1, N'2017-05-08', NULL),
    (25, N'CMV-2743', N'Medicina interna', N'Universidad Nacional de Costa Rica', 11, 1, N'2015-09-14', N'Coordina el área de hospitalización'),
    (26, N'CMV-2856', N'Medicina general', N'Universidad Latina de Costa Rica', 8, 0, N'2018-01-22', NULL),
    (27, N'CMV-2901', N'Cirugía ortopédica', N'Universidad Nacional de Costa Rica', 13, 1, N'2013-08-05', NULL),
    (28, N'CMV-3044', N'Medicina general', N'Universidad Técnica Nacional', 6, 1, N'2020-03-17', NULL),
    (29, N'CMV-3120', N'Dermatología veterinaria', N'Universidad VERITAS', 9, 0, N'2017-11-29', NULL),
    (30, N'CMV-3287', N'Medicina general', N'Universidad Latina de Costa Rica', 7, 0, N'2019-04-10', N'Labora media jornada'),
    (31, N'CMV-3355', N'Medicina interna', N'Universidad Nacional de Costa Rica', 10, 1, N'2016-07-25', NULL),
    (32, N'CMV-3412', N'Medicina general', N'Universidad Técnica Nacional', 5, 1, N'2021-02-08', NULL),
    (33, N'CMV-3508', N'Cirugía de tejidos blandos', N'Universidad Nacional de Costa Rica', 12, 1, N'2014-10-13', NULL),
    (34, N'CMV-3651', N'Medicina general', N'Universidad Latina de Costa Rica', 4, 0, N'2022-05-19', NULL),
    (35, N'CMV-3729', N'Dermatología veterinaria', N'Universidad VERITAS', 8, 0, N'2018-09-03', NULL),
    (36, N'CMV-3803', N'Medicina general', N'Universidad Nacional de Costa Rica', 6, 1, N'2020-06-15', NULL),
    (37, N'CMV-3946', N'Medicina interna', N'Universidad Nacional de Costa Rica', 9, 1, N'2017-03-27', NULL),
    (38, N'CMV-4032', N'Medicina general', N'Universidad Técnica Nacional', 3, 0, N'2023-01-30', NULL),
    (39, N'CMV-4118', N'Cirugía ortopédica', N'Universidad Nacional de Costa Rica', 11, 1, N'2015-12-07', NULL),
    (40, N'CMV-4275', N'Medicina general', N'Universidad Latina de Costa Rica', 2, 0, N'2024-04-22', N'Contrato por servicios profesionales');

-- Proveedores de medicamentos y suministros
INSERT INTO Proveedor (id_proveedor, nombre_empresa, contacto, telefono, correo, direccion, activo, condicion_pago) VALUES
    (1, N'Distribuidora Veterinaria del Este S.A.', N'Carlos Herrera', N'2234-5510', N'ventas@distvet-este.co.cr', N'Curridabat, San José', 1, N'Crédito 30 días'),
    (2, N'Farmavet Costa Rica S.A.', N'Lucía Espinoza', N'2245-8823', N'pedidos@farmavetcr.com', N'La Uruca, San José', 1, N'Crédito 30 días'),
    (3, N'Agrocampo del Valle S.A.', N'Roberto Núñez', N'2278-4419', N'info@agrocampovalle.co.cr', N'Cartago centro', 1, N'Contado'),
    (4, N'Laboratorios Zoosalud S.A.', N'Patricia Loría', N'2290-6672', N'ventas@zoosalud.com', N'Heredia, San Francisco', 1, N'Crédito 45 días'),
    (5, N'Importadora Animal Care CR', N'Manuel Rivas', N'2221-3348', N'contacto@animalcarecr.com', N'Zapote, San José', 1, N'Crédito 30 días'),
    (6, N'Provet Suministros S.A.', N'Alejandra Meza', N'2256-9915', N'ventas@provetcr.com', N'Alajuela centro', 1, N'Contado'),
    (7, N'Nutrición Animal del Pacífico', N'Gustavo Solera', N'2661-2287', N'pedidos@nutripacifico.co.cr', N'Puntarenas centro', 1, N'Crédito 30 días'),
    (8, N'BioVet Laboratorios S.A.', N'Silvia Granados', N'2283-7741', N'info@biovetlab.com', N'San Pedro, Montes de Oca', 1, N'Crédito 60 días'),
    (9, N'Distribuidora Canina y Felina S.A.', N'Erick Bermúdez', N'2244-1156', N'ventas@dcfcr.com', N'Tibás, San José', 1, N'Crédito 30 días'),
    (10, N'Insumos Veterinarios del Norte', N'Marlene Chinchilla', N'2460-8834', N'pedidos@ivnorte.co.cr', N'San Carlos, Alajuela', 1, N'Contado'),
    (11, N'Vacunas y Biológicos CR S.A.', N'Federico Arias', N'2228-5567', N'ventas@vacbiocr.com', N'Escazú, San José', 1, N'Crédito 45 días'),
    (12, N'Equipos Médicos Veterinarios S.A.', N'Rocío Valverde', N'2235-2290', N'info@emvet.co.cr', N'Pavas, San José', 1, N'Crédito 60 días'),
    (13, N'Alimentos Premium Pet S.A.', N'Javier Montoya', N'2272-6613', N'pedidos@premiumpetcr.com', N'Desamparados, San José', 1, N'Crédito 30 días'),
    (14, N'Droguería Veterinaria Central', N'Ana Cascante', N'2258-9948', N'ventas@drovetcentral.com', N'San José centro', 1, N'Contado'),
    (15, N'Suplementos Animales del Sur', N'Óscar Fonseca', N'2771-3325', N'info@suplesur.co.cr', N'Pérez Zeledón, San José', 0, N'Contado'),
    (16, N'Genéricos Veterinarios S.A.', N'Karla Miranda', N'2249-7752', N'pedidos@genvetcr.com', N'Goicoechea, San José', 1, N'Crédito 30 días'),
    (17, N'Importadora Mascota Feliz', N'Diego Alpízar', N'2262-4486', N'ventas@mascotafelizcr.com', N'Heredia centro', 1, N'Crédito 30 días'),
    (18, N'Antiparasitarios de Centroamérica', N'Vanessa Rojas', N'2231-8819', N'info@antiparasitarioscr.com', N'Santa Ana, San José', 1, N'Crédito 45 días'),
    (19, N'Laboratorio Clínico Animal S.A.', N'Henry Sibaja', N'2225-5573', N'contacto@labclinanimal.com', N'Moravia, San José', 1, N'Crédito 30 días'),
    (20, N'Distribuidora Farmacéutica Vet Plus', N'Gabriela Solís', N'2240-2264', N'ventas@vetpluscr.com', N'Guadalupe, Goicoechea', 1, N'Crédito 30 días');

-- Catalogo de servicios con precios en colones
INSERT INTO Servicio (id_servicio, nombre_servicio, categoria, descripcion, precio_base, duracion_estimada_min, requiere_veterinario, activo) VALUES
    (1, N'Consulta general', N'Consulta', N'Valoración médica general de la mascota', 18500.00, 30, 1, 1),
    (2, N'Consulta de emergencia', N'Consulta', N'Atención inmediata fuera de agenda', 35000.00, 45, 1, 1),
    (3, N'Vacunación múltiple', N'Prevención', N'Aplicación de vacuna séxtuple o triple felina', 16000.00, 15, 1, 1),
    (4, N'Vacunación antirrábica', N'Prevención', N'Aplicación de vacuna contra la rabia', 12000.00, 15, 1, 1),
    (5, N'Desparasitación', N'Prevención', N'Desparasitación interna según peso', 9500.00, 15, 0, 1),
    (6, N'Castración canina', N'Cirugía', N'Esterilización quirúrgica de perros', 85000.00, 90, 1, 1),
    (7, N'Castración felina', N'Cirugía', N'Esterilización quirúrgica de gatos', 60000.00, 60, 1, 1),
    (8, N'Cirugía menor', N'Cirugía', N'Procedimientos quirúrgicos ambulatorios', 120000.00, 90, 1, 1),
    (9, N'Cirugía mayor', N'Cirugía', N'Procedimientos quirúrgicos con anestesia general', 250000.00, 180, 1, 1),
    (10, N'Limpieza dental', N'Odontología', N'Profilaxis dental con ultrasonido', 55000.00, 60, 1, 1),
    (11, N'Grooming completo', N'Estética', N'Baño, corte, uñas y limpieza de oídos', 22000.00, 90, 0, 1),
    (12, N'Baño medicado', N'Estética', N'Baño con shampoo dermatológico', 15000.00, 45, 0, 1),
    (13, N'Corte de uñas', N'Estética', N'Corte y limado de uñas', 5000.00, 15, 0, 1),
    (14, N'Radiografía', N'Diagnóstico', N'Estudio radiográfico simple', 28000.00, 30, 1, 1),
    (15, N'Ultrasonido', N'Diagnóstico', N'Estudio ecográfico abdominal', 32000.00, 40, 1, 1),
    (16, N'Hemograma completo', N'Laboratorio', N'Análisis sanguíneo completo', 18000.00, 20, 0, 1),
    (17, N'Examen coprológico', N'Laboratorio', N'Análisis de heces por parásitos', 8500.00, 15, 0, 1),
    (18, N'Hospitalización por día', N'Hospitalización', N'Internamiento con monitoreo diario', 45000.00, 1440, 1, 1),
    (19, N'Colocación de microchip', N'Prevención', N'Implante de microchip de identificación', 25000.00, 20, 1, 1),
    (20, N'Certificado de salud', N'Consulta', N'Emisión de certificado para viaje', 20000.00, 30, 1, 1);

-- Catalogo de medicamentos con su proveedor
INSERT INTO Medicamento (id_medicamento, nombre_comercial, principio_activo, presentacion, unidad_medida, precio_unitario, requiere_receta, id_proveedor) VALUES
    (1, N'Amoxi-Vet 250', N'Amoxicilina 250 mg', N'Caja de 10 tabletas', N'Caja', 6500.00, 1, 2),
    (2, N'Meloxivet 1.5', N'Meloxicam 1.5 mg/ml', N'Frasco gotero 15 ml', N'Frasco', 7800.00, 1, 2),
    (3, N'Frontline Plus Perro M', N'Fipronil y S-metopreno', N'Pipeta 1.34 ml', N'Pipeta', 12500.00, 0, 18),
    (4, N'NexGard 28.3 mg', N'Afoxolaner', N'Caja de 3 masticables', N'Caja', 28000.00, 0, 18),
    (5, N'Bravecto 500 mg', N'Fluralaner', N'Tableta masticable', N'Unidad', 32000.00, 0, 18),
    (6, N'Drontal Plus', N'Praziquantel, pirantel y febantel', N'Caja de 6 tabletas', N'Caja', 14500.00, 0, 1),
    (7, N'Vacuna Séxtuple Canina', N'Virus vivos atenuados', N'Vial 1 dosis', N'Dosis', 9500.00, 1, 11),
    (8, N'Vacuna Antirrábica', N'Virus inactivado', N'Vial 1 dosis', N'Dosis', 7000.00, 1, 11),
    (9, N'Metrovet 250', N'Metronidazol 250 mg', N'Caja de 20 tabletas', N'Caja', 5800.00, 1, 16),
    (10, N'Predni-Vet 5', N'Prednisolona 5 mg', N'Caja de 30 tabletas', N'Caja', 4900.00, 1, 16),
    (11, N'Tramavet Gotas', N'Tramadol 50 mg/ml', N'Frasco gotero 10 ml', N'Frasco', 8900.00, 1, 2),
    (12, N'Omeprazol Vet 10', N'Omeprazol 10 mg', N'Caja de 14 cápsulas', N'Caja', 5200.00, 1, 16),
    (13, N'Cerenia 24 mg', N'Maropitant', N'Caja de 4 tabletas', N'Caja', 21000.00, 1, 4),
    (14, N'Apoquel 16 mg', N'Oclacitinib', N'Caja de 20 tabletas', N'Caja', 38500.00, 1, 4),
    (15, N'Baytril 50 mg', N'Enrofloxacina', N'Caja de 10 tabletas', N'Caja', 9800.00, 1, 1),
    (16, N'Doxivet 100', N'Doxiciclina 100 mg', N'Caja de 10 tabletas', N'Caja', 6200.00, 1, 16),
    (17, N'Advantage Multi Gato', N'Imidacloprid y moxidectina', N'Pipeta 0.8 ml', N'Pipeta', 13500.00, 0, 18),
    (18, N'Shampoo Clorhexidina 4%', N'Clorhexidina', N'Botella 250 ml', N'Botella', 11500.00, 0, 5),
    (19, N'Suplemento Omega Pet', N'Ácidos grasos omega 3 y 6', N'Frasco 60 cápsulas', N'Frasco', 15500.00, 0, 13),
    (20, N'Suero Ringer Lactato', N'Solución electrolítica', N'Bolsa 500 ml', N'Bolsa', 4500.00, 1, 12);

-- Existencias por lote con stock minimo y vencimiento
INSERT INTO Inventario (id_inventario, id_medicamento, stock_actual, stock_minimo, fecha_ultima_entrada, lote, fecha_vencimiento, ubicacion) VALUES
    (1, 1, 42, 10, N'2026-06-15', N'L-2026-0114', N'2027-08-31', N'Farmacia estante A1'),
    (2, 2, 35, 10, N'2026-06-15', N'L-2026-0115', N'2027-05-30', N'Farmacia estante A1'),
    (3, 3, 60, 15, N'2026-07-01', N'L-2026-0230', N'2028-01-31', N'Farmacia estante B2'),
    (4, 4, 25, 8, N'2026-07-01', N'L-2026-0231', N'2027-11-30', N'Farmacia estante B2'),
    (5, 5, 18, 8, N'2026-05-20', N'L-2026-0180', N'2027-09-30', N'Farmacia estante B2'),
    (6, 6, 30, 10, N'2026-06-02', N'L-2026-0195', N'2027-12-31', N'Farmacia estante B1'),
    (7, 7, 50, 20, N'2026-07-10', N'L-2026-0301', N'2026-12-31', N'Refrigerador R1'),
    (8, 8, 45, 20, N'2026-07-10', N'L-2026-0302', N'2026-11-30', N'Refrigerador R1'),
    (9, 9, 28, 10, N'2026-04-18', N'L-2026-0122', N'2027-06-30', N'Farmacia estante A2'),
    (10, 10, 33, 10, N'2026-04-18', N'L-2026-0123', N'2027-04-30', N'Farmacia estante A2'),
    (11, 11, 15, 6, N'2026-05-05', N'L-2026-0150', N'2027-03-31', N'Farmacia gaveta C1 con llave'),
    (12, 12, 22, 8, N'2026-05-05', N'L-2026-0151', N'2027-10-31', N'Farmacia estante A2'),
    (13, 13, 12, 5, N'2026-06-20', N'L-2026-0210', N'2027-07-31', N'Farmacia estante A3'),
    (14, 14, 9, 5, N'2026-06-20', N'L-2026-0211', N'2027-08-31', N'Farmacia estante A3'),
    (15, 15, 26, 10, N'2026-03-12', N'L-2026-0090', N'2027-02-28', N'Farmacia estante A1'),
    (16, 16, 31, 10, N'2026-03-12', N'L-2026-0091', N'2027-05-31', N'Farmacia estante A2'),
    (17, 17, 40, 12, N'2026-07-05', N'L-2026-0288', N'2028-02-29', N'Farmacia estante B2'),
    (18, 18, 20, 6, N'2026-02-25', N'L-2026-0055', N'2028-06-30', N'Bodega estante D1'),
    (19, 19, 17, 6, N'2026-02-25', N'L-2026-0056', N'2027-12-31', N'Bodega estante D1'),
    (20, 20, 55, 20, N'2026-07-12', N'L-2026-0310', N'2027-01-31', N'Bodega estante D2');

-- Mascotas registradas, cada una asociada a su dueno
INSERT INTO Mascota (id_mascota, id_cliente, nombre, especie, raza, fecha_nacimiento, peso_kg, sexo) VALUES
    (1, 1, N'Rocky', N'Perro', N'Labrador Retriever', N'2021-04-10', 32.50, N'M'),
    (2, 2, N'Luna', N'Gato', N'Criollo', N'2022-08-03', 4.20, N'H'),
    (3, 3, N'Max', N'Perro', N'Golden Retriever', N'2019-11-22', 32.80, N'M'),
    (4, 3, N'Kira', N'Perro', N'Pastor Alemán', N'2020-06-15', 28.40, N'H'),
    (5, 4, N'Toby', N'Perro', N'Schnauzer Miniatura', N'2023-01-30', 7.80, N'M'),
    (6, 5, N'Nala', N'Gato', N'Siamés', N'2021-09-18', 3.90, N'H'),
    (7, 6, N'Zeus', N'Perro', N'Rottweiler', N'2020-02-27', 45.00, N'M'),
    (8, 7, N'Coco', N'Ave', N'Cotorra frente roja', N'2018-05-12', 0.32, N'M'),
    (9, 8, N'Manchas', N'Perro', N'Criollo', N'2022-03-08', 15.60, N'M'),
    (10, 9, N'Pelusa', N'Gato', N'Persa', N'2020-12-01', 4.50, N'H'),
    (11, 9, N'Simba', N'Gato', N'Criollo', N'2023-06-20', 3.60, N'M'),
    (12, 10, N'Bruno', N'Perro', N'Bulldog Francés', N'2021-07-14', 12.30, N'M'),
    (13, 11, N'Canela', N'Perro', N'Cocker Spaniel', N'2019-10-05', 13.10, N'H'),
    (14, 12, N'Mía', N'Gato', N'Angora', N'2022-11-11', 3.80, N'H'),
    (15, 13, N'Thor', N'Perro', N'Husky Siberiano', N'2020-08-23', 24.70, N'M'),
    (16, 14, N'Motita', N'Conejo', N'Cabeza de león', N'2023-04-02', 1.60, N'H'),
    (17, 15, N'Negro', N'Perro', N'Criollo', N'2018-01-19', 20.20, N'M'),
    (18, 16, N'Princesa', N'Perro', N'Poodle', N'2022-05-25', 5.40, N'H'),
    (19, 17, N'Copito', N'Hámster', N'Sirio dorado', N'2025-02-14', 0.12, N'M'),
    (20, 19, N'Chispa', N'Perro', N'Chihuahua', N'2021-12-30', 2.80, N'H');

-- Agenda de citas de junio y julio de 2026
INSERT INTO Cita (id_cita, id_mascota, id_veterinario, id_servicio, fecha_hora, motivo, estado, observaciones) VALUES
    (1, 1, 22, 1, N'2026-06-01 09:00', N'Decaimiento y falta de apetito', N'Atendida', NULL),
    (2, 2, 24, 3, N'2026-06-02 10:30', N'Refuerzo anual de vacunas', N'Atendida', NULL),
    (3, 3, 25, 1, N'2026-06-03 08:30', N'Cojera en pata trasera derecha', N'Atendida', N'Se recomendó radiografía'),
    (4, 5, 26, 5, N'2026-06-04 14:00', N'Desparasitación de rutina', N'Atendida', NULL),
    (5, 6, 23, 12, N'2026-06-05 11:00', N'Picazón constante y caída de pelo', N'Atendida', N'Caso dermatológico en seguimiento'),
    (6, 7, 21, 9, N'2026-06-08 07:30', N'Cirugía por torsión gástrica programada', N'Atendida', N'Requiere ayuno de 12 horas'),
    (7, 9, 28, 1, N'2026-06-09 15:30', N'Herida en la oreja por pelea', N'Atendida', NULL),
    (8, 10, 29, 12, N'2026-06-10 10:00', N'Dermatitis recurrente', N'Atendida', NULL),
    (9, 12, 31, 14, N'2026-06-11 09:30', N'Dificultad respiratoria, revisar vías', N'Atendida', NULL),
    (10, 13, 32, 10, N'2026-06-12 13:00', N'Mal aliento y sarro acumulado', N'Atendida', NULL),
    (11, 4, 27, 9, N'2026-06-15 07:30', N'Cirugía de rodilla programada', N'Atendida', N'Control postoperatorio en 15 días'),
    (12, 15, 36, 1, N'2026-06-16 16:00', N'Vómitos desde hace dos días', N'Atendida', NULL),
    (13, 17, 37, 15, N'2026-06-18 11:30', N'Control de masa abdominal', N'Atendida', NULL),
    (14, 18, 34, 3, N'2026-06-22 09:00', N'Esquema de vacunación pendiente', N'Atendida', NULL),
    (15, 20, 38, 1, N'2026-06-25 14:30', N'Temblores y debilidad', N'Atendida', NULL),
    (16, 8, 25, 1, N'2026-07-06 10:00', N'Pérdida de plumas en el pecho', N'Atendida', NULL),
    (17, 14, 35, 12, N'2026-07-08 15:00', N'Alergia en la piel', N'Programada', NULL),
    (18, 16, 30, 1, N'2026-07-20 09:30', N'Revisión general del conejo', N'Programada', NULL),
    (19, 11, 33, 7, N'2026-07-22 08:00', N'Castración programada', N'Programada', N'Confirmar ayuno con el dueño'),
    (20, 19, 40, 1, N'2026-07-24 13:30', N'Chequeo general del hámster', N'Programada', NULL);

-- Expedientes clinicos de las consultas atendidas
INSERT INTO HistorialMedico (id_historial, id_mascota, id_veterinario, fecha_consulta, diagnostico, temperatura, peso_consulta, notas) VALUES
    (1, 1, 22, N'2026-06-01 09:20', N'Gastroenteritis leve', 39.20, 32.10, N'Paciente decaído, mucosas rosadas. Se indica dieta blanda por cinco días y control de hidratación en casa.'),
    (2, 2, 24, N'2026-06-02 10:45', N'Paciente sano, esquema de vacunas al día', 38.40, 4.25, N'Se aplica refuerzo de triple felina sin reacciones adversas.'),
    (3, 3, 25, N'2026-06-03 08:50', N'Displasia de cadera grado leve', 38.60, 32.60, N'Cojera intermitente en tren posterior. Se envía radiografía de cadera y condroprotectores.'),
    (4, 5, 26, N'2026-06-04 14:15', N'Paciente sano, control preventivo', 38.30, 7.85, N'Desparasitación interna aplicada según peso.'),
    (5, 6, 23, N'2026-06-05 11:20', N'Dermatitis alérgica por pulgas', 38.90, 3.85, N'Zonas de alopecia en lomo. Se indica baño medicado semanal y control antipulgas mensual.'),
    (6, 7, 21, N'2026-06-08 08:00', N'Torsión gástrica, resolución quirúrgica', 39.50, 44.20, N'Cirugía de emergencia programada. Paciente estable tras el procedimiento, queda internado para observación.'),
    (7, 9, 28, N'2026-06-09 15:45', N'Herida lacerante en pabellón auricular', 39.00, 15.55, N'Se limpia y sutura la herida. Collar isabelino por diez días.'),
    (8, 10, 29, N'2026-06-10 10:20', N'Dermatitis por Malassezia', 38.70, 4.55, N'Descamación y olor característico. Se indica shampoo de clorhexidina y control en tres semanas.'),
    (9, 12, 31, N'2026-06-11 09:50', N'Síndrome braquiocefálico moderado', 38.80, 12.40, N'Estridor respiratorio al ejercicio. Se recomienda control de peso y evitar calor extremo.'),
    (10, 13, 32, N'2026-06-12 13:25', N'Enfermedad periodontal grado dos', 38.50, 13.05, N'Sarro abundante en molares. Profilaxis dental realizada bajo sedación sin complicaciones.'),
    (11, 4, 27, N'2026-06-15 08:00', N'Ruptura de ligamento cruzado anterior', 38.60, 28.10, N'Cirugía de rodilla realizada con técnica extracapsular. Reposo estricto por cuatro semanas.'),
    (12, 15, 36, N'2026-06-16 16:20', N'Gastritis aguda', 39.10, 24.50, N'Vómitos biliosos. Se indica omeprazol y dieta gastrointestinal por una semana.'),
    (13, 17, 37, N'2026-06-18 11:50', N'Masa abdominal en estudio', 38.40, 20.05, N'Ultrasonido muestra masa esplénica de tres centímetros. Se programa biopsia y hemograma de control.'),
    (14, 18, 34, N'2026-06-22 09:15', N'Paciente sana, esquema iniciado', 38.20, 5.45, N'Primera dosis de vacuna múltiple aplicada. Refuerzo en veintiún días.'),
    (15, 20, 38, N'2026-06-25 14:50', N'Hipoglucemia leve', 37.80, 2.75, N'Temblores por ayuno prolongado. Se estabiliza con suero glucosado y se ajusta el horario de comidas.'),
    (16, 8, 25, N'2026-07-06 10:20', N'Picaje por estrés', 40.80, 0.31, N'Pérdida de plumas autoinducida. Se recomienda enriquecimiento ambiental y control en un mes.'),
    (17, 3, 25, N'2026-07-07 09:00', N'Control de displasia, evolución favorable', 38.50, 32.40, N'Cojera disminuyó con el tratamiento. Continuar condroprotectores dos meses más.'),
    (18, 7, 21, N'2026-07-09 08:30', N'Control postoperatorio de gastropexia', 38.60, 43.80, N'Herida quirúrgica limpia y seca. Se retiran puntos sin complicaciones.'),
    (19, 6, 23, N'2026-07-10 11:00', N'Control dermatológico, mejoría parcial', 38.80, 3.90, N'Crecimiento de pelo nuevo en zonas afectadas. Continuar baños medicados quincenales.'),
    (20, 4, 27, N'2026-07-13 08:15', N'Control postquirúrgico de rodilla', 38.50, 28.00, N'Apoya la extremidad correctamente. Iniciar caminatas cortas controladas.');

-- Tratamientos derivados de los registros del historial
INSERT INTO Tratamiento (id_tratamiento, id_historial, nombre_tratamiento, descripcion, fecha_inicio, fecha_fin, costo, estado) VALUES
    (1, 1, N'Dieta blanda y protector gástrico', N'Dieta de pollo y arroz con omeprazol diario', N'2026-06-01', N'2026-06-08', 12500.00, N'Finalizado'),
    (2, 3, N'Condroprotectores articulares', N'Suplemento articular diario por tres meses', N'2026-06-03', NULL, 46500.00, N'En curso'),
    (3, 5, N'Baños medicados semanales', N'Shampoo de clorhexidina una vez por semana', N'2026-06-05', N'2026-07-10', 34500.00, N'Finalizado'),
    (4, 6, N'Recuperación postquirúrgica gástrica', N'Antibiótico, analgesia y dieta fraccionada', N'2026-06-08', N'2026-06-22', 58000.00, N'Finalizado'),
    (5, 7, N'Antibioticoterapia por herida', N'Amoxicilina cada doce horas y limpieza diaria', N'2026-06-09', N'2026-06-19', 15800.00, N'Finalizado'),
    (6, 8, N'Tratamiento antifúngico tópico', N'Baños con clorhexidina dos veces por semana', N'2026-06-10', N'2026-07-01', 23000.00, N'Finalizado'),
    (7, 9, N'Control de peso y manejo ambiental', N'Dieta hipocalórica y restricción de ejercicio en calor', N'2026-06-11', NULL, 18000.00, N'En curso'),
    (8, 10, N'Cuidado dental postprofilaxis', N'Enjuague oral y pasta dental enzimática', N'2026-06-12', N'2026-06-26', 9500.00, N'Finalizado'),
    (9, 11, N'Rehabilitación de rodilla', N'Reposo, hielo local y fisioterapia progresiva', N'2026-06-15', NULL, 75000.00, N'En curso'),
    (10, 12, N'Protector gástrico y dieta especial', N'Omeprazol diario y alimento gastrointestinal', N'2026-06-16', N'2026-06-23', 14200.00, N'Finalizado'),
    (11, 13, N'Preparación prequirúrgica de biopsia', N'Hemograma, coagulación y ayuno programado', N'2026-06-18', NULL, 42000.00, N'En curso'),
    (12, 15, N'Ajuste nutricional por hipoglucemia', N'Comidas fraccionadas cada seis horas', N'2026-06-25', N'2026-07-09', 8500.00, N'Finalizado'),
    (13, 16, N'Enriquecimiento ambiental', N'Juguetes de forrajeo y cambio de rutina', N'2026-07-06', NULL, 12000.00, N'En curso'),
    (14, 2, N'Refuerzo vacunal programado', N'Aplicación de refuerzo anual según esquema', N'2026-06-02', N'2026-06-02', 16000.00, N'Finalizado'),
    (15, 4, N'Desparasitación trimestral', N'Programa de desparasitación cada tres meses', N'2026-06-04', NULL, 28500.00, N'En curso'),
    (16, 14, N'Esquema de vacunación cachorra', N'Serie de tres dosis con refuerzos cada veintiún días', N'2026-06-22', NULL, 48000.00, N'En curso'),
    (17, 17, N'Continuación de condroprotectores', N'Segunda fase del suplemento articular', N'2026-07-07', NULL, 31000.00, N'En curso'),
    (18, 18, N'Retiro de puntos y alta quirúrgica', N'Control final de herida y alta médica', N'2026-07-09', N'2026-07-09', 6500.00, N'Finalizado'),
    (19, 19, N'Baños medicados quincenales', N'Fase de mantenimiento dermatológico', N'2026-07-10', NULL, 17250.00, N'En curso'),
    (20, 20, N'Fisioterapia de rodilla fase dos', N'Caminatas cortas controladas dos veces al día', N'2026-07-13', NULL, 25000.00, N'En curso');

-- Recetas emitidas en las consultas
INSERT INTO Prescripcion (id_prescripcion, id_historial, id_medicamento, dosis, frecuencia, duracion_dias, indicaciones, fecha_prescripcion) VALUES
    (1, 1, 12, N'Media cápsula de 10 mg', N'Cada 24 horas', 7, N'Administrar en ayunas por la mañana', N'2026-06-01'),
    (2, 1, 9, N'Media tableta de 250 mg', N'Cada 12 horas', 5, N'Dar con comida para evitar molestias', N'2026-06-01'),
    (3, 3, 2, N'0.5 ml por vía oral', N'Cada 24 horas', 10, N'Suspender si presenta vómitos', N'2026-06-03'),
    (4, 5, 18, N'Aplicar en baño completo', N'Una vez por semana', 30, N'Dejar actuar diez minutos antes de enjuagar', N'2026-06-05'),
    (5, 5, 3, N'Una pipeta completa', N'Cada 30 días', 90, N'Aplicar en la cruz, no bañar 48 horas después', N'2026-06-05'),
    (6, 6, 15, N'Una tableta de 50 mg', N'Cada 12 horas', 10, N'Completar todo el tratamiento aunque mejore', N'2026-06-08'),
    (7, 6, 11, N'4 gotas por vía oral', N'Cada 8 horas', 5, N'Para control del dolor postoperatorio', N'2026-06-08'),
    (8, 7, 1, N'Una tableta de 250 mg', N'Cada 12 horas', 10, N'Dar con alimento', N'2026-06-09'),
    (9, 8, 18, N'Aplicar en baño completo', N'Dos veces por semana', 21, N'Concentrar en zonas con descamación', N'2026-06-10'),
    (10, 9, 10, N'Media tableta de 5 mg', N'Cada 24 horas', 14, N'Reducir dosis gradualmente al finalizar', N'2026-06-11'),
    (11, 10, 1, N'Una tableta de 250 mg', N'Cada 12 horas', 7, N'Prevención de infección tras profilaxis', N'2026-06-12'),
    (12, 11, 11, N'5 gotas por vía oral', N'Cada 8 horas', 7, N'Control del dolor postquirúrgico', N'2026-06-15'),
    (13, 11, 15, N'Una tableta de 50 mg', N'Cada 12 horas', 10, N'Antibiótico de cobertura postoperatoria', N'2026-06-15'),
    (14, 12, 12, N'Una cápsula de 10 mg', N'Cada 24 horas', 7, N'Administrar 30 minutos antes del desayuno', N'2026-06-16'),
    (15, 12, 13, N'Media tableta de 24 mg', N'Cada 24 horas', 4, N'Solo si persisten los vómitos', N'2026-06-16'),
    (16, 13, 16, N'Una tableta de 100 mg', N'Cada 24 horas', 14, N'Iniciar tras resultados del hemograma', N'2026-06-18'),
    (17, 15, 19, N'Una cápsula', N'Cada 24 horas', 30, N'Suplemento de apoyo nutricional', N'2026-06-25'),
    (18, 17, 2, N'0.4 ml por vía oral', N'Cada 24 horas', 15, N'Segunda fase antiinflamatoria', N'2026-07-07'),
    (19, 19, 18, N'Aplicar en baño completo', N'Cada 15 días', 60, N'Fase de mantenimiento dermatológico', N'2026-07-10'),
    (20, 20, 2, N'0.5 ml por vía oral', N'Cada 24 horas', 10, N'Antes de cada sesión de fisioterapia', N'2026-07-13');

-- Facturas emitidas: el subtotal es la suma de sus lineas y el impuesto es el 13 por ciento
INSERT INTO Factura (id_factura, id_cliente, id_empleado, fecha_emision, subtotal, impuesto, total, estado_pago) VALUES
    (1, 1, 41, N'2026-06-01 10:15', 23700.00, 3081.00, 26781.00, N'Pagada'),
    (2, 2, 42, N'2026-06-02 11:10', 16000.00, 2080.00, 18080.00, N'Pagada'),
    (3, 3, 41, N'2026-06-03 09:45', 41850.00, 5440.50, 47290.50, N'Pagada'),
    (4, 4, 42, N'2026-06-04 14:40', 9500.00, 1235.00, 10735.00, N'Pagada'),
    (5, 5, 41, N'2026-06-05 12:05', 38250.00, 4972.50, 43222.50, N'Pagada'),
    (6, 6, 43, N'2026-06-11 16:30', 385000.00, 50050.00, 435050.00, N'Pagada'),
    (7, 8, 42, N'2026-06-09 16:20', 25000.00, 3250.00, 28250.00, N'Pagada'),
    (8, 9, 41, N'2026-06-10 10:50', 15000.00, 1950.00, 16950.00, N'Pagada'),
    (9, 10, 42, N'2026-06-11 10:15', 28000.00, 3640.00, 31640.00, N'Pagada'),
    (10, 11, 41, N'2026-06-12 13:55', 55000.00, 7150.00, 62150.00, N'Pagada'),
    (11, 3, 43, N'2026-06-16 17:10', 295000.00, 38350.00, 333350.00, N'Pendiente'),
    (12, 13, 42, N'2026-06-16 17:00', 18500.00, 2405.00, 20905.00, N'Pagada'),
    (13, 15, 41, N'2026-06-18 12:20', 32000.00, 4160.00, 36160.00, N'Pagada'),
    (14, 16, 42, N'2026-06-22 09:40', 15200.00, 1976.00, 17176.00, N'Pagada'),
    (15, 19, 41, N'2026-06-25 15:25', 18500.00, 2405.00, 20905.00, N'Pagada'),
    (16, 7, 42, N'2026-07-06 10:45', 18500.00, 2405.00, 20905.00, N'Pagada'),
    (17, 12, 41, N'2026-07-08 15:40', 27000.00, 3510.00, 30510.00, N'Pendiente'),
    (18, 16, 42, N'2026-07-10 11:20', 28000.00, 3640.00, 31640.00, N'Anulada'),
    (19, 17, 41, N'2026-07-11 10:30', 20900.00, 2717.00, 23617.00, N'Pagada'),
    (20, 20, 42, N'2026-07-15 14:10', 32000.00, 4160.00, 36160.00, N'Pagada');

-- Lineas de factura: cada una corresponde a un servicio o a un medicamento
INSERT INTO DetalleFactura (id_detalle, id_factura, id_servicio, id_medicamento, cantidad, precio_unitario, descuento, subtotal_linea) VALUES
    (1, 1, 1, NULL, 1, 18500.00, 0.00, 18500.00),
    (2, 1, NULL, 12, 1, 5200.00, 0.00, 5200.00),
    (3, 2, 3, NULL, 1, 16000.00, 0.00, 16000.00),
    (4, 3, 1, NULL, 1, 18500.00, 10.00, 16650.00),
    (5, 3, 14, NULL, 1, 28000.00, 10.00, 25200.00),
    (6, 4, 5, NULL, 1, 9500.00, 0.00, 9500.00),
    (7, 5, 12, NULL, 1, 15000.00, 5.00, 14250.00),
    (8, 5, NULL, 18, 1, 11500.00, 0.00, 11500.00),
    (9, 5, NULL, 3, 1, 12500.00, 0.00, 12500.00),
    (10, 6, 9, NULL, 1, 250000.00, 0.00, 250000.00),
    (11, 6, 18, NULL, 3, 45000.00, 0.00, 135000.00),
    (12, 7, 1, NULL, 1, 18500.00, 0.00, 18500.00),
    (13, 7, NULL, 1, 1, 6500.00, 0.00, 6500.00),
    (14, 8, 12, NULL, 1, 15000.00, 0.00, 15000.00),
    (15, 9, 14, NULL, 1, 28000.00, 0.00, 28000.00),
    (16, 10, 10, NULL, 1, 55000.00, 0.00, 55000.00),
    (17, 11, 9, NULL, 1, 250000.00, 0.00, 250000.00),
    (18, 11, 18, NULL, 1, 45000.00, 0.00, 45000.00),
    (19, 12, 1, NULL, 1, 18500.00, 0.00, 18500.00),
    (20, 13, 15, NULL, 1, 32000.00, 0.00, 32000.00),
    (21, 14, 3, NULL, 1, 16000.00, 5.00, 15200.00),
    (22, 15, 1, NULL, 1, 18500.00, 0.00, 18500.00),
    (23, 16, 1, NULL, 1, 18500.00, 0.00, 18500.00),
    (24, 17, NULL, 17, 2, 13500.00, 0.00, 27000.00),
    (25, 18, NULL, 4, 1, 28000.00, 0.00, 28000.00),
    (26, 19, 11, NULL, 1, 22000.00, 5.00, 20900.00),
    (27, 20, NULL, 5, 1, 32000.00, 0.00, 32000.00);

-- Internamientos historicos y actuales
INSERT INTO Hospitalizacion (id_hospitalizacion, id_mascota, id_veterinario, fecha_ingreso, fecha_egreso, motivo_ingreso, jaula_asignada, costo_dia) VALUES
    (1, 7, 21, N'2026-06-08 10:30', N'2026-06-11 16:00', N'Observación postquirúrgica por torsión gástrica', N'J-01', 45000.00),
    (2, 4, 27, N'2026-06-15 11:00', N'2026-06-16 17:00', N'Recuperación de cirugía de rodilla', N'J-02', 45000.00),
    (3, 15, 36, N'2026-06-16 17:00', N'2026-06-17 12:00', N'Hidratación por gastritis aguda', N'J-03', 45000.00),
    (4, 20, 38, N'2026-06-25 15:30', N'2026-06-26 10:00', N'Estabilización por hipoglucemia', N'J-04', 45000.00),
    (5, 1, 22, N'2026-06-01 10:00', N'2026-06-02 09:00', N'Hidratación por gastroenteritis', N'J-05', 45000.00),
    (6, 13, 32, N'2026-06-12 12:30', N'2026-06-12 18:00', N'Recuperación de sedación dental', N'J-06', 45000.00),
    (7, 17, 37, N'2026-07-15 08:00', N'2026-07-16 14:00', N'Biopsia de masa esplénica', N'J-01', 45000.00),
    (8, 3, 25, N'2025-11-10 09:00', N'2025-11-12 10:00', N'Crisis de dolor articular', N'J-02', 42000.00),
    (9, 9, 28, N'2025-09-05 16:20', N'2025-09-06 11:00', N'Sutura de herida profunda', N'J-03', 42000.00),
    (10, 12, 31, N'2025-12-20 14:00', N'2025-12-22 09:30', N'Crisis respiratoria por calor', N'J-04', 42000.00),
    (11, 6, 23, N'2025-08-14 10:15', N'2025-08-15 15:00', N'Reacción alérgica severa', N'J-05', 42000.00),
    (12, 2, 24, N'2025-07-22 09:40', N'2025-07-23 08:30', N'Observación por ingesta de planta tóxica', N'J-06', 42000.00),
    (13, 10, 29, N'2025-10-30 13:00', N'2025-11-01 10:00', N'Infección cutánea generalizada', N'J-07', 42000.00),
    (14, 18, 34, N'2026-01-18 11:30', N'2026-01-19 09:00', N'Deshidratación por diarrea', N'J-07', 45000.00),
    (15, 5, 26, N'2026-02-09 15:45', N'2026-02-10 12:00', N'Observación tras convulsión aislada', N'J-08', 45000.00),
    (16, 14, 35, N'2026-03-27 10:00', N'2026-03-28 16:30', N'Absceso con drenaje quirúrgico', N'J-08', 45000.00),
    (17, 19, 40, N'2026-04-15 12:20', N'2026-04-15 18:00', N'Observación por caída de la jaula', N'J-09', 45000.00),
    (18, 16, 30, N'2026-05-06 09:10', N'2026-05-07 11:30', N'Estasis gastrointestinal del conejo', N'J-09', 45000.00),
    (19, 11, 33, N'2026-05-28 07:50', N'2026-05-28 17:00', N'Recuperación de castración', N'J-10', 45000.00),
    (20, 8, 25, N'2026-07-18 09:30', NULL, N'Observación por picaje severo y baja de peso', N'J-10', 45000.00);

GO

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
