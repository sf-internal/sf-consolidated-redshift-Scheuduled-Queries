Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: Aggregate call logs
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: Every 15 minutes, only on Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday

Query statement: CALL dba_monitoring.sp_run_calls_step(7, 1);
