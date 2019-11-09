/*
    Function qfunc_loglogger. Creates trigger 
    intended to write changes in a table to logger.logtable
    with trigger procedure logger.log_logger()
*/

-- FUNCTION: logger.qfunc_loglogger(character varying, character varying, boolean)

-- DROP FUNCTION logger.qfunc_loglogger(character varying, character varying, boolean);

CREATE OR REPLACE FUNCTION logger.qfunc_loglogger(
	schema_name character varying,
	table_name character varying,
	status boolean)
    RETURNS void
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$BEGIN
    CASE 
        WHEN status = TRUE THEN
        
            EXECUTE 'DROP TRIGGER IF EXISTS '||$2||'_log_logger_trigger ON '||$1||'.'||$2||';';

            EXECUTE
                'CREATE TRIGGER '||$2||'_log_logger_trigger
                  AFTER INSERT OR DELETE OR UPDATE 
                  ON '||$1||'.'||$2||'
                  FOR EACH ROW
                  EXECUTE PROCEDURE logger.log_logger();';

        WHEN status = FALSE THEN
            EXECUTE 'DROP TRIGGER IF EXISTS '||$2||'_log_logger_trigger ON '||$1||'.'||$2||';';

    END CASE;

END;

$BODY$;

ALTER FUNCTION logger.qfunc_loglogger(character varying, character varying, boolean)
    OWNER TO postgres;