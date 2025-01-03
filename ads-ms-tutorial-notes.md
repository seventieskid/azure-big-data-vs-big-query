Notes of Azure Synpase Analytics PoC
------------------------------------

- Generally, Azure is "laggy". Just because an ARM template is marked as "deployed" does not mean the resouces behind it are fully operational. This is particularly relevant to Storage Accounts and Synapse Analytics workspaces which are complex creations.

You'll see weird 404s on some menu paths until things are complete. Don't use until the 404s are gone.

- Follow this tutorial from MS: https://learn.microsoft.com/en-us/azure/synapse-analytics/get-started-create-workspace

- Pre-Reqs:
    - For encryption at rest - Encryption key in Azure key-vault
    - MSI assigned to it's compute ?? - User managed identity with role "Key Vault Crypto Service Encryption User"

- Choose to create with VPC, full encryption, and private according to guiderails

- Issue: Standard_RAGRS was defaulted in during point-n-click setup, and caused failure. See https://learn.microsoft.com/en-us/rest/api/storagerp/srp_sku_types. Replace with Standard_LRS in ARM create template (accessible by clicking through from failure).

- Nice feature in Azure that you have access to Azure Resource Manager (ARM) creation templates.

- Takes 10 mins to create Synapse Workspace, and dependent stack of artefacts

- Goto workspace, and see properties to grab "Workspace web URL". Something like:-

https://web.azuresynapse.net?workspace=%2fsubscriptions%2f60e1436b-d08b-466d-b42a-98011fed3eb2%2fresourceGroups%2fazuron-synapse%2fproviders%2fMicrosoft.Synapse%2fworkspaces%2fazuron-synapse

- Upload data links:-

Used for SQL queries: https://azuronsynapselake.dfs.core.windows.net/azuron-users/2024NYCTripSmall.parquet

Used for Spark queries: abfss://azuron-users@azuronsynapselake.dfs.core.windows.net/2024NYCTripSmall.parquet

- Work in a dedicated Synapse Analytics studio on the web. Nice. Not main Azure.

Serverless SQL pool
-------------------
- Serverless SQL pools (Built-in). Very easy to use.

- Only a facade over Azure Storage Account

- Limited capabilties in creating temporary tables

TO-DO: Follow up training - https://learn.microsoft.com/en-us/training/modules/query-data-lake-using-azure-synapse-serverless-sql-pools/?source=recommendations

- Performance not as good as dedicated SQL pools

- With DW100c, seems like a 240TB limit. Manage --> SQL Pools --> Configuration --> Max size
Apache Spark pool
-----------------
- Nice notebook user feel in the IDE

- Initial notebook took 3min 48 secs to establish Spark session and load data into dataframe. That is a substantial boot time.

- Initial command to pull back 10 recs took 19 secs 53ms. Eeek

- Overall seems slower than serverless SQL

- Notebook based access only via DataFrames. Programmatic overhead. Not like GCP BQ query execution.

Dedicated SQL pool
------------------

- SQL UPDATE and INSERT statements can be used here, but not on SERVERLESS SQL pools
- Nice comparison between serverless and dedicated SQL pools. Dedicated is where it's at in terms of performance apparently.

- Performance level slidebar shows nice cost implications from: DW100c (1.51 USD per hour) to DW30000c (453.00 USD per hour)

- We'll run our tests using the cheapest for now: DW100c

- Can't choose how many instances are in the pool though - interesting

- 6 mins and 25 secs to deploy

- Not nice big SQL statement to load dedicated SQL tables from Azure blob storage. Probably not the way you'd operate at scale anyhow.

- Dedicated SQL pools can be paused to save money. Pausing takes around 90 secs. Unpausing takes around 150 secs.

- Very much like BQ look and feel and user experience.

Simple comparison between Azure Dedicated SQL Pool and GCP Big Query

Azure SQL:-

DROP TABLE [dbo].[PassengerCountStats];

SELECT passenger_count as PassengerCount,
      SUM(trip_distance) as SumTripDistance_miles,
      AVG(trip_distance) as AvgTripDistance_miles
INTO dbo.PassengerCountStats
FROM  dbo.NYCTaxiTripSmall
WHERE trip_distance > 0 AND passenger_count > 0
GROUP BY passenger_count;

