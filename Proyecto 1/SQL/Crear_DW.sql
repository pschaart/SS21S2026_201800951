IF DB_ID('SGFoodDW') IS NULL
    CREATE DATABASE SGFoodDW;
GO

USE SGFoodDW;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg')
    EXEC('CREATE SCHEMA stg');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dw')
    EXEC('CREATE SCHEMA dw');
GO

/* =========================
   BORRADO SI YA EXISTE
   ========================= */

IF OBJECT_ID('dw.FactVentas', 'U') IS NOT NULL
    DROP TABLE dw.FactVentas;
GO

IF OBJECT_ID('dw.DimProducto', 'U') IS NOT NULL
    DROP TABLE dw.DimProducto;
GO

IF OBJECT_ID('dw.DimUbicacion', 'U') IS NOT NULL
    DROP TABLE dw.DimUbicacion;
GO

IF OBJECT_ID('dw.DimCanalVenta', 'U') IS NOT NULL
    DROP TABLE dw.DimCanalVenta;
GO

IF OBJECT_ID('dw.DimCliente', 'U') IS NOT NULL
    DROP TABLE dw.DimCliente;
GO

IF OBJECT_ID('dw.DimFecha', 'U') IS NOT NULL
    DROP TABLE dw.DimFecha;
GO

IF OBJECT_ID('stg.TransaccionesVenta_SQL', 'U') IS NOT NULL
    DROP TABLE stg.TransaccionesVenta_SQL;
GO

IF OBJECT_ID('stg.TransaccionesVenta_Excel', 'U') IS NOT NULL
    DROP TABLE stg.TransaccionesVenta_Excel;
GO

/* =========================
   STAGING
   ========================= */

CREATE TABLE stg.TransaccionesVenta_SQL
(
    TransaccionId            BIGINT         NULL,
    FechaTransaccion         DATE           NULL,
    ClienteId                VARCHAR(20)    NULL,
    ClienteNombre            VARCHAR(120)   NULL,
    SegmentoCliente          VARCHAR(40)    NULL,
    CanalVenta               VARCHAR(30)    NULL,
    Departamento             VARCHAR(60)    NULL,
    Municipio                VARCHAR(60)    NULL,
    ProductoSKU              VARCHAR(30)    NULL,
    ProductoNombre           VARCHAR(120)   NULL,
    Marca                    VARCHAR(60)    NULL,
    Categoria                VARCHAR(60)    NULL,
    Subcategoria             VARCHAR(60)    NULL,
    Fabricante               VARCHAR(60)    NULL,
    CantidadVendida          INT            NULL,
    ExistenciaAntesVenta     INT            NULL,
    ExistenciaDespuesVenta   INT            NULL,
    PrecioUnitario           DECIMAL(18,2)  NULL
);
GO

CREATE TABLE stg.TransaccionesVenta_Excel
(
    Fecha                DATE           NULL,
    ClienteId            VARCHAR(20)    NULL,
    ClienteNombre        VARCHAR(120)   NULL,
    SegmentoCliente      VARCHAR(40)    NULL,
    CanalVenta           VARCHAR(30)    NULL,
    Departamento         VARCHAR(60)    NULL,
    Municipio            VARCHAR(60)    NULL,
    ProductoSKU          VARCHAR(30)    NULL,
    ProductoNombre       VARCHAR(120)   NULL,
    Marca                VARCHAR(60)    NULL,
    Categoria            VARCHAR(60)    NULL,
    Subcategoria         VARCHAR(60)    NULL,
    Fabricante           VARCHAR(60)    NULL,
    CantidadVendida      INT            NULL,
    InventarioInicial    INT            NULL,
    InventarioFinal      INT            NULL,
    PrecioUnitario       DECIMAL(18,2)  NULL,
    CostoUnitario        DECIMAL(18,2)  NULL,
    Descuento            DECIMAL(18,2)  NULL,
    ImporteNeto          DECIMAL(18,2)  NULL,
    MargenEstimado       DECIMAL(18,2)  NULL
);
GO

/* =========================
   DIMENSIONES
   ========================= */

CREATE TABLE dw.DimFecha
(
    FechaKey        INT          NOT NULL PRIMARY KEY,    -- YYYYMMDD
    FechaCompleta   DATE         NOT NULL UNIQUE,
    Anio            SMALLINT     NOT NULL,
    Trimestre       TINYINT      NOT NULL,
    Mes             TINYINT      NOT NULL,
    NombreMes       VARCHAR(20)  NOT NULL,
    Dia             TINYINT      NOT NULL,
    NombreDia       VARCHAR(20)  NOT NULL
);
GO

