- Redshift serverless
- Private VPC /16 with 3 x availability zones, take all default options
- Zero public subnets
- Upload 132 files to S3 for nyc yellow taxi data

- Time to create serverless workgroup/namespace @ 64 RPUs - 40 secs

- Rely on an automated secret being created in Secrets Manager, that will be used by Glue too.

- Nice seamless integration in the AWS UI

- Need these VPC endpoints for AWS Glue / Redshift

com.amazonaws.eu-west-1.secretsmanager
com.amazonaws.eu-west-1.sts
com.amazonaws.eu-west-1.redshift
com.amazonaws.eu-west-1.s3 (automatic on vpc creation)
com.amazonaws.vpce.eu-west-1.vpce-svc-01d147228e6470aae (automatic on vpc creation)

- IAM setup policies and trusts

Create as per aws-redshift-serverless/roles

- AWS Glue - very tricky to get a Redshift connection created

* Needed VPCe
* Needed IAMs

Because Redshift was set to route it's traffic inside the VPC

Observations
------------
- Redshift is just a SQL warehouse it brings nothing else.
- Redshift has it's own SQL dialect, close to BQ, minimal changes on sample query, but changes nonetheless.
- Redshift has capability to run Redshift SQL queries, and will have an API to do so too.
- Good scaling optinos on Redshift. We went with HALF the default (128RPU), so 64RPU. Can go to 1024RPU.
- Spark SQL can only be run with a partnered AWS service like Glue, EMR or Sagemaker.
- Those tools are complex and take a long time to orient to become productive.
- We focussed on AWS Glue. It can run Spark SQL or Spark Notebooks, but it's heavily wrapped in AWS Glue. None of that is hidden from us.
- Some decent scaling options on AWS Glue

Tests
-----

Query Type: Redshift SQL Editor UI 
File: aws-redshift-serverless/nyc_taxi_data_complete.sql
Redshift Size: 64 RPU

Cost: 23 USD
Load time: 14.2s
Query time: Av. 651ms
Rows returned: 69295804

3836ms
23ms
14ms
13ms
10ms
11ms

Query Type: AWS Glue 5.0
File: aws-redshift-serverless/glue/nyc-taxis-2016-spark-sql.py
Glue Worker Type: G.4X (16vCPUs, 64GB RAM)
Number of Workers: 2
Processing Units: 8 DPUs


Cost: ?? USD
Query time: Av. 7083ms

6200ms
7700ms
7100ms
6400ms
7800ms
7300ms
