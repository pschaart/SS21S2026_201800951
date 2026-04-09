USE SGFoodDW;
GO

/* Reinicio de carga completa */
TRUNCATE TABLE dw.FactVentas;
GO

DELETE FROM dw.DimProducto;
DELETE FROM dw.DimUbicacion;
DELETE FROM dw.DimCanalVenta;
DELETE FROM dw.DimCliente;
GO

DBCC CHECKIDENT ('dw.DimCliente', RESEED, 0);
DBCC CHECKIDENT ('dw.DimCanalVenta', RESEED, 0);
DBCC CHECKIDENT ('dw.DimUbicacion', RESEED, 0);
DBCC CHECKIDENT ('dw.DimProducto', RESEED, 0);
GO

;WITH ExcelRaw AS
(
    SELECT
        CAST(Fecha AS DATE) AS FechaTransaccion,
        LTRIM(RTRIM(CAST(ClienteId AS VARCHAR(20)))) AS ClienteId,
        LTRIM(RTRIM(CAST(ClienteNombre AS VARCHAR(120)))) AS ClienteNombre,
        LTRIM(RTRIM(CAST(SegmentoCliente AS VARCHAR(40)))) AS SegmentoCliente,
        LTRIM(RTRIM(CAST(CanalVenta AS VARCHAR(30)))) AS CanalVenta,
        LTRIM(RTRIM(CAST(Departamento AS VARCHAR(60)))) AS Departamento,
        LTRIM(RTRIM(CAST(Municipio AS VARCHAR(60)))) AS Municipio,
        LTRIM(RTRIM(CAST(ProductoSKU AS VARCHAR(30)))) AS ProductoSKU,
        LTRIM(RTRIM(CAST(ProductoNombre AS VARCHAR(120)))) AS ProductoNombre,
        LTRIM(RTRIM(CAST(Marca AS VARCHAR(60)))) AS Marca,
        LTRIM(RTRIM(CAST(Categoria AS VARCHAR(60)))) AS Categoria,
        LTRIM(RTRIM(CAST(Subcategoria AS VARCHAR(60)))) AS Subcategoria,
        LTRIM(RTRIM(CAST(Fabricante AS VARCHAR(60)))) AS Fabricante,
        CantidadVendida,
        InventarioInicial,
        InventarioFinal,
        PrecioUnitario,
        CostoUnitario,
        Descuento,
        ImporteNeto,
        MargenEstimado
    FROM stg.TransaccionesVenta_Excel
),
ExcelDedup AS
(
    SELECT *,
           ROW_NUMBER() OVER
           (
               PARTITION BY
                   FechaTransaccion, ClienteId, ClienteNombre, SegmentoCliente,
                   CanalVenta, Departamento, Municipio, ProductoSKU, ProductoNombre,
                   Marca, Categoria, Subcategoria, Fabricante, CantidadVendida,
                   InventarioInicial, InventarioFinal, PrecioUnitario, CostoUnitario,
                   Descuento, ImporteNeto, MargenEstimado
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM ExcelRaw
),
ExcelBase AS
(
    SELECT
        ClienteId,
        ClienteNombre,
        SegmentoCliente,
        CanalVenta,
        Departamento,
        Municipio,
        ProductoSKU,
        ProductoNombre,
        Marca,
        Categoria,
        Subcategoria,
        Fabricante
    FROM ExcelDedup
    WHERE rn = 1
),
SQLBase AS
(
    SELECT
        LTRIM(RTRIM(ClienteId)) AS ClienteId,
        LTRIM(RTRIM(ClienteNombre)) AS ClienteNombre,
        LTRIM(RTRIM(SegmentoCliente)) AS SegmentoCliente,
        LTRIM(RTRIM(CanalVenta)) AS CanalVenta,
        LTRIM(RTRIM(Departamento)) AS Departamento,
        LTRIM(RTRIM(Municipio)) AS Municipio,
        LTRIM(RTRIM(ProductoSKU)) AS ProductoSKU,
        LTRIM(RTRIM(ProductoNombre)) AS ProductoNombre,
        LTRIM(RTRIM(Marca)) AS Marca,
        LTRIM(RTRIM(Categoria)) AS Categoria,
        LTRIM(RTRIM(Subcategoria)) AS Subcategoria,
        LTRIM(RTRIM(Fabricante)) AS Fabricante
    FROM stg.TransaccionesVenta_SQL
),
AllRows AS
(
    SELECT * FROM SQLBase
    UNION
    SELECT * FROM ExcelBase
)

/* DimCliente */
INSERT INTO dw.DimCliente (ClienteId, ClienteNombre, SegmentoCliente)
SELECT DISTINCT
    ClienteId,
    ClienteNombre,
    SegmentoCliente
FROM AllRows
WHERE ClienteId IS NOT NULL
  AND ClienteNombre IS NOT NULL
  AND SegmentoCliente IS NOT NULL;
GO

;WITH ExcelRaw AS
(
    SELECT LTRIM(RTRIM(CAST(CanalVenta AS VARCHAR(30)))) AS CanalVenta
    FROM stg.TransaccionesVenta_Excel
),
ExcelDedup AS
(
    SELECT CanalVenta,
           ROW_NUMBER() OVER (PARTITION BY CanalVenta ORDER BY (SELECT NULL)) AS rn
    FROM ExcelRaw
),
ExcelBase AS
(
    SELECT CanalVenta
    FROM ExcelDedup
    WHERE rn = 1
),
SQLBase AS
(
    SELECT LTRIM(RTRIM(CanalVenta)) AS CanalVenta
    FROM stg.TransaccionesVenta_SQL
),
AllRows AS
(
    SELECT CanalVenta FROM SQLBase
    UNION
    SELECT CanalVenta FROM ExcelBase
)

/* DimCanalVenta */
INSERT INTO dw.DimCanalVenta (CanalVenta)
SELECT DISTINCT CanalVenta
FROM AllRows
WHERE CanalVenta IS NOT NULL;
GO

;WITH ExcelRaw AS
(
    SELECT
        LTRIM(RTRIM(CAST(Departamento AS VARCHAR(60)))) AS Departamento,
        LTRIM(RTRIM(CAST(Municipio AS VARCHAR(60)))) AS Municipio
    FROM stg.TransaccionesVenta_Excel
),
ExcelDedup AS
(
    SELECT Departamento, Municipio,
           ROW_NUMBER() OVER
           (
               PARTITION BY Departamento, Municipio
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM ExcelRaw
),
ExcelBase AS
(
    SELECT Departamento, Municipio
    FROM ExcelDedup
    WHERE rn = 1
),
SQLBase AS
(
    SELECT
        LTRIM(RTRIM(Departamento)) AS Departamento,
        LTRIM(RTRIM(Municipio)) AS Municipio
    FROM stg.TransaccionesVenta_SQL
),
AllRows AS
(
    SELECT Departamento, Municipio FROM SQLBase
    UNION
    SELECT Departamento, Municipio FROM ExcelBase
)

/* DimUbicacion */
INSERT INTO dw.DimUbicacion (Departamento, Municipio)
SELECT DISTINCT Departamento, Municipio
FROM AllRows
WHERE Departamento IS NOT NULL
  AND Municipio IS NOT NULL;
GO

;WITH ExcelRaw AS
(
    SELECT
        LTRIM(RTRIM(CAST(ProductoSKU AS VARCHAR(30)))) AS ProductoSKU,
        LTRIM(RTRIM(CAST(ProductoNombre AS VARCHAR(120)))) AS ProductoNombre,
        LTRIM(RTRIM(CAST(Marca AS VARCHAR(60)))) AS Marca,
        LTRIM(RTRIM(CAST(Categoria AS VARCHAR(60)))) AS Categoria,
        LTRIM(RTRIM(CAST(Subcategoria AS VARCHAR(60)))) AS Subcategoria,
        LTRIM(RTRIM(CAST(Fabricante AS VARCHAR(60)))) AS Fabricante
    FROM stg.TransaccionesVenta_Excel
),
ExcelDedup AS
(
    SELECT *,
           ROW_NUMBER() OVER
           (
               PARTITION BY ProductoSKU, ProductoNombre, Marca, Categoria, Subcategoria, Fabricante
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM ExcelRaw
),
ExcelBase AS
(
    SELECT
        ProductoSKU,
        ProductoNombre,
        Marca,
        Categoria,
        Subcategoria,
        Fabricante
    FROM ExcelDedup
    WHERE rn = 1
),
SQLBase AS
(
    SELECT
        LTRIM(RTRIM(ProductoSKU)) AS ProductoSKU,
        LTRIM(RTRIM(ProductoNombre)) AS ProductoNombre,
        LTRIM(RTRIM(Marca)) AS Marca,
        LTRIM(RTRIM(Categoria)) AS Categoria,
        LTRIM(RTRIM(Subcategoria)) AS Subcategoria,
        LTRIM(RTRIM(Fabricante)) AS Fabricante
    FROM stg.TransaccionesVenta_SQL
),
AllRows AS
(
    SELECT * FROM SQLBase
    UNION
    SELECT * FROM ExcelBase
)

/* DimProducto */
INSERT INTO dw.DimProducto
(
    ProductoSKU,
    ProductoNombre,
    Marca,
    Categoria,
    Subcategoria,
    Fabricante
)
SELECT DISTINCT
    ProductoSKU,
    ProductoNombre,
    Marca,
    Categoria,
    Subcategoria,
    Fabricante
FROM AllRows
WHERE ProductoSKU IS NOT NULL
  AND ProductoNombre IS NOT NULL;
GO