CREATE TABLE dw.DimCliente
(
    ClienteKey          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ClienteId           VARCHAR(20)       NOT NULL,
    ClienteNombre       VARCHAR(120)      NOT NULL,
    SegmentoCliente     VARCHAR(40)       NOT NULL,
    CONSTRAINT UQ_DimCliente UNIQUE (ClienteId)
);
GO

CREATE TABLE dw.DimCanalVenta
(
    CanalVentaKey   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CanalVenta      VARCHAR(30)       NOT NULL,
    CONSTRAINT UQ_DimCanalVenta UNIQUE (CanalVenta)
);
GO

CREATE TABLE dw.DimUbicacion
(
    UbicacionKey    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Departamento    VARCHAR(60)       NOT NULL,
    Municipio       VARCHAR(60)       NOT NULL,
    CONSTRAINT UQ_DimUbicacion UNIQUE (Departamento, Municipio)
);
GO

CREATE TABLE dw.DimProducto
(
    ProductoKey         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductoSKU         VARCHAR(30)       NOT NULL,
    ProductoNombre      VARCHAR(120)      NOT NULL,
    Marca               VARCHAR(60)       NOT NULL,
    Categoria           VARCHAR(60)       NOT NULL,
    Subcategoria        VARCHAR(60)       NOT NULL,
    Fabricante          VARCHAR(60)       NOT NULL,
    CONSTRAINT UQ_DimProducto UNIQUE (ProductoSKU)
);
GO

/* =========================
   HECHOS
   ========================= */

CREATE TABLE dw.FactVentas
(
    VentaKey                 BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TransaccionId            BIGINT               NULL,
    FechaKey                 INT                  NOT NULL,
    ClienteKey               INT                  NOT NULL,
    CanalVentaKey            INT                  NOT NULL,
    UbicacionKey             INT                  NOT NULL,
    ProductoKey              INT                  NOT NULL,

    CantidadVendida          INT                  NOT NULL,
    PrecioUnitario           DECIMAL(18,2)        NULL,
    CostoUnitario            DECIMAL(18,2)        NULL,
    Descuento                DECIMAL(18,2)        NULL,
    ImporteNeto              DECIMAL(18,2)        NULL,
    MargenEstimado           DECIMAL(18,2)        NULL,
    ExistenciaAntesVenta     INT                  NULL,
    ExistenciaDespuesVenta   INT                  NULL,

    FuenteSQL                BIT                  NOT NULL DEFAULT 0,
    FuenteExcel              BIT                  NOT NULL DEFAULT 0,

    CONSTRAINT FK_FactVentas_DimFecha
        FOREIGN KEY (FechaKey) REFERENCES dw.DimFecha(FechaKey),

    CONSTRAINT FK_FactVentas_DimCliente
        FOREIGN KEY (ClienteKey) REFERENCES dw.DimCliente(ClienteKey),

    CONSTRAINT FK_FactVentas_DimCanalVenta
        FOREIGN KEY (CanalVentaKey) REFERENCES dw.DimCanalVenta(CanalVentaKey),

    CONSTRAINT FK_FactVentas_DimUbicacion
        FOREIGN KEY (UbicacionKey) REFERENCES dw.DimUbicacion(UbicacionKey),

    CONSTRAINT FK_FactVentas_DimProducto
        FOREIGN KEY (ProductoKey) REFERENCES dw.DimProducto(ProductoKey)
);
GO

/* =========================
   CARGA DE DIMFECHA
   ========================= */

SET LANGUAGE Spanish;
GO

DECLARE @FechaInicio DATE = '2025-01-01';
DECLARE @FechaFin    DATE = '2026-12-31';

;WITH Fechas AS
(
    SELECT @FechaInicio AS FechaCompleta
    UNION ALL
    SELECT DATEADD(DAY, 1, FechaCompleta)
    FROM Fechas
    WHERE FechaCompleta < @FechaFin
)
INSERT INTO dw.DimFecha
(
    FechaKey,
    FechaCompleta,
    Anio,
    Trimestre,
    Mes,
    NombreMes,
    Dia,
    NombreDia
)
SELECT
    CAST(CONVERT(CHAR(8), FechaCompleta, 112) AS INT) AS FechaKey,
    FechaCompleta,
    YEAR(FechaCompleta) AS Anio,
    DATEPART(QUARTER, FechaCompleta) AS Trimestre,
    MONTH(FechaCompleta) AS Mes,
    DATENAME(MONTH, FechaCompleta) AS NombreMes,
    DAY(FechaCompleta) AS Dia,
    DATENAME(WEEKDAY, FechaCompleta) AS NombreDia
FROM Fechas
OPTION (MAXRECURSION 800);
GO