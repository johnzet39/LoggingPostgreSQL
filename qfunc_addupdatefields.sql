/*
    Function qfunc_addupdatefields. Adds columns to table for writing
    username that had changed current row, his ipaddres, date of changing.
    Creates trigger intended to write information to columns with trigger
    procedure public.log_update().
*/

-- FUNCTION: public.qfunc_addupdatefields(character varying, character varying, boolean)

-- DROP FUNCTION public.qfunc_addupdatefields(character varying, character varying, boolean);

CREATE OR REPLACE FUNCTION public.qfunc_addupdatefields(
	schema_name character varying,
	table_name character varying,
	status boolean)
    RETURNS void
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$


BEGIN
    CASE 
        WHEN status = TRUE THEN
        
            BEGIN
                EXECUTE
                    'ALTER TABLE '||$1||'.'||$2||' ADD COLUMN update_username CHAR(30);
                    ALTER TABLE '||$1||'.'||$2||' ADD COLUMN update_address CHAR(30);
                    ALTER TABLE '||$1||'.'||$2||' ADD COLUMN update_time TIMESTAMP WITHOUT TIME ZONE;';
            EXCEPTION
                WHEN duplicate_column THEN
                    NULL;
            END;

            EXECUTE 'DROP TRIGGER IF EXISTS '||$2||'_log_update_trigger ON '||$1||'.'||$2||';';

            EXECUTE
                'CREATE TRIGGER '||$2||'_log_update_trigger
                  BEFORE INSERT OR UPDATE
                  ON '||$1||'.'||$2||'
                  FOR EACH ROW
                  EXECUTE PROCEDURE public.log_update();';
 
        WHEN status = FALSE THEN
            EXECUTE 'DROP TRIGGER IF EXISTS '||$2||'_log_update_trigger ON '||$1||'.'||$2||';';

    END CASE;
    

END;


$BODY$;

ALTER FUNCTION public.qfunc_addupdatefields(character varying, character varying, boolean)
    OWNER TO postgres;