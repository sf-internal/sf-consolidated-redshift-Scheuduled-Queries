Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: aggregate-ping-listings
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: Every 30 minutes, only on Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday

Query statement:

CALL dba_monitoring.sp_run_ping_listings_step(10,1);
CALL dba_monitoring.sp_run_ping_listings_step(10,2);
CALL dba_monitoring.sp_run_ping_listings_step(10,3);
CALL dba_monitoring.sp_run_ping_listings_step(10,4);