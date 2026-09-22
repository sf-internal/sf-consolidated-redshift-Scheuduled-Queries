CREATE OR REPLACE PROCEDURE forms.aggregate_visits(p_days_ago integer)
 LANGUAGE plpgsql
AS $$
DECLARE
  v_days INT := COALESCE(p_days_ago, 0);
  v_target_date TIMESTAMP;
BEGIN
  v_target_date := GETDATE() - v_days;

  RAISE INFO 'Target Timestamp: %', v_target_date;

  CREATE TEMP TABLE staging_aggr_visits2 AS
  SELECT DISTINCT
    v.*,

    vd.consumer_dob,
    vd.consumer_age,
    vd.time_on_form,
    vd.insured,
    vd.continuous_insurance,
    vd.home_owner,
    vd.gender,
    vd.marital_status,
    vd.education,
    vd.credit_rating,
    vd.military_affiliation,
    vd.col1 AS marketing_group_id,

    vad.num_drivers,
    vad.num_vehicles,
    vad.violations,
    vad.accidents,
    vad.dui,
    vad.license_status,

    concat(concat(u.first_name, ' '), u.last_name) AS pub_name,
    u.company AS pub_company,
    u.budget,
    u.budget_pacing,

    concat(concat(um.first_name, ' '), um.last_name) AS manager,

    c.syndi_click,
    c.rev_share,

    st.name AS source_type,
    ug.name AS marketing_group_name,

    bl.anura,
    bl.bad_dispo,
    bl.call_disposition,
    bl.desc AS bad_lead_desc,

    cc.accepted AS cc_accepted,
    cc.connected AS cc_connected,
    cc.rev AS cc_rev,
    cc.call_duration AS cc_call_duration,
    cc.inbound AS cc_inbound,
    cc.rep_connected,

    cast(
      extract(
        'hour'
        FROM CONVERT_TIMEZONE(
          'UTC',
          'America/Los_Angeles',
          v.created_at
        )
      ) AS integer
    ) AS pst_hour,

    cast(
      date(
        DATE_TRUNC(
          'day',
          CONVERT_TIMEZONE(
            'UTC',
            'America/Los_Angeles',
            v.created_at
          )
        )
      ) AS date
    ) AS pst_day,

    cast(
      date(
        DATE_TRUNC(
          'week',
          CONVERT_TIMEZONE(
            'UTC',
            'America/Los_Angeles',
            v.created_at
          )
        )
      ) AS date
    ) AS pst_week,

    cast(
      date(
        DATE_TRUNC(
          'month',
          CONVERT_TIMEZONE(
            'UTC',
            'America/Los_Angeles',
            v.created_at
          )
        )
      ) AS date
    ) AS pst_month,

    cast(
      date(
        DATE_TRUNC(
          'quarter',
          CONVERT_TIMEZONE(
            'UTC',
            'America/Los_Angeles',
            v.created_at
          )
        )
      ) AS date
    ) AS pst_quarter,

    cast(
      date(
        DATE_TRUNC(
          'year',
          CONVERT_TIMEZONE(
            'UTC',
            'America/Los_Angeles',
            v.created_at
          )
        )
      ) AS date
    ) AS pst_year,

    cast(
      extract(
        'DOW'
        FROM CONVERT_TIMEZONE(
          'UTC',
          'America/Los_Angeles',
          v.created_at
        )
      ) AS integer
    ) AS pst_weekday,

    cast(
      extract(
        'hour'
        FROM CONVERT_TIMEZONE(
          'UTC',
          'America/New_York',
          v.created_at
        )
      ) AS integer
    ) AS est_hour,

    cast(
      date(
        DATE_TRUNC(
          'day',
          CONVERT_TIMEZONE(
            'UTC',
            'America/New_York',
            v.created_at
          )
        )
      ) AS date
    ) AS est_day,

    cast(
      date(
        DATE_TRUNC(
          'week',
          CONVERT_TIMEZONE(
            'UTC',
            'America/New_York',
            v.created_at
          )
        )
      ) AS date
    ) AS est_week,

    cast(
      date(
        DATE_TRUNC(
          'month',
          CONVERT_TIMEZONE(
            'UTC',
            'America/New_York',
            v.created_at
          )
        )
      ) AS date
    ) AS est_month,

    cast(
      date(
        DATE_TRUNC(
          'quarter',
          CONVERT_TIMEZONE(
            'UTC',
            'America/New_York',
            v.created_at
          )
        )
      ) AS date
    ) AS est_quarter,

    cast(
      date(
        DATE_TRUNC(
          'year',
          CONVERT_TIMEZONE(
            'UTC',
            'America/New_York',
            v.created_at
          )
        )
      ) AS date
    ) AS est_year,

    cast(
      extract(
        'DOW'
        FROM CONVERT_TIMEZONE(
          'UTC',
          'America/New_York',
          v.created_at
        )
      ) AS integer
    ) AS est_weekday,

    cir.general_liability
      || cir.commercial_auto
      || cir.commercial_property
      || cir.professional_liability
      || cir.directors_officers_liability
      || cir.business_owners_package
      || cir.workers_comp
      || cir.commercial_crime
      || cir.cyber_insurance AS commercial_type,

    cir.naics_code,

    -- PPV2-415: vertical-specific consumer attributes
    lh.residence_type AS property_type,
    lh.square_footage,
    lh.number_of_stories,
    lh.year_built,

    la.tobacco,
    la.has_pre_existing_conditions AS health_conditions,

    hr.household_income,

    cir.years_in_business,
    cir.full_time_employees,
    cir.part_time_employees,
    cir.revenue AS business_revenue,

    nullif(
      rtrim(
        CASE
          WHEN json_extract_path_text(
                 ghrd.plan_types,
                 'ppo',
                 TRUE
               ) IN ('true', '1')
          THEN 'PPO,'
          ELSE ''
        END
        ||
        CASE
          WHEN json_extract_path_text(
                 ghrd.plan_types,
                 'hmo',
                 TRUE
               ) IN ('true', '1')
          THEN 'HMO,'
          ELSE ''
        END
        ||
        CASE
          WHEN json_extract_path_text(
                 ghrd.plan_types,
                 'hsa',
                 TRUE
               ) IN ('true', '1')
          THEN 'HSA,'
          ELSE ''
        END
        ||
        CASE
          WHEN json_extract_path_text(
                 ghrd.plan_types,
                 'hra',
                 TRUE
               ) IN ('true', '1')
          THEN 'HRA,'
          ELSE ''
        END
        ||
        CASE
          WHEN json_extract_path_text(
                 ghrd.plan_types,
                 'epo',
                 TRUE
               ) IN ('true', '1')
          THEN 'EPO,'
          ELSE ''
        END
        ||
        CASE
          WHEN json_extract_path_text(
                 ghrd.plan_types,
                 'other',
                 TRUE
               ) IN ('true', '1')
          THEN 'Other,'
          ELSE ''
        END,
        ','
      ),
      ''
    ) AS plan_type,

    left(ghrd.num_employees, 765) AS num_employees,
    ld.requested_coverage

  FROM forms.visits v

  LEFT JOIN forms.visit_details vd
    ON v.id = vd.visit_id

  LEFT JOIN forms.visit_auto_details vad
    ON v.id = vad.visit_id

  LEFT JOIN affiliate_portal.users u
    ON v.aid = u.id

  LEFT JOIN affiliate_portal.users um
    ON u.manager_id = um.id

  LEFT JOIN forms.campaigns c
    ON v.cid = c.id

  LEFT JOIN affiliate_portal.source_types st
    ON c.source_type_id = st.id

  LEFT JOIN affiliate_portal.user_groups ug
    ON vd.col1 = ug.id

  LEFT JOIN forms.bad_leads bl
    ON v.lead_id = bl.lead_id

  LEFT JOIN forms.click_calls cc
    ON v.id = cc.visit_id

  -- PPV2-415:
  -- Dedup commercial insurance rows to one row per lead_id.
  LEFT JOIN (
    SELECT
      lead_id,
      naics_code,
      years_in_business,
      full_time_employees,
      part_time_employees,
      revenue,
      general_liability,
      commercial_auto,
      commercial_property,
      professional_liability,
      directors_officers_liability,
      business_owners_package,
      workers_comp,
      commercial_crime,
      cyber_insurance
    FROM (
      SELECT
        lead_id,
        naics_code,
        years_in_business,
        full_time_employees,
        part_time_employees,
        revenue,
        general_liability,
        commercial_auto,
        commercial_property,
        professional_liability,
        directors_officers_liability,
        business_owners_package,
        workers_comp,
        commercial_crime,
        cyber_insurance,
        row_number() OVER (
          PARTITION BY lead_id
          ORDER BY updated_at DESC NULLS LAST, id DESC
        ) AS rn
      FROM forms.commercial_insurance_requests
      WHERE lead_id IS NOT NULL
    ) d
    WHERE d.rn = 1
  ) cir
    ON v.lead_id = cir.lead_id

  -- Home
  LEFT JOIN (
    SELECT
      lead_id,
      residence_type,
      square_footage,
      number_of_stories,
      year_built
    FROM (
      SELECT
        lead_id,
        residence_type,
        square_footage,
        number_of_stories,
        year_built,
        row_number() OVER (
          PARTITION BY lead_id
          ORDER BY updated_at DESC NULLS LAST, id DESC
        ) AS rn
      FROM forms.lead_homes
      WHERE lead_id IS NOT NULL
    ) d
    WHERE d.rn = 1
  ) lh
    ON v.lead_id = lh.lead_id

  -- Life / Health
  LEFT JOIN (
    SELECT
      lead_id,
      tobacco,
      has_pre_existing_conditions
    FROM (
      SELECT
        lead_id,
        tobacco,
        has_pre_existing_conditions,
        row_number() OVER (
          PARTITION BY lead_id
          ORDER BY updated_at DESC NULLS LAST, id DESC
        ) AS rn
      FROM forms.lead_applicants
      WHERE lead_id IS NOT NULL
    ) d
    WHERE d.rn = 1
  ) la
    ON v.lead_id = la.lead_id

  -- Health
  LEFT JOIN (
    SELECT
      lead_id,
      household_income
    FROM (
      SELECT
        lead_id,
        household_income,
        row_number() OVER (
          PARTITION BY lead_id
          ORDER BY updated_at DESC NULLS LAST, id DESC
        ) AS rn
      FROM forms.health_records
      WHERE lead_id IS NOT NULL
    ) d
    WHERE d.rn = 1
  ) hr
    ON v.lead_id = hr.lead_id

  -- Group Health
  LEFT JOIN (
    SELECT
      lead_id,
      plan_types,
      num_employees
    FROM (
      SELECT
        lead_id,
        plan_types,
        num_employees,
        row_number() OVER (
          PARTITION BY lead_id
          ORDER BY updated_at DESC NULLS LAST, id DESC
        ) AS rn
      FROM forms.group_health_request_details
      WHERE lead_id IS NOT NULL
    ) d
    WHERE d.rn = 1
  ) ghrd
    ON v.lead_id = ghrd.lead_id

  LEFT JOIN forms.leads ld
    ON v.lead_id = ld.id

  WHERE v.updated_at >= DATE_TRUNC(
          'day',
          CONVERT_TIMEZONE(
            'UTC',
            'America/Los_Angeles',
            v_target_date
          )
        )
    AND v.updated_at <= DATE_TRUNC(
          'day',
          CONVERT_TIMEZONE(
            'UTC',
            'America/Los_Angeles',
            v_target_date
          )
        ) + interval '34 hour'
    AND v.id IS NOT NULL;

  DELETE FROM forms.aggr_visits
  USING staging_aggr_visits2 s
  WHERE forms.aggr_visits.id = s.id;

  INSERT INTO forms.aggr_visits (
    id,
    ip_address,
    aid,
    cid,
    sid,
    ks,
    created_at,
    updated_at,
    cost,
    uid,
    referrer,
    lead_type_id,
    device_type,
    landing_page,
    click_id,
    gclid,
    full_url,
    started,
    submitted,
    qualified,
    state,
    zip,
    tid,
    qualified_lead,
    lead_revenue,
    total_ad_clicks,
    ad_click_revenue,
    total_quote_clicks,
    quote_click_revenue,
    total_calls,
    call_revenue,
    affiliate_cost,
    refunded,
    refunded_amount,
    form_version_id,
    bad_lead,
    raw_lead_id,
    lead_id,
    sub1,
    manager_id,
    duplicate,
    cost_adj,
    prefill_perc,
    prefill_missing_data,
    domain,
    max_call_duration,
    unity_revenue,
    home_bundle,
    quoted,
    policy,
    consumer_dob,
    consumer_age,
    continuous_insurance,
    gender,
    marital_status,
    education,
    credit_rating,
    license_status,
    pub_name,
    pub_company,
    budget,
    budget_pacing,
    manager,
    source_type,
    marketing_group_name,
    anura,
    call_disposition,
    bad_lead_desc,
    cc_rev,
    pst_day,
    pst_week,
    pst_month,
    pst_quarter,
    pst_year,
    pst_weekday,
    est_day,
    est_week,
    est_month,
    est_quarter,
    est_year,
    est_weekday,
    commercial_type,
    source_type_id,
    tof,
    time_on_form,
    insured,
    home_owner,
    military_affiliation,
    violations,
    accidents,
    dui,
    marketing_group_id,
    num_drivers,
    num_vehicles,
    syndi_click,
    rev_share,
    bad_dispo,
    cc_accepted,
    cc_connected,
    cc_inbound,
    rep_connected,
    cc_call_duration,
    pst_hour,
    est_hour,
    naics_code,
    property_type,
    square_footage,
    number_of_stories,
    year_built,
    tobacco,
    health_conditions,
    household_income,
    years_in_business,
    full_time_employees,
    part_time_employees,
    business_revenue,
    plan_type,
    num_employees,
    requested_coverage
  )
  SELECT
    id,
    ip_address,
    aid,
    cid,
    sid,
    ks,
    created_at,
    updated_at,
    cost,
    uid,
    referrer,
    lead_type_id,
    device_type,
    landing_page,
    click_id,
    gclid,
    full_url,
    started,
    submitted,
    qualified,
    state,
    zip,
    tid,
    qualified_lead,
    lead_revenue,
    total_ad_clicks,
    ad_click_revenue,
    total_quote_clicks,
    quote_click_revenue,
    total_calls,
    call_revenue,
    affiliate_cost,
    refunded,
    refunded_amount,
    form_version_id,
    bad_lead,
    raw_lead_id,
    lead_id,
    sub1,
    manager_id,
    duplicate,
    cost_adj,
    prefill_perc,
    prefill_missing_data,
    domain,
    max_call_duration,
    unity_revenue,
    home_bundle,
    quoted,
    policy,
    consumer_dob,
    consumer_age,
    continuous_insurance,
    gender,
    marital_status,
    education,
    credit_rating,
    license_status,
    pub_name,
    pub_company,
    budget,
    budget_pacing,
    manager,
    source_type,
    marketing_group_name,
    anura,
    call_disposition,
    bad_lead_desc,
    cc_rev,
    pst_day,
    pst_week,
    pst_month,
    pst_quarter,
    pst_year,
    pst_weekday,
    est_day,
    est_week,
    est_month,
    est_quarter,
    est_year,
    est_weekday,
    commercial_type,
    source_type_id,
    tof,
    time_on_form,
    insured,
    home_owner,
    military_affiliation,
    violations,
    accidents,
    dui,
    marketing_group_id,
    num_drivers,
    num_vehicles,
    syndi_click,
    rev_share,
    bad_dispo,
    cc_accepted,
    cc_connected,
    cc_inbound,
    rep_connected,
    cc_call_duration,
    pst_hour,
    est_hour,
    naics_code,
    property_type,
    square_footage,
    number_of_stories,
    year_built,
    tobacco,
    health_conditions,
    household_income,
    years_in_business,
    full_time_employees,
    part_time_employees,
    business_revenue,
    plan_type,
    num_employees,
    requested_coverage
  FROM staging_aggr_visits2;

  DROP TABLE IF EXISTS staging_aggr_visits2;
END;
$$
