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
    cir.general_liability || cir.commercial_auto || cir.commercial_property || cir.professional_liability
            || cir.directors_officers_liability || cir.business_owners_package || cir.workers_comp || cir.commercial_crime || cir.cyber_insurance as commercial_type,
    cir.naics_code,
    -- PPV2-415: vertical-specific consumer attributes
    lh.residence_type as property_type,
    lh.square_footage,
    lh.number_of_stories,
    lh.year_built,
    la.tobacco,
    la.has_pre_existing_conditions as health_conditions,
    hr.household_income,
    cir.years_in_business,
    cir.full_time_employees,
    cir.part_time_employees,
    cir.revenue as business_revenue,
    nullif(rtrim(
        case when json_extract_path_text(ghrd.plan_types, 'ppo',   TRUE) in ('true','1') then 'PPO,'   else '' end ||
        case when json_extract_path_text(ghrd.plan_types, 'hmo',   TRUE) in ('true','1') then 'HMO,'   else '' end ||
        case when json_extract_path_text(ghrd.plan_types, 'hsa',   TRUE) in ('true','1') then 'HSA,'   else '' end ||
        case when json_extract_path_text(ghrd.plan_types, 'hra',   TRUE) in ('true','1') then 'HRA,'   else '' end ||
        case when json_extract_path_text(ghrd.plan_types, 'epo',   TRUE) in ('true','1') then 'EPO,'   else '' end ||
        case when json_extract_path_text(ghrd.plan_types, 'other', TRUE) in ('true','1') then 'Other,' else '' end
    , ','), '') as plan_type,
    left(ghrd.num_employees, 765) as num_employees,
    ld.requested_coverage
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
  -- PPV2-415: deduped. 373 leads carry >1 row; a plain join fans out aggr_visits
  -- and double-counts every downstream rollup. DISTINCT only collapses identical rows.
  left join (
      select lead_id, naics_code, years_in_business, full_time_employees, part_time_employees, revenue,
             general_liability, commercial_auto, commercial_property, professional_liability,
             directors_officers_liability, business_owners_package, workers_comp, commercial_crime, cyber_insurance
      from (
          select lead_id, naics_code, years_in_business, full_time_employees, part_time_employees, revenue,
                 general_liability, commercial_auto, commercial_property, professional_liability,
                 directors_officers_liability, business_owners_package, workers_comp, commercial_crime, cyber_insurance,
                 row_number() over (partition by lead_id order by updated_at desc nulls last, id desc) as rn
          from forms.commercial_insurance_requests
          where lead_id is not null
      ) d where d.rn = 1
  ) cir on v.lead_id = cir.lead_id
  -- PPV2-415: new per-vertical sources, all deduped to one row per lead_id
  left join (
      select lead_id, residence_type, square_footage, number_of_stories, year_built
      from (
          select lead_id, residence_type, square_footage, number_of_stories, year_built,
                 row_number() over (partition by lead_id order by updated_at desc nulls last, id desc) as rn
          from forms.lead_homes where lead_id is not null
      ) d where d.rn = 1
  ) lh on v.lead_id = lh.lead_id
  left join (
      select lead_id, tobacco, has_pre_existing_conditions
      from (
          select lead_id, tobacco, has_pre_existing_conditions,
                 row_number() over (partition by lead_id order by updated_at desc nulls last, id desc) as rn
          from forms.lead_applicants where lead_id is not null
      ) d where d.rn = 1
  ) la on v.lead_id = la.lead_id
  left join (
      select lead_id, household_income
      from (
          select lead_id, household_income,
                 row_number() over (partition by lead_id order by updated_at desc nulls last, id desc) as rn
          from forms.health_records where lead_id is not null
      ) d where d.rn = 1
  ) hr on v.lead_id = hr.lead_id
  left join (
      select lead_id, plan_types, num_employees
      from (
          select lead_id, plan_types, num_employees,
                 row_number() over (partition by lead_id order by updated_at desc nulls last, id desc) as rn
          from forms.group_health_request_details where lead_id is not null
      ) d where d.rn = 1
  ) ghrd on v.lead_id = ghrd.lead_id
  left join forms.leads ld on v.lead_id = ld.id
  where v.updated_at >= DATEADD(minute, -500, GETDATE()) and v.created_at >= DATEADD(month, -6, GETDATE());

  DELETE FROM forms.aggr_visits
  USING staging_aggr_visits s
  WHERE forms.aggr_visits.id = s.id;

  INSERT INTO forms.aggr_visits(
    id,ip_address,aid,cid,sid,ks,created_at,updated_at,cost,uid,referrer,lead_type_id,device_type,landing_page,click_id,gclid,full_url,started,submitted,qualified,state,zip,tid,qualified_lead,lead_revenue,total_ad_clicks,ad_click_revenue,total_quote_clicks,quote_click_revenue,total_calls,call_revenue,affiliate_cost,refunded,refunded_amount,form_version_id,bad_lead,raw_lead_id,lead_id,sub1,manager_id,duplicate,cost_adj,prefill_perc,prefill_missing_data,domain,max_call_duration,unity_revenue,home_bundle,quoted,policy,consumer_dob,consumer_age,continuous_insurance,gender,marital_status,education,credit_rating,license_status,pub_name,pub_company,budget,budget_pacing,manager,source_type,marketing_group_name,anura,call_disposition,bad_lead_desc,cc_rev,pst_day,pst_week,pst_month,pst_quarter,pst_year,pst_weekday,est_day,est_week,est_month,est_quarter,est_year,est_weekday,commercial_type,source_type_id,tof,time_on_form,insured,home_owner,military_affiliation,violations,accidents,dui,marketing_group_id,num_drivers,num_vehicles,syndi_click,rev_share,bad_dispo,cc_accepted,cc_connected,cc_inbound,rep_connected,cc_call_duration,pst_hour,est_hour,naics_code,property_type,square_footage,number_of_stories,year_built,tobacco,health_conditions,household_income,years_in_business,full_time_employees,part_time_employees,business_revenue,plan_type,num_employees,requested_coverage
  )
  SELECT id,ip_address,aid,cid,sid,ks,created_at,updated_at,cost,uid,referrer,lead_type_id,device_type,landing_page,click_id,gclid,full_url,started,submitted,qualified,state,zip,tid,qualified_lead,lead_revenue,total_ad_clicks,ad_click_revenue,total_quote_clicks,quote_click_revenue,total_calls,call_revenue,affiliate_cost,refunded,refunded_amount,form_version_id,bad_lead,raw_lead_id,lead_id,sub1,manager_id,duplicate,cost_adj,prefill_perc,prefill_missing_data,domain,max_call_duration,unity_revenue,home_bundle,quoted,policy,consumer_dob,consumer_age,continuous_insurance,gender,marital_status,education,credit_rating,license_status,pub_name,pub_company,budget,budget_pacing,manager,source_type,marketing_group_name,anura,call_disposition,bad_lead_desc,cc_rev,pst_day,pst_week,pst_month,pst_quarter,pst_year,pst_weekday,est_day,est_week,est_month,est_quarter,est_year,est_weekday,commercial_type,source_type_id,tof,time_on_form,insured,home_owner,military_affiliation,violations,accidents,dui,marketing_group_id,num_drivers,num_vehicles,syndi_click,rev_share,bad_dispo,cc_accepted,cc_connected,cc_inbound,rep_connected,cc_call_duration,pst_hour,est_hour,naics_code,property_type,square_footage,number_of_stories,year_built,tobacco,health_conditions,household_income,years_in_business,full_time_employees,part_time_employees,business_revenue,plan_type,num_employees,requested_coverage
  FROM staging_aggr_visits;

  DROP TABLE IF EXISTS staging_aggr_visits;
END;
$$