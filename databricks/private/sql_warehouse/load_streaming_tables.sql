CREATE OR REFRESH STREAMING TABLE new_york.tlc_yellow_trips_2016 AS
SELECT * FROM STREAM read_files('abfss://users@azuron.dfs.core.windows.net/nyc-taxis-2016', FORMAT => 'csv')
