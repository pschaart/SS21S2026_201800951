USE SGFoodDW;
GO

TRUNCATE TABLE dw.FactVentas;
GO

/* ==========================================
   PARTE 1: CARGA BASE DESDE SQL ENRIQUECIDA
   ========================================== */

;WITH ExcelRaw AS
(
    SELECT
        CAST(Fecha AS DATE) AS FechaTransaccion,
        LTRIM(RTRIM(CAST(ClienteId AS VARCHAR(20)))) AS ClienteId,
        LTRIM(RTRIM(CAST(CanalVenta AS VARCHAR(30)))) AS CanalVenta,
        LTRIM(RTRIM(CAST(Departamento AS VARCHAR(60)))) AS Departamento,
        LTRIM(RTRIM(CAST(Municipio AS VARCHAR(60)))) AS Municipio,
        LTRIM(RTRIM(CAST(ProductoSKU AS VARCHAR(30)))) AS ProductoSKU,
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
                   FechaTransaccion, ClienteId, CanalVenta, Departamento, Municipio,
                   ProductoSKU, CantidadVendida, InventarioInicial, InventarioFinal,
                   PrecioUnitario, CostoUnitario, Descuento, ImporteNeto, MargenEstimado
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM ExcelRaw
),
ExcelBase AS
(
    SELECT *
    FROM ExcelDedup
    WHERE rn = 1
),
SQLBase AS
(
    SELECT
        TransaccionId,
        CAST(FechaTransaccion AS DATE) AS FechaTransaccion,
        LTRIM(RTRIM(ClienteId)) AS ClienteId,
        LTRIM(RTRIM(CanalVenta)) AS CanalVenta,
        LTRIM(RTRIM(Departamento)) AS Departamento,
        LTRIM(RTRIM(Municipio)) AS Municipio,
        LTRIM(RTRIM(ProductoSKU)) AS ProductoSKU,
        CantidadVendida,
        ExistenciaAntesVenta,
        ExistenciaDespuesVenta,
        PrecioUnitario
    FROM stg.TransaccionesVenta_SQL
),
SQLEnriquecido AS
(
    SELECT
        s.TransaccionId,
        s.FechaTransaccion,
        s.ClienteId,
        s.CanalVenta,
        s.Departamento,
        s.Municipio,
        s.ProductoSKU,
        s.CantidadVendida,
        s.ExistenciaAntesVenta,
        s.ExistenciaDespuesVenta,
        s.PrecioUnitario,

        x.CostoUnitario,
        COALESCE(x.Descuento, 0.00) AS Descuento,

        COALESCE(
            x.ImporteNeto,
            CAST(s.CantidadVendida * s.PrecioUnitario AS DECIMAL(18,2))
        ) AS ImporteNeto,

        COALESCE(
            x.MargenEstimado,
            CASE
                WHEN x.CostoUnitario IS NOT NULL
                THEN CAST(((s.PrecioUnitario - x.CostoUnitario) * s.CantidadVendida) - COALESCE(x.Descuento,0) AS DECIMAL(18,2))
                ELSE NULL
            END
        ) AS MargenEstimado,

        CAST(1 AS BIT) AS FuenteSQL,
        CAST(CASE WHEN x.ClienteId IS NULL THEN 0 ELSE 1 END AS BIT) AS FuenteExcel
    FROM SQLBase s
    LEFT JOIN ExcelBase x
        ON  s.FechaTransaccion = x.FechaTransaccion
        AND s.ClienteId = x.ClienteId
        AND s.CanalVenta = x.CanalVenta
        AND s.Departamento = x.Departamento
        AND s.Municipio = x.Municipio
        AND s.ProductoSKU = x.ProductoSKU
        AND s.CantidadVendida = x.CantidadVendida
        AND s.PrecioUnitario = x.PrecioUnitario
)

INSERT INTO dw.FactVentas
(
    TransaccionId,
    FechaKey,
    ClienteKey,
    CanalVentaKey,
    UbicacionKey,
    ProductoKey,
    CantidadVendida,
    PrecioUnitario,
    CostoUnitario,
    Descuento,
    ImporteNeto,
    MargenEstimado,
    ExistenciaAntesVenta,
    ExistenciaDespuesVenta,
    FuenteSQL,
    FuenteExcel
)
SELECT
    s.TransaccionId,
    df.FechaKey,
    dc.ClienteKey,
    dcv.CanalVentaKey,
    du.UbicacionKey,
    dp.ProductoKey,
    s.CantidadVendida,
    s.PrecioUnitario,
    s.CostoUnitario,
    s.Descuento,
    s.ImporteNeto,
    s.MargenEstimado,
    s.ExistenciaAntesVenta,
    s.ExistenciaDespuesVenta,
    s.FuenteSQL,
    s.FuenteExcel
FROM SQLEnriquecido s
INNER JOIN dw.DimFecha df
    ON df.FechaCompleta = s.FechaTransaccion
