/* ============================================================
   01_create_db.sql
   ============================================================ */
IF DB_ID(N'DW_Vuelos') IS NULL
BEGIN
    CREATE DATABASE DW_Vuelos;
END;
GO

USE DW_Vuelos;
GO

/* ============================================================
   02_create_tables.sql
   Modelo estrella para dataset_vuelos_crudo.csv
   ============================================================ */

-- Limpieza
DROP TABLE IF EXISTS dbo.FactVuelos;
DROP TABLE IF EXISTS dbo.DimCurrency;
DROP TABLE IF EXISTS dbo.DimPaymentMethod;
DROP TABLE IF EXISTS dbo.DimSalesChannel;
DROP TABLE IF EXISTS dbo.DimPasajero;
DROP TABLE IF EXISTS dbo.DimAerolinea;
DROP TABLE IF EXISTS dbo.DimAeropuerto;
DROP TABLE IF EXISTS dbo.DimFecha;
GO

/* =========================
   DIMENSIONES
   ========================= */

-- DimFecha
IF OBJECT_ID('dbo.DimFecha', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimFecha (
        FechaKey    INT          NOT NULL PRIMARY KEY,   -- surrogate key (cargada desde Python)
        Fecha       DATE         NOT NULL,
        Anio        INT          NOT NULL,
        Mes         INT          NOT NULL,
        NombreMes   VARCHAR(20)  NOT NULL,
        Trimestre   INT          NOT NULL,
        Dia         INT          NOT NULL,
        NombreDia   VARCHAR(20)  NOT NULL,
        CONSTRAINT UQ_DimFecha_Fecha UNIQUE (Fecha)
    );
END;
GO

-- DimAeropuerto (para origen y destino)
IF OBJECT_ID('dbo.DimAeropuerto', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimAeropuerto (
        AeropuertoKey INT         NOT NULL PRIMARY KEY,  -- surrogate key (Python)
        AirportCode   VARCHAR(10) NOT NULL,
        CONSTRAINT UQ_DimAeropuerto_AirportCode UNIQUE (AirportCode)
    );
END;
GO

-- DimAerolinea
IF OBJECT_ID('dbo.DimAerolinea', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimAerolinea (
        AerolineaKey  INT           NOT NULL PRIMARY KEY,  -- surrogate key (Python)
        AirlineCode   VARCHAR(10)   NULL,
        AirlineName   VARCHAR(200)  NULL
    );
END;
GO

-- DimPasajero
IF OBJECT_ID('dbo.DimPasajero', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimPasajero (
        PasajeroKey   INT          NOT NULL PRIMARY KEY, -- surrogate key (Python)
        PassengerId   VARCHAR(50)  NOT NULL,
        Genero        VARCHAR(2)   NULL,                 -- M/F/O/U
        Edad          INT          NULL,
        RangoEdad     VARCHAR(20)  NULL,
        Nacionalidad  VARCHAR(10)  NULL,
        CONSTRAINT UQ_DimPasajero_PassengerId UNIQUE (PassengerId)
    );
END;
GO

-- DimSalesChannel
IF OBJECT_ID('dbo.DimSalesChannel', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimSalesChannel (
        SalesChannelKey INT          NOT NULL PRIMARY KEY, -- surrogate key (Python)
        SalesChannel    VARCHAR(50)  NOT NULL,
        CONSTRAINT UQ_DimSalesChannel UNIQUE (SalesChannel)
    );
END;
GO

-- DimPaymentMethod
IF OBJECT_ID('dbo.DimPaymentMethod', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimPaymentMethod (
        PaymentMethodKey INT          NOT NULL PRIMARY KEY, -- surrogate key (Python)
        PaymentMethod    VARCHAR(50)  NOT NULL,
        CONSTRAINT UQ_DimPaymentMethod UNIQUE (PaymentMethod)
    );
END;
GO

-- DimCurrency
IF OBJECT_ID('dbo.DimCurrency', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimCurrency (
        CurrencyKey INT          NOT NULL PRIMARY KEY, -- surrogate key (Python)
        Currency    VARCHAR(10)  NOT NULL,
        CONSTRAINT UQ_DimCurrency UNIQUE (Currency)
    );
END;
GO


/* =========================
   TABLA DE HECHOS
   ========================= */
IF OBJECT_ID('dbo.FactVuelos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FactVuelos (
        FactKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,

        -- Natural key del dataset para evitar duplicados
        RecordId INT NOT NULL,

        -- Fechas (3 roles)
        DepartureFechaKey INT NOT NULL,
        ArrivalFechaKey   INT NULL,
        BookingFechaKey   INT NULL,

        -- Aeropuertos (2 roles)
        AeropuertoOrigenKey  INT NOT NULL,
        AeropuertoDestinoKey INT NOT NULL,

        -- Otras dimensiones
        AerolineaKey  INT NOT NULL,
        PasajeroKey   INT NOT NULL,
        SalesChannelKey   INT NULL,
        PaymentMethodKey  INT NULL,
        CurrencyKey       INT NULL,

        -- Atributos del vuelo (degenerate dimensions)
        FlightNumber  VARCHAR(20) NULL,
        AircraftType  VARCHAR(50) NULL,
        CabinClass    VARCHAR(30) NULL,
        Seat          VARCHAR(10) NULL,
        Status        VARCHAR(30) NULL,

        -- Métricas
        DurationMin   INT NULL,
        DelayMin      INT NULL,
        TicketPrice       DECIMAL(12,2) NULL,
        TicketPriceUsdEst DECIMAL(12,2) NULL,
        BagsTotal     INT NULL,
        BagsChecked   INT NULL,

        CONSTRAINT UQ_FactVuelos_RecordId UNIQUE (RecordId),

        CONSTRAINT FK_Fact_DepDate FOREIGN KEY (DepartureFechaKey) REFERENCES dbo.DimFecha(FechaKey),
        CONSTRAINT FK_Fact_ArrDate FOREIGN KEY (ArrivalFechaKey)   REFERENCES dbo.DimFecha(FechaKey),
        CONSTRAINT FK_Fact_BookDate FOREIGN KEY (BookingFechaKey)  REFERENCES dbo.DimFecha(FechaKey),

        CONSTRAINT FK_Fact_AeroO FOREIGN KEY (AeropuertoOrigenKey)  REFERENCES dbo.DimAeropuerto(AeropuertoKey),
        CONSTRAINT FK_Fact_AeroD FOREIGN KEY (AeropuertoDestinoKey) REFERENCES dbo.DimAeropuerto(AeropuertoKey),

        CONSTRAINT FK_Fact_Airline FOREIGN KEY (AerolineaKey) REFERENCES dbo.DimAerolinea(AerolineaKey),
        CONSTRAINT FK_Fact_Pax     FOREIGN KEY (PasajeroKey)  REFERENCES dbo.DimPasajero(PasajeroKey),

        CONSTRAINT FK_Fact_SC  FOREIGN KEY (SalesChannelKey)  REFERENCES dbo.DimSalesChannel(SalesChannelKey),
        CONSTRAINT FK_Fact_PM  FOREIGN KEY (PaymentMethodKey) REFERENCES dbo.DimPaymentMethod(PaymentMethodKey),
        CONSTRAINT FK_Fact_CUR FOREIGN KEY (CurrencyKey)      REFERENCES dbo.DimCurrency(CurrencyKey)
    );
END;
GO

/* =========================
   ÍNDICES (recomendados)
   ========================= */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactVuelos_DepartureFechaKey' AND object_id = OBJECT_ID('dbo.FactVuelos'))
CREATE INDEX IX_FactVuelos_DepartureFechaKey ON dbo.FactVuelos(DepartureFechaKey);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactVuelos_Ruta' AND object_id = OBJECT_ID('dbo.FactVuelos'))
CREATE INDEX IX_FactVuelos_Ruta ON dbo.FactVuelos(AeropuertoOrigenKey, AeropuertoDestinoKey);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactVuelos_Aerolinea' AND object_id = OBJECT_ID('dbo.FactVuelos'))
CREATE INDEX IX_FactVuelos_Aerolinea ON dbo.FactVuelos(AerolineaKey);
GO