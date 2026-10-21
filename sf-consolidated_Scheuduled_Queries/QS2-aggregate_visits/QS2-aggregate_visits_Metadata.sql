Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: aggregate forms visits
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: Every 30 minutes, only on Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday

Query statement: 
CALL dba_monitoring.sp_run_visits_step(5, 1);
CALL dba_monitoring.sp_run_visits_step(5, 2);
CALL dba_monitoring.sp_run_visits_step(5, 3);
CALL dba_monitoring.sp_run_visits_step(5, 4);
CALL dba_monitoring.sp_run_visits_step(5, 5);
CALL dba_monitoring.sp_run_visits_step(5, 6);
CALL dba_monitoring.sp_run_visits_step(5, 7);