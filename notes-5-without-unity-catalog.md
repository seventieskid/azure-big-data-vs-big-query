https://adb-1632221817634632.12.azuredatabricks.net/config

Direct access to GCS from Azure: https://learn.microsoft.com/en-us/azure/databricks/connect/storage/gcs

Python Databricks API docs - https://databricks-sdk-py.readthedocs.io/en/latest/account/provisioning/workspaces.html

pip3 install databricks-sdk

Everything everywhere on ADFSS and WASDB:-

spark.hadoop.fs.azure.account.auth.type OAuth
spark.hadoop.fs.azure.account.oauth.provider.type org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider
spark.hadoop.fs.azure.account.oauth2.client.id 22d7dbcd-blee
spark.hadoop.fs.azure.account.oauth2.client.secret {{secrets/kv-azuron-with-policies/databricks-all-storage}}
spark.hadoop.fs.azure.account.oauth2.client.endpoint https://login.microsoftonline.com/576d634f-7729-4278-9174-4ed588ee532a/oauth2/token

or in python:

service_credential = dbutils.secrets.get(scope="kv-azuron-with-policies",key="atabricks-all-storage")

Test It In SQL Editor on ADB
----------------------------

LIST 'abfss://users@azuron.dfs.core.windows.net/nyc-taxis-2016'