CREATE OR REPLACE TABLE `eastern-bridge-474702-g4.proyecto_2_taxi.viz_viajes_por_mes` AS
SELECT
  pickup_month,
  COUNT(*) AS total_viajes,
  ROUND(AVG(total_amount), 2) AS promedio_total,
  ROUND(AVG(tip_amount), 2) AS promedio_propina
FROM `eastern-bridge-474702-g4.proyecto_2_taxi.taxi_trips_2022_clean`
GROUP BY pickup_month
ORDER BY pickup_month;

CREATE OR REPLACE TABLE `eastern-bridge-474702-g4.proyecto_2_taxi.viz_viajes_por_hora` AS
SELECT
  pickup_hour,
  COUNT(*) AS total_viajes,
  ROUND(AVG(trip_distance), 2) AS distancia_promedio,
  ROUND(AVG(total_amount), 2) AS total_promedio,
  ROUND(AVG(tip_amount), 2) AS propina_promedio
FROM `eastern-bridge-474702-g4.proyecto_2_taxi.taxi_trips_2022_clean`
GROUP BY pickup_hour
ORDER BY pickup_hour;

CREATE OR REPLACE TABLE `eastern-bridge-474702-g4.proyecto_2_taxi.viz_propina_por_pago` AS
SELECT
  payment_type,
  COUNT(*) AS total_viajes,
  ROUND(AVG(fare_amount), 2) AS tarifa_promedio,
  ROUND(AVG(tip_amount), 2) AS propina_promedio,
  ROUND(AVG(tip_percentage), 4) AS porcentaje_propina_promedio
FROM `eastern-bridge-474702-g4.proyecto_2_taxi.taxi_trips_2022_clean`
GROUP BY payment_type
ORDER BY total_viajes DESC;

CREATE OR REPLACE TABLE `eastern-bridge-474702-g4.proyecto_2_taxi.viz_top_zonas_origen` AS
SELECT
  pickup_location_id,
  COUNT(*) AS total_viajes,
  ROUND(AVG(total_amount), 2) AS total_promedio,
  ROUND(AVG(tip_amount), 2) AS propina_promedio
FROM `eastern-bridge-474702-g4.proyecto_2_taxi.taxi_trips_2022_clean`
GROUP BY pickup_location_id
ORDER BY total_viajes DESC
LIMIT 20;