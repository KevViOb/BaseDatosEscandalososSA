# Diccionario de datos de Escandalosos S.A.

Documento generado con `python src/gen_diccionario.py` a partir de `src/schema_def.py`, la misma definicion que produce el script SQL y los diagramas. Comprende las 17 entidades del modelo logico.

## Entidades

### 1. Persona

Supertipo de la jerarquia de herencia. Centraliza los datos personales comunes de clientes y empleados.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_persona | INT | NO | PK | Identificador unico de la persona |
| identificacion | VARCHAR(20) | NO | UNIQUE | Cedula de identidad o DIMEX, valor unico |
| nombre | VARCHAR(80) | NO |  | Nombre de pila de la persona |
| apellidos | VARCHAR(100) | NO |  | Apellidos de la persona |
| telefono | VARCHAR(20) | NO |  | Telefono de contacto principal |
| correo | VARCHAR(100) | SI |  | Correo electronico de contacto |
| direccion | VARCHAR(200) | SI |  | Direccion fisica de residencia |
| fecha_nacimiento | DATE | SI |  | Fecha de nacimiento |
| tipo_persona | VARCHAR(20) | NO |  | Discriminador del subtipo: Cliente o Empleado |

Restricciones adicionales:

* `CHECK: (tipo_persona IN ('Cliente', 'Empleado'))`

### 2. Puesto

Catalogo de puestos de trabajo de la clinica con su informacion salarial base.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_puesto | INT | NO | PK | Identificador unico del puesto |
| nombre_puesto | VARCHAR(60) | NO |  | Nombre del puesto de trabajo |
| departamento | VARCHAR(60) | NO |  | Departamento al que pertenece el puesto |
| nivel | VARCHAR(30) | NO |  | Nivel jerarquico: Operativo, Tecnico, Profesional o Gerencial |
| salario_base | DECIMAL(10,2) | NO |  | Salario base mensual del puesto en colones |
| descripcion | VARCHAR(200) | SI |  | Descripcion de las funciones del puesto |
| activo | BIT | NO |  | Indica si el puesto esta vigente (1) o no (0) |
| fecha_creacion | DATE | NO |  | Fecha en que se creo el puesto |

Restricciones adicionales:

* `CHECK: (salario_base > 0)`

### 3. Cliente

Subtipo de Persona. Hereda los datos personales y agrega la informacion comercial del cliente.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_cliente | INT | NO | PK, FK hacia Persona | Identificador del cliente, hereda de Persona |
| fecha_registro | DATE | NO |  | Fecha en que se registro en la clinica |
| tipo_cliente | VARCHAR(20) | NO |  | Clasificacion comercial: Regular, Frecuente o VIP |
| preferencia_contacto | VARCHAR(20) | NO |  | Medio preferido de contacto: Telefono, Correo o WhatsApp |
| acepta_promociones | BIT | NO |  | Indica si acepta recibir promociones (1) o no (0) |
| referido_por | VARCHAR(80) | SI |  | Como conocio la clinica o quien lo refirio |
| notas | VARCHAR(200) | SI |  | Observaciones generales sobre el cliente |
| estado | VARCHAR(20) | NO |  | Estado del cliente: Activo o Inactivo |

Restricciones adicionales:

* `CHECK: (tipo_cliente IN ('Regular', 'Frecuente', 'VIP'))`
* `CHECK: (estado IN ('Activo', 'Inactivo'))`

### 4. Empleado

Subtipo de Persona. Hereda los datos personales y agrega la informacion laboral del colaborador.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_empleado | INT | NO | PK, FK hacia Persona | Identificador del empleado, hereda de Persona |
| id_puesto | INT | NO | FK hacia Puesto | Puesto que ocupa dentro de la clinica |
| salario | DECIMAL(10,2) | NO |  | Salario mensual bruto en colones |
| fecha_ingreso | DATE | NO |  | Fecha de ingreso a la empresa |
| tipo_contrato | VARCHAR(30) | NO |  | Modalidad de contratacion: Indefinido, Plazo fijo o Servicios |
| jornada | VARCHAR(30) | NO |  | Jornada laboral: Completa, Media o Mixta |
| estado | VARCHAR(20) | NO |  | Estado laboral: Activo o Inactivo |
| fecha_salida | DATE | SI |  | Fecha de salida si ya no labora en la clinica |

Restricciones adicionales:

* `CHECK: (salario > 0)`
* `CHECK: (estado IN ('Activo', 'Inactivo'))`

### 5. Veterinario

