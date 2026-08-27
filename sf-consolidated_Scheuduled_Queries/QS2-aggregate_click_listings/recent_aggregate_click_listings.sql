CREATE OR REPLACE PROCEDURE pingpost.recent_aggregate_click_listings()
 LANGUAGE plpgsql
AS $$
BEGIN

    CREATE TEMP TABLE staging_aggr_click_listings AS

    WITH listing_date_range AS (SELECT
            DATEADD(day, -1, MIN(created_at)) AS min_created_at,
            DATEADD(day,  1, MAX(created_at)) AS max_created_at
        FROM pingpost.click_ping_response_listings
        WHERE updated_at >= DATEADD(minute, -60, GETDATE())
    )
    SELECT DISTINCT cprl.id,cprl.click_ping_id,cprl.click_ping_response_id,
  cprl.aid,cprl.cid,cprl.sid,cprl.partner_id,cprl.response_partner_id AS network_id,pa.name AS network_name,cprl.lead_type_id,lt.name AS lead_type,
cpd.source_type_id,st.name AS source_type,cp.user_group_id AS marketing_group_id,
ug.name AS marketing_group,cpd.zip,cpd.city,cpd.state,cpd.device_type,
cpd.currently_insured,cpd.continuous_coverage,cpd.own_home,cpd.num_drivers,
cpd.num_vehicles,cpd.age,cpd.gender,cpd.marital_status,cpd.education,
cpd.credit_rating,cpd.military_affiliation,cpd.moving_violations AS violations,
cpd.dui,cpd.at_fault_accidents AS accidents,cpd.tobacco,    cpd.major_health_conditions,cpd.life_coverage_type,cpd.life_coverage_amount,
cpd.property_type,cpd.property_age,cpd.years_in_business,     cpd.commercial_coverage_type,cpd.household_income,cpd.ip_address,      cpd.user_agent,cpd.session_id,cpd.jornaya_lead_id,cpd.trusted_form_token,
cprl.title,cprl.description,cprl.click_url,cprl.tracking_url,cprl.logo_url,
 cprl.site_host,cprl.company_name,cprl.display_name,cprl.payout,
cprl.est_payout,cprl.position,cprl.selected,cprl.viewed,cprl.clicked,
cprl.de_duped,cprl.excluded,cprl.retail,CAST(EXTRACT('hour' FROM CONVERT_TIMEZONE(
 'UTC','America/Los_Angeles',cprl.created_at)) AS INTEGER) AS pst_hour,        CAST(DATE(DATE_TRUNC('day',CONVERT_TIMEZONE('UTC','America/Los_Angeles',
cprl.created_at))) AS DATE) AS pst_day,CAST(DATE(DATE_TRUNC('week',         CONVERT_TIMEZONE('UTC','America/Los_Angeles',cprl.created_at))) AS DATE) AS pst_week,CAST(DATE(DATE_TRUNC('month',CONVERT_TIMEZONE('UTC',             'America/Los_Angeles',cprl.created_at))) AS DATE) AS pst_month,
CAST(DATE(DATE_TRUNC('quarter',CONVERT_TIMEZONE('UTC',          'America/Los_Angeles',cprl.created_at))) AS DATE) AS pst_quarter,
CAST(DATE(DATE_TRUNC('year',CONVERT_TIMEZONE('UTC',               'America/Los_Angeles',cprl.created_at))) AS DATE) AS pst_year,
CASE WHEN cprl.partner_id IN (12362) THEN 'Syndi-click'
WHEN cprl.aid IN ('3511') THEN 'Unity'
WHEN cprl.partner_id IN (12064) THEN 'Pop-under'
 ELSE 'Thank-you Page'
END AS listing_type,cprle.account_id,cprle.campaign_id,cprl.created_at,
cprl.updated_at
 FROM pingpost.click_ping_response_listings cprl
 LEFT JOIN pingpost.click_ping_details cpd
ON cpd.click_ping_id = cprl.click_ping_id
LEFT JOIN pingpost.click_pings cp
ON cp.id = cprl.click_ping_id
LEFT JOIN pingpost.partners pa
 ON cprl.response_partner_id = pa.id
 LEFT JOIN pingpost.lead_types lt
ON lt.id = cprl.lead_type_id
LEFT JOIN affiliate_portal.source_types st
 ON st.id = cpd.source_type_id
LEFT JOIN affiliate_portal.user_groups ug
ON ug.id = cp.user_group_id
LEFT JOIN pingpost.click_ping_response_listing_events cprle
ON cprle.click_ping_response_listing_id = cprl.id
AND cprle.created_at >= (SELECT min_created_at FROM listing_date_range)
 AND cprle.created_at <= (SELECT max_created_at FROM listing_date_range)
WHERE cprl.updated_at >= DATEADD(minute, -60, GETDATE());

DELETE FROM pingpost.aggr_click_listings USING staging_aggr_click_listings s
WHERE pingpost.aggr_click_listings.id = s.id;

INSERT INTO pingpost.aggr_click_listings (id,click_ping_id,     click_ping_response_id,aid,cid,sid,partner_id,network_id,network_name,
lead_type_id,lead_type,source_type_id,source_type,marketing_group_id,
marketing_group,zip,city,state,device_type,currently_insured,      continuous_coverage,own_home,num_drivers,num_vehicles,age,gender,
marital_status,education,credit_rating,military_affiliation,violations,
dui,accidents,tobacco,major_health_conditions,life_coverage_type,
life_coverage_amount,property_type,property_age,years_in_business,
commercial_coverage_type,household_income,ip_address,user_agent,session_id,
jornaya_lead_id,trusted_form_token,title,description,click_url,tracking_url,
logo_url,site_host,company_name,display_name,payout,est_payout,position,
selected,viewed,clicked,de_duped,excluded,retail,pst_hour,pst_day,pst_week,
pst_month,pst_quarter,pst_year,listing_type,account_id,campaign_id,created_at,
updated_at)
 SELECT id,click_ping_id,click_ping_response_id,aid,cid,sid,partner_id,
network_id,network_name,lead_type_id,lead_type,source_type_id,source_type,
marketing_group_id,marketing_group,zip,city,state,device_type,     currently_insured,continuous_coverage,own_home,num_drivers,num_vehicles,
age,gender,marital_status,education,credit_rating,military_affiliation,
violations,dui,accidents,tobacco,major_health_conditions,       life_coverage_type,life_coverage_amount,property_type,property_age,
years_in_business,commercial_coverage_type,household_income,ip_address,
user_agent,session_id,jornaya_lead_id,trusted_form_token,title,description,
click_url,tracking_url,logo_url,site_host,company_name,display_name,
payout,est_payout,position,selected,viewed,clicked,de_duped,excluded,retail,
pst_hour,pst_day,pst_week,pst_month,pst_quarter,pst_year,listing_type,
 account_id,campaign_id,created_at,updated_at
FROM staging_aggr_click_listings;

DROP TABLE IF EXISTS staging_aggr_click_listings;

END;
$$
	
