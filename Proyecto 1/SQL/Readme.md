# Proyecto 1 - Implementación del flujo completo de Microsoft con SSIS y SSAS en SQL Server

## 1. Información general

**Curso:** Seminario de Sistemas 2  
**Proyecto:** Proyecto 1 - Fuente transaccional SG-Food  
**Estudiante:** Pablo Gerardo Schaart Calderon  
**Carné:** 201800951 
**Repositorio:** `SS22S2026_201800951/Proyecto1`

## 2. Objetivo

Implementar una solución de Business Intelligence para la empresa SG-Food utilizando herramientas de Microsoft, integrando datos desde una base transaccional SQL Server y un archivo Excel complementario, aplicando procesos ETL en SSIS, almacenando la información en un Data Warehouse local en SQL Server y construyendo un modelo analítico multidimensional en SSAS para el análisis de ventas e inventarios.

## 3. Descripción del problema

La empresa SG-Food requiere una estructura analítica que permita consultar información de ventas e inventarios sin depender directamente de la base transaccional operativa. Para resolverlo, se implementó una arquitectura compuesta por:

- extracción desde una fuente SQL Server remota;
- extracción desde un archivo Excel como fuente heterogénea complementaria;
- transformación, limpieza y estandarización de datos;
- carga hacia un Data Warehouse local con modelo dimensional;
- construcción de un modelo analítico en SSAS.

## 4. Fuentes de datos

### 4.1 Fuente transaccional principal

- **Servidor:** `34.63.26.98,1433`
- **Base de datos:** `SGFoodOLTP`
- **Tabla principal:** `dbo.TransaccionesVenta`

Campos relevantes utilizados:

- `TransaccionId`
- `FechaTransaccion`
- `ClienteId`
- `ClienteNombre`
- `SegmentoCliente`
- `CanalVenta`
- `Departamento`
- `Municipio`
- `ProductoSKU`
- `ProductoNombre`
- `Marca`
- `Categoria`
- `Subcategoria`
- `Fabricante`
- `CantidadVendida`
- `ExistenciaAntesVenta`
- `ExistenciaDespuesVenta`
- `PrecioUnitario`

### 4.2 Fuente heterogénea complementaria

- **Archivo:** `SGFood_Proyecto1_Muestra.xlsx`

Campos relevantes utilizados:

- `Fecha`
- `ClienteId`
- `ClienteNombre`
- `SegmentoCliente`
- `CanalVenta`
- `Departamento`
- `Municipio`
- `ProductoSKU`
- `ProductoNombre`
- `Marca`
- `Categoria`
- `Subcategoria`
- `Fabricante`
- `CantidadVendida`
- `InventarioInicial`
- `InventarioFinal`
- `PrecioUnitario`
- `CostoUnitario`
- `Descuento`
- `ImporteNeto`
- `MargenEstimado`

## 5. Arquitectura de la solución

    Fuente SQL Server (SGFoodOLTP.dbo.TransaccionesVenta)
                             +
    Archivo Excel (SGFood_Proyecto1_Muestra.xlsx)
                             |
                             v
                    Staging en SQL Server local
                             |
                             v
                    Data Warehouse SGFoodDW
                             |
                             v
                   Modelo multidimensional SSAS

## 6. Herramientas utilizadas

- Microsoft SQL Server
- SQL Server Management Studio
- Visual Studio
- SQL Server Integration Services (SSIS)
- SQL Server Analysis Services (SSAS)
- T-SQL
- Archivo Excel como fuente heterogénea

## 7. Justificación del diseño

Se implementó un modelo estrella porque facilita el análisis multidimensional, simplifica la construcción del cubo en SSAS y separa claramente las dimensiones descriptivas de la tabla de hechos. La fuente SQL Server se utilizó como base principal de ventas, mientras que el archivo Excel se integró como fuente complementaria para enriquecer métricas y cumplir con el requerimiento de múltiples fuentes heterogéneas.

## 8. Data Warehouse implementado

### 8.1 Base de datos local

- **Nombre:** `SGFoodDW`

### 8.2 Esquemas

- `stg`
- `dw`

### 8.3 Tablas de staging

#### `stg.TransaccionesVenta_SQL`
Almacena temporalmente la extracción desde la fuente transaccional remota.

#### `stg.TransaccionesVenta_Excel`
Almacena temporalmente la extracción desde el archivo Excel.

### 8.4 Dimensiones

#### `dw.DimFecha`
Campos principales:
- `FechaKey`
- `FechaCompleta`
- `Anio`
- `Trimestre`
- `Mes`
- `NombreMes`
- `Dia`
- `NombreDia`

