-- See https://medium.com/@linniartan/nyc-taxi-data-analysis-part-1-clean-and-transform-data-in-bigquery-2cb1142c6b8b
DECLARE EndTime timestamp;
DECLARE StartTime timestamp;

SET StartTime = (SELECT CURRENT_TIMESTAMP());

SELECT 
    COUNT(*)
FROM
(
SELECT *,
    TIMESTAMP_DIFF(dropoff_datetime,pickup_datetime,SECOND) as time_duration_in_secs,
    ROUND(trip_distance/TIMESTAMP_DIFF(dropoff_datetime,pickup_datetime,SECOND),2)*3600 as driving_speed_miles_per_hour,
    (CASE WHEN total_amount=0 THEN 0
    ELSE ROUND(tip_amount*100/total_amount,2) END) as tip_rate,
    EXTRACT(YEAR from pickup_datetime) as pickup_year,
    EXTRACT(MONTH from pickup_datetime) as pickup_month,
    CONCAT(CAST(EXTRACT(YEAR from pickup_datetime) as STRING),"-",CAST(EXTRACT(MONTH from pickup_datetime) AS STRING)) as pickup_yearmonth,
    EXTRACT(DATE from pickup_datetime) as pickup_date,
    FORMAT_DATE('%A',DATE(pickup_datetime)) as pickup_weekday_name,
    EXTRACT(HOUR from pickup_datetime) as pickup_hour,
    EXTRACT(YEAR from dropoff_datetime) as dropoff_year,
    EXTRACT(MONTH from dropoff_datetime) as dropoff_month,
    CONCAT(CAST(EXTRACT(YEAR from dropoff_datetime) as STRING),"-",CAST(EXTRACT(MONTH from dropoff_datetime) AS STRING)) as dropoff_yearmonth,
    EXTRACT(DATE from dropoff_datetime) as dropoff_date,
    FORMAT_DATE('%A',DATE(dropoff_datetime)) as dropoff_weekday_name,
    EXTRACT(HOUR from dropoff_datetime) as dropoff_hour
FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
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
    AND TIMESTAMP_DIFF(dropoff_datetime,pickup_datetime,SECOND) > 0
    AND passenger_count > 0
    AND trip_distance >= 0 
    AND tip_amount >= 0 
    AND tolls_amount >= 0 
    AND mta_tax >= 0 
    AND fare_amount >= 0
    AND total_amount >= 0;

SET EndTime = (SELECT CURRENT_TIMESTAMP());

SELECT timestamp_diff(EndTime, StartTime, MILLISECOND) as Duration_In_Millisecs