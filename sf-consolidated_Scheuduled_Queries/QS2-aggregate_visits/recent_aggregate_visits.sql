CREATE OR REPLACE PROCEDURE forms.recent_aggregate_visits()
 LANGUAGE plpgsql
AS $$
BEGIN
  CREATE TEMP TABLE staging_aggr_visits AS
  select distinct
    v.*,
    vd.consumer_dob, vd.consumer_age, vd.time_on_form, vd.insured, vd.continuous_insurance, vd.home_owner, vd.gender, vd.marital_status, vd.education, vd.credit_rating, vd.military_affiliation, vd.col1 as marketing_group_id,
    vad.num_drivers, vad.num_vehicles, vad.violations, vad.accidents, vad.dui, vad.license_status,
    concat(concat(u.first_name, ' '), u.last_name) as pub_name, u.company as pub_company, u.budget, u.budget_pacing,
    concat(concat(um.first_name, ' '), um.last_name) as manager,
    c.syndi_click, c.rev_share,
    st.name as source_type,
    ug.name as marketing_group_name,
    bl.anura, bl.bad_dispo, bl.call_disposition, bl.desc as bad_lead_desc,
    cc.accepted as cc_accepted, cc.connected as cc_connected, cc.rev as cc_rev, cc.call_duration as cc_call_duration, cc.inbound as cc_inbound, cc.rep_connected,
    cast(extract('hour' from CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', v.created_at)) as integer) as pst_hour,
    cast(date(DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', v.created_at))) as date) as pst_day,
    cast(date(DATE_TRUNC('week', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', v.created_at))) as date) as pst_week,
    cast(date(DATE_TRUNC('month', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', v.created_at))) as date) as pst_month,
    cast(date(DATE_TRUNC('quarter', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', v.created_at))) as date) as pst_quarter,
    cast(date(DATE_TRUNC('year', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', v.created_at))) as date) as pst_year,
    cast(extract('DOW' from CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', v.created_at)) as integer) as pst_weekday,
    cast(extract('hour' from CONVERT_TIMEZONE('UTC', 'America/New_York', v.created_at)) as integer) as est_hour,
    cast(date(DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/New_York', v.created_at))) as date) as est_day,
    cast(date(DATE_TRUNC('week', CONVERT_TIMEZONE('UTC', 'America/New_York', v.created_at))) as date) as est_week,
    cast(date(DATE_TRUNC('month', CONVERT_TIMEZONE('UTC', 'America/New_York', v.created_at))) as date) as est_month,
    cast(date(DATE_TRUNC('quarter', CONVERT_TIMEZONE('UTC', 'America/New_York', v.created_at))) as date) as est_quarter,
    cast(date(DATE_TRUNC('year', CONVERT_TIMEZONE('UTC', 'America/New_York', v.created_at))) as date) as est_year,
    cast(extract('DOW' from CONVERT_TIMEZONE('UTC', 'America/New_York', v.created_at)) as integer) as est_weekday,
    general_liability || commercial_auto || commercial_property || professional_liability
            || directors_officers_liability || business_owners_package || workers_comp || commercial_crime || cyber_insurance as commercial_type,
    cir.naics_code
  from forms.visits v
  left join forms.visit_details vd on v.id = vd.visit_id
  left join forms.visit_auto_details vad on v.id = vad.visit_id
  left join affiliate_portal.users u on v.aid = u.id
  left join affiliate_portal.users um on u.manager_id = um.id
  left join forms.campaigns c on v.cid = c.id
  left join affiliate_portal.source_types st on c.source_type_id = st.id
  left join affiliate_portal.user_groups ug on vd.col1 = ug.id
  left join forms.bad_leads bl on v.lead_id = bl.lead_id
  left join forms.click_calls cc on v.id = cc.visit_id
  left join forms.commercial_insurance_requests cir on v.lead_id = cir.lead_id
  where v.updated_at >= DATEADD(minute, -500, GETDATE()) and v.created_at >= DATEADD(month, -6, GETDATE());

  DELETE FROM forms.aggr_visits
  USING staging_aggr_visits s
  WHERE forms.aggr_visits.id = s.id;

  INSERT INTO forms.aggr_visits(
    id,ip_address,aid,cid,sid,ks,created_at,updated_at,cost,uid,referrer,lead_type_id,device_type,landing_page,click_id,gclid,full_url,started,submitted,qualified,state,zip,tid,qualified_lead,lead_revenue,total_ad_clicks,ad_click_revenue,total_quote_clicks,quote_click_revenue,total_calls,call_revenue,affiliate_cost,refunded,refunded_amount,form_version_id,bad_lead,raw_lead_id,lead_id,sub1,manager_id,duplicate,cost_adj,prefill_perc,prefill_missing_data,domain,max_call_duration,unity_revenue,home_bundle,quoted,policy,consumer_dob,consumer_age,continuous_insurance,gender,marital_status,education,credit_rating,license_status,pub_name,pub_company,budget,budget_pacing,manager,source_type,marketing_group_name,anura,call_disposition,bad_lead_desc,cc_rev,pst_day,pst_week,pst_month,pst_quarter,pst_year,pst_weekday,est_day,est_week,est_month,est_quarter,est_year,est_weekday,commercial_type,source_type_id,tof,time_on_form,insured,home_owner,military_affiliation,violations,accidents,dui,marketing_group_id,num_drivers,num_vehicles,syndi_click,rev_share,bad_dispo,cc_accepted,cc_connected,cc_inbound,rep_connected,cc_call_duration,pst_hour,est_hour,naics_code
  )
  SELECT id,ip_address,aid,cid,sid,ks,created_at,updated_at,cost,uid,referrer,lead_type_id,device_type,landing_page,click_id,gclid,full_url,started,submitted,qualified,state,zip,tid,qualified_lead,lead_revenue,total_ad_clicks,ad_click_revenue,total_quote_clicks,quote_click_revenue,total_calls,call_revenue,affiliate_cost,refunded,refunded_amount,form_version_id,bad_lead,raw_lead_id,lead_id,sub1,manager_id,duplicate,cost_adj,prefill_perc,prefill_missing_data,domain,max_call_duration,unity_revenue,home_bundle,quoted,policy,consumer_dob,consumer_age,continuous_insurance,gender,marital_status,education,credit_rating,license_status,pub_name,pub_company,budget,budget_pacing,manager,source_type,marketing_group_name,anura,call_disposition,bad_lead_desc,cc_rev,pst_day,pst_week,pst_month,pst_quarter,pst_year,pst_weekday,est_day,est_week,est_month,est_quarter,est_year,est_weekday,commercial_type,source_type_id,tof,time_on_form,insured,home_owner,military_affiliation,violations,accidents,dui,marketing_group_id,num_drivers,num_vehicles,syndi_click,rev_share,bad_dispo,cc_accepted,cc_connected,cc_inbound,rep_connected,cc_call_duration,pst_hour,est_hour,naics_code
  FROM staging_aggr_visits;

  DROP TABLE IF EXISTS staging_aggr_visits;
END;
$$
	
