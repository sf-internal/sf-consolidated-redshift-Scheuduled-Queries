-- One-time backfill of the call rollup tables from all of call_tracking.aggr_call_logs.
-- Run after create_call_rollup_tables.sql and before adding the refresh procedures
-- to the QS2-aggregate_call_logs schedule. Safe to re-run: each table is emptied first.

BEGIN;

DELETE FROM call_tracking.pub_aggr_call_stats;

INSERT INTO call_tracking.pub_aggr_call_stats(pst_day, pst_week, pst_month, pst_quarter, pst_year, pst_weekday, aff_portal_id, affiliate_id, lead_type_id, manager_id, source_type, marketing_group, aff_type, cc_reviewed, total_calls, total_transfers, total_transfers_qualified, total_cost, total_revenue, total_calls_reviewed, total_refunded, total_errors, transfer_duration_sum, transfer_duration_count, duration_sum, duration_count)
SELECT
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
WHERE pst_day IS NOT NULL
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14;

DELETE FROM call_tracking.pub_aggr_call_state_stats;

INSERT INTO call_tracking.pub_aggr_call_state_stats(pst_day, pst_week, pst_month, pst_quarter, pst_year, pst_weekday, aff_portal_id, affiliate_id, lead_type_id, manager_id, source_type, marketing_group, aff_type, cc_reviewed, state, total_calls, total_transfers, total_transfers_qualified, total_cost, total_revenue, total_calls_reviewed, total_refunded, total_errors, transfer_duration_sum, transfer_duration_count, duration_sum, duration_count)
SELECT
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
  state,
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
WHERE pst_day IS NOT NULL
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15;

DELETE FROM call_tracking.graph_aggr_call_stats;

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
WHERE pst_day IS NOT NULL
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15;

COMMIT;

ANALYZE call_tracking.pub_aggr_call_stats;
ANALYZE call_tracking.pub_aggr_call_state_stats;
ANALYZE call_tracking.graph_aggr_call_stats;
