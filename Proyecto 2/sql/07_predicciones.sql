CREATE OR REPLACE TABLE `eastern-bridge-474702-g4.proyecto_2_taxi.predicciones_logistic` AS
SELECT
  *
FROM ML.PREDICT(
  MODEL `eastern-bridge-474702-g4.proyecto_2_taxi.modelo_logistic_high_tip`,
  (
    SELECT
      is_high_tip,
      pickup_datetime,
      pickup_hour,
      pickup_dayofweek,
      pickup_month,
      passenger_count,
      trip_distance,
      fare_amount,
      payment_type,
      pickup_location_id,
      dropoff_location_id,
      trip_duration_minutes,
      time_period
    FROM `eastern-bridge-474702-g4.proyecto_2_taxi.taxi_trips_2022_clean`
    WHERE pickup_date BETWEEN '2022-12-01' AND '2022-12-31'
    LIMIT 10000
  )
);

CREATE OR REPLACE TABLE `eastern-bridge-474702-g4.proyecto_2_taxi.predicciones_boosted_tree` AS
SELECT
  *
FROM ML.PREDICT(
  MODEL `eastern-bridge-474702-g4.proyecto_2_taxi.modelo_boosted_tree_high_tip`,
  (
    SELECT
      is_high_tip,
      pickup_datetime,
      pickup_hour,
      pickup_dayofweek,
      pickup_month,
      passenger_count,
      trip_distance,
      fare_amount,
      payment_type,
      pickup_location_id,
      dropoff_location_id,
      trip_duration_minutes,
      time_period
    FROM `eastern-bridge-474702-g4.proyecto_2_taxi.taxi_trips_2022_clean`
    WHERE pickup_date BETWEEN '2022-12-01' AND '2022-12-31'
    LIMIT 10000
  )
);

CREATE OR REPLACE TABLE `eastern-bridge-474702-g4.proyecto_2_taxi.viz_comparacion_predicciones` AS
SELECT
  'LOGISTIC_REG' AS modelo,
  predicted_is_high_tip AS prediccion,
  COUNT(*) AS cantidad
FROM `eastern-bridge-474702-g4.proyecto_2_taxi.predicciones_logistic`
GROUP BY predicted_is_high_tip

UNION ALL

SELECT
  'BOOSTED_TREE_CLASSIFIER' AS modelo,
  predicted_is_high_tip AS prediccion,
  COUNT(*) AS cantidad
FROM `eastern-bridge-474702-g4.proyecto_2_taxi.predicciones_boosted_tree`
GROUP BY predicted_is_high_tip;