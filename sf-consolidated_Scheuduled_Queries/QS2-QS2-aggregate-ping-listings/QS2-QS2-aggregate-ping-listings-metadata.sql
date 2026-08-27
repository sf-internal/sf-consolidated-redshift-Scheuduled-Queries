Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: aggregate-ping-listings
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: Every 30 minutes, only on Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday

Query statement:

call pingpost.recent_aggregate_ping_listings();
CALL pingpost.refresh_aggr_default_ping_listings(0);
CALL pingpost.refresh_aggr_common_ping_listings(0);
CALL pingpost.refresh_aggr_hourly_ping_listings(0);