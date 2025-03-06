-- This is Redshift SQL
CREATE SCHEMA if not exists new_york;

CREATE TABLE if not exists new_york.tlc_yellow_trips_2016 (
    vendor_id integer ENCODE az64,
    pickup_datetime timestamp without time zone ENCODE az64,
    dropoff_datetime timestamp without time zone ENCODE az64,
    passenger_count integer ENCODE az64,
    trip_distance real ENCODE raw,
    pickup_longitude character varying(256) ENCODE lzo,
    pickup_latitude double precision ENCODE raw,
    rate_code integer ENCODE az64,
    store_and_fwd_flag character varying(256) ENCODE lzo,
    dropoff_longitude character varying(256) ENCODE lzo,
    dropoff_latitude double precision ENCODE raw,
    payment_type integer ENCODE az64,
    fare_amount real ENCODE raw,
    extra real ENCODE raw,
    mta_tax real ENCODE raw,
    tip_amount real ENCODE raw,
    tolls_amount real ENCODE raw,
    imp_surcharge real ENCODE raw,
    total_amount real ENCODE raw
) DISTSTYLE AUTO;

COPY dev.new_york.tlc_yellow_trips_2016
FROM 's3://aws-azuron/'
IAM_ROLE 'arn:aws:iam::413874846216:role/service-role/AmazonRedshift-CommandsAccessRole-20250305T152433'
FORMAT AS CSV DELIMITER ',' QUOTE '"' IGNOREHEADER 1 REGION AS 'eu-west-1';