Subtipo de Empleado. Hereda los datos laborales y agrega la informacion profesional del medico veterinario.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_veterinario | INT | NO | PK, FK hacia Empleado | Identificador del veterinario, hereda de Empleado |
| numero_colegiado | VARCHAR(30) | NO | UNIQUE | Numero de colegiatura profesional, valor unico |
| especialidad | VARCHAR(60) | NO |  | Especialidad medica principal |
| universidad_titulo | VARCHAR(100) | NO |  | Universidad que otorgo el titulo |
| anios_experiencia | INT | NO |  | Anios de experiencia profesional |
| atiende_emergencias | BIT | NO |  | Indica si atiende turnos de emergencia (1) o no (0) |
| fecha_colegiatura | DATE | NO |  | Fecha de incorporacion al colegio profesional |
| observaciones | VARCHAR(200) | SI |  | Notas adicionales sobre el profesional |

Restricciones adicionales:

* `CHECK: (anios_experiencia >= 0)`

### 6. Proveedor

Empresas proveedoras de medicamentos y suministros de la clinica.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_proveedor | INT | NO | PK | Identificador unico del proveedor |
| nombre_empresa | VARCHAR(100) | NO |  | Razon social del proveedor |
| contacto | VARCHAR(80) | NO |  | Nombre de la persona de contacto |
| telefono | VARCHAR(20) | NO |  | Telefono del proveedor |
| correo | VARCHAR(100) | SI |  | Correo electronico del proveedor |
| direccion | VARCHAR(200) | SI |  | Direccion fisica del proveedor |
| activo | BIT | NO |  | Indica si el proveedor esta activo (1) o no (0) |
| condicion_pago | VARCHAR(60) | NO |  | Condiciones de pago pactadas: contado, credito 30 dias, etc. |

### 7. Servicio

Catalogo de servicios que ofrece la clinica veterinaria con su precio base.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_servicio | INT | NO | PK | Identificador unico del servicio |
| nombre_servicio | VARCHAR(80) | NO |  | Nombre del servicio |
| categoria | VARCHAR(40) | NO |  | Categoria: Consulta, Cirugia, Estetica, Laboratorio, etc. |
| descripcion | VARCHAR(200) | SI |  | Descripcion del servicio |
| precio_base | DECIMAL(10,2) | NO |  | Precio base del servicio en colones |
| duracion_estimada_min | INT | NO |  | Duracion estimada en minutos |
| requiere_veterinario | BIT | NO |  | Indica si lo debe brindar un veterinario (1) o no (0) |
| activo | BIT | NO |  | Indica si el servicio esta vigente (1) o no (0) |

Restricciones adicionales:

* `CHECK: (precio_base >= 0)`
* `CHECK: (duracion_estimada_min > 0)`

### 8. Medicamento

Catalogo de medicamentos y productos farmaceuticos que comercializa la clinica.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_medicamento | INT | NO | PK | Identificador unico del medicamento |
| nombre_comercial | VARCHAR(100) | NO |  | Nombre comercial del producto |
| principio_activo | VARCHAR(100) | NO |  | Principio activo del medicamento |
| presentacion | VARCHAR(60) | NO |  | Presentacion del producto: tabletas, suspension, pipeta, etc. |
| unidad_medida | VARCHAR(30) | NO |  | Unidad en que se vende: unidad, frasco, caja, etc. |
| precio_unitario | DECIMAL(10,2) | NO |  | Precio de venta por unidad en colones |
| requiere_receta | BIT | NO |  | Indica si requiere receta veterinaria (1) o no (0) |
| id_proveedor | INT | NO | FK hacia Proveedor | Proveedor que suministra el medicamento |

Restricciones adicionales:

* `CHECK: (precio_unitario >= 0)`

### 9. Mascota

Pacientes de la clinica. Cada mascota pertenece a un cliente registrado.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_mascota | INT | NO | PK | Identificador unico de la mascota |
| id_cliente | INT | NO | FK hacia Cliente | Cliente dueno de la mascota |
| nombre | VARCHAR(60) | NO |  | Nombre de la mascota |
| especie | VARCHAR(40) | NO |  | Especie del animal: Perro, Gato, Conejo, Ave, etc. |
| raza | VARCHAR(60) | NO |  | Raza de la mascota o Criollo si no aplica |
| fecha_nacimiento | DATE | SI |  | Fecha de nacimiento aproximada |
| peso_kg | DECIMAL(5,2) | NO |  | Peso actual en kilogramos |
| sexo | CHAR(1) | NO |  | Sexo de la mascota: M (macho) o H (hembra) |

Restricciones adicionales:

* `CHECK: (peso_kg > 0)`
* `CHECK: (sexo IN ('M', 'H'))`

### 10. Cita

