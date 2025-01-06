-- See https://medium.com/@linniartan/nyc-taxi-data-analysis-part-1-clean-and-transform-data-in-bigquery-2cb1142c6b8b
DECLARE EndTime timestamp;
DECLARE StartTime timestamp;

SET StartTime = (SELECT CURRENT_TIMESTAMP());

SELECT 
  MIN(dropoff_longitude) min_long, 
  MAX(dropoff_longitude) max_long,
  MIN(dropoff_latitude) min_lat,
  MAX(dropoff_latitude) max_lat
FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`;

SET EndTime = (SELECT CURRENT_TIMESTAMP());

SELECT timestamp_diff(EndTime, StartTime, MILLISECOND) as Duration_In_Millisecs