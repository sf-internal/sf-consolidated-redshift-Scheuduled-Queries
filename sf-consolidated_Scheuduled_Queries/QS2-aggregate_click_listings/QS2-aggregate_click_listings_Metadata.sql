Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: aggregate_click_listings
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: Every 30 minutes, only on Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday

Query Statement:
CALL dba_monitoring.sp_run_listings_step(6, 1);
CALL dba_monitoring.sp_run_listings_step(6, 2);
CALL dba_monitoring.sp_run_listings_step(6, 3);
CALL dba_monitoring.sp_run_listings_step(6, 4);