CREATE OR REPLACE PROCEDURE call_tracking.refresh_graph_aggr_call_stats(p_days_ago integer)
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
  CREATE TEMP TABLE staging_graph_call_stats_dates AS
    select distinct pst_day as dt
    from call_tracking.aggr_call_logs
    where updated_at >= from_target_date
      and updated_at <= to_target_date;

  -- Delete existing records for the dates to be refreshed
  DELETE FROM call_tracking.graph_aggr_call_stats
  WHERE pst_day IN (SELECT dt FROM staging_graph_call_stats_dates);

  -- Insert refreshed data into the main table
  INSERT INTO call_tracking.graph_aggr_call_stats(pst_hour, pst_day, pst_week, pst_month, pst_quarter, pst_year, pst_weekday, aff_portal_id, affiliate_id, lead_type_id, manager_id, source_type, marketing_group, aff_type, cc_reviewed, total_calls, total_transfers, total_transfers_qualified, total_cost, total_revenue, total_calls_reviewed, total_refunded, total_errors, transfer_duration_sum, transfer_duration_count, duration_sum, duration_count)
  SELECT
    pst_hour,
    pst_day,
    pst_week,
    pst_month,
    pst_quarter,
    pst_year,
    pst_weekday,
    aff_portal_id,
    affiliate_id,
    lead_type_id,
    manager_id,
    source_type,
    marketing_group,
    aff_type,
    cc_reviewed,
    count(*) AS total_calls,
    sum(case when quote_calls_stat_id is not null then 1 else 0 end) AS total_transfers,
    sum(case when revenue > 0 then 1 else 0 end) AS total_transfers_qualified,
    sum(cost) AS total_cost,
    sum(case when is_promo is true then 0 else revenue end) AS total_revenue,
    sum(case when cc_reviewed is true then 1 else 0 end) AS total_calls_reviewed,
    sum(case when refunded is true then 1 else 0 end) AS total_refunded,
    sum(case when erred is true then 1 else 0 end) AS total_errors,
    sum(transfer_duration::bigint) AS transfer_duration_sum,
    count(transfer_duration) AS transfer_duration_count,
    sum(coalesce(duration, transfer_duration)::bigint) AS duration_sum,
    count(coalesce(duration, transfer_duration)) AS duration_count
  FROM call_tracking.aggr_call_logs
  WHERE pst_day >= (SELECT MIN(dt) FROM staging_graph_call_stats_dates)
  AND pst_day <= (SELECT MAX(dt) FROM staging_graph_call_stats_dates)
  AND pst_day IN (SELECT dt FROM staging_graph_call_stats_dates)
  group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15;

  -- Drop the staging table
  DROP TABLE IF EXISTS staging_graph_call_stats_dates;
END;
$$
