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

Test Cluster Compute - Processing Data Directly From Azure Data Lake Storage Gen2
---------------------------------------------------------------------------------

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

Row count: 69295971

25174ms
22763ms
21638ms
21542ms
21914ms
21013ms

Av. 22341ms

Test #2 - Standard_DS14_V2 (16 Cores 112GB RAM) - 1 OFF  

(needs StandardDV2Family quota increase 0 to 16 - 16 x 1)  - comparable with compute from other Azure Big Data tests

- Switch cluster size by Compute --> Edit --> [choose compute]

Test results:-

Load data - ?? mins - fastest of all platforms so far

Spark queries:-

Row count: 69295971

20141ms
16249ms
16737ms
16406ms
16274ms
16332ms

Av. 17023ms

**** Looks like it's very responsive to more CPU/memory


Serverless Starter Warehouse Variant
------------------

https://learn.microsoft.com/en-us/azure/databricks/delta-live-tables/load#load-files-from-cloud-object-storage

Manually load data to storage....

- Create directory nyc_taxi_2016
- Create a schema: Catalog --> azuron --> Create --> new_york --> azuron-datbricks (external connection) --> nyc_taxi_2016 (directory)
- Load CSV files like this....

??

Data Warehouse Variant
-----------------------

- Tried serverless

How about trying ingestion directly from GCS ?