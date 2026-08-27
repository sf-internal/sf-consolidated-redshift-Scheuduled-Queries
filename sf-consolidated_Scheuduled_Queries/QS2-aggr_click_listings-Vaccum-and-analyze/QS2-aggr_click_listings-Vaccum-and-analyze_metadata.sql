Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: aggr_click_listings-Vaccum-and-analyze
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: At 12:00, only on Saturday

Query statement:

vacuum sort only pingpost.aggr_click_listings;
ANALYZE pingpost.aggr_click_listings;
