CREATE TABLE dba_monitoring.redshift_scheduled_query_execution_history_7 (
    execution_id character varying(100) NOT NULL ENCODE lzo COLLATE case_sensitive,
    schedule_id bigint ENCODE az64,
    schedule_name character varying(255) ENCODE lzo COLLATE case_sensitive,
    query_id bigint ENCODE az64,
    status character varying(30) ENCODE lzo COLLATE case_sensitive,
    start_time timestamp without time zone ENCODE az64,
    end_time timestamp without time zone ENCODE az64,
    duration_seconds integer ENCODE az64,
    rows_processed bigint ENCODE az64,
    refresh_timestamp timestamp without time zone ENCODE az64,
    error_message character varying(65535) ENCODE lzo COLLATE case_sensitive,
    collected_at timestamp without time zone DEFAULT getdate() ENCODE az64,
    current_step character varying(255) ENCODE lzo COLLATE case_sensitive,
    failed_step character varying(255) ENCODE lzo COLLATE case_sensitive,
    completed_steps integer ENCODE az64,
    current_step_order integer ENCODE az64,
    failed_step_order integer ENCODE az64,
    run_id character varying(150) ENCODE lzo COLLATE case_sensitive
)
DISTSTYLE AUTO
SORTKEY ( end_time );	
