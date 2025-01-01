-- See https://medium.com/@linniartan/nyc-taxi-data-analysis-part-1-clean-and-transform-data-in-bigquery-2cb1142c6b8b

DECLARE @EndTime AS datetime2;
DECLARE @StartTime AS datetime2;

SET @StartTime = CURRENT_TIMESTAMP;

SELECT 
    t.*
FROM
(
SELECT *,
    DATEDIFF(SECOND, pickup_datetime, dropoff_datetime) as time_duration_in_secs,
    ROUND(trip_distance/DATEDIFF(SECOND, pickup_datetime, dropoff_datetime),2)*3600 as driving_speed_miles_per_hour,
    (CASE WHEN total_amount=0 THEN 0
    ELSE ROUND(tip_amount*100/total_amount,2) END) as tip_rate,
    YEAR(pickup_datetime) as pickup_year,
    MONTH(pickup_datetime) as pickup_month,
    CONCAT(CAST(YEAR(pickup_datetime) as VARCHAR),'-',CAST(MONTH(pickup_datetime) AS VARCHAR)) as pickup_yearmonth,
    CAST(pickup_datetime AS date) as pickup_date,
    FORMAT(CAST(pickup_datetime AS date), 'dddd') as pickup_weekday_name,
    DATEPART(YEAR, pickup_datetime) as pickup_hour,
    YEAR(dropoff_datetime) as dropoff_year,
    MONTH(dropoff_datetime) as dropoff_month,
    CONCAT(CAST(YEAR(dropoff_datetime) as VARCHAR),'-',CAST(MONTH(dropoff_datetime) AS VARCHAR)) as dropoff_yearmonth,
    CAST(dropoff_datetime AS date) as dropoff_date,
    FORMAT(CAST(dropoff_datetime AS date), 'dddd') as dropoff_weekday_name,
    DATEPART(YEAR, dropoff_datetime) as dropoff_hour
FROM [new_york].[tlc_yellow_trips_2016]
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
    AND DATEDIFF(SECOND, pickup_datetime,dropoff_datetime) > 0
    AND passenger_count > 0
    AND trip_distance >= 0 
    AND tip_amount >= 0 
    AND tolls_amount >= 0 
    AND mta_tax >= 0 
    AND fare_amount >= 0
    AND total_amount >= 0;

SET @EndTime = CURRENT_TIMESTAMP;

SELECT DATEDIFF(MILLISECOND, @StartTime, @EndTime) as Duration_In_Millisecs