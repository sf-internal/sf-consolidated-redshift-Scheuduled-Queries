Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: Aggregate call logs
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: Every 15 minutes, only on Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday

Query statement: CALL call_tracking.recent_aggregate_call_logs();
