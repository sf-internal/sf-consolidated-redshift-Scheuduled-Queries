CREATE OR REPLACE PROCEDURE pingpost.refresh_aggr_common_click_listings(p_days_ago integer)
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
    CREATE TEMP TABLE staging_aggr_common_click_listings_dates AS
    select distinct pst_day as dt
    from pingpost.aggr_click_listings
    where updated_at >= from_target_date
        and updated_at <= to_target_date;

    -- Delete existing records for the dates to be refreshed
    DELETE FROM pingpost.aggr_common_click_listings
    WHERE pst_day IN (SELECT dt FROM staging_aggr_common_click_listings_dates);

    -- Insert refreshed data for the specified date range
    INSERT INTO pingpost.aggr_common_click_listings (
        pst_day,
        pst_week,
        pst_month,
        pst_quarter,
        pst_year,
        display_name,
        network_name,
        listing_type,
        state,
        lead_type,
        source_type,
        marketing_group,
        lead_type_id,
        source_type_id,
        marketing_group_id,
        device_type,
        aid,
        cid,
        account_id,
        campaign_id,
        total_searches,
        pos_searches,
        total_impressions,
        total_clicks,
        total_revenue,
        total_bid,
        sum_pos
    )
    select
        pst_day,
        pst_week,
        pst_month,
        pst_quarter,
        pst_year,
        display_name,
        network_name,
        listing_type,
        state,
        lead_type,
        source_type,
        marketing_group,
        lead_type_id,
        source_type_id,
        marketing_group_id,
        device_type,
        aid,
        cid,
        account_id,
        campaign_id,
        coalesce(count(*), 0) as searches,
        coalesce(sum(case when position is not null then 1 else 0 end), 0) as pos_searches,
        coalesce(sum(case when viewed is true then 1 else 0 end), 0) as impressions,
        coalesce(sum(case when clicked is true then 1 else 0 end), 0) as clicks,
        coalesce(sum(case when clicked is true then payout else 0 end), 0) as rev,
        coalesce(sum(payout), 0) as total_bid,
        coalesce(sum(position), 0) as sum_pos
    from pingpost.aggr_click_listings
    WHERE pst_day >= (SELECT MIN(dt) FROM staging_aggr_common_click_listings_dates)
    AND pst_day <= (SELECT MAX(dt) FROM staging_aggr_common_click_listings_dates)
    AND pst_day IN (SELECT dt FROM staging_aggr_common_click_listings_dates)
    group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20;

    -- Clean up staging table
    DROP TABLE staging_aggr_common_click_listings_dates;
END;
$$
	
