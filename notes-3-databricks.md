Azure Databricks
----------------

General Observations
--------------------
- Green tech. in the bank

- Approximately 4 mins to create Databricks workspace, but as with all things Azure there's a lag between "deployment complete" and actually having the service usable

- Similar time to delete Databricks workspace

- Test on premimum pricing tier (not free tier) to ensure cost comparisons can be made whilst testing. This is a must to take advantage of Entra ID integration between Databricks and Azure. i.e. We don't have to manage storage keys for data access.

- Nice UI, entirely isolated from the Azure Portal experience, but creates a ton of stuff in the background

- Tutorial - https://learn.microsoft.com/en-us/azure/databricks/ingestion/cloud-object-storage/onboard-data

- Nice imporovement hints in the UI, e.g. use disk caching to speed up queries

- Nice embedded assistant too

- Setup and run tests in around 1 hour - very quick and easy and intuitive.

- Very large choice of VMs, including families we've used before

- Can automatically terminate cluster after a given period or on an adhoc basis in the Databricks UI. 

It masks the fact that underlying compute remains on on your Azure subscription, so remains on, running and chargable !!!

- Looks like Google data source ingestion goes via a crew called Fivetran. No use.

Can't see any other way to ingest directly from GCS because there's no other way to store GCP secrets. Databricks UI Credentials doesn't support GCP creds.

Haven't really looked at this area in depth though, it's it's doubtful.

- All tables are delta tables by default unless you choose otherwise

Somewhere to Store the Data - Create Azure Storage Account
-----------------------------------------------------------

- In resource group azuron-databricks
- With "Enable hierarchical namespace"
- Create container "data"
- Called "azurondatabricks"

A Means To Access The Data from Databricks - Use Managed Identity to Control Access from Databricks to Your Storage Account
----------------------------------------------------------------------------------------------------------------------------

This is important and used in all variations apart from the simple spark based load.

https://learn.microsoft.com/en-us/azure/databricks/data-governance/unity-catalog/azure-managed-identities

- Create Managed Identity, "azuron-databricks"
- Storage account "azurondatabricks", assign role: Storage Blob Data Contributor
- Storage account "azurondatabricks", assign role: Storage Queue Data Contributor
- Resource group, assign role: EventGrid EventSubscription Contributor

Azure Portal --> Access Connector For Azure Databricks --> Use the MSI from above.

Grab: /subscriptions/60e1436b-d08b-466d-b42a-98011fed3eb2/resourceGroups/azuron-databricks/providers/Microsoft.Databricks/accessConnectors/azuron-databricks

Catalog --> External Data --> Credential --> Create  (Only available with Premium and Free Databracks pricing tiering)

Credential name: azuron-databricks
Access connector ID: /subscriptions/60e1436b-d08b-466d-b42a-98011fed3eb2/resourceGroups/azuron-databricks/providers/Microsoft.Databricks/accessConnectors/azuron-databricks
User assigned managed identity ID (optional): /subscriptions/60e1436b-d08b-466d-b42a-98011fed3eb2/resourcegroups/azuron-databricks/providers/Microsoft.ManagedIdentity/userAssignedIdentities/azuron-databricks

