# etl_vuelos.py
import os
import re
import calendar
import pandas as pd
from sqlalchemy import create_engine, text

# =========================
# CONFIG
# =========================
CSV_PATH = r"./dataset_vuelos_crudo.csv" 
SQL_SERVER = os.getenv("SQL_SERVER", "localhost")
SQL_DATABASE = os.getenv("SQL_DATABASE", "DW_Vuelos")
SQL_DRIVER = os.getenv("SQL_DRIVER", "ODBC Driver 17 for SQL Server")
SQL_TRUSTED = os.getenv("SQL_TRUSTED", "yes").lower() in ("1", "true", "yes")

SCHEMA = "dbo"

LOAD_MODE = "append"  # "replace" o "append"


# =========================
# HELPERS
# =========================
def standardize_columns(df: pd.DataFrame) -> pd.DataFrame:
    """
    Convierte columnas a snake_case:
    - minúsculas
    - espacios/guiones -> _
    - quita caracteres raros
    """
    df = df.copy()
    df.columns = [
        re.sub(r"_+", "_",
               re.sub(r"[^a-z0-9_]", "",
                      re.sub(r"[\s\-]+", "_", str(c).strip().lower())
               )
        ).strip("_")
        for c in df.columns
    ]
    return df


def normalize_str(x):
    if pd.isna(x):
        return None
    s = str(x).strip()
    s = re.sub(r"\s+", " ", s)
    return s if s != "" else None

def upper_code(x):
    s = normalize_str(x)
    return s.upper() if s else None

def parse_mixed_datetime(series: pd.Series) -> pd.Series:
    """
    Dataset trae formatos mixtos:
      - '20/01/2024 10:14' (dayfirst)
      - '03-15-2025 01:58 PM' (month-day + AM/PM)
    """
    s = series.astype("string")

    # Pass 1: dayfirst (dd/mm/yyyy HH:MM)
    dt1 = pd.to_datetime(s, errors="coerce", dayfirst=True)

    # Pass 2: mm-dd-yyyy hh:mm AM/PM
    mask = dt1.isna() & s.notna()
    if mask.any():
        dt2 = pd.to_datetime(s[mask], errors="coerce", format="%m-%d-%Y %I:%M %p")
        dt1.loc[mask] = dt2

    return dt1

def to_numeric_price(x):
    """
    ticket_price viene a veces con coma decimal: '77,60'
    ticket_price_usd_est viene como string numérico: '77.60'
    """
    if pd.isna(x):
        return None
    s = str(x).strip()
    if s == "":
        return None
    s = s.replace(" ", "")
    # si tiene coma y no tiene punto, asumimos coma decimal
    if "," in s and "." not in s:
        s = s.replace(",", ".")
    # eliminar separadores miles comunes (si aparecieran)
    s = s.replace("'", "")
    try:
        return float(s)
    except:
        return None

def age_range(age):
    if age is None or pd.isna(age):
        return "UNKNOWN"
    try:
        a = int(age)
    except:
        return "UNKNOWN"
    if a < 18: return "0-17"
    if a <= 25: return "18-25"
    if a <= 35: return "26-35"
    if a <= 45: return "36-45"
    if a <= 60: return "46-60"
    return "61+"

def norm_gender(g):
    g = upper_code(g)
    if g in ("M", "MALE", "H", "HOMBRE"):
        return "M"
    if g in ("F", "FEMALE", "M", "MUJER"):
        return "F"
    if g in ("O", "OTHER"):
        return "O"
    return "U"

