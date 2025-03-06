-- This is Redshift SQL
SELECT 
    count(*)
FROM
(
SELECT *,
    DATEDIFF(SECOND,pickup_datetime,dropoff_datetime) as time_duration_in_secs,
    ROUND(trip_distance/DATEDIFF(SECOND,pickup_datetime,dropoff_datetime),2)*3600 as driving_speed_miles_per_hour,
    (CASE WHEN total_amount=0 THEN 0
    ELSE ROUND(tip_amount*100/total_amount,2) END) as tip_rate,
    EXTRACT(YEAR from pickup_datetime) as pickup_year,
    EXTRACT(MONTH from pickup_datetime) as pickup_month,
    CONCAT(EXTRACT(YEAR from pickup_datetime), CONCAT('-',EXTRACT(MONTH from pickup_datetime))) as pickup_yearmonth,
    CAST(pickup_datetime AS date) as pickup_date,
    TO_CHAR(pickup_datetime, 'Day') as pickup_weekday_name,
    EXTRACT(HOUR from pickup_datetime) as pickup_hour,
    EXTRACT(YEAR from dropoff_datetime) as dropoff_year,
    EXTRACT(MONTH from dropoff_datetime) as dropoff_month,
    CONCAT(EXTRACT(YEAR from dropoff_datetime), CONCAT('-',EXTRACT(MONTH from dropoff_datetime))) as dropoff_yearmonth,
    CAST(dropoff_datetime AS date) as dropoff_date,
    TO_CHAR(dropoff_datetime, 'Day') as dropoff_weekday_name,
    EXTRACT(HOUR from dropoff_datetime) as dropoff_hour
FROM dev.new_york.tlc_yellow_trips_2016
/* filter by latitude & longitude that are within the correct range */
WHERE 
  ((pickup_latitude BETWEEN -90 AND 90) AND
  (pickup_longitude BETWEEN -180 AND 180)) 
AND
  ((dropoff_latitude BETWEEN -90 AND 90) AND
  (dropoff_longitude BETWEEN -180 AND 180))
) t
WHERE 
    pickup_datetime BETWEEN '2016-01-01' AND '2016-12-31' 
    AND dropoff_datetime BETWEEN '2016-01-01' AND '2016-12-31'
    AND DATEDIFF(SECOND,pickup_datetime,dropoff_datetime) > 0
    AND passenger_count > 0
    AND trip_distance >= 0 
    AND tip_amount >= 0 
    AND tolls_amount >= 0 
    AND mta_tax >= 0 
    AND fare_amount >= 0
    AND total_amount >= 0;