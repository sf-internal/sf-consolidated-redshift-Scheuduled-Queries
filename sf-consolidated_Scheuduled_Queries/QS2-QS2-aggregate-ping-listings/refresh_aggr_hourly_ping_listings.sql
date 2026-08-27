CREATE OR REPLACE PROCEDURE pingpost.refresh_aggr_hourly_ping_listings(p_days_ago integer)
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

    CREATE TEMP TABLE staging_hourly_ping_dates AS
    SELECT DISTINCT pst_day AS dt
    FROM pingpost.aggr_ping_listings
    WHERE updated_at >= from_target_date AND updated_at <= to_target_date;

    DELETE FROM pingpost.aggr_hourly_ping_listings
    WHERE pst_day IN (SELECT dt FROM staging_hourly_ping_dates);

    INSERT INTO pingpost.aggr_hourly_ping_listings (
        pst_hour, pst_day, pst_week, pst_month, pst_quarter, pst_year,
        carrier_name, account_name, network_name, bid_type,
        state, device_type, lead_type_id, source_type_id, marketing_group_id, aid, cid,
        total_listings, bids, auction_bids, de_dupes, discarded_bids,
        no_consent_bids, posts, accepted_posts,
        total_payout, auction_payout, auction_payout_count,
        gross_revenue, promo_revenue
    )
    SELECT
        pst_hour, pst_day, pst_week, pst_month, pst_quarter, pst_year,
        carrier_name, account_name, network_name, bid_type,
        state, device_type, lead_type_id, source_type_id, marketing_group_id, aid, cid,
        COALESCE(COUNT(*), 0),
        COALESCE(SUM(CASE WHEN payout > 0 THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN selected IS TRUE THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN de_duped IS TRUE THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN payout > 0 AND bid <= 0 THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN payout > 0 AND consent_verified IS FALSE THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN posted IS TRUE AND consent_verified IS NOT FALSE THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN accepted IS TRUE THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(payout), 0),
        COALESCE(SUM(CASE WHEN bid > 0 THEN payout ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN bid > 0 THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN accepted IS TRUE THEN payout ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN accepted IS TRUE THEN paid_by_promo ELSE 0 END), 0)
    FROM pingpost.aggr_ping_listings
    WHERE pst_day IN (SELECT dt FROM staging_hourly_ping_dates)
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17;

    DROP TABLE staging_hourly_ping_dates;
END;
$$
	