#### `dw.DimCliente`
Campos principales:
- `ClienteKey`
- `ClienteId`
- `ClienteNombre`
- `SegmentoCliente`

#### `dw.DimCanalVenta`
Campos principales:
- `CanalVentaKey`
- `CanalVenta`

#### `dw.DimUbicacion`
Campos principales:
- `UbicacionKey`
- `Departamento`
- `Municipio`

#### `dw.DimProducto`
Campos principales:
- `ProductoKey`
- `ProductoSKU`
- `ProductoNombre`
- `Marca`
- `Categoria`
- `Subcategoria`
- `Fabricante`

### 8.5 Tabla de hechos

#### `dw.FactVentas`

Campos y medidas principales:
- `VentaKey`
- `TransaccionId`
- `FechaKey`
- `ClienteKey`
- `CanalVentaKey`
- `UbicacionKey`
- `ProductoKey`
- `CantidadVendida`
- `PrecioUnitario`
- `CostoUnitario`
- `Descuento`
- `ImporteNeto`
- `MargenEstimado`
- `ExistenciaAntesVenta`
- `ExistenciaDespuesVenta`
- `FuenteSQL`
- `FuenteExcel`

### 8.6 Relaciones

- `dw.FactVentas.FechaKey` -> `dw.DimFecha.FechaKey`
- `dw.FactVentas.ClienteKey` -> `dw.DimCliente.ClienteKey`
- `dw.FactVentas.CanalVentaKey` -> `dw.DimCanalVenta.CanalVentaKey`
- `dw.FactVentas.UbicacionKey` -> `dw.DimUbicacion.UbicacionKey`
- `dw.FactVentas.ProductoKey` -> `dw.DimProducto.ProductoKey`

## 9. Proceso ETL implementado en SSIS

El proyecto SSIS fue dividido en paquetes para facilitar su ejecución y mantenimiento.

### 9.1 `01_Stg_SQL.dtsx`

**Objetivo:** extraer datos desde la fuente SQL Server remota y cargarlos al staging local.

**Lógica general:**
1. truncar `stg.TransaccionesVenta_SQL`;
2. leer `dbo.TransaccionesVenta`;
3. cargar datos en `stg.TransaccionesVenta_SQL`.

### 9.2 `02_Stg_Excel.dtsx`

**Objetivo:** extraer datos desde el archivo Excel y cargarlos al staging local.

**Lógica general:**
1. truncar `stg.TransaccionesVenta_Excel`;
2. leer hoja del archivo Excel;
3. convertir tipos de dato en `Data Conversion`;
4. cargar datos en `stg.TransaccionesVenta_Excel`.

**Transformaciones aplicadas:**
- conversión de texto Unicode a tipos compatibles con SQL Server;
- conversión de fechas;
- conversión de columnas numéricas;
- alineación de tipos con las tablas staging.

### 9.3 `03_Cargar_Dimensiones.dtsx`

**Objetivo:** cargar las dimensiones del Data Warehouse.

**Lógica aplicada:**
- limpieza de espacios con `LTRIM` y `RTRIM`;
- consolidación de datos desde SQL y Excel;
- eliminación de duplicados;
- inserción en:
  - `dw.DimCliente`
  - `dw.DimCanalVenta`
  - `dw.DimUbicacion`
  - `dw.DimProducto`

### 9.4 `04_Cargar_FactVentas.dtsx`

**Objetivo:** cargar la tabla de hechos integrando ambas fuentes.

**Lógica aplicada:**
- uso de la fuente SQL como base principal;
- enriquecimiento con métricas del Excel cuando existía correspondencia;
- inserción de registros exclusivos del Excel;
- resolución de claves foráneas hacia las dimensiones;
- carga final en `dw.FactVentas`.

### 9.5 `00_Master.dtsx`

**Objetivo:** orquestar el flujo completo del ETL.

**Orden de ejecución:**
1. `01_Stg_SQL.dtsx`
2. `02_Stg_Excel.dtsx`
3. `03_Cargar_Dimensiones.dtsx`
4. `04_Cargar_FactVentas.dtsx`

## 10. Limpieza, transformación y estandarización

Durante el ETL se aplicaron las siguientes acciones:

- limpieza de espacios en campos texto;
- conversión de tipos de datos entre Excel y SQL Server;
- deduplicación de registros en la fuente Excel;
- separación de staging y modelo dimensional;
- integración de múltiples fuentes;
- uso de claves sustitutas en dimensiones;
- control de integridad referencial entre dimensiones y hechos.

## 11. Scripts SQL incluidos

La carpeta `SQL` contiene los siguientes archivos:

