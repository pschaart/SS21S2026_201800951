-- ============================================================
-- PROYECTO 2 - CREACION DE TABLA DERIVADA OPTIMIZADA
-- Se crea una tabla limpia, particionada por fecha y clusterizada
-- por zonas de origen y destino.
-- ============================================================

CREATE OR REPLACE TABLE `eastern-bridge-474702-g4.proyecto_2_taxi.taxi_trips_2022_clean`
PARTITION BY pickup_date
CLUSTER BY pickup_location_id, dropoff_location_id, payment_type
AS
SELECT
  vendor_id,
  pickup_datetime,
  dropoff_datetime,
  DATE(pickup_datetime) AS pickup_date,
  EXTRACT(HOUR FROM pickup_datetime) AS pickup_hour,
  EXTRACT(DAYOFWEEK FROM pickup_datetime) AS pickup_dayofweek,
  EXTRACT(MONTH FROM pickup_datetime) AS pickup_month,

  passenger_count,
  trip_distance,
  rate_code,
  store_and_fwd_flag,
  payment_type,

  fare_amount,
  extra,
  mta_tax,
  tip_amount,
  tolls_amount,
  imp_surcharge AS improvement_surcharge,
  total_amount,

  pickup_location_id,
  dropoff_location_id,

  TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE) AS trip_duration_minutes,

  SAFE_DIVIDE(tip_amount, fare_amount) AS tip_percentage,

  CASE
    WHEN tip_amount >= 5 THEN 1
    ELSE 0
  END AS is_high_tip,

  CASE
    WHEN EXTRACT(HOUR FROM pickup_datetime) BETWEEN 6 AND 11 THEN 'MANANA'
    WHEN EXTRACT(HOUR FROM pickup_datetime) BETWEEN 12 AND 17 THEN 'TARDE'
    WHEN EXTRACT(HOUR FROM pickup_datetime) BETWEEN 18 AND 23 THEN 'NOCHE'
    ELSE 'MADRUGADA'
  END AS time_period

FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
WHERE
  pickup_datetime >= TIMESTAMP('2022-01-01')
  AND pickup_datetime < TIMESTAMP('2023-01-01')
  AND dropoff_datetime > pickup_datetime
  AND trip_distance > 0
  AND trip_distance <= 100
  AND fare_amount > 0
  AND total_amount > 0
  AND tip_amount >= 0
  AND passenger_count BETWEEN 1 AND 6;