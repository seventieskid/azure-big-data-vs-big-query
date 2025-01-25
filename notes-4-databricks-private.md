Azure Databricks on Private Networks
------------------------------------

General Observations
--------------------

- After databricks workspace deletion/recreation, tables in a custom catalog appear to be lost, despite the underlying storage not being removed when the original DB workspace was deleted - weird. Only recovery is to remove the underlying storage and load again. Not great, because that means the Databricks workspace can never be deleted.

Follow this - https://learn.microsoft.com/en-us/azure/databricks/security/network/classic/private-link-standard

DELETE ORDER

- databricks workspace
- private endpoint
- private dns zone privatelink.azuredatabricks.net - unlink virtual network
- private dns zone privatelink.azuredatabricks.net
- network security group - disassociate 2 x subnets
- network security group

Private Networking
------------------

VNet (equiv. to a VPC) - 10.28.0.0/23

subnet - private-link - 10.28.1.0/27
subnet - public-subnet - 10.28.0.0/25
subnet - private-subnet - 10.28.0.128/25

- Leave all other options to defaults

Creating an inital private databricks workspace:-

- Deploy Azure Databricks workspace with Secure Cluster Connectivity (No Public IP)
- Deploy Azure Databricks workspace in your own Virtual Network (VNet)

- Use the ip ranges above

- Allow Public Network Access

- Required NSG Rules - No Azure Databricks Rules

- Network security group is automatically created with access to storage and eventhub services, plus SQL ports

- The NSG IS NOT automatically DELETED when the workspace is removed. Must unassign from private/public subnets first, before deleting it.

- Include private endpoint creation too. It isn't automatically DELETED when the workspace is removed.

This consumes the following number of ips:-

private-link x 4
public-subnet x 3
private-subnet x 3

IP range: First remove the default IP range, and then add IP range 10.28.0.0/23.
Create subnet public-subnet with range 10.28.0.0/25.
Create subnet private-subnet with range 10.28.0.128/25.
Create subnet private-link with range 10.28.1.0/27.

Looks like applying the ARM template is creating these additional things as a the databricks workspace is being created:-

- Creating 3 x subnets
- Creating and applying NSG to subnets
- Creates a private endpoint
- DNS private zone privatelink.azuredatabricks.net, with an A record from the Databricks workspace unique hostname (e.g. adb-4273513135918642.2) to the private IP of the private endpoint (e.g. 10.28.1.4). As with AWS, it allows a public address to be resolved privately over the MS backbone, not public internet.

(All information gleened from observing the ARM template deployment, which is really nice on Azure)

Re-usable ARM templates don't work because of embedded IDs for things that are created by the nested templates.

So, until it's terraformed, just click and point manually in the Azure portal.

Test the private connections by creating a cluster
--------------------------------------------------

- Single node, single user
- Runtime: 15.4 LTS (Scala 2.12, Spark 3.5.0)
- Standard_DS14_V2 (16 Cores 112GB RAM) - 2 OFF  - 8 DBU/h  (quota needs upping)
- A VM is created on your Azure subscription
- Photon ON

Observe where the VMs are created and the IP addresses assigned.

One VM in the public subnet only. Unclear why it needed 2 OFF for a single node solution. There's only one VM.

Create a Custom Catalog When Private
-------------------------------------

- Create Databricks Access Connector (in Azure Portal)

<---- /subscriptions/60e1436b-d08b-466d-b42a-98011fed3eb2/resourceGroups/azuron-databricks/providers/Microsoft.Databricks/accessConnectors/azuron

- Create credential (In databricks ui)

Catalog --> External Data --> Credentials

Name: azuron-databricks

--> /subscriptions/60e1436b-d08b-466d-b42a-98011fed3eb2/resourceGroups/azuron-databricks/providers/Microsoft.Databricks/accessConnectors/azuron

--> /subscriptions/60e1436b-d08b-466d-b42a-98011fed3eb2/resourcegroups/azuron-databricks/providers/Microsoft.ManagedIdentity/userAssignedIdentities/azuron-databricks

- Create external location

Add container to storage in Azure portal: abfss://catalog@azuron.dfs.core.windows.net/

Catalog --> External Data --> Create external location

External location name: catalog-azuron
URL: abfss://catalog@azuron.dfs.core.windows.net/
Storage credential: azuron-databricks

Catalog --> + --> Add Catalog --> azuron_custom

Create Schema
-------------

Catalog --> azuron_custom --> Create schema button --> new_york

Create a Pro SQL Warehouse (can't use Severless)
------------------------------------------------

Firstly, delete default Serverless SQL warehouse

- Size Small (12 DBU/h)
- Uses standardEDSv4Family, 32 CPUs, must increase quota, default is 10 only
- Scaling 1 - 1

Seems to automatically create VMs:-

Standard_E16ds_v4 1 OFF ( 16 x 1 = 16 vCPUs)
Standard_E8ds_v4  4 OFF ( 8 x 4 = 32 vCPUs)

This took ~ 5 mins to create

Load Data in SQL Data Warehouse - With Auto Loader and Delta Live Tables
------------------------------------------------------------------------

- Nice SQL user interface with great performance statistics

See https://learn.microsoft.com/en-us/azure/databricks/tables/streaming

- SQL Editor LIST 'abfss://users@azuron.dfs.core.windows.net/nyc-taxis-2016/'

- Load data run databricks/private/sql_warehouse/load_streaming_tables.sql in SQL editor

Table created in 4 mins 22 secs

Test 1:
--------

Query Type: SQL Editor UI databricks/private/sql_warehouse/nyc_taxi_data_complete.sql
Data Catalog: Unity
Table Type: Delta
Queried Through: SQL Warehouse
SQL Warehouse: Pro Small

Returned count - 69295945

Speeds read of ui...

>>>> first 246644ms

2024ms
1055ms
1011ms
947ms
998ms
1067ms

Av. 1184ms

Lots pro data warehouses sizing options - lots (4 DBU/h - 528 DBu/h)

It turns off, and drains compute (and cost) after a pre-defined period - 45 mins default.

Test 2:
--------

Query Type: Spark Python Notebook databricks/private/sql_warehouse/spark_python_query.ipynb
Data Catalog: Unity
Table Type: Delta
Queried Through: Compute Cluster
SQL Warehouse: Pro Small

>>> first 349250ms

5161ms
4098ms
4325ms
3987ms
3969ms
4137ms

av. 4280ms

Test 3:
--------

Query Type: Spark SQL Notebook databricks/private/sql_warehouse/spark_sql_query.ipynb
Data Catalog: Unity
Table Type: Delta
Queried Through: Compute Cluster
SQL Warehouse: Pro Small

>>> first 8754ms

450ms
439ms
404ms
389ms
396ms
363ms

av. 406ms   << the absolute fastest of all big data tech and variations