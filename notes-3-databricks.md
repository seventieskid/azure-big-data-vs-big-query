Azure Databricks
----------------

General Observations
--------------------
- Green tech. in the bank

- Approximately 4 mins to create Databricks workspace

- Nice UI, entirely isolated from the Azure Portal experience, but creates a ton of stuff in the background

- Tutorial - https://learn.microsoft.com/en-us/azure/databricks/ingestion/cloud-object-storage/onboard-data

- Nice imporovement hints in the UI, e.g. use disk caching to speed up queries

- Nice embedded assistant too

- Setup and run tests in around 1 hour - very quick and easy and intuitive.

- Very large choice of VMs, including families we've used before

- Support for direct Spark SQL ingestion from Google Cloud Storage bucket

- Can automatically terminate cluster after a given period or on an adhoc basis. Very powerful. Of course, it can be restarted too. BUT the underlying compute remains on, running and chargable !!!

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

??ms

Av. ??ms