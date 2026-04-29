-- ============================================================
-- PROYECTO 2 - EXPLORACION INICIAL DEL DATASET PUBLICO
-- Dataset: NYC Taxi Trips 2022
-- Tabla: bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022
-- ============================================================

-- 1. Conteo total de registros
SELECT
  COUNT(*) AS total_registros
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`;


-- 2. Revisión de fechas mínimas y máximas
SELECT
  MIN(pickup_datetime) AS fecha_minima_pickup,
  MAX(pickup_datetime) AS fecha_maxima_pickup,
  MIN(dropoff_datetime) AS fecha_minima_dropoff,
  MAX(dropoff_datetime) AS fecha_maxima_dropoff
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`;


-- 3. Revisión de columnas principales y calidad básica
SELECT
  COUNT(*) AS total_registros,
  COUNTIF(pickup_datetime IS NULL) AS pickup_null,
  COUNTIF(dropoff_datetime IS NULL) AS dropoff_null,
  COUNTIF(passenger_count IS NULL) AS passenger_count_null,
  COUNTIF(trip_distance IS NULL) AS trip_distance_null,
  COUNTIF(fare_amount IS NULL) AS fare_amount_null,
  COUNTIF(tip_amount IS NULL) AS tip_amount_null,
  COUNTIF(total_amount IS NULL) AS total_amount_null
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`;


-- 4. Estadísticas descriptivas básicas
SELECT
  AVG(trip_distance) AS promedio_distancia,
  MIN(trip_distance) AS distancia_minima,
  MAX(trip_distance) AS distancia_maxima,
  AVG(fare_amount) AS promedio_tarifa,
  AVG(tip_amount) AS promedio_propina,
  AVG(total_amount) AS promedio_total
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
WHERE
  trip_distance > 0
  AND fare_amount > 0
  AND total_amount > 0;


-- 5. Distribución por método de pago
SELECT
  payment_type,
  COUNT(*) AS cantidad_viajes,
  ROUND(AVG(total_amount), 2) AS promedio_total,
  ROUND(AVG(tip_amount), 2) AS promedio_propina
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
GROUP BY payment_type
ORDER BY cantidad_viajes DESC;