- `Crear_DW.sql`
- `Cargar_Dimensiones.sql`
- `Cargar_FactVentas.sql`
- `Validaciones_Fuente.sql`
- `Validaciones_DW.sql`
- `Consultas_Analiticas.sql`

### 11.1 `Crear_DW.sql`
Crea la base `SGFoodDW`, esquemas, tablas de staging, dimensiones, tabla de hechos y carga de `dw.DimFecha`.

### 11.2 `Cargar_Dimensiones.sql`
Limpia, estandariza y carga las dimensiones desde staging.

### 11.3 `Cargar_FactVentas.sql`
Integra las fuentes SQL y Excel para poblar `dw.FactVentas`.

### 11.4 `Validaciones_Fuente.sql`
Incluye consultas para revisar estructura y contenido de la fuente remota.

### 11.5 `Validaciones_DW.sql`
Incluye conteos, validaciones de integridad referencial y controles básicos de calidad.

### 11.6 `Consultas_Analiticas.sql`
Incluye consultas analíticas para comprobar el comportamiento del modelo.

## 13. Modelo analítico en SSAS

El proyecto multidimensional fue construido sobre el Data Warehouse local.

### 13.1 Objetos creados

- origen de datos;
- vista del origen de datos;
- dimensiones;
- cubo multidimensional.

### 13.2 Dimensiones analíticas

- `Dim Fecha`
- `Dim Cliente`
- `Dim Canal Venta`
- `Dim Ubicacion`
- `Dim Producto`

### 13.3 Medidas definidas

A partir de `FactVentas` se definieron medidas como:

- `CantidadVendida`
- `PrecioUnitario`
- `CostoUnitario`
- `Descuento`
- `ImporteNeto`
- `MargenEstimado`
- `ExistenciaAntesVenta`
- `ExistenciaDespuesVenta`

### 13.4 Jerarquías definidas

#### Jerarquía de tiempo
- Año
- Trimestre
- Mes
- Día

#### Jerarquía de producto
- Categoría
- Subcategoría
- Producto

#### Jerarquía de ubicación
- Departamento
- Municipio

## 14. Manual de ejecución

### 14.1 Requisitos previos

- SQL Server instalado
- Visual Studio con soporte para SSIS y SSAS
- acceso a la fuente remota `SGFoodOLTP`
- archivo Excel disponible
- instancia SSAS configurada para despliegue del proyecto multidimensional

### 14.2 Ejecución del Data Warehouse

1. ejecutar `Crear_DW.sql` en la instancia local de SQL Server;
2. verificar la creación de las tablas y la carga de `dw.DimFecha`.

### 14.3 Ejecución del ETL

1. configurar los administradores de conexión de SSIS:
   - conexión remota a `SGFoodOLTP`;
   - conexión local a `SGFoodDW`;
   - conexión al archivo Excel;
2. ejecutar `00_Master.dtsx`.

### 14.4 Validación del DW

1. ejecutar `Validaciones_Fuente.sql`;
2. ejecutar `Validaciones_DW.sql`;
3. ejecutar `Consultas_Analiticas.sql`.

### 14.5 Ejecución de SSAS

1. revisar el origen de datos;
2. revisar la vista del origen de datos;
3. compilar el proyecto multidimensional;
4. implementar el proyecto en la instancia SSAS configurada;
5. procesar dimensiones y cubo;
6. validar resultados desde el navegador del cubo.

## 15. Estructura del repositorio

    Proyecto1/
    │
    ├── README.md
    ├── SQL/
    │   ├── Crear_DW.sql
    │   ├── Cargar_Dimensiones.sql
    │   ├── Cargar_FactVentas.sql
    │   ├── Validaciones_Fuente.sql
    │   ├── Validaciones_DW.sql
    │   └── Consultas_Analiticas.sql
    ├── SSIS/
    │   └── ETL_SGFood/
    ├── SSAS/
    │   └── ProyectoMultidimensional1/

## 16. Evidencias sugeridas

Se recomienda incluir capturas de:

- conexión exitosa a la fuente remota;
- ejecución de paquetes SSIS;
- conteos en tablas staging;
- conteos en dimensiones y tabla de hechos;
- procesamiento exitoso del cubo en SSAS;
- navegación del cubo con medidas y dimensiones;
- consultas analíticas ejecutadas.

## 17. Conclusiones

Se implementó una solución integral de Business Intelligence basada en SQL Server, SSIS y SSAS. El proyecto permitió integrar datos desde una fuente transaccional remota y una fuente heterogénea en Excel, transformarlos y cargarlos a un Data Warehouse dimensional, y posteriormente analizarlos mediante un modelo multidimensional.

La solución final permite analizar la información por tiempo, producto, cliente, canal y ubicación, apoyando la toma de decisiones sobre ventas e inventarios.