def build_dim_date(dates: pd.Series, key_name="FechaKey"):
    d = pd.to_datetime(dates, errors="coerce").dt.date
    dim = pd.DataFrame({"Fecha": d}).dropna().drop_duplicates()
    dim = dim.sort_values("Fecha").reset_index(drop=True)
    dim[key_name] = dim.index + 1

    dt = pd.to_datetime(dim["Fecha"])
    dim["Anio"] = dt.dt.year
    dim["Mes"] = dt.dt.month
    dim["NombreMes"] = dim["Mes"].apply(lambda m: calendar.month_name[int(m)])
    dim["Trimestre"] = ((dim["Mes"] - 1) // 3 + 1).astype(int)
    dim["Dia"] = dt.dt.day
    dim["NombreDia"] = dt.dt.day_name()

    return dim[[key_name, "Fecha", "Anio", "Mes", "NombreMes", "Trimestre", "Dia", "NombreDia"]]

def dim_from_series(series: pd.Series, key_name: str, col_name: str):
    dim = pd.DataFrame({col_name: series}).dropna().drop_duplicates()
    dim = dim.sort_values(col_name).reset_index(drop=True)
    dim[key_name] = dim.index + 1
    return dim[[key_name, col_name]]

def make_engine(database: str):
    if SQL_TRUSTED:
        conn_str = (
            f"mssql+pyodbc://@{SQL_SERVER}/{database}"
            f"?driver={SQL_DRIVER.replace(' ', '+')}"
            f"&Trusted_Connection=yes"
        )
    else:
        user = os.getenv("SQL_USER")
        pwd = os.getenv("SQL_PASSWORD")
        if not user or not pwd:
            raise RuntimeError("SQL_TRUSTED=no pero no se definió SQL_USER/SQL_PASSWORD.")
        conn_str = (
            f"mssql+pyodbc://{user}:{pwd}@{SQL_SERVER}/{database}"
            f"?driver={SQL_DRIVER.replace(' ', '+')}"
        )
    return create_engine(conn_str, fast_executemany=True)

# =========================
# SQL DDL 
# =========================
DDL = f"""
IF DB_ID(N'{SQL_DATABASE}') IS NULL
BEGIN
    CREATE DATABASE {SQL_DATABASE};
END;
"""

DDL_TABLES = f"""
USE {SQL_DATABASE};

IF OBJECT_ID('{SCHEMA}.DimFecha', 'U') IS NULL
CREATE TABLE {SCHEMA}.DimFecha (
  FechaKey INT NOT NULL PRIMARY KEY,
  Fecha DATE NOT NULL UNIQUE,
  Anio INT NOT NULL,
  Mes INT NOT NULL,
  NombreMes VARCHAR(20) NOT NULL,
  Trimestre INT NOT NULL,
  Dia INT NOT NULL,
  NombreDia VARCHAR(20) NOT NULL
);

IF OBJECT_ID('{SCHEMA}.DimAeropuerto', 'U') IS NULL
CREATE TABLE {SCHEMA}.DimAeropuerto (
  AeropuertoKey INT NOT NULL PRIMARY KEY,
  AirportCode VARCHAR(10) NOT NULL UNIQUE
);

IF OBJECT_ID('{SCHEMA}.DimAerolinea', 'U') IS NULL
CREATE TABLE {SCHEMA}.DimAerolinea (
  AerolineaKey INT NOT NULL PRIMARY KEY,
  AirlineCode VARCHAR(10) NULL,
  AirlineName VARCHAR(200) NULL
);

IF OBJECT_ID('{SCHEMA}.DimPasajero', 'U') IS NULL
CREATE TABLE {SCHEMA}.DimPasajero (
  PasajeroKey INT NOT NULL PRIMARY KEY,
  PassengerId VARCHAR(50) NOT NULL UNIQUE,
  Genero VARCHAR(2) NULL,
  Edad INT NULL,
  RangoEdad VARCHAR(20) NULL,
  Nacionalidad VARCHAR(10) NULL
);

IF OBJECT_ID('{SCHEMA}.DimSalesChannel', 'U') IS NULL
CREATE TABLE {SCHEMA}.DimSalesChannel (
  SalesChannelKey INT NOT NULL PRIMARY KEY,
  SalesChannel VARCHAR(50) NOT NULL UNIQUE
);

IF OBJECT_ID('{SCHEMA}.DimPaymentMethod', 'U') IS NULL
CREATE TABLE {SCHEMA}.DimPaymentMethod (
  PaymentMethodKey INT NOT NULL PRIMARY KEY,
  PaymentMethod VARCHAR(50) NOT NULL UNIQUE
);

IF OBJECT_ID('{SCHEMA}.DimCurrency', 'U') IS NULL
CREATE TABLE {SCHEMA}.DimCurrency (
  CurrencyKey INT NOT NULL PRIMARY KEY,
  Currency VARCHAR(10) NOT NULL UNIQUE
);

IF OBJECT_ID('{SCHEMA}.FactVuelos', 'U') IS NULL
CREATE TABLE {SCHEMA}.FactVuelos (
  FactKey BIGINT IDENTITY(1,1) PRIMARY KEY,
  RecordId INT NOT NULL UNIQUE,

  DepartureFechaKey INT NOT NULL,
  ArrivalFechaKey INT NULL,
  BookingFechaKey INT NULL,

  AeropuertoOrigenKey INT NOT NULL,
  AeropuertoDestinoKey INT NOT NULL,
  AerolineaKey INT NOT NULL,
  PasajeroKey INT NOT NULL,

  SalesChannelKey INT NULL,
  PaymentMethodKey INT NULL,
  CurrencyKey INT NULL,

  FlightNumber VARCHAR(20) NULL,
  AircraftType VARCHAR(50) NULL,
  CabinClass VARCHAR(30) NULL,
  Seat VARCHAR(10) NULL,
  Status VARCHAR(30) NULL,

  DurationMin INT NULL,
  DelayMin INT NULL,

  TicketPrice DECIMAL(12,2) NULL,
  TicketPriceUsdEst DECIMAL(12,2) NULL,

  BagsTotal INT NULL,
  BagsChecked INT NULL,

  CONSTRAINT FK_F_DepDate FOREIGN KEY (DepartureFechaKey) REFERENCES {SCHEMA}.DimFecha(FechaKey),
  CONSTRAINT FK_F_ArrDate FOREIGN KEY (ArrivalFechaKey) REFERENCES {SCHEMA}.DimFecha(FechaKey),
  CONSTRAINT FK_F_BookDate FOREIGN KEY (BookingFechaKey) REFERENCES {SCHEMA}.DimFecha(FechaKey),

  CONSTRAINT FK_F_Orig FOREIGN KEY (AeropuertoOrigenKey) REFERENCES {SCHEMA}.DimAeropuerto(AeropuertoKey),
  CONSTRAINT FK_F_Dest FOREIGN KEY (AeropuertoDestinoKey) REFERENCES {SCHEMA}.DimAeropuerto(AeropuertoKey),
  CONSTRAINT FK_F_Airline FOREIGN KEY (AerolineaKey) REFERENCES {SCHEMA}.DimAerolinea(AerolineaKey),
  CONSTRAINT FK_F_Pax FOREIGN KEY (PasajeroKey) REFERENCES {SCHEMA}.DimPasajero(PasajeroKey),

  CONSTRAINT FK_F_SC FOREIGN KEY (SalesChannelKey) REFERENCES {SCHEMA}.DimSalesChannel(SalesChannelKey),
  CONSTRAINT FK_F_PM FOREIGN KEY (PaymentMethodKey) REFERENCES {SCHEMA}.DimPaymentMethod(PaymentMethodKey),
  CONSTRAINT FK_F_CUR FOREIGN KEY (CurrencyKey) REFERENCES {SCHEMA}.DimCurrency(CurrencyKey)
);
"""


# =========================
# ETL
# =========================
def extract(csv_path: str) -> pd.DataFrame:
    # Intentar detectar separador
    seps = [",", ";", "\t", "|"]
    best_df = None
    best_cols = 0
    best_sep = None

    for sep in seps:
        try:
            tmp = pd.read_csv(csv_path, sep=sep, engine="python")
            ncols = tmp.shape[1]
            if ncols > best_cols:
                best_df = tmp
                best_cols = ncols
                best_sep = sep
        except Exception:
            pass

    if best_df is None or best_cols <= 1:
        # Último intento: autodetección de pandas (puede ser más lenta)
        best_df = pd.read_csv(csv_path, sep=None, engine="python")
        best_sep = "auto"

    df = best_df
    print(f"Separador detectado: {best_sep!r}")

    # Normalizar nombres de columnas a snake_case
    df = standardize_columns(df)

    print("Columnas detectadas:", list(df.columns))
    print(f"Rows raw: {len(df):,} | Cols: {df.shape[1]}")
    return df

def transform(df: pd.DataFrame):
    # --- Normalizaciones base ---
    df = df.copy()

    # strings
    for c in df.columns:
        if df[c].dtype == object:
            df[c] = df[c].map(normalize_str)

    # códigos y campos categóricos
    df["airline_code"] = df["airline_code"].map(upper_code)
    df["origin_airport"] = df["origin_airport"].map(upper_code)
    df["destination_airport"] = df["destination_airport"].map(upper_code)
    df["currency"] = df["currency"].map(upper_code)
    df["passenger_nationality"] = df["passenger_nationality"].map(upper_code)
    df["passenger_gender"] = df["passenger_gender"].map(norm_gender)
    df["sales_channel"] = df["sales_channel"].map(lambda x: upper_code(x))
    df["payment_method"] = df["payment_method"].map(lambda x: upper_code(x))
    df["status"] = df["status"].map(lambda x: upper_code(x))
    df["cabin_class"] = df["cabin_class"].map(lambda x: upper_code(x))
    df["aircraft_type"] = df["aircraft_type"].map(lambda x: upper_code(x))

    # fechas (mixtas)
    df["departure_dt"] = parse_mixed_datetime(df["departure_datetime"])
    df["arrival_dt"] = parse_mixed_datetime(df["arrival_datetime"])
    df["booking_dt"] = parse_mixed_datetime(df["booking_datetime"])

    # numéricos
    df["duration_min"] = pd.to_numeric(df["duration_min"], errors="coerce").round().astype("Int64")
    df["delay_min"] = pd.to_numeric(df["delay_min"], errors="coerce").round().astype("Int64")

    df["ticket_price_num"] = df["ticket_price"].map(to_numeric_price)
    df["ticket_price_usd_est_num"] = df["ticket_price_usd_est"].map(to_numeric_price)

    df["bags_total"] = pd.to_numeric(df["bags_total"], errors="coerce").astype("Int64")
    df["bags_checked"] = pd.to_numeric(df["bags_checked"], errors="coerce").astype("Int64")

    df["passenger_age"] = pd.to_numeric(df["passenger_age"], errors="coerce").round().astype("Int64")
    df["rango_edad"] = df["passenger_age"].map(lambda x: age_range(x))

    # --- Construcción de dimensiones ---
    dim_fecha = build_dim_date(pd.concat([
        df["departure_dt"].dropna(),
        df["arrival_dt"].dropna(),
        df["booking_dt"].dropna()
    ]).dropna())

    dim_aeropuerto = dim_from_series(
        pd.concat([df["origin_airport"], df["destination_airport"]]).dropna().map(upper_code),
        "AeropuertoKey", "AirportCode"
    )

    # aerolínea (por code+name)
    dim_aerolinea = df[["airline_code", "airline_name"]].dropna(how="all").drop_duplicates()
    dim_aerolinea = dim_aerolinea.sort_values(["airline_code", "airline_name"]).reset_index(drop=True)
    dim_aerolinea["AerolineaKey"] = dim_aerolinea.index + 1
    dim_aerolinea = dim_aerolinea.rename(columns={"airline_code": "AirlineCode", "airline_name": "AirlineName"})
    dim_aerolinea = dim_aerolinea[["AerolineaKey", "AirlineCode", "AirlineName"]]

    # pasajero (id único)
    dim_pasajero = df[["passenger_id", "passenger_gender", "passenger_age", "rango_edad", "passenger_nationality"]].copy()
    dim_pasajero["passenger_id"] = dim_pasajero["passenger_id"].map(lambda x: normalize_str(x))
    dim_pasajero = dim_pasajero.dropna(subset=["passenger_id"]).drop_duplicates(subset=["passenger_id"])
    dim_pasajero = dim_pasajero.sort_values("passenger_id").reset_index(drop=True)
    dim_pasajero["PasajeroKey"] = dim_pasajero.index + 1
    dim_pasajero = dim_pasajero.rename(columns={
        "passenger_id": "PassengerId",
        "passenger_gender": "Genero",
        "passenger_age": "Edad",
        "rango_edad": "RangoEdad",
        "passenger_nationality": "Nacionalidad",
    })
    dim_pasajero["Edad"] = dim_pasajero["Edad"].astype("Int64")
    dim_pasajero = dim_pasajero[["PasajeroKey", "PassengerId", "Genero", "Edad", "RangoEdad", "Nacionalidad"]]

    dim_sales_channel = dim_from_series(df["sales_channel"].dropna(), "SalesChannelKey", "SalesChannel")
    dim_payment_method = dim_from_series(df["payment_method"].dropna(), "PaymentMethodKey", "PaymentMethod")
    dim_currency = dim_from_series(df["currency"].dropna(), "CurrencyKey", "Currency")

    # --- Mapas para FKs ---
    fecha_map = dict(zip(dim_fecha["Fecha"], dim_fecha["FechaKey"]))
    airport_map = dict(zip(dim_aeropuerto["AirportCode"], dim_aeropuerto["AeropuertoKey"]))

    # airline map: por code+name (si code es nulo, intenta por name)
    airline_map = {}
    for _, r in dim_aerolinea.iterrows():
        airline_map[(r["AirlineCode"], r["AirlineName"])] = int(r["AerolineaKey"])

    pax_map = dict(zip(dim_pasajero["PassengerId"], dim_pasajero["PasajeroKey"]))
    sc_map = dict(zip(dim_sales_channel["SalesChannel"], dim_sales_channel["SalesChannelKey"]))
    pm_map = dict(zip(dim_payment_method["PaymentMethod"], dim_payment_method["PaymentMethodKey"]))
    cur_map = dict(zip(dim_currency["Currency"], dim_currency["CurrencyKey"]))

    # --- Construcción de hechos ---
    fact = pd.DataFrame()
    fact["RecordId"] = pd.to_numeric(df["record_id"], errors="coerce").astype("Int64")

    dep_date = df["departure_dt"].dt.date
    arr_date = df["arrival_dt"].dt.date
    book_date = df["booking_dt"].dt.date

    fact["DepartureFechaKey"] = dep_date.map(lambda d: fecha_map.get(d))
    fact["ArrivalFechaKey"] = arr_date.map(lambda d: fecha_map.get(d))
    fact["BookingFechaKey"] = book_date.map(lambda d: fecha_map.get(d))

    fact["AeropuertoOrigenKey"] = df["origin_airport"].map(lambda c: airport_map.get(c))
    fact["AeropuertoDestinoKey"] = df["destination_airport"].map(lambda c: airport_map.get(c))

    fact["AerolineaKey"] = [
        airline_map.get((upper_code(c), normalize_str(n)), None)
        for c, n in zip(df["airline_code"], df["airline_name"])
    ]

    fact["PasajeroKey"] = df["passenger_id"].map(lambda pid: pax_map.get(normalize_str(pid)))

    fact["SalesChannelKey"] = df["sales_channel"].map(lambda x: sc_map.get(x))
    fact["PaymentMethodKey"] = df["payment_method"].map(lambda x: pm_map.get(x))
    fact["CurrencyKey"] = df["currency"].map(lambda x: cur_map.get(x))

    fact["FlightNumber"] = df["flight_number"].map(normalize_str)
    fact["AircraftType"] = df["aircraft_type"].map(normalize_str)
    fact["CabinClass"] = df["cabin_class"].map(normalize_str)
    fact["Seat"] = df["seat"].map(normalize_str)
    fact["Status"] = df["status"].map(normalize_str)

    fact["DurationMin"] = df["duration_min"].astype("Int64")
    fact["DelayMin"] = df["delay_min"].astype("Int64")
    fact["TicketPrice"] = df["ticket_price_num"]
    fact["TicketPriceUsdEst"] = df["ticket_price_usd_est_num"]
    fact["BagsTotal"] = df["bags_total"].astype("Int64")
    fact["BagsChecked"] = df["bags_checked"].astype("Int64")

    # Reglas mínimas de integridad: requiere claves obligatorias
    required = ["RecordId", "DepartureFechaKey", "AeropuertoOrigenKey", "AeropuertoDestinoKey", "AerolineaKey", "PasajeroKey"]
    fact_clean = fact.dropna(subset=required).copy()
    fact_clean["RecordId"] = fact_clean["RecordId"].astype(int)

    # Devuelve dims y fact
    dims = {
        "DimFecha": dim_fecha,
        "DimAeropuerto": dim_aeropuerto,
        "DimAerolinea": dim_aerolinea,
        "DimPasajero": dim_pasajero,
        "DimSalesChannel": dim_sales_channel,
        "DimPaymentMethod": dim_payment_method,
        "DimCurrency": dim_currency,
    }
    return dims, fact_clean

def load(dims: dict, fact: pd.DataFrame):
    # 1) Conectar a master para crear la base
    engine_master = make_engine("master")

    # CREATE DATABASE debe ir fuera de transacción => AUTOCOMMIT
    with engine_master.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
        conn.execute(text(f"""
            IF DB_ID(N'{SQL_DATABASE}') IS NULL
            BEGIN
                CREATE DATABASE {SQL_DATABASE};
            END;
        """))

    # 2) Conectar a la base destino
    engine_dw = make_engine(SQL_DATABASE)

    # 3) Crear tablas si no existen
    with engine_dw.begin() as conn:
        conn.execute(text(DDL_TABLES))  # DDL_TABLES debe usar USE DW_Vuelos; o quitarlo (ver nota abajo)

    # 4) Cargar dimensiones
    for name, ddf in dims.items():
        ddf.to_sql(name, engine_dw, schema=SCHEMA, if_exists=LOAD_MODE, index=False, chunksize=5000)

    # 5) Cargar hecho
    fact.to_sql("FactVuelos", engine_dw, schema=SCHEMA, if_exists=LOAD_MODE, index=False, chunksize=5000)

def main():
    print("== EXTRACT ==")
    df = extract(CSV_PATH)
    print(f"Rows raw: {len(df):,} | Cols: {df.shape[1]}")

    print("== TRANSFORM ==")
    dims, fact = transform(df)
    for k, v in dims.items():
        print(f"{k}: {len(v):,}")
    print(f"FactVuelos (after FK filter): {len(fact):,}")

    print("== LOAD ==")
    load(dims, fact)
    print("Carga completada.")

if __name__ == "__main__":
    main()