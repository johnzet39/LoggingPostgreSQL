/*
    Trigger function logger.log_update().
    Writes information about the user who made the change to current row
    and date of the change.

*/

-- FUNCTION: logger.log_update()

-- DROP FUNCTION logger.log_update();

CREATE FUNCTION logger.log_update()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF 
AS $BODY$
BEGIN
NEW.update_username:=session_user;    
NEW.update_address:=inet_client_addr(); 
NEW.update_time:=current_timestamp; 
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION logger.log_update()
    OWNER TO postgres;