Azure Databricks
----------------

General Observations
--------------------
- Green tech. in the bank

- Approximately 4 mins to create Databricks workspace

- Similar time to delete Databricks workspace

- Nice UI, entirely isolated from the Azure Portal experience, but creates a ton of stuff in the background

- Tutorial - https://learn.microsoft.com/en-us/azure/databricks/ingestion/cloud-object-storage/onboard-data

- Nice imporovement hints in the UI, e.g. use disk caching to speed up queries

- Nice embedded assistant too

- Setup and run tests in around 1 hour - very quick and easy and intuitive.

- Very large choice of VMs, including families we've used before

- Support for direct Spark SQL ingestion from Google Cloud Storage bucket

- Can automatically terminate cluster after a given period or on an adhoc basis. Very powerful. Of course, it can be restarted too. BUT the underlying compute remains on, running and chargable !!!

- Looks like Google data source ingestion goes via a crew called Fivetran. No use.

Create Azure Storage Account
----------------------------

- In resource group azuron-databricks
- With "Enable hierarchical namespace"
- Create container "data"
- Called "azurondatabricks"

Use MSI to Control Access from Databricks to Your Storage Account
-----------------------------------------------------------------

https://learn.microsoft.com/en-us/azure/databricks/data-governance/unity-catalog/azure-managed-identities

- Create Managed Identity, "azuron-databricks"
- Storage account "azurondatabricks", assign role: Storage Blob Data Contributor
- Storage account "azurondatabricks", assign role: Storage Queue Data Contributor
- Resource group, assign role: EventGrid EventSubscription Contributor

Azure Portal --> Access Connector For Azure Databricks --> Use the MSI from above.

Grab: /subscriptions/60e1436b-d08b-466d-b42a-98011fed3eb2/resourceGroups/azuron-databricks/providers/Microsoft.Databricks/accessConnectors/azuron-databricks

Catalog --> Credential --> Create

Credential name: azuron-databricks
Access connector ID: /subscriptions/60e1436b-d08b-466d-b42a-98011fed3eb2/resourceGroups/azuron-databricks/providers/Microsoft.Databricks/accessConnectors/azuron-databricks
User assigned managed identity ID (optional): /subscriptions/60e1436b-d08b-466d-b42a-98011fed3eb2/resourcegroups/azuron-databricks/providers/Microsoft.ManagedIdentity/userAssignedIdentities/azuron-databricks

Catalog --> External Location --> Create

External location name: azuron-databricks
URL: abfss://data@azurondatabricks.dfs.core.windows.net/
Storage credential: (from drop down) azuron-databricks

Cluster - Processing Data Directly From Azure Data Lake Storage Gen2
--------------------------------------------------------------------

- Create single node cluster on Standard_DS13_V2 (8 Cores 56GB RAM) - 1 OFF

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

- Switch cluster size by Compute --> Edit --> [choose compute]

- Create single node cluster on Standard_DS14_V2 (16 Cores 112GB RAM) - 1 OFF  (needs StandardDV2Family quota increase 0 to 16 - 16 x 1)

Need to up quota limit to 16 to use this.

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


Looks like it's very responsive to more CPU/memory


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