SELECT * FROM dbo.PassengerCountStats
ORDER BY PassengerCount;

BQ SQL:-

DROP TABLE azuron-play-area.azure_compare.PassengerCountStats;

CREATE TABLE azuron-play-area.azure_compare.PassengerCountStats
  AS
SELECT
  passenger_count as PassengerCount,
  SUM(trip_distance) as SumTripDistance_miles,
  AVG(trip_distance) as AvgTripDistance_miles
FROM
  azuron-play-area.azure_compare.NYCTaxiTripSmall
WHERE
  trip_distance > 0 AND passenger_count > 0
GROUP BY
  passenger_count;

SELECT
  *
FROM
  azuron-play-area.azure_compare.PassengerCountStats
ORDER BY
PassengerCount;


New York Yellow Taxi Trips 2023
-------------------------------

total for year 38,310,226

BQ Query: Sum all trips for the 12 months:

SELECT 
  SUM(cnt),
FROM (
  SELECT row_count  as cnt FROM `azuron-play-area.npc_yellow_taxi_2023.__TABLES__`
  GROUP BY 1
)

- Spark loading of 12 months data appears quicker than BQ on a per month basis. Anecdotal only though.

- Pain in the bum to wait for the spark session to start every time - probably need to configure session timeout to something sensible

Notebook to load spark, one month at a time....

%%pyspark
spark.sql("CREATE DATABASE IF NOT EXISTS npc_yellow_taxi_2023")

df = spark.read.load('abfss://azuron-users@azuronsynapselake.dfs.core.windows.net/yellow_tripdata_2023-01.parquet', format='parquet')

df.write.mode("overwrite").saveAsTable("npc_yellow_taxi_2023.yellow_tripdata_2023-01")

LOAD DEDICATED SQL POOL FROM STORAGE CONTAINER
----------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.objects O JOIN sys.schemas S ON O.schema_id = S.schema_id WHERE O.NAME = 'yellow_tripdata_2023_01' AND O.TYPE = 'U' AND S.NAME = 'dbo')
CREATE TABLE dbo.yellow_tripdata_2023_01
    (
    [VendorID] bigint, 
    [store_and_fwd_flag] nvarchar(1) NULL, 
    [RatecodeID] float NULL, 
    [PULocationID] bigint NULL,  
    [DOLocationID] bigint NULL, 
    [passenger_count] float NULL, 
    [trip_distance] float NULL, 
    [fare_amount] float NULL, 
    [extra] float NULL, 
    [mta_tax] float NULL, 
    [tip_amount] float NULL, 
    [tolls_amount] float NULL, 
    [ehail_fee] float NULL, 
    [improvement_surcharge] float NULL, 
    [total_amount] float NULL, 
    [payment_type] float NULL, 
    [trip_type] float NULL, 
    [congestion_surcharge] float  NULL
    )
WITH
    (
    DISTRIBUTION = ROUND_ROBIN,
     CLUSTERED COLUMNSTORE INDEX
     -- HEAP
    )
GO

COPY INTO dbo.yellow_tripdata_2023_01
(VendorID 1, store_and_fwd_flag 4, RatecodeID 5,  PULocationID 6 , DOLocationID 7,  
 passenger_count 8,trip_distance 9, fare_amount 10, extra 11, mta_tax 12, tip_amount 13, 
 tolls_amount 14, ehail_fee 15, improvement_surcharge 16, total_amount 17, 
 payment_type 18, trip_type 19, congestion_surcharge 20 )
FROM 'https://azuronsynapselake.dfs.core.windows.net/azuron-users/yellow_tripdata_2023-01.parquet'
WITH
(
    FILE_TYPE = 'PARQUET'
    ,MAXERRORS = 0
    ,IDENTITY_INSERT = 'OFF'
    ,AUTO_CREATE_TABLE ='ON'
)

Loading Data Into Tables
------------------------

!!!! GOT INTO A KNOT WITH TOO MANY UNCOMMITTED CHANGES AND CIRCULAR REFERENCES BETWEEN ARTEFACTS. PUBLISH REGULARLY IS THE KEY  - HAD TO DELETE RESOURCE GROUP TO RECOVER - NOT NICE !!!!

1. Export 2016 nyc taxi data from big query as uncompressed csv files - 132 in all.

