CREATE OR REPLACE PROCEDURE pingpost.recent_aggregate_ping_listings()
 LANGUAGE plpgsql
AS $$
BEGIN

  -- Get the created_at range for rows updated in the last 60 minutes
  CREATE TEMP TABLE ping_listing_date_range AS
  SELECT MIN(created_at) AS min_created_at,MAX(created_at) AS max_created_at FROM pingpost.ping_listings WHERE updated_at >= DATEADD(minute, -60, GETDATE());


CREATE TEMP TABLE staging_aggr_ping_listings AS 
SELECT pl.id,pl.ping_id,pd.aid,pd.cid,p.lead_type_id,pd.source_type_id,pd.user_group_id AS marketing_group_id,pl.carrier_name,pl.account_name,pa.name AS network_name,
CASE WHEN pl.exclusive = 1 THEN 'Exclusive' ELSE 'Shared' END AS bid_type,pd.state,pd.device_type,pd.insured,pd.home_owner,pd.military_affiliation,pl.payout,pl.bid,
pl.paid_by_promo,pl.selected,pl.de_duped,pl.posted,pl.accepted,pl.consent_verified,
CAST(EXTRACT('hour' FROM CONVERT_TIMEZONE('UTC','America/Los_Angeles',pl.created_at)) AS INTEGER ) AS pst_hour,
CAST(DATE(DATE_TRUNC('day',CONVERT_TIMEZONE('UTC','America/Los_Angeles',pl.created_at))) AS DATE ) AS pst_day,
CAST(DATE(DATE_TRUNC('week',CONVERT_TIMEZONE('UTC','America/Los_Angeles',pl.created_at))) AS DATE ) AS pst_week,
CAST(DATE(DATE_TRUNC('month',CONVERT_TIMEZONE('UTC','America/Los_Angeles',pl.created_at))) AS DATE ) AS pst_month,
CAST(DATE(DATE_TRUNC('quarter',CONVERT_TIMEZONE('UTC','America/Los_Angeles',pl.created_at))) AS DATE ) AS pst_quarter,
CAST(DATE(DATE_TRUNC('year',CONVERT_TIMEZONE('UTC','America/Los_Angeles',pl.created_at))) AS DATE) AS pst_year,
pl.created_at,pl.updated_at
FROM pingpost.ping_listings pl
CROSS JOIN ping_listing_date_range dr
LEFT JOIN pingpost.pings p ON p.id = pl.ping_id
LEFT JOIN pingpost.ping_details pd ON pd.ping_id = pl.ping_id
LEFT JOIN pingpost.partners pa ON pa.id = pl.partner_id
WHERE pl.updated_at >= DATEADD(minute, -60, GETDATE()) AND pl.created_at >= dr.min_created_at AND pl.created_at <= dr.max_created_at;


DELETE FROM pingpost.aggr_ping_listings USING staging_aggr_ping_listings s WHERE pingpost.aggr_ping_listings.id = s.id;

INSERT INTO pingpost.aggr_ping_listings (id,ping_id,aid,cid,lead_type_id,source_type_id,marketing_group_id,carrier_name,account_name,network_name,bid_type,state,
device_type,insured,home_owner,military_affiliation,payout,bid,paid_by_promo,selected,de_duped,posted,accepted,consent_verified, pst_hour,pst_day,pst_week,pst_month,
pst_quarter,pst_year,created_at,updated_at)
SELECT id,ping_id,aid,cid,lead_type_id,source_type_id, marketing_group_id,carrier_name,account_name,network_name,bid_type,state,device_type,insured,home_owner,military_affiliation,
payout, bid,paid_by_promo,selected,de_duped,posted,accepted,consent_verified,pst_hour,pst_day,pst_week,pst_month,pst_quarter,pst_year,created_at,updated_at FROM staging_aggr_ping_listings;


DROP TABLE IF EXISTS staging_aggr_ping_listings;
DROP TABLE IF EXISTS ping_listing_date_range;

END;
$$
	