Agenda de citas de la clinica. Relaciona mascota, veterinario y servicio en una fecha y hora.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_cita | INT | NO | PK | Identificador unico de la cita |
| id_mascota | INT | NO | FK hacia Mascota | Mascota que asiste a la cita |
| id_veterinario | INT | NO | FK hacia Veterinario | Veterinario asignado a la cita |
| id_servicio | INT | NO | FK hacia Servicio | Servicio que se brindara en la cita |
| fecha_hora | DATETIME | NO |  | Fecha y hora programada de la cita |
| motivo | VARCHAR(200) | NO |  | Motivo por el cual se agenda la cita |
| estado | VARCHAR(20) | NO |  | Estado: Programada, Atendida, Cancelada o Ausente |
| observaciones | VARCHAR(300) | SI |  | Observaciones adicionales de la cita |

Restricciones adicionales:

* `CHECK: (estado IN ('Programada', 'Atendida', 'Cancelada', 'Ausente'))`

### 11. HistorialMedico

Registro clinico de cada consulta realizada a una mascota.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_historial | INT | NO | PK | Identificador unico del registro clinico |
| id_mascota | INT | NO | FK hacia Mascota | Mascota a la que pertenece el registro |
| id_veterinario | INT | NO | FK hacia Veterinario | Veterinario que realizo la consulta |
| fecha_consulta | DATETIME | NO |  | Fecha y hora de la consulta |
| diagnostico | VARCHAR(300) | NO |  | Diagnostico emitido por el veterinario |
| temperatura | DECIMAL(4,1) | SI |  | Temperatura corporal en grados Celsius |
| peso_consulta | DECIMAL(5,2) | SI |  | Peso registrado el dia de la consulta en kilogramos |
| notas | VARCHAR(MAX) | SI |  | Notas clinicas extensas de la consulta |

### 12. Tratamiento

Tratamientos indicados a partir de un registro del historial medico.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_tratamiento | INT | NO | PK | Identificador unico del tratamiento |
| id_historial | INT | NO | FK hacia HistorialMedico | Registro clinico que origino el tratamiento |
| nombre_tratamiento | VARCHAR(100) | NO |  | Nombre del tratamiento indicado |
| descripcion | VARCHAR(300) | SI |  | Descripcion detallada del tratamiento |
| fecha_inicio | DATE | NO |  | Fecha de inicio del tratamiento |
| fecha_fin | DATE | SI |  | Fecha de finalizacion, nula si sigue en curso |
| costo | DECIMAL(10,2) | NO |  | Costo total del tratamiento en colones |
| estado | VARCHAR(20) | NO |  | Estado: En curso, Finalizado o Suspendido |

Restricciones adicionales:

* `CHECK: (costo >= 0)`
* `CHECK: (estado IN ('En curso', 'Finalizado', 'Suspendido'))`
* `CHECK: (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)`

### 13. Prescripcion

Medicamentos recetados en una consulta del historial medico.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_prescripcion | INT | NO | PK | Identificador unico de la prescripcion |
| id_historial | INT | NO | FK hacia HistorialMedico | Consulta en la que se emitio la receta |
| id_medicamento | INT | NO | FK hacia Medicamento | Medicamento recetado |
| dosis | VARCHAR(80) | NO |  | Dosis indicada del medicamento |
| frecuencia | VARCHAR(60) | NO |  | Frecuencia de administracion |
| duracion_dias | INT | NO |  | Duracion del tratamiento en dias |
| indicaciones | VARCHAR(200) | SI |  | Indicaciones adicionales para el dueno |
| fecha_prescripcion | DATE | NO |  | Fecha en que se emitio la prescripcion |

Restricciones adicionales:

* `CHECK: (duracion_dias > 0)`

### 14. Inventario

Existencias de medicamentos por lote, con control de stock minimo y vencimiento.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_inventario | INT | NO | PK | Identificador unico del registro de inventario |
| id_medicamento | INT | NO | FK hacia Medicamento | Medicamento al que corresponde la existencia |
| stock_actual | INT | NO |  | Cantidad disponible actualmente |
| stock_minimo | INT | NO |  | Cantidad minima antes de generar alerta de compra |
| fecha_ultima_entrada | DATE | NO |  | Fecha de la ultima entrada de producto |
| lote | VARCHAR(40) | NO |  | Numero de lote del producto |
| fecha_vencimiento | DATE | NO |  | Fecha de vencimiento del lote |
| ubicacion | VARCHAR(60) | NO |  | Ubicacion fisica dentro de la bodega o farmacia |

Restricciones adicionales:

* `CHECK: (stock_actual >= 0)`
* `CHECK: (stock_minimo >= 0)`
* `UNIQUE (id_medicamento, lote)`

### 15. Factura

