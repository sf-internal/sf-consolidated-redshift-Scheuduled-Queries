CREATE TABLE dba_monitoring.redshift_scheduled_query_steps (
    schedule_id bigint NOT NULL ENCODE az64,
    step_order integer NOT NULL ENCODE az64,
    step_name character varying(255) NOT NULL ENCODE lzo COLLATE case_sensitive,
    sql_statement character varying(65535) NOT NULL ENCODE lzo COLLATE case_sensitive,
    enabled boolean DEFAULT true ENCODE raw,
    created_at timestamp without time zone DEFAULT getdate() ENCODE az64,
    updated_at timestamp without time zone DEFAULT getdate() ENCODE az64
)
DISTSTYLE AUTO;	
