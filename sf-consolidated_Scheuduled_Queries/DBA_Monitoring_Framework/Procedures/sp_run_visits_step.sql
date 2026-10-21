CREATE OR REPLACE PROCEDURE dba_monitoring.sp_run_visits_step(p_schedule_id bigint, p_step_order integer)
 LANGUAGE plpgsql
AS $$
DECLARE
    v_run_id VARCHAR(150);
    v_execution_id VARCHAR(200);
    v_schedule_name VARCHAR(255);
    v_step_name VARCHAR(255);
    v_sql_statement VARCHAR(65535);
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
BEGIN
    -- Reject mismatched schedules before executing any business SQL.
    IF p_schedule_id IS NULL OR p_schedule_id <> 5 THEN
        RAISE EXCEPTION 'sp_run_visits_step allows only schedule_id 5; received %', p_schedule_id;
    END IF;

    SELECT schedule_name INTO v_schedule_name
    FROM dba_monitoring.redshift_scheduled_query_config
    WHERE schedule_id = p_schedule_id
      AND schedule_state = 'Enabled'
      AND monitoring_required = TRUE
      AND execution_mode = 'GENERIC_WRAPPER';

    IF v_schedule_name IS NULL THEN
        RAISE EXCEPTION 'Schedule ID % is not enabled/configured for GENERIC_WRAPPER execution', p_schedule_id;
    END IF;

    SELECT step_name, sql_statement INTO v_step_name, v_sql_statement
    FROM dba_monitoring.redshift_scheduled_query_steps
    WHERE schedule_id = p_schedule_id
      AND step_order = p_step_order
      AND enabled = TRUE;

    IF v_step_name IS NULL THEN
        RAISE EXCEPTION 'No enabled step found for schedule_id %, step_order %', p_schedule_id, p_step_order;
    END IF;

    SELECT GETDATE() INTO v_start_time;
    v_run_id = 'S' || p_schedule_id::VARCHAR
        || '-STEP' || p_step_order::VARCHAR
        || '-' || TO_CHAR(v_start_time, 'YYYYMMDDHH24MISS')
        || '-' || PG_BACKEND_PID()::VARCHAR;
    v_execution_id = v_run_id || '-EXEC';

    BEGIN
        EXECUTE v_sql_statement;
        SELECT GETDATE() INTO v_end_time;

        INSERT INTO dba_monitoring.redshift_scheduled_query_execution_history_5
            (run_id, execution_id, schedule_id, schedule_name, status,
             start_time, end_time, duration_seconds, completed_steps,
             error_message, collected_at)
        VALUES
            (v_run_id, v_execution_id, p_schedule_id, v_schedule_name,
             'SUCCESS', v_start_time, v_end_time,
             DATEDIFF(second, v_start_time, v_end_time), 1, NULL, v_end_time);

    EXCEPTION WHEN OTHERS THEN
        SELECT GETDATE() INTO v_end_time;
        INSERT INTO dba_monitoring.redshift_scheduled_query_execution_history_5
            (run_id, execution_id, schedule_id, schedule_name, status,
             failed_step, failed_step_order, start_time, end_time,
             duration_seconds, completed_steps, error_message, collected_at)
        VALUES
            (v_run_id, v_execution_id, p_schedule_id, v_schedule_name,
             'FAILED', v_step_name, p_step_order, v_start_time, v_end_time,
             DATEDIFF(second, v_start_time, v_end_time), 0, SQLERRM, v_end_time);
    END;
END;
$$
	
