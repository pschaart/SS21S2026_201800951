USE SGFoodDW;
GO

/* Conteos staging */
SELECT COUNT(*) AS total_stg_sql
FROM stg.TransaccionesVenta_SQL;
GO

SELECT COUNT(*) AS total_stg_excel
FROM stg.TransaccionesVenta_Excel;
GO

/* Conteo Excel deduplicado */
;WITH ExcelDedup AS
(
    SELECT *,
           ROW_NUMBER() OVER
           (
               PARTITION BY
                   Fecha, ClienteId, ClienteNombre, SegmentoCliente, CanalVenta,
                   Departamento, Municipio, ProductoSKU, ProductoNombre, Marca,
                   Categoria, Subcategoria, Fabricante, CantidadVendida,
                   InventarioInicial, InventarioFinal, PrecioUnitario, CostoUnitario,
                   Descuento, ImporteNeto, MargenEstimado
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM stg.TransaccionesVenta_Excel
)
SELECT COUNT(*) AS total_excel_unico
FROM ExcelDedup
WHERE rn = 1;
GO

/* Conteos DW */
SELECT COUNT(*) AS total_dim_fecha
FROM dw.DimFecha;
GO

SELECT COUNT(*) AS total_dim_cliente
FROM dw.DimCliente;
GO

SELECT COUNT(*) AS total_dim_canal
FROM dw.DimCanalVenta;
GO

SELECT COUNT(*) AS total_dim_ubicacion
FROM dw.DimUbicacion;
GO

SELECT COUNT(*) AS total_dim_producto
FROM dw.DimProducto;
GO

SELECT COUNT(*) AS total_fact
FROM dw.FactVentas;
GO

SELECT COUNT(*) AS total_fact_fuente_sql
FROM dw.FactVentas
WHERE FuenteSQL = 1;
GO

SELECT COUNT(*) AS total_fact_fuente_excel
FROM dw.FactVentas
WHERE FuenteExcel = 1;
GO

/* Integridad referencial */
SELECT COUNT(*) AS huerfanos_fecha
FROM dw.FactVentas f
LEFT JOIN dw.DimFecha d ON f.FechaKey = d.FechaKey
WHERE d.FechaKey IS NULL;
GO

SELECT COUNT(*) AS huerfanos_cliente
FROM dw.FactVentas f
LEFT JOIN dw.DimCliente d ON f.ClienteKey = d.ClienteKey
WHERE d.ClienteKey IS NULL;
GO

SELECT COUNT(*) AS huerfanos_canal
FROM dw.FactVentas f
LEFT JOIN dw.DimCanalVenta d ON f.CanalVentaKey = d.CanalVentaKey
WHERE d.CanalVentaKey IS NULL;
GO

SELECT COUNT(*) AS huerfanos_ubicacion
FROM dw.FactVentas f
LEFT JOIN dw.DimUbicacion d ON f.UbicacionKey = d.UbicacionKey
WHERE d.UbicacionKey IS NULL;
GO

SELECT COUNT(*) AS huerfanos_producto
FROM dw.FactVentas f
LEFT JOIN dw.DimProducto d ON f.ProductoKey = d.ProductoKey
WHERE d.ProductoKey IS NULL;
GO

/* Calidad básica */
SELECT COUNT(*) AS registros_con_precio_negativo
FROM dw.FactVentas
WHERE PrecioUnitario < 0;
GO

SELECT COUNT(*) AS registros_con_cantidad_negativa
FROM dw.FactVentas
WHERE CantidadVendida < 0;
GO

SELECT COUNT(*) AS registros_con_importe_nulo
FROM dw.FactVentas
WHERE ImporteNeto IS NULL;
GO