Catalog --> External Location --> Create (Only available with Premium and Free Databracks pricing tiering

External location name: azuron-databricks
URL: abfss://data@azurondatabricks.dfs.core.windows.net/
Storage credential: (from drop down) azuron-databricks

"TEST CONNECTION" BUTTON TO PROVE IT WORKS

Cluster Exists Variant 1 - Processing Data Directly From Azure Data Lake Storage Gen2
--------------------------------------0--------------------------------------------

A cluster is somewhere to run stuff only. It's processing power, that's all. It's not the same thing as the "Databricks SQL Warehouse" option.

Test #1 - Standard_DS13_V2

- Single node, single user
- Runtime: 15.4 LTS (Scala 2.12, Spark 3.5.0)
- Standard_DS13_V2 (8 Cores 56GB RAM) - 1 OFF (equates to 4DBU/h)
- A VM is created on your Azure subscription
- Photon ON

- Databricks UI --> New --> Notebook

    - Connect to cluster (top right)
    - Run notebook databricks/load_and_query.ipynb by copying and pasting from the github repo here into the UI. Access from databricks

Test results:-

Load data - 2.16 mins - fastest of all platforms so far

Spark queries:-

Run databricks/cluster/spark_load_and_query.ipynb

Row count: 69295971

25174ms
22763ms
21638ms
21542ms
21914ms
21013ms

Av. 22341ms

Test #2 - Standard_DS14_V2 (16 Cores 112GB RAM) - 1 OFF  - 8 DBU/h

(needs StandardDV2Family quota increase 0 to 16 - 16 x 1)  - comparable with compute from other Azure Big Data tests

- Switch cluster size by Compute --> Edit --> [choose compute]

Test results:-

Load data - ?? mins - fastest of all platforms so far

Spark queries:-

Run databricks/cluster/spark_load_and_query.ipynb

Row count: 69295971

20141ms
16249ms
16737ms
16406ms
16274ms
16332ms

Av. 17023ms

**** Looks like it's very responsive to more CPU/memory


Notebook Variant 2 - Using Databricks Pipeline into Unity Catalog - BAD
-----------------------------------------------------------------------

https://learn.microsoft.com/en-us/azure/databricks/ingestion/cloud-object-storage/onboard-data

- Ensure data is already loaded into Azure Data Lake Gen 2 directory:-

e.g. abfss://users@azuron.dfs.core.windows.net/nyc-taxis-2016/*

- Don't need a cluster, one will be auto created to process the notebook

- Create external location, and credential using MSI - instructions are above. This gives access from Databricks to Azure storage account

Check connection:-

New --> Notebook - spark-delta-nyc-taxis-2016 - Save ()

(content from databricks/cluster/spark-delta-nyc-taxis-2016.ipynb)

This cannot be run from a notebook, it gives syntax errors, it must be run from a pipeline, see below.

Worflows --> Delta Live Tables --> Create Pipeline

    - content from databricks/cluster/spark-from-cluster.pipeline

    - 10 DBU/h

    - Run the pipeline to create and load the table into the catalog

    - Seems to be just another way of loading a delta tables into the catalog, so loading time comparisons are relevant, but not query times.

    - This will create a compute cluster on-the-fly for the job to use in your Azure subscription. YOU CANNOT POINT TO AN EXISTING CLUSTER. That could prove costly and quota heavy.

    - Seems to always create a multi-node cluster, can't choose a single node option (2 x VMs minimum)

    - Pipeline takes 14 mins to run, including spinning up the compute cluster and loading the data. Looks like it took 3m 49secs to load the table, which is slow compared to other variants.

    - Nice pipeline statistics though in the UI.

    - VMs created by the pipeline seem to linger, with no obvious way to delete them - disappear after 10 mins

    - All fields have been created as type strings in the delta table. That's not really any good for us. i.e. Pipeline are not as clever as a streaming table creation mechanism below.


Data Warehouse Variant - With Auto Loader and Delta Live Tables - GOOD
----------------------------------------------------------------------

- Nice SQL user interface with great performance statistics

See https://learn.microsoft.com/en-us/azure/databricks/tables/streaming

- Start "Serverless Starter Warehouse" - default Small (12 DBU/h)

- Create external location, and credential using MSI - instructions are above. This gives access from Databricks to Azure storage account

- SQL Editor LIST 'abfss://users@azuron.dfs.core.windows.net/nyc-taxis-2016/'

- Load data run databricks/sql_warehouse/load_streaming_tables.sql

Table created in 4mins 41 secs

- In SQL Editor, check row count (get path from catalog right click):-

SELECT COUNT(*) FROM azuron_1942372571023859.default.nyc_taxis_2016;

Test 1:
--------

Tool:               Databricks SQL Editor UI
Magic Variable:     Not applicable
Connected Compute:  Severless SQL Warehouse - Small
Data Catalog:       Unity

run databricks/sql_warehouse/nyc_taxi_data_complete.sql

Returned count - 69295945

Speeds read of ui...

1040ms
990ms
1035ms
988ms
982ms
977ms

Av. 1002ms

Lots and lots of servless data warehouses sizing options - lots (4 DBU/h - 528 DBu/h)

It also turns off after 10 mins by default. Is truely serverless - can't see anything on the Azure subscription.

Test 2:
--------

Tool:               Databricks UI Notebook
Magic Variable:     %python
Connected Compute:  Cluster
Data Catalog:       Unity

run databricks/sql_warehouse/spark_python_query.ipynb

>>> first 27622ms
5886ms
4774ms
4479ms
4576ms
4311ms
4281ms

av. 4717ms

Test 3:
--------

Tool:               Databricks UI Notebook
Magic Variable:     %sql
Connected Compute:  Cluster
Data Catalog:       Unity

run databricks/sql_warehouse/spark_sql_query.ipynb

>>> first 8062ms
276ms
335ms
288ms
273ms
281ms
778ms

av. 372ms   << the absolute fastest of all big data tech and variations