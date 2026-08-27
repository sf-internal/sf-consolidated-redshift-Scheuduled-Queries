Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: aggregate-query-listings
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: Every 30 minutes, only on Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday

Query statement:

CALL call_tracking.recent_aggregate_query_listings();
CALL call_tracking.refresh_aggr_default_query_listings(0);
CALL call_tracking.refresh_aggr_common_query_listings(0);
CALL call_tracking.refresh_aggr_hourly_query_listings(0);

