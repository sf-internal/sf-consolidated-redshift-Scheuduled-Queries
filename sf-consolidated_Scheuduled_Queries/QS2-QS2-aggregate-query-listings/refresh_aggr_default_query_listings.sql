CREATE OR REPLACE PROCEDURE call_tracking.refresh_aggr_default_query_listings(p_days_ago integer)
 LANGUAGE plpgsql
AS $$
DECLARE
    v_days INT := COALESCE(p_days_ago, 0);
    from_target_date TIMESTAMP;
    to_target_date   TIMESTAMP;
BEGIN
    from_target_date := DATE_TRUNC('day', CONVERT_TIMEZONE('UTC','US/Pacific', GETDATE() - v_days - interval '2 minute'));
    to_target_date   := DATE_TRUNC('day', CONVERT_TIMEZONE('UTC','US/Pacific', GETDATE() - v_days + 1));
    RAISE INFO 'Target Timestamp: %', from_target_date;

    CREATE TEMP TABLE staging_default_query_dates AS
    SELECT DISTINCT pst_day AS dt
    FROM call_tracking.aggr_query_listings
    WHERE updated_at >= from_target_date AND updated_at <= to_target_date;

    DELETE FROM call_tracking.aggr_default_query_listings
    WHERE pst_day IN (SELECT dt FROM staging_default_query_dates);

    INSERT INTO call_tracking.aggr_default_query_listings (
        pst_day, pst_week, pst_month, pst_quarter, pst_year,
        account_name, service_provider, network,
        searches, impressions, de_dupes, exclusions, calls, billable_calls,
        revenue, total_price, sum_position, pos_count, sum_dupe_diff, dupe_diff_count
    )
    SELECT
        pst_day, pst_week, pst_month, pst_quarter, pst_year,
        account_name, service_provider, network,
        COALESCE(COUNT(*), 0),
        COALESCE(SUM(CASE WHEN displayed   IS TRUE THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN de_duped    IS TRUE THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN excluded    IS TRUE THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN transferred IS TRUE THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN billable    IS TRUE THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN billable    IS TRUE THEN price ELSE 0 END), 0),
        COALESCE(SUM(price), 0),
        COALESCE(SUM(position), 0),
        COALESCE(SUM(CASE WHEN position  IS NOT NULL THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(dupe_diff), 0),
        COALESCE(SUM(CASE WHEN dupe_diff IS NOT NULL THEN 1 ELSE 0 END), 0)
    FROM call_tracking.aggr_query_listings
    WHERE pst_day IN (SELECT dt FROM staging_default_query_dates)
    GROUP BY 1,2,3,4,5,6,7,8;

    DROP TABLE staging_default_query_dates;
END;
$$
	
