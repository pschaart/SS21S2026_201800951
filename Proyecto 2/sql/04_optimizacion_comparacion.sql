-- CONSULTA ESTANDAR SOBRE DATASET PUBLICO
SELECT
  EXTRACT(MONTH FROM pickup_datetime) AS mes,
  pickup_location_id,
  COUNT(*) AS total_viajes,
  ROUND(AVG(total_amount), 2) AS promedio_total
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
WHERE
  pickup_datetime >= '2022-01-01'
  AND pickup_datetime < '2023-01-01'
  AND pickup_location_id IS NOT NULL
GROUP BY mes, pickup_location_id
ORDER BY mes, total_viajes DESC;

-- CONSULTA OPTIMIZADA SOBRE TABLA PARTICIONADA Y CLUSTERIZADA
SELECT
  pickup_month AS mes,
  pickup_location_id,
  COUNT(*) AS total_viajes,
  ROUND(AVG(total_amount), 2) AS promedio_total
FROM `eastern-bridge-474702-g4.proyecto_2_taxi.taxi_trips_2022_clean`
WHERE
  pickup_date BETWEEN '2022-01-01' AND '2022-12-31'
  AND pickup_location_id IS NOT NULL
GROUP BY mes, pickup_location_id
ORDER BY mes, total_viajes DESC;