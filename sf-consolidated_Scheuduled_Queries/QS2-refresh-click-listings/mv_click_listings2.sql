Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: Refresh click_listings MV
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: Every 30 minutes, only on Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday

Query Statement: REFRESH MATERIALIZED VIEW pingpost.click_listings2;