INNER JOIN dw.DimCliente dc
    ON dc.ClienteId = s.ClienteId
INNER JOIN dw.DimCanalVenta dcv
    ON dcv.CanalVenta = s.CanalVenta
INNER JOIN dw.DimUbicacion du
    ON du.Departamento = s.Departamento
   AND du.Municipio = s.Municipio
INNER JOIN dw.DimProducto dp
    ON dp.ProductoSKU = s.ProductoSKU;
GO

/* ==========================================
   PARTE 2: FILAS SOLO DEL EXCEL NO EXISTENTES EN SQL
   ========================================== */

;WITH ExcelRaw AS
(
    SELECT
        CAST(Fecha AS DATE) AS FechaTransaccion,
        LTRIM(RTRIM(CAST(ClienteId AS VARCHAR(20)))) AS ClienteId,
        LTRIM(RTRIM(CAST(CanalVenta AS VARCHAR(30)))) AS CanalVenta,
        LTRIM(RTRIM(CAST(Departamento AS VARCHAR(60)))) AS Departamento,
        LTRIM(RTRIM(CAST(Municipio AS VARCHAR(60)))) AS Municipio,
        LTRIM(RTRIM(CAST(ProductoSKU AS VARCHAR(30)))) AS ProductoSKU,
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
                   FechaTransaccion, ClienteId, CanalVenta, Departamento, Municipio,
                   ProductoSKU, CantidadVendida, InventarioInicial, InventarioFinal,
                   PrecioUnitario, CostoUnitario, Descuento, ImporteNeto, MargenEstimado
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM ExcelRaw
),
ExcelBase AS
(
    SELECT *
    FROM ExcelDedup
    WHERE rn = 1
),
SQLBase AS
(
    SELECT
        CAST(FechaTransaccion AS DATE) AS FechaTransaccion,
        LTRIM(RTRIM(ClienteId)) AS ClienteId,
        LTRIM(RTRIM(CanalVenta)) AS CanalVenta,
        LTRIM(RTRIM(Departamento)) AS Departamento,
        LTRIM(RTRIM(Municipio)) AS Municipio,
        LTRIM(RTRIM(ProductoSKU)) AS ProductoSKU,
        CantidadVendida,
        PrecioUnitario
    FROM stg.TransaccionesVenta_SQL
)

INSERT INTO dw.FactVentas
(
    TransaccionId,
    FechaKey,
    ClienteKey,
    CanalVentaKey,
    UbicacionKey,
    ProductoKey,
    CantidadVendida,
    PrecioUnitario,
    CostoUnitario,
    Descuento,
    ImporteNeto,
    MargenEstimado,
    ExistenciaAntesVenta,
    ExistenciaDespuesVenta,
    FuenteSQL,
    FuenteExcel
)
SELECT
    NULL AS TransaccionId,
    df.FechaKey,
    dc.ClienteKey,
    dcv.CanalVentaKey,
    du.UbicacionKey,
    dp.ProductoKey,
    x.CantidadVendida,
    x.PrecioUnitario,
    x.CostoUnitario,
    COALESCE(x.Descuento, 0.00) AS Descuento,
    COALESCE(x.ImporteNeto, CAST(x.CantidadVendida * x.PrecioUnitario AS DECIMAL(18,2))) AS ImporteNeto,
    COALESCE(
        x.MargenEstimado,
        CASE
            WHEN x.CostoUnitario IS NOT NULL
            THEN CAST(((x.PrecioUnitario - x.CostoUnitario) * x.CantidadVendida) - COALESCE(x.Descuento,0) AS DECIMAL(18,2))
            ELSE NULL
        END
    ) AS MargenEstimado,
    x.InventarioInicial AS ExistenciaAntesVenta,
    x.InventarioFinal   AS ExistenciaDespuesVenta,
    CAST(0 AS BIT) AS FuenteSQL,
    CAST(1 AS BIT) AS FuenteExcel
FROM ExcelBase x
INNER JOIN dw.DimFecha df
    ON df.FechaCompleta = x.FechaTransaccion
INNER JOIN dw.DimCliente dc
    ON dc.ClienteId = x.ClienteId
INNER JOIN dw.DimCanalVenta dcv
    ON dcv.CanalVenta = x.CanalVenta
INNER JOIN dw.DimUbicacion du
    ON du.Departamento = x.Departamento
   AND du.Municipio = x.Municipio
INNER JOIN dw.DimProducto dp
    ON dp.ProductoSKU = x.ProductoSKU
WHERE NOT EXISTS
(
    SELECT 1
    FROM SQLBase s
    WHERE s.FechaTransaccion = x.FechaTransaccion
      AND s.ClienteId = x.ClienteId
      AND s.CanalVenta = x.CanalVenta
      AND s.Departamento = x.Departamento
      AND s.Municipio = x.Municipio
      AND s.ProductoSKU = x.ProductoSKU
      AND s.CantidadVendida = x.CantidadVendida
      AND s.PrecioUnitario = x.PrecioUnitario
);
GO