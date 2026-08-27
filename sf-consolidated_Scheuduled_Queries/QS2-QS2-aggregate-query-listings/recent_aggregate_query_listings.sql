CREATE OR REPLACE PROCEDURE call_tracking.recent_aggregate_query_listings()
 LANGUAGE plpgsql
AS $$
DECLARE
    min_created_at TIMESTAMP;
    max_created_at TIMESTAMP;
BEGIN
    SELECT DATEADD(day, -1, MIN(created_at)),DATEADD(day,  1, MAX(created_at))
    INTO min_created_at,max_created_at
    FROM call_tracking.customer_query_listings
    WHERE updated_at >= DATEADD(minute, -60, GETDATE());

CREATE TEMP TABLE staging_aggr_query_listings AS
SELECT l.id,l.customer_query_id,d.aid,d.cid,d.quote_calls_lead_type_id,
d.source_type_id,d.marketing_group_id,l.account_name,l.service_provider,
l.network,d.state,d.insured,d.home_owner,d.military_affiliation,
d.bundle,d.accidents,d.dui,d.home_claims,d.medical_conditions,
d.dental,d.medicaid,d.requested_coverage,d.property_type,
d.household_income,d.continuous_insurance,d.num_vehicles,l.price,
CAST(l.position AS NUMERIC(8,2)) AS position,l.dupe_diff,
 l.displayed,l.transferred,l.billable,l.de_duped,l.excluded,
CAST(EXTRACT('hour' FROM CONVERT_TIMEZONE('UTC',               'America/Los_Angeles',l.created_at)) AS INTEGER) AS pst_hour,
CAST(DATE(DATE_TRUNC('day',CONVERT_TIMEZONE('UTC',                     'America/Los_Angeles',l.created_at))) AS DATE) AS pst_day,
CAST( DATE(DATE_TRUNC('week',CONVERT_TIMEZONE('UTC',                        'America/Los_Angeles',l.created_at))) AS DATE) AS pst_week,
CAST(DATE(DATE_TRUNC('month',CONVERT_TIMEZONE('UTC',                        'America/Los_Angeles',l.created_at))) AS DATE) AS pst_month,
CAST(DATE(DATE_TRUNC('quarter',CONVERT_TIMEZONE('UTC',                        'America/Los_Angeles',l.created_at))) AS DATE) AS pst_quarter,
CAST(DATE(DATE_TRUNC('year',CONVERT_TIMEZONE('UTC',                        'America/Los_Angeles',l.created_at))) AS DATE) AS pst_year,
 l.created_at,l.updated_at
FROM call_tracking.customer_query_listings l
LEFT JOIN call_tracking.customer_query_details d
ON d.customer_query_id = l.customer_query_id
AND d.created_at >= min_created_at
AND d.created_at <= max_created_at
WHERE l.updated_at >= DATEADD(minute, -60, GETDATE());


DELETE FROM call_tracking.aggr_query_listings USING staging_aggr_query_listings s
WHERE call_tracking.aggr_query_listings.id = s.id;

INSERT INTO call_tracking.aggr_query_listings (id,customer_query_id,
aid,cid,quote_calls_lead_type_id,source_type_id,marketing_group_id,
account_name,service_provider,network,state,insured,home_owner,
military_affiliation,bundle,accidents,dui,home_claims,medical_conditions,
dental,medicaid,requested_coverage,property_type,household_income,
continuous_insurance,num_vehicles,price,position,dupe_diff,displayed,
transferred,billable,de_duped,excluded,pst_hour,pst_day,pst_week,
pst_month,pst_quarter,pst_year,created_at,updated_at)

SELECT id,customer_query_id,aid,cid,quote_calls_lead_type_id,source_type_id,
marketing_group_id,account_name,service_provider,network,state,insured,
home_owner,military_affiliation,bundle,accidents,dui,home_claims,
medical_conditions,dental,medicaid,requested_coverage,property_type,
household_income,continuous_insurance,num_vehicles,price,position,
dupe_diff,displayed,transferred,billable,de_duped,excluded,pst_hour,
pst_day,pst_week,pst_month,pst_quarter,pst_year,created_at,
updated_at FROM staging_aggr_query_listings;

DROP TABLE IF EXISTS staging_aggr_query_listings;

END;
$$
	
