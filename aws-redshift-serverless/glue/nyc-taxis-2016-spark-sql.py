# This is an ETL script that can be dropped straight in AWS Glue
# It depends on a Redshift connection being present in AWS Glue called azuron-redshift
# It runs Spark SQL, not Redshfit SQL
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame

def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Script generated for node azuron-redshift
azuronredshift_node1741207446166 = glueContext.create_dynamic_frame.from_options(connection_type="redshift", connection_options={"redshiftTmpDir": "s3://aws-glue-assets-413874846216-eu-west-1/temporary/", "useConnectionProperties": "true", "dbtable": "new_york.tlc_yellow_trips_2016", "connectionName": "azuron-redshift"}, transformation_ctx="azuronredshift_node1741207446166")

# Script generated for node SQL Query
SqlQuery0 = '''
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
FROM gluealiasnyctaxis2016
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
'''
SQLQuery_node1741259118816 = sparkSqlQuery(glueContext, query = SqlQuery0, mapping = {"gluealiasnyctaxis2016":azuronredshift_node1741207446166}, transformation_ctx = "SQLQuery_node1741259118816")

job.commit()