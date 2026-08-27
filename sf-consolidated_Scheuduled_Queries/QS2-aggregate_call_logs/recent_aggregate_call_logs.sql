CREATE OR REPLACE PROCEDURE call_tracking.recent_aggregate_call_logs()
 LANGUAGE plpgsql
AS $$
BEGIN
  CREATE TEMP TABLE staging_aggr_call_logs AS
  select 
    cl.*,
    cast(extract('hour' from CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', cl.created_at)) as integer) as pst_hour,
    cast(date(DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', cl.created_at))) as date) as pst_day,
    cast(date(DATE_TRUNC('week', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', cl.created_at))) as date) as pst_week,
    cast(date(DATE_TRUNC('month', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', cl.created_at))) as date) as pst_month,
    cast(date(DATE_TRUNC('quarter', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', cl.created_at))) as date) as pst_quarter,
    cast(date(DATE_TRUNC('year', CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', cl.created_at))) as date) as pst_year,
    cast(extract('DOW' from CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', cl.created_at)) as integer) as pst_weekday,
    lt.lead_type as call_type,
    st.name as pub_source_type,
    ug.name as pub_marketing_group,
    u.first_name || ' ' || u.last_name || ' (' || u.id || ')' as pub_name,
    c.name as pub_campaign_name
  from call_tracking.call_logs cl
  left join forms.campaigns c on cl.form_cid = c.id and cl.affiliate_id = 57
  left join affiliate_portal.source_types st on c.source_type_id = st.id
  left join affiliate_portal.users u on cl.form_aid = u.id and cl.affiliate_id = 57
  left join affiliate_portal.user_groups ug on u.user_group_id = ug.id
  left join contactability.quote_calls_lead_types lt on cl.lead_type_id = lt.id
  where cl.updated_at >= DATEADD(minute, -60, GETDATE()) and cl.created_at >= DATEADD(day, -2, GETDATE());

  DELETE FROM call_tracking.aggr_call_logs
  USING staging_aggr_call_logs s
  WHERE call_tracking.aggr_call_logs.id = s.id;

  INSERT INTO call_tracking.aggr_call_logs
  SELECT *
  FROM staging_aggr_call_logs;

  DROP TABLE IF EXISTS staging_aggr_call_logs;
END;
$$
	
