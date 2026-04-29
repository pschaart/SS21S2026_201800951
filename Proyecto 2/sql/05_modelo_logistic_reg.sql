-- ============================================================
-- MODELO 1: LOGISTIC REGRESSION
-- Objetivo: predecir si un viaje tendrá propina alta.
-- Prevención de data leakage:
-- No se usan tip_amount, tip_percentage ni total_amount como features.
-- ============================================================

CREATE OR REPLACE MODEL `eastern-bridge-474702-g4.proyecto_2_taxi.modelo_logistic_high_tip`
OPTIONS(
  model_type = 'LOGISTIC_REG',
  input_label_cols = ['is_high_tip'],
  data_split_method = 'CUSTOM',
  data_split_col = 'data_split',
  max_iterations = 20,
  learn_rate_strategy = 'CONSTANT',
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