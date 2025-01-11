-- See https://medium.com/@linniartan/nyc-taxi-data-analysis-part-1-clean-and-transform-data-in-bigquery-2cb1142c6b8b
DECLARE EndTime timestamp;
DECLARE StartTime timestamp;

SET var StartTime = (SELECT current_timestamp());

SELECT
     
    COUNT(*)
FROM
(
SELECT *,
    DATEDIFF(SECOND, pickup_datetime, dropoff_datetime) as time_duration_in_secs,
    ROUND(trip_distance/DATEDIFF(SECOND, pickup_datetime, dropoff_datetime),2)*3600 as driving_speed_miles_per_hour,
    (CASE WHEN total_amount=0 THEN 0
    ELSE ROUND(tip_amount*100/total_amount,2) END) as tip_rate,
    DATE_FORMAT(pickup_datetime, "yyyy") as pickup_year,
    DATE_FORMAT(pickup_datetime, "MM") as pickup_month,
    CONCAT(CAST(DATE_FORMAT(pickup_datetime, "yyyy") as STRING),"-",CAST(DATE_FORMAT(pickup_datetime, "MM") AS STRING)) as pickup_yearmonth,
    DATE_FORMAT(pickup_datetime, "yyyyMMdd") as pickup_date,
    DATE_FORMAT(pickup_datetime, "EEEE") as pickup_weekday_name,
    DATE_FORMAT(pickup_datetime, "hh") as pickup_hour,
    DATE_FORMAT(dropoff_datetime, "yyyy") as dropoff_year,
    DATE_FORMAT(dropoff_datetime, "MM") as dropoff_month,
    CONCAT(CAST(DATE_FORMAT(dropoff_datetime, "yyyy") as STRING),"-",CAST(DATE_FORMAT(dropoff_datetime, "MM") AS STRING)) as dropoff_yearmonth,
    DATE_FORMAT(dropoff_datetime, "yyyyMMdd") as dropoff_date,
    DATE_FORMAT(dropoff_datetime, "EEEE") as dropoff_weekday_name,
    DATE_FORMAT(dropoff_datetime, "hh") as dropoff_hour
FROM azuron_1942372571023859.default.nyc_taxis_2016
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
    
SET var EndTime = (SELECT CURRENT_TIMESTAMP());

SELECT TIMESTAMPDIFF(MILLISECOND, StartTime, EndTime) as Duration_In_Millisecs