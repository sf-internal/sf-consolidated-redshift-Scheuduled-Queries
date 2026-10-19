-- One-time DDL for the call rollup tables built from call_tracking.aggr_call_logs.
-- Run before deploying the refresh procedures.

CREATE TABLE call_tracking.pub_aggr_call_stats (
    pst_day date ENCODE raw,
    pst_week date ENCODE az64,
    pst_month date ENCODE az64,
    pst_quarter date ENCODE az64,
    pst_year date ENCODE az64,
    pst_weekday integer ENCODE az64,
    aff_portal_id integer ENCODE raw,
    affiliate_id integer ENCODE raw,
    lead_type_id integer ENCODE raw,
    manager_id integer ENCODE az64,
    source_type character varying(765) ENCODE bytedict,
    marketing_group character varying(765) ENCODE bytedict,
    aff_type integer ENCODE az64,
    cc_reviewed smallint ENCODE az64,
    total_calls integer ENCODE az64,
    total_transfers integer ENCODE az64,
    total_transfers_qualified integer ENCODE az64,
    total_cost numeric(20,2) ENCODE az64,
    total_revenue numeric(20,2) ENCODE az64,
    total_calls_reviewed integer ENCODE az64,
    total_refunded integer ENCODE az64,
    total_errors integer ENCODE az64,
    transfer_duration_sum bigint ENCODE az64,
    transfer_duration_count integer ENCODE az64,
    duration_sum bigint ENCODE az64,
    duration_count integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( pst_day, aff_portal_id, affiliate_id, lead_type_id );

CREATE TABLE call_tracking.pub_aggr_call_state_stats (
    pst_day date ENCODE raw,
    pst_week date ENCODE az64,
    pst_month date ENCODE az64,
    pst_quarter date ENCODE az64,
    pst_year date ENCODE az64,
    pst_weekday integer ENCODE az64,
    aff_portal_id integer ENCODE raw,
    affiliate_id integer ENCODE raw,
    lead_type_id integer ENCODE raw,
    manager_id integer ENCODE az64,
    source_type character varying(765) ENCODE bytedict,
    marketing_group character varying(765) ENCODE bytedict,
    aff_type integer ENCODE az64,
    cc_reviewed smallint ENCODE az64,
    state character varying(765) ENCODE bytedict,
    total_calls integer ENCODE az64,
    total_transfers integer ENCODE az64,
    total_transfers_qualified integer ENCODE az64,
    total_cost numeric(20,2) ENCODE az64,
    total_revenue numeric(20,2) ENCODE az64,
    total_calls_reviewed integer ENCODE az64,
    total_refunded integer ENCODE az64,
    total_errors integer ENCODE az64,
    transfer_duration_sum bigint ENCODE az64,
    transfer_duration_count integer ENCODE az64,
    duration_sum bigint ENCODE az64,
    duration_count integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( pst_day, aff_portal_id, affiliate_id, lead_type_id );

CREATE TABLE call_tracking.graph_aggr_call_stats (
    pst_hour integer ENCODE az64,
    pst_day date ENCODE raw,
    pst_week date ENCODE az64,
    pst_month date ENCODE az64,
    pst_quarter date ENCODE az64,
    pst_year date ENCODE az64,
    pst_weekday integer ENCODE az64,
    aff_portal_id integer ENCODE raw,
    affiliate_id integer ENCODE raw,
    lead_type_id integer ENCODE raw,
    manager_id integer ENCODE az64,
    source_type character varying(765) ENCODE bytedict,
    marketing_group character varying(765) ENCODE bytedict,
    aff_type integer ENCODE az64,
    cc_reviewed smallint ENCODE az64,
    total_calls integer ENCODE az64,
    total_transfers integer ENCODE az64,
    total_transfers_qualified integer ENCODE az64,
    total_cost numeric(20,2) ENCODE az64,
    total_revenue numeric(20,2) ENCODE az64,
    total_calls_reviewed integer ENCODE az64,
    total_refunded integer ENCODE az64,
    total_errors integer ENCODE az64,
    transfer_duration_sum bigint ENCODE az64,
    transfer_duration_count integer ENCODE az64,
    duration_sum bigint ENCODE az64,
    duration_count integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( pst_day, aff_portal_id, affiliate_id, lead_type_id );
