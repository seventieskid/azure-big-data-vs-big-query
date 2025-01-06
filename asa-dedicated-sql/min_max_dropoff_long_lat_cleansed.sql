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
/* filter by latitude & longitude that are within the correct range */
  ((pickup_latitude BETWEEN -90 AND 90) AND
  (pickup_longitude BETWEEN -180 AND 180)) 
AND
  ((dropoff_latitude BETWEEN -90 AND 90) AND
  (dropoff_longitude BETWEEN -180 AND 180))
/*filter the dates to only include 2016 dates and remove those with trip duration <= 0 */
AND 
    pickup_datetime BETWEEN '2016-01-01' AND '2016-12-31' AND
    dropoff_datetime BETWEEN '2016-01-01' AND '2016-12-31' 
AND DATEDIFF(SECOND, pickup_datetime, dropoff_datetime) > 0;

SET @EndTime = CURRENT_TIMESTAMP;

SELECT DATEDIFF(MILLISECOND, @StartTime, @EndTime) as Duration_In_Millisecs