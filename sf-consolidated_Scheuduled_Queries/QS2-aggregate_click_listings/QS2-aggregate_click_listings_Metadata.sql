Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: aggregate_click_listings
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: Every 30 minutes, only on Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday

Query Statement:
CALL pingpost.recent_aggregate_click_listings();
CALL pingpost.refresh_aggr_default_click_listings(0);
CALL pingpost.refresh_aggr_common_click_listings(0);
CALL pingpost.refresh_aggr_hourly_click_listings(0);