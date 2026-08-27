CREATE OR REPLACE PROCEDURE forms.refresh_pub_aggr_source_stats(p_days_ago integer)
 LANGUAGE plpgsql
AS $_$
DECLARE
    v_days           INT := COALESCE(p_days_ago, 0);
    from_target_date TIMESTAMP;
    to_target_date   TIMESTAMP;
BEGIN
  from_target_date := DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'US/Pacific', GETDATE() - v_days - interval '2 minute'));
  to_target_date   := DATE_TRUNC('day', CONVERT_TIMEZONE('UTC', 'US/Pacific', GETDATE() - v_days + 1));
  RAISE INFO 'Target Timestamp: %', from_target_date;

  CREATE TEMP TABLE staging_pub_source_stats_dates AS
    SELECT DISTINCT pst_day AS dt
    FROM forms.aggr_visits
    WHERE updated_at >= from_target_date
      AND updated_at <= to_target_date;

  DELETE FROM forms.pub_aggr_source_stats
  WHERE pst_day IN (SELECT dt FROM staging_pub_source_stats_dates);

  INSERT INTO forms.pub_aggr_source_stats (
      pst_day, pst_week, pst_month, pst_quarter, pst_year, pst_weekday,
      aid, cid, sid, source_id, lead_type_id, lead_type, marketing_group_id, marketing_group,
      source_type_id, source_type, manager_id, device_type, syndi_click, payout_type,
      total_visits, unique_visits, form_starts, form_submits, qualified_leads, paid_leads,
      total_calls, total_clicks, full_data_visits, mobile_visits, total_quotes, total_policies,
      min15_calls, min25_calls,
      total_bad_leads, total_bad_dispositions,
      lead_revenue, call_revenue, click_revenue, unity_revenue, total_cost, total_cost_adjustment,
      avg_prefill_perc, avg_tof,
      sum_prefill_perc, prefill_visits, sum_tof, tof_visits)
  -- forms.sources has no enforced primary key and the replica carries one
  -- exactly-duplicated row; max(id) collapses it so the LEFT JOIN below cannot
  -- fan out a source's measures. Every (aid, cid, sid) maps to at most one id.
  WITH src AS (
    SELECT aid, cid, sid, max(id) AS source_id
    FROM forms.sources
    GROUP BY aid, cid, sid
  ),
  -- aggr_visits.aid / .cid are varchar and can hold non-numeric junk, so the
  -- INTEGER side is cast to varchar rather than the other way round -- casting
  -- av.aid to int would abort the whole procedure on one bad row.
  v AS (
    SELECT av.*, src.source_id
    FROM forms.aggr_visits av
    LEFT JOIN src
           ON src.aid::varchar = av.aid
          AND src.cid::varchar = av.cid
          AND src.sid          = av.sid
    WHERE av.pst_day >= (SELECT MIN(dt) FROM staging_pub_source_stats_dates)
      AND av.pst_day <= (SELECT MAX(dt) FROM staging_pub_source_stats_dates)
      AND av.pst_day IN (SELECT dt FROM staging_pub_source_stats_dates)
  )
  SELECT
      pst_day,
      pst_week,
      pst_month,
      pst_quarter,
      pst_year,
      pst_weekday,
      aid,
      cid,
      sid,
      source_id,
      lead_type_id::integer AS lead_type_id,
      null AS lead_type,
      marketing_group_id,
      marketing_group_name AS marketing_group,
      source_type_id,
      source_type,
      manager_id,
      device_type,
      syndi_click,
      CASE WHEN rev_share = '1' THEN 'Rev Share' ELSE 'CPL' END AS payout_type,

      count(*)                                                                          AS total_visits,
      coalesce(sum(CASE WHEN duplicate      IS FALSE THEN 1 ELSE 0 END), 0)              AS unique_visits,
      coalesce(sum(CASE WHEN started        IS TRUE  THEN 1 ELSE 0 END), 0)              AS form_starts,
      coalesce(sum(CASE WHEN submitted      IS TRUE  THEN 1 ELSE 0 END), 0)              AS form_submits,
      coalesce(sum(CASE WHEN qualified_lead IS TRUE  THEN 1 ELSE 0 END), 0)              AS qualified_leads,
      coalesce(sum(CASE WHEN cost IS NOT NULL AND cost - coalesce(cost_adj, 0) > 0
                       THEN 1 ELSE 0 END), 0)                                            AS paid_leads,
      coalesce(sum(total_calls), 0)                                                      AS total_calls,
      coalesce(sum(total_ad_clicks), 0) + coalesce(sum(total_quote_clicks), 0)           AS total_clicks,
      coalesce(sum(CASE WHEN prefill_perc >= 100 THEN 1 ELSE 0 END), 0)                  AS full_data_visits,
      coalesce(sum(CASE WHEN device_type = 'mobile' THEN 1 ELSE 0 END), 0)               AS mobile_visits,
      coalesce(sum(CASE WHEN quoted IS TRUE THEN 1 ELSE 0 END), 0)                       AS total_quotes,
      coalesce(sum(CASE WHEN policy IS TRUE THEN 1 ELSE 0 END), 0)                       AS total_policies,
      coalesce(sum(CASE WHEN max_call_duration >= 900  THEN 1 ELSE 0 END), 0)            AS min15_calls,
      coalesce(sum(CASE WHEN max_call_duration >= 1500 THEN 1 ELSE 0 END), 0)            AS min25_calls,

      coalesce(sum(CASE WHEN anura IS TRUE THEN 1 ELSE 0 END), 0)                        AS total_bad_leads,
      coalesce(sum(CASE WHEN bad_dispo = 'true' THEN 1 ELSE 0 END), 0)                   AS total_bad_dispositions,

      round(coalesce(sum(lead_revenue), 0), 2)                                           AS lead_revenue,
      round(coalesce(sum(call_revenue), 0), 2)                                           AS call_revenue,
      round(coalesce(sum(ad_click_revenue), 0) + coalesce(sum(quote_click_revenue), 0), 2) AS click_revenue,
      round(coalesce(sum(unity_revenue), 0), 2)                                          AS unity_revenue,
      round(coalesce(sum(cost), 0), 2)                                                   AS total_cost,
      round(coalesce(sum(cost_adj), 0), 2)                                               AS total_cost_adjustment,

      round(coalesce(avg(prefill_perc), 0))                                               AS avg_prefill_perc,
      round(coalesce(avg(CASE WHEN tof ~ '^[0-9]+([.][0-9]+)?$'
                             THEN tof::numeric END), 0), 2)                              AS avg_tof,
      round(coalesce(sum(prefill_perc), 0), 2)                                           AS sum_prefill_perc,
      coalesce(sum(CASE WHEN prefill_perc IS NOT NULL THEN 1 ELSE 0 END), 0)             AS prefill_visits,
      round(coalesce(sum(CASE WHEN tof ~ '^[0-9]+([.][0-9]+)?$'
                              THEN tof::numeric ELSE 0 END), 0), 2)                      AS sum_tof,
      coalesce(sum(CASE WHEN tof ~ '^[0-9]+([.][0-9]+)?$' THEN 1 ELSE 0 END), 0)         AS tof_visits
  FROM v
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20;

  DROP TABLE IF EXISTS staging_pub_source_stats_dates;
END;
$_$
	
