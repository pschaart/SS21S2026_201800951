-- ============================================================
-- MODELO 2: BOOSTED TREE CLASSIFIER
-- Objetivo: comparar un modelo basado en árboles contra regresión logística.
-- ============================================================

CREATE OR REPLACE MODEL `eastern-bridge-474702-g4.proyecto_2_taxi.modelo_boosted_tree_high_tip`
OPTIONS(
  model_type = 'BOOSTED_TREE_CLASSIFIER',
  input_label_cols = ['is_high_tip'],
  data_split_method = 'CUSTOM',
  data_split_col = 'data_split',
  max_iterations = 20,
  max_tree_depth = 6,
  learn_rate = 0.1
) AS
SELECT
  is_high_tip,

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
  time_period,

  CASE
    WHEN pickup_date < '2022-10-01' THEN FALSE
    ELSE TRUE
  END AS data_split

FROM `eastern-bridge-474702-g4.proyecto_2_taxi.taxi_trips_2022_clean`
WHERE
  pickup_date BETWEEN '2022-01-01' AND '2022-12-31'
  AND MOD(ABS(FARM_FINGERPRINT(CAST(pickup_datetime AS STRING))), 10) < 3;