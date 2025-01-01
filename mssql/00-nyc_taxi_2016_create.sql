-- DROP TABLE new_york.tlc_yellow_trips_2016;
-- DROP SCHEMA new_york;

--CREATE SCHEMA new_york;

CREATE TABLE new_york.tlc_yellow_trips_2016
( 
	[vendor_id] [nvarchar]  NULL,
	[pickup_datetime] [datetime2]  NULL,
	[dropoff_datetime] [datetime2]  NULL,
	[passenger_count] [bigint]  NULL,
	[trip_distance] [float]  NULL,
	[pickup_longitude] [float]  NULL,
	[pickup_latitude] [float]  NULL,
	[rate_code] [bigint]  NULL,
	[store_and_fwd_flag] [nvarchar]  NULL,
	[dropoff_longitude] [float]  NULL,
	[dropoff_latitude] [float]  NULL,
	[payment_type] [nvarchar]  NULL,
	[fare_amount] [float]  NULL,
	[extra] [float]  NULL,
	[mta_tax] [float]  NULL,
	[tip_amount] [float]  NULL,
	[tolls_amount] [float]  NULL,
	[imp_surcharge] [float]  NULL,
	[total_amount] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,  --https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-distribute
	CLUSTERED COLUMNSTORE INDEX  --https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-index
)
GO