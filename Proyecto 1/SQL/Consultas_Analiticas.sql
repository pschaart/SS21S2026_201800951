USE SGFoodDW;
GO

/* 1. Ventas por año y mes */
SELECT
    df.Anio,
    df.Mes,
    df.NombreMes,
    SUM(f.CantidadVendida) AS TotalCantidad,
    SUM(f.ImporteNeto) AS TotalImporte,
    SUM(f.MargenEstimado) AS TotalMargen
FROM dw.FactVentas f
INNER JOIN dw.DimFecha df
    ON f.FechaKey = df.FechaKey
GROUP BY
    df.Anio,
    df.Mes,
    df.NombreMes
ORDER BY
    df.Anio,
    df.Mes;
GO

/* 2. Ventas por categoría */
SELECT
    p.Categoria,
    SUM(f.CantidadVendida) AS TotalCantidad,
    SUM(f.ImporteNeto) AS TotalImporte,
    SUM(f.MargenEstimado) AS TotalMargen
FROM dw.FactVentas f
INNER JOIN dw.DimProducto p
    ON f.ProductoKey = p.ProductoKey
GROUP BY p.Categoria
ORDER BY TotalImporte DESC;
GO

/* 3. Ventas por canal */
SELECT
    c.CanalVenta,
    SUM(f.CantidadVendida) AS TotalCantidad,
    SUM(f.ImporteNeto) AS TotalImporte
FROM dw.FactVentas f
INNER JOIN dw.DimCanalVenta c
    ON f.CanalVentaKey = c.CanalVentaKey
GROUP BY c.CanalVenta
ORDER BY TotalImporte DESC;
GO

/* 4. Ventas por departamento y municipio */
SELECT
    u.Departamento,
    u.Municipio,
    SUM(f.CantidadVendida) AS TotalCantidad,
    SUM(f.ImporteNeto) AS TotalImporte
FROM dw.FactVentas f
INNER JOIN dw.DimUbicacion u
    ON f.UbicacionKey = u.UbicacionKey
GROUP BY
    u.Departamento,
    u.Municipio
ORDER BY TotalImporte DESC;
GO

/* 5. Top 10 productos */
SELECT TOP (10)
    p.ProductoSKU,
    p.ProductoNombre,
    p.Categoria,
    SUM(f.CantidadVendida) AS TotalCantidad,
    SUM(f.ImporteNeto) AS TotalImporte
FROM dw.FactVentas f
INNER JOIN dw.DimProducto p
    ON f.ProductoKey = p.ProductoKey
GROUP BY
    p.ProductoSKU,
    p.ProductoNombre,
    p.Categoria
ORDER BY TotalImporte DESC;
GO