Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: QS2-aggregate-lead-campaign-sub-sources
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: Every 30 minutes, only on Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday

Query statement: CALL dba_monitoring.sp_run_source_stats_step(11,1);
