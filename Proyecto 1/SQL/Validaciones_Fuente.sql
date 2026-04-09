USE SGFoodOLTP;
GO

SELECT TOP (10) *
FROM dbo.TransaccionesVenta;
GO

SELECT COUNT(*) AS total_registros
FROM dbo.TransaccionesVenta;
GO

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'TransaccionesVenta'
ORDER BY ORDINAL_POSITION;
GO

SELECT CanalVenta, COUNT(*) AS total
FROM dbo.TransaccionesVenta
GROUP BY CanalVenta
ORDER BY total DESC;
GO

SELECT Categoria, COUNT(*) AS total
FROM dbo.TransaccionesVenta
GROUP BY Categoria
ORDER BY total DESC;
GO

SELECT Departamento, Municipio, COUNT(*) AS total
FROM dbo.TransaccionesVenta
GROUP BY Departamento, Municipio
ORDER BY total DESC;
GO

SELECT ClienteId, ClienteNombre, COUNT(*) AS total
FROM dbo.TransaccionesVenta
GROUP BY ClienteId, ClienteNombre
ORDER BY total DESC;
GO

SELECT ProductoSKU, ProductoNombre, COUNT(*) AS total
FROM dbo.TransaccionesVenta
GROUP BY ProductoSKU, ProductoNombre
ORDER BY total DESC;
GO