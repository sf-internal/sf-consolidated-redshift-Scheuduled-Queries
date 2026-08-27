Cluster or workgroup: sf-consolidated
Database name: smartfinancial
Query description: vacuum click_ping_response_listings
SNS topic: -
State: ACTIVATED
IAM role: dms-access-for-endpoint 
Authentication: temporary credentials password for DB User
Frequency: At 07:00

Query statement:

vacuum sort only pingpost.click_ping_response_listings to 100 percent;
analyze pingpost.click_ping_response_listings;
