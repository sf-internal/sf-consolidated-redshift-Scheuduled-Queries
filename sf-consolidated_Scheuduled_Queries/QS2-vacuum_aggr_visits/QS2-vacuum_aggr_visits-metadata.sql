Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: Vacuum sort and analyze aggr_visits
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: At 08:00

Query statement:
vacuum sort only forms.aggr_visits to 100 percent;
analyze forms.aggr_visits;
