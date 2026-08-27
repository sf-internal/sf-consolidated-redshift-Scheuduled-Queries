CREATE OR REPLACE PROCEDURE forms.refresh_pub_aggr_state_stats(p_days_ago integer)
 LANGUAGE plpgsql
AS $$
DECLARE
    v_days INT := COALESCE(p_days_ago, 0);
    from_target_date TIMESTAMP;
    to_target_date TIMESTAMP;
BEGIN
  from_target_date := DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'US/Pacific', GETDATE() - v_days - interval '2 minute'));
  to_target_date := DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'US/Pacific', GETDATE() - v_days + 1));
  RAISE INFO 'Target Timestamp: %', from_target_date;
  -- Create staging table with distinct dates to be refreshed
  CREATE TEMP TABLE staging_pub_state_stats_dates AS
    select distinct pst_day as dt
    from forms.aggr_visits
    where updated_at >= from_target_date
      and updated_at <= to_target_date;

  -- Delete existing records for the dates to be refreshed
  DELETE FROM forms.pub_aggr_state_stats
  WHERE pst_day IN (SELECT dt FROM staging_pub_state_stats_dates);

  -- Insert refreshed data into the main table
  INSERT INTO forms.pub_aggr_state_stats(pst_day, pst_week, pst_month, pst_quarter, pst_year, pst_weekday, aid, cid, state, lead_type_id, lead_type, marketing_group_id, marketing_group, source_type_id, source_type, manager_id, device_type, syndi_click, payout_type, total_visits, unique_visits, form_starts, form_submits, qualified_leads, paid_leads, lead_revenue, total_calls, call_revenue, total_clicks, click_revenue, unity_revenue, total_cost, avg_prefill_perc, full_data_visits, mobile_visits, total_quotes, total_policies, total_bad_leads, total_bad_dispositions, avg_tof, min15_calls, min25_calls, total_cost_adjustment)
  SELECT
    pst_day,
    pst_week,
    pst_month,
    pst_quarter,
    pst_year,
    pst_weekday,
    aid,
    cid,
    state,
    lead_type_id::integer AS lead_type_id,
    null as lead_type,
    marketing_group_id,
    marketing_group_name as marketing_group,
    source_type_id,
    source_type,
    manager_id,
    device_type,
    syndi_click,
    case when rev_share = '1' then 'Rev Share' else 'CPL' end as payout_type,
    count(*) AS total_visits,
    coalesce(sum(case when duplicate is false then 1 else 0 end), 0) AS unique_visits,
    coalesce(sum(case when started is true then 1 else 0 end), 0) AS form_starts,
    coalesce(sum(case when submitted is true then 1 else 0 end), 0) AS form_submits,
    coalesce(sum(case when qualified_lead is true then 1 else 0 end), 0) AS qualified_leads,
    coalesce(sum(case when cost is not null and cost-COALESCE(cost_adj,0) > 0 then 1 else 0 end), 0) AS paid_leads,
    round(coalesce(sum(lead_revenue), 0), 2) AS lead_revenue,
    coalesce(sum(total_calls), 0) AS total_calls,
    round(coalesce(sum(call_revenue), 0), 2) AS call_revenue,
    coalesce(sum(total_ad_clicks), 0) + coalesce(sum(total_quote_clicks), 0) AS total_clicks,
    round(coalesce(sum(ad_click_revenue), 0) + coalesce(sum(quote_click_revenue), 0), 2) AS click_revenue,
    round(coalesce(sum(unity_revenue), 0), 2) AS unity_revenue,
    round(coalesce(sum(cost), 0), 2) AS total_cost,
    round(coalesce(avg(prefill_perc), 0)) AS avg_prefill_perc,
    coalesce(sum(case when prefill_perc >= 100 then 1 else 0 end), 0) AS full_data_visits,
    coalesce(sum(case when device_type = 'mobile' then 1 else 0 end), 0) AS mobile_visits,
    coalesce(sum(case when quoted is true then 1 else 0 end), 0) AS total_quotes,
    coalesce(sum(case when policy is true then 1 else 0 end), 0) AS total_policies,
    coalesce(sum(case when anura is true then 1 else 0 end), 0) AS total_bad_leads,
    coalesce(sum(case when bad_dispo = 'true' then 1 else 0 end), 0) AS total_bad_dispositions,
    round(coalesce(avg(tof), 0), 2) AS avg_tof,
    coalesce(sum(case when max_call_duration >= 900 then 1 else 0 end), 0) AS min15_calls,
    coalesce(sum(case when max_call_duration >= 1500 then 1 else 0 end), 0) AS min25_calls,
    round(coalesce(sum(cost_adj), 0), 2) AS total_cost_adjustment
  FROM forms.aggr_visits
  WHERE pst_day >= (SELECT MIN(dt) FROM staging_pub_state_stats_dates)
  AND pst_day <= (SELECT MAX(dt) FROM staging_pub_state_stats_dates)
  AND pst_day IN (SELECT dt FROM staging_pub_state_stats_dates)
  group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19;

  -- Drop the staging table
  DROP TABLE IF EXISTS staging_pub_state_stats_dates;
END;
$$
	
