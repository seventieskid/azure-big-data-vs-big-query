import os
import time
from databricks.connect import DatabricksSession         # pip3 install --upgrade "databricks-connect==15.4.*"

os.environ["DATABRICKS_HOST"]          = "https://adb-1341475029794072.12.azuredatabricks.net/"
os.environ["DATABRICKS_CLIENT_ID"]     = "XXX"
os.environ["DATABRICKS_CLIENT_SECRET"] = "YYY"
os.environ["DATABRICKS_CLUSTER_ID"]    = "0602-192457-n4t86tqv"

# Use the AAD token to authenticate with DatabricksSession
spark = DatabricksSession.builder.getOrCreate()

df = spark.sql("""
    SELECT
    *
    FROM
    system.information_schema.catalogs
    WHERE
    catalog_name = 'azuron_1341475029794072'
""")

# Record start time
start_time = time.time()

df.show()

# Record end time
end_time = time.time()

# Calculate the elapsed time
elapsed_time = end_time - start_time
print(f"Execution time: {elapsed_time:.4f} seconds")