Location: bigquery-public-data.new_york.tlc_yellow_trips_2016
Rows: 131,165,043
Logical GB: 14.89

2. Load files into Azure blob storage 

3. Create definition for CSV source:

Data --> Integration Dataset --> Azure Datalake storage Gen2 --> nyc_taxi_2016_csv

- Enable interactive authoring (clieck info button in UI)
- Interactive authoring allows you to browse the lake gen2
- Select specifc file here, now wildcards. We'll wilcard at the pipeline level.
- Quote char == Escape char
- PREVIEW DATA TO ENSURE ALL IS LOADING OK

ALL FIELD ARE OF TYPE STRING

PUBLISH

3. Develop --> Dataflow --> nyc_taxi_2016_csv_to_tab

- Slider to "Data flow debug". Gives some nice ability to check during development

- Source: choose dataset nyc_taxi_2016_csv, initially wildcard paths are EMPTY (until we move to the mass load)

- Sink: create dataset nyc_taxi_2016_tab insitu, type Azure Synapse Analytics.

  Test connection. Seems buggy. When testing connection, it fails, so drop into integration set and add DB SQL pool name and publish - AZURON.

  Mapping: Auto mapping will do here

  Check Data Preview tab to ensure it comes out like you expect.

4. Integrate --> Pipeline --> nyc_taxi_2016_csv_to_tab

- Settings

  - Dataflow (nyc_taxi_2016_csv_to_tab)
  - Staging Linked Service + Staging Path

5. Try to load one CSV file into table and check the outcome...

This will take approximately 90 secs

6. Query top 10 rows. Do the same on Big Query.

If all looks ok, TRUNCATE the table.

7. Mass load

- Data --> Linked --> nyc_taxi_2016_csv

- Connection --> File Path --> Remove file name

- Develop --> Dataflow --> nyc_taxi_2016_csv_to_tab --> Source Options --> Add * to wildcard

PUBLISH

- Intergrate --> Pipeline --> nyc_taxi_2016_csv_to_tab --> Add Trigger --> Manual

- Monitor --> Pipline Run

It will take around 30 mins to load all the data into the table

We have choose a single unit of work in the "Sink", so it won't commit to the DB in batches, only as whole.

8. Verify count on table is 131,165,043

VS Code Integration
-------------------

- Can easily connect to Azure Synapse Dedicated SQL pool

- Can run queries locally, Cmd+Shift+E

- Very very nice linting features on MS SQL to spot mistakes whilst migrating BQ SQL.

Complex Query Testing
---------------------

Big Query (Interactive)
-----------------------

NYC_TAXI_DATA_COMPLETE QUERY

Measured time: 20.359secs
Elapsed time: 18 secs
Slot time consumed: 39min 21 secs

Azure Synapse Analytics Dedicated SQL Pool
------------------------------------------

Seems like a consistent 240TB limit per dedicated node pool

Approx time to scale (DW100c to DW200c)= 4mins 20secs
Approx time to scale (DW200c to DW1000c)= 3mins 12secs
Approx time to scale (DW1000c to DW7500c)= 6mins 01secs

Approx time to scale down (DW7500c to DW100c)= ??mins ??secs

(All tests run directly in portal)

DW100c (concurrency=4, min%perrequest=25, cost=1.51 USD/hour) - 513480 ms 
DW200c (concurrency=8, min%perrequest=12.5, cost=3.02 USD/hour) - 499690 ms
DW1000c (concurrency=32, min%perrequest=3, cost=15.10 USD/hour) - 515800 ms
DW7500c (concurrency=128, min%perrequest=0.75, cost=113.25 USD/hour) - 479877 / 484780 ms

EXPENSIVE !!!

Azure Synapse Analytics Spark Severless Pool
--------------------------------------------

No storage limit, because we're on Azure Datalake Storage Gen 2

3min 48secs to spin up spark session (all test results EXCLUDE spark session startup time)

(All tests run directly in portal)

Autoscale = OFF
Dynamically allocate executors = OFF
Intelligent cache size = OFF
Load, create table, query

(Beyond 3, will need a total regional vcpu increase from 12 to 40)


Size tests :-

3 x Medium (4 vCores, 32GB) - Cost 1.85 US/hour - 258332ms, 316027ms