Encabezado de las facturas emitidas a los clientes.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_factura | INT | NO | PK | Identificador unico de la factura |
| id_cliente | INT | NO | FK hacia Cliente | Cliente al que se emite la factura |
| id_empleado | INT | NO | FK hacia Empleado | Empleado que emitio la factura |
| fecha_emision | DATETIME | NO |  | Fecha y hora de emision |
| subtotal | DECIMAL(10,2) | NO |  | Suma de las lineas de detalle antes de impuesto |
| impuesto | DECIMAL(10,2) | NO |  | Impuesto al valor agregado del 13 por ciento |
| total | DECIMAL(10,2) | NO |  | Monto total de la factura con impuesto |
| estado_pago | VARCHAR(20) | NO |  | Estado del pago: Pendiente, Pagada o Anulada |

Restricciones adicionales:

* `CHECK: (subtotal >= 0)`
* `CHECK: (estado_pago IN ('Pendiente', 'Pagada', 'Anulada'))`

### 16. DetalleFactura

Lineas de detalle de cada factura. Cada linea corresponde a un servicio o a un medicamento, nunca a ambos.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_detalle | INT | NO | PK | Identificador unico de la linea de detalle |
| id_factura | INT | NO | FK hacia Factura | Factura a la que pertenece la linea |
| id_servicio | INT | SI | FK hacia Servicio | Servicio facturado, nulo si la linea es de medicamento |
| id_medicamento | INT | SI | FK hacia Medicamento | Medicamento facturado, nulo si la linea es de servicio |
| cantidad | INT | NO |  | Cantidad facturada |
| precio_unitario | DECIMAL(10,2) | NO |  | Precio unitario aplicado en la venta |
| descuento | DECIMAL(5,2) | NO |  | Porcentaje de descuento aplicado a la linea |
| subtotal_linea | DECIMAL(10,2) | NO |  | Monto de la linea con el descuento aplicado |

Restricciones adicionales:

* `CHECK: (cantidad > 0)`
* `CHECK: (descuento >= 0 AND descuento <= 100)`
* `CHECK: ((id_servicio IS NOT NULL AND id_medicamento IS NULL) OR (id_servicio IS NULL AND id_medicamento IS NOT NULL))`

### 17. Hospitalizacion

Internamientos de mascotas con su jaula asignada y costo por dia.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_hospitalizacion | INT | NO | PK | Identificador unico del internamiento |
| id_mascota | INT | NO | FK hacia Mascota | Mascota internada |
| id_veterinario | INT | NO | FK hacia Veterinario | Veterinario responsable del internamiento |
| fecha_ingreso | DATETIME | NO |  | Fecha y hora de ingreso |
| fecha_egreso | DATETIME | SI |  | Fecha y hora de egreso, nula si sigue internada |
| motivo_ingreso | VARCHAR(200) | NO |  | Motivo medico del internamiento |
| jaula_asignada | VARCHAR(20) | NO |  | Codigo de la jaula o espacio asignado |
| costo_dia | DECIMAL(10,2) | NO |  | Costo del internamiento por dia en colones |

Restricciones adicionales:

* `CHECK: (costo_dia >= 0)`
* `CHECK: (fecha_egreso IS NULL OR fecha_egreso >= fecha_ingreso)`

## Tabla de apoyo del modelo fisico

`AuditoriaPrecioServicio` no forma parte de las 17 entidades logicas. La usa el trigger `trg_Servicio_AuditarPrecio` para registrar los cambios de precio de los servicios.

| Columna | Tipo de dato | Nulo | Clave | Descripcion |
| --- | --- | --- | --- | --- |
| id_auditoria | INT IDENTITY(1,1) | NO | PK | Identificador autoincremental |
| id_servicio | INT | NO | FK hacia Servicio | Servicio cuyo precio cambio |
| precio_anterior | DECIMAL(10,2) | NO |  | Precio antes del cambio |
| precio_nuevo | DECIMAL(10,2) | NO |  | Precio despues del cambio |
| fecha_cambio | DATETIME | NO |  | Fecha del cambio, por defecto GETDATE() |
| usuario | VARCHAR(100) | NO |  | Usuario que hizo el cambio, por defecto SYSTEM_USER |

## Indices no agrupados

| Indice | Tabla | Columnas |
| --- | --- | --- |
| IX_Mascota_Cliente | Mascota | id_cliente |
| IX_Cita_Veterinario_Fecha | Cita | id_veterinario, fecha_hora |
| IX_Cita_Mascota | Cita | id_mascota |
| IX_Historial_Mascota | HistorialMedico | id_mascota |
| IX_Prescripcion_Historial | Prescripcion | id_historial |
| IX_Inventario_Medicamento | Inventario | id_medicamento |
| IX_Factura_Cliente | Factura | id_cliente |
| IX_DetalleFactura_Factura | DetalleFactura | id_factura |
