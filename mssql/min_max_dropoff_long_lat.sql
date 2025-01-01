-- See https://medium.com/@linniartan/nyc-taxi-data-analysis-part-1-clean-and-transform-data-in-bigquery-2cb1142c6b8b

DECLARE @EndTime AS datetime2;
DECLARE @StartTime AS datetime2;

SET @StartTime = CURRENT_TIMESTAMP;

SELECT 
    MIN(dropoff_longitude) min_long, 
    MAX(dropoff_longitude) max_long,
    MIN(dropoff_latitude) min_lat,
    MAX(dropoff_latitude) max_lat
FROM [new_york].[tlc_yellow_trips_2016]
WHERE 
  ((pickup_latitude BETWEEN -90 AND 90) AND
  (pickup_longitude BETWEEN -180 AND 180)) 
AND
  ((dropoff_latitude BETWEEN -90 AND 90) AND
  (dropoff_longitude BETWEEN -180 AND 180));

SET @EndTime = CURRENT_TIMESTAMP;

SELECT DATEDIFF(MILLISECOND, @StartTime, @EndTime) as Duration_In_Millisecs