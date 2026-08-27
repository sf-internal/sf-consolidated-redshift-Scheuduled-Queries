Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: 
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: At 06:00

Query statement: 

vacuum sort only forms.visits to 100 percent;
analyze forms.visits;