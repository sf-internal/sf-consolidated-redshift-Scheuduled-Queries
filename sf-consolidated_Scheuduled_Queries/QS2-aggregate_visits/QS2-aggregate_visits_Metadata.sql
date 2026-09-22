Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: aggregate forms visits
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: Every 30 minutes, only on Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday

Query statement: 
CALL forms.recent_aggregate_visits();
CALL forms.aggregate_visits(0);
CALL forms.refresh_pub_aggr_stats(0);
CALL forms.refresh_pub_aggr_state_stats(0);
CALL forms.refresh_graph_aggr_stats(0);
CALL forms.refresh_graph_aggr_state_stats(0);

delete forms.pub_aggr_stats where pst_day >= GETDATE() - 30 and aid not in (select id::varchar from affiliate_portal.users) OR aid is null;
delete forms.pub_aggr_state_stats where pst_day >= GETDATE() - 30 and aid not in (select id::varchar from affiliate_portal.users) OR aid is null;
delete forms.graph_aggr_stats where pst_day >= GETDATE() - 30 and aid not in (select id::varchar from affiliate_portal.users) OR aid is null;
delete forms.graph_aggr_state_stats where pst_day >= GETDATE() - 30 and aid not in (select id::varchar from affiliate_portal.users) OR aid is null;