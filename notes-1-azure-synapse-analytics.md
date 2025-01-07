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

Serverless SQL pool - BYPASS
----------------------------
- Serverless SQL pools (Built-in). Very easy to use.

- Only a facade over Azure Storage Account

- Limited capabilties in creating temporary tables

TO-DO: Follow up training - https://learn.microsoft.com/en-us/training/modules/query-data-lake-using-azure-synapse-serverless-sql-pools/?source=recommendations

- Performance not as good as dedicated SQL pools

- With DW100c, seems like a 240TB limit. Manage --> SQL Pools --> Configuration --> Max size


Dedicated SQL pool
------------------

- see https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/memory-concurrency-limits

- SQL UPDATE and INSERT statements can be used here, but not on SERVERLESS SQL pools

- Performance level slidebar shows nice cost implications from: DW100c (1.51 USD per hour) to DW30000c (453.00 USD per hour)

- Can't choose how many instances are in the pool though - interesting

- 6 mins and 25 secs to deploy

- Not nice big SQL statement to load dedicated SQL tables from Azure blob storage. Probably not the way you'd operate at scale anyhow.

- Dedicated SQL pools can be paused to save money. Pausing takes around 90 secs. Unpausing takes around 150 secs.

- Very much like BQ look and feel and user experience.

- Seems like a consistent 240TB limit per dedicated node pool

- Loading Data Into Tables

- Tricky SQL conversion between BQ SQL and MS SQL Server syntax. Likely to be the deal breaker on this tech.

- Can't go bigger than a DW30000c (453USD per hour) - is this enough for us ? 60 x compute nodes

"The maximum service level is DW30000c, which has 60 Compute nodes and one distribution per Compute node. For example, a 600 TB data warehouse at DW30000c processes approximately 10 TB per Compute node."

- Ability to provide workload isolation is a nice feature, but only if there's enough resource available to logically split on DW3000c !

!!!! GOT INTO A KNOT WITH TOO MANY UNCOMMITTED CHANGES AND CIRCULAR REFERENCES BETWEEN ARTEFACTS. PUBLISH REGULARLY IS THE KEY  - HAD TO DELETE RESOURCE GROUP TO RECOVER - NOT NICE !!!!

1. Export 2016 nyc taxi data from big query as uncompressed csv files - 132 in all.

Location: bigquery-public-data.new_york.tlc_yellow_trips_2016
Rows: 131,165,043
Logical GB: 14.89

2. Load files into Azure blob storage manually

3. Create definition for CSV source:

Data --> Integration Dataset --> Azure Datalake storage Gen2 --> CSV

- Name: nyc_taxi_2016_csv
- Enable interactive authoring (click info button in UI) - Interactive authoring allows you to browse the lake gen2
- Select specifc file here, no wildcards. We'll wilcard at the azure data pipeline level later.
- Quote char == Escape char
- PREVIEW DATA TO ENSURE ALL IS LOADING OK

ALL FIELD ARE OF TYPE STRING

PUBLISH

3. Create SQL internal table using DDL 00-nyc_taxi_2016_create.sql


3. Develop --> Dataflow --> nyc_taxi_2016_csv_to_tab

- Slider to "Data flow debug". Gives some nice ability to check during development

- Source: choose dataset nyc_taxi_2016_csv, initially wildcard paths are EMPTY (until we move to the mass load)

- Sink: create dataset nyc_taxi_2016_tab insitu, type Azure Synapse Analytics.

  Test connection. Seems buggy. When testing connection, it fails, so drop into integration set and add DB SQL pool name and publish - AZURON.

  Mapping: Auto mapping will do here

  Might have to add the DB dedicated SQL pool "AZURON" twice.

  Check Data Preview tab to ensure it comes out like you expect.

4. Integrate --> Pipeline --> nyc_taxi_2016_csv_to_tab

- Settings

  - Dataflow (nyc_taxi_2016_csv_to_tab)
  - Staging Linked Service + Staging Path

  - Run the pipeline. Try to load one CSV file into table and check the outcome...This will take approximately 90 secs

6. Manually query top 10 rows. Do the same on Big Query.

If all looks ok, TRUNCATE the table.

7. Mass load

- Data --> Linked --> Integration dataset --> nyc_taxi_2016_csv

- Develop --> Dataflow --> nyc_taxi_2016_csv_to_tab --> Source Options --> Add * to wildcard

PUBLISH

- Intergrate --> Pipeline --> nyc_taxi_2016_csv_to_tab --> Add Trigger --> Trigger Now

- Monitor --> Pipline Run

It will take around 23 mins to load all the data into the table

We have choose a single unit of work in the "Sink", so it won't commit to the DB in batches, only as whole.

8. Verify count on table is 131,165,043

9. Run the test nyc_taxi_data_complete.sql

VS Code Integration
-------------------

- Can easily connect to Azure Synapse Dedicated SQL pool

- Can run queries locally, Cmd+Shift+E

- Very very nice linting features on MS SQL to spot mistakes whilst migrating BQ SQL.


Test Scenarios
--------------

Approx time to scale (DW100c to DW200c)= 4mins 20secs
Approx time to scale (DW200c to DW1000c)= 3mins 12secs
Approx time to scale (DW1000c to DW7500c)= 6mins 01secs

Approx time to scale down (DW7500c to DW100c)= ??mins ??secs

(All tests run directly in portal)

DW100c (concurrency=4, min%perrequest=25, cost=1.51 USD/hour)

Row count 69295945

44840ms
3796ms
3277ms
3333ms
3297ms
3310ms
3207ms

Av. 3270ms

DW6000c (concurrency=128, min%perrequest=0.75, cost=90.60 USD/hour)

Row count 69295945

3050ms
320ms
310ms
333ms
300ms
323ms
313ms


Av. 317ms

EXPENSIVE AND FASTER THAN BQ !!!

Apache Spark pool
-----------------
- Notebook support for SparkR, PySpark, SparkSQL Spark(Scala). Lots of nice options there.

- Less than one minute to scale or descale

- Nice notebook user feel in the IDE

- Initial notebook took 3min 48 secs to establish Spark session and load data into dataframe. It's not substantial for long jobs.

- Initial command to pull back 10 recs took 19 secs 53ms. Eeek

- Overall seems slower than serverless SQL

- Notebook based access only via DataFrames. Programmatic overhead. Not like GCP BQ query execution.

- No storage limit, because we're on Azure Datalake Storage Gen 2

- Spark session management is an additional overhead, because it does hold vCPU quotas. So it needs consideration and management.

- Better native notebook experience than Jupyter or Zepplin

- No complex SQL table load needed nor SHIFT of the data into a SQL relational database

- Can it scale sufficiently, Seems like a limit of:-

XXLarge (64VCores, 432GB) x 200 OFF - 1978USD per hour !! Holy moly.

- Can scale horizontally and vertically on the fly.

(All tests run directly in portal)

Autoscale = OFF
Dynamically allocate executors = OFF
Intelligent cache size = OFF
3 x Small (4 vCores, 32GB) - Cost 1.85 US/hour (minimum size pool) [rougly like-for-like with HDInsight Spark]

(Beyond 3, will need a total regional vcpu increase from 12 to 40)

Load and table creation time (one off), assuming data is already on Azure Storage Data Lake Gen 2:-

245890ms

complex query wrapped, only reporting count, to remove the time to return and render in UI (deemed not important during batch processing)

row count = 69295971

118396ms
117813ms
117809ms

Av: 118006ms

Cheap - incurred £4.71 for all dedicated spark pool testing on ASA vs £00 for dedicated SQL pool on ASA.
