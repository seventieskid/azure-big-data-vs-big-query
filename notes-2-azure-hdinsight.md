HD Insights Interactive Query (aka Apache Hive LLAP - Low Latency Analytics Processing)
---------------------------------------------------------------------------------------

General observations...

- Very little integration with Azure. It feels totally like a complex OSS stack running on top of something (Azure)

- Feels clunky. Took 49 mins to complete the deployment process successfully using the ARM template.

- Only a few minutes to delete. Which makes me think it's not really deleting what it created fully. Check costs tomorrow :)

- Creates a complex file system in Azure gen2 storage, even before the data gets loaded.

- Took a whole working day just to get a cluster created !!

Setup storage acccount

  - See https://learn.microsoft.com/en-us/azure/hdinsight/hdinsight-hadoop-use-data-lake-storage-gen2-portal
  - Call it say "azuronhdinsight"
  - Under Advanced tab - Enabled next to Hierarchical namespace under Data Lake Storage Gen2.
  - Create user managed identity
  - Assign "Storage Blob Data Owner" scoped to "azuronhdinsight"

Cluster type: Interactive Query

A LOT of configuration options, which amounts to a complex infra solution

Node automatic recommendations (7.84USD per hour):

Head node: D13 v2 (8 Cores 56 GB RAM) - 2 OFF     (needs StandardDV2Family quota increase 0 to 16 - 8 x 2)
Zookeeper node: A2 v2 (2 Cores 4GB RAM) - 3 OFF   (needs StandardAV2Family quota increase 0 to 6 - 2 x 3)
Worker node: D14 v2 (16 Cores 112GB RAM) - 4 OFF  (needs StandardDV2Family quota increase 0 to 64 - 16 x 4)

In the end (because of a delay on the A2 quota approval) went with (3.43USD per hour):

Head node: D13 v2 (8 Cores 56 GB RAM) - 2 OFF     (needs StandardDV2Family quota increase 0 to 16 - 8 x 2)
Zookeeper node: D2 v2 (2 Cores 7GB RAM) - 3 OFF   (needs StandardDV2Family quota increase 0 to 6 - 2 x 3)
Worker node: D14 v2 (16 Cores 112GB RAM) - 1 OFF  (needs StandardDV2Family quota increase 0 to 16 - 16 x 1)

StandardDV2Family quota increase to 0 to 38

This is gonna cost a lot and there's no abilty to PAUSE when it's not in use; billing is per minute, until the cluster is deleted.

https://azuron.azurehdinsight.net

Follow this tutorial, but for taxi data instead:-

https://learn.microsoft.com/en-us/azure/hdinsight/interactive-query/interactive-query-tutorial-analyze-flight-data

Gave up with this variation because it was too complex to figure out how to load and query the data.

Light on www resources to follow.

HD Insights Spark
-----------------

General Obserations
-------------------
- Cost incurred unless cluster is DELETED. No option for pausing.

- Can tune Head/Zookeeper/worker in a way you can't with ASA Spark pool - PLUS

- Cannot scale without destroying and recreating the cluster - BAD

- Slightly more spark admin than ASA Spark (session setup etc)

- Nice ability to observe Spark cluster through charts (not possible on ASA)

- Tear down cluster, but use same storage account to re-create new cluster gives access to all existing notebooks and data.

Setup storage acccount

  - See https://learn.microsoft.com/en-us/azure/hdinsight/hdinsight-hadoop-use-data-lake-storage-gen2-portal
  - Call it say "azuronhdinsight"
  - Under Advanced tab - Enabled next to Hierarchical namespace under Data Lake Storage Gen2.
  - Create user managed identity
  - Assign "Storage Blob Data Owner" scoped to "azuronhdinsight"

Cluster type: Spark

Head node: E8 v3 (8 Cores 64 GB RAM) - 2 OFF     (needs StandardEV3Family quota increase 0 to 16 - 8 x 2)
Zookeeper node: A2 v2 (2 Cores 4GB RAM) - 3 OFF   (needs StandardAV2Family quota increase 0 to 6 - 2 x 3)
Worker node: E8 v3 (8 Cores 64 GB RAM) - 4 OFF  (needs StandardEV3Family quota increase 0 to 32 - 8 x 4)

In the end (because of a delay on the A2 quota approval) went with (2.99USD per hour):

Head node: D13 v2 (8 Cores 56 GB RAM) - 2 OFF     (needs StandardDV2Family quota increase 0 to 16 - 8 x 2)
Zookeeper node: D2 v2 (2 Cores 7GB RAM) - 3 OFF   (needs StandardDV2Family quota increase 0 to 6 - 2 x 3)
Worker node: D14 v2 (16 Cores 112GB RAM) - 1 OFF  (needs StandardDV2Family quota increase 0 to 16 - 16 x 1)

Time to create was 21 mins
Time to destroy was 2 mins

https://azuron.azurehdinsight.net/jupyter (or from Azure HDI landing page)

Run this tutorial --> https://docs.azure.cn/en-us/hdinsight/spark/apache-spark-load-data-run-query

- 30 secs to start the spark session

Load and table creation time (one off), assuming data is already on Azure Storage Data Lake Gen 2:-

275000ms (which is worse than ASA spark pool with less cores and RAM)

Delivers into abfss://azuron-2025-01-06t18-30-54-196z@azuronhdinsight.dfs.core.windows.net/apps/spark/warehouse/new_york.db/tlc_yellow_trips_2016

Row count returned is 69295971

3 x test runs
111010ms
111902ms
112585ms

Av: 111,832ms