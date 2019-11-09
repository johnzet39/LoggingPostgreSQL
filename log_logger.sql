/*
    Trigger function log_logger. Creates row in the logtable
    containing information about operations and writes
    changes of attributes to field "result_context".
    Allows to save old geometry of item.
*/


-- FUNCTION: logger.log_logger()

-- DROP FUNCTION logger.log_logger();

CREATE OR REPLACE FUNCTION logger.log_logger()
  RETURNS trigger AS
$BODY$

/* 
Элементарный аудит изменений атрибутов таблицы
(current_query() - текущий запрос)
*/

DECLARE
Cur1 CURSOR FOR select column_name from information_schema.columns where table_name=TG_TABLE_NAME and table_schema=TG_TABLE_SCHEMA and column_name not in ('geom_polygon', 'geom_line', 'geom_point', 'geom', 'X_COORD', 'Y_COORD', 'RECNO', 'AREA', 'PERIMETER');

strSQL varchar(5000);
result_context VARCHAR(5000);   
type_geom VARCHAR(20);
geom_column VARCHAR(20);
old_val varchar(2000);
new_val varchar(2000);

BEGIN

    
    execute 'SELECT 1 from geometry_columns gc where gc.f_table_schema = '''|| TG_TABLE_SCHEMA || ''' and  gc.f_table_name = '''|| TG_TABLE_NAME || ''' limit 1' into geom_column;

    -- если таблица без графики
    IF geom_column is NULL THEN

        result_context := '';
        
        -- СОБЫТИЕ УДАЛЕНИЯ
        IF TG_OP = 'DELETE' THEN

            FOR col in Cur1 LOOP
                EXECUTE 'SELECT $1."'|| col.column_name || '"::text' INTO old_val USING OLD;
                IF LENGTH(old_val) > 0 THEN
                    result_context := result_context || '[' || col.column_name || ']: ' || COALESCE(old_val, '') || '; ';
                END IF;
            END LOOP;

            INSERT INTO logger.logtable(username,    address,           timechange,             tableschema,       tablename,    action, context,           gidnum) VALUES 
                                           (session_user,inet_client_addr(),current_timestamp,  TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP,  result_context, OLD.id);
            RETURN OLD;
                
        -- СОБЫТИЕ ОБНОВЛЕНИЯ
        ELSIF TG_OP = 'UPDATE' THEN

            -- формируем строку из измененных атрибутов со старыми и новыми значениями
            FOR col in Cur1 LOOP
                EXECUTE 'SELECT $1."'|| col.column_name || '"::text' INTO new_val USING NEW;
                EXECUTE 'SELECT $1."'|| col.column_name || '"::text' INTO old_val USING OLD;
                IF COALESCE(old_val, '') <> COALESCE(new_val, '') THEN
                    result_context := result_context || '[' || col.column_name || ']: ' || COALESCE(old_val, '') || ' --> ' || COALESCE(new_val, '') || '; ';
                END IF;
            END LOOP;

            INSERT INTO logger.logtable(username,    address,           timechange,             tableschema,       tablename,    action, context,        gidnum) VALUES 
                                           (session_user,inet_client_addr(),current_timestamp,  TG_TABLE_SCHEMA,TG_TABLE_NAME,TG_OP,  result_context, OLD.id);
            RETURN NEW;
                
        -- СОБЫТИЕ ВСТАВКИ
        ELSIF TG_OP = 'INSERT' THEN

            FOR col in Cur1 LOOP
                EXECUTE 'SELECT $1."'|| col.column_name || '"::text' INTO new_val USING NEW;
                IF LENGTH(new_val) > 0 THEN
                    result_context := result_context || '[' || col.column_name || ']: ' || COALESCE(new_val, '') || '; ';
                END IF;
            END LOOP;

            INSERT INTO logger.logtable(username,    address,           timechange,             tableschema,       tablename,    action, context,        gidnum) VALUES 
                                           (session_user,inet_client_addr(),current_timestamp,  TG_TABLE_SCHEMA,TG_TABLE_NAME,TG_OP,  result_context,  NEW.id);
            RETURN NEW;
        END IF;

    -- если таблица с графикой
    ELSE
    
        -- СОБЫТИЕ УДАЛЕНИЯ
        IF TG_OP = 'DELETE' THEN

            type_geom = ST_GeometryType(OLD.geom);
            
            -- формируем строку из всех атрибутов
            result_context := '';
            FOR col in Cur1 LOOP
                EXECUTE 'SELECT $1."'|| col.column_name || '"::text' INTO old_val USING OLD;
                IF LENGTH(old_val) > 0 THEN
                    result_context := result_context || '[' || col.column_name || ']: ' || COALESCE(old_val, '') || '; ';
                END IF;
            END LOOP;

            IF type_geom = 'ST_MultiLineString' or type_geom = 'ST_LineString' THEN 
                INSERT INTO logger.logtable(username,    address,           timechange,             tableschema,       tablename,    action,                 context, geom_line,          gidnum) VALUES 
                                           (session_user,inet_client_addr(),current_timestamp,      TG_TABLE_SCHEMA,   TG_TABLE_NAME,TG_OP,  result_context, ST_Multi(OLD.geom), OLD.gid);
                RETURN OLD;

            ELSIF type_geom = 'ST_MultiPolygon' or type_geom = 'ST_Polygon' THEN 
                INSERT INTO logger.logtable(username,    address,           timechange,             tableschema,       tablename,    action,                 context, geom_polygon,       gidnum) VALUES 
                                           (session_user,inet_client_addr(),current_timestamp,      TG_TABLE_SCHEMA,   TG_TABLE_NAME,TG_OP,  result_context, ST_Multi(OLD.geom), OLD.gid);
                RETURN OLD;

            ELSIF type_geom = 'ST_MultiPoint' or type_geom = 'ST_Point' THEN 
                INSERT INTO logger.logtable(username,    address,           timechange,             tableschema,       tablename,    action, context,        geom_point,         gidnum) VALUES 
                                           (session_user,inet_client_addr(),current_timestamp,      TG_TABLE_SCHEMA,   TG_TABLE_NAME,TG_OP,  result_context, ST_Multi(OLD.geom), OLD.gid);
                RETURN OLD;

            END IF; 

        -- СОБЫТИЕ ОБНОВЛЕНИЯ
        ELSIF TG_OP = 'UPDATE' THEN

            result_context := '';
            type_geom = ST_GeometryType(OLD.geom);

            -- если изменялась геометрия
            IF NOT st_equals(NEW.geom, OLD.geom) THEN
                result_context := result_context || 'Изменена геометрия; ';
            END IF;

            -- формируем строку из измененных атрибутов со старыми и новыми значениями
            FOR col in Cur1 LOOP
                EXECUTE 'SELECT $1."'|| col.column_name || '"::text' INTO new_val USING NEW;
                EXECUTE 'SELECT $1."'|| col.column_name || '"::text' INTO old_val USING OLD;
                IF COALESCE(old_val, '') <> COALESCE(new_val, '') THEN
                    result_context := result_context || '[' || col.column_name || ']: ' || COALESCE(old_val, '') || ' --> ' || COALESCE(new_val, '') || '; ';
                END IF;
            END LOOP;

            IF type_geom = 'ST_MultiLineString' or type_geom = 'ST_LineString' THEN 
                INSERT INTO logger.logtable(username,    address,           timechange,             tableschema,       tablename,    action, context,        geom_line,          gidnum) VALUES 
                                           (session_user,inet_client_addr(),current_timestamp,      TG_TABLE_SCHEMA,   TG_TABLE_NAME,TG_OP,  result_context, ST_Multi(OLD.geom), OLD.gid);
                RETURN NEW;

            ELSIF type_geom = 'ST_MultiPolygon' or type_geom = 'ST_Polygon' THEN 
                INSERT INTO logger.logtable(username,    address,           timechange,             tableschema,       tablename,    action, context,        geom_polygon,       gidnum) VALUES 
                                           (session_user,inet_client_addr(),current_timestamp,      TG_TABLE_SCHEMA,   TG_TABLE_NAME,TG_OP,  result_context, ST_Multi(OLD.geom), OLD.gid);
                RETURN NEW;

            ELSIF type_geom = 'ST_MultiPoint' or type_geom = 'ST_Point' THEN 
                INSERT INTO logger.logtable(username,    address,           timechange,             tableschema,       tablename,    action, context,        geom_point,         gidnum) VALUES 
                                           (session_user,inet_client_addr(),current_timestamp,      TG_TABLE_SCHEMA,   TG_TABLE_NAME,TG_OP,  result_context, ST_Multi(OLD.geom), OLD.gid);
                RETURN NEW;

            END IF;

        -- СОБЫТИЕ ВСТАВКИ
        ELSIF TG_OP = 'INSERT' THEN
        
            type_geom = ST_GeometryType(NEW.geom);

            result_context := '';
            FOR col in Cur1 LOOP
                EXECUTE 'SELECT $1."'|| col.column_name || '"::text' INTO new_val USING NEW;
                IF LENGTH(new_val) > 0 THEN
                    result_context := result_context || '[' || col.column_name || ']: ' || COALESCE(new_val, '') || '; ';
                END IF;
            END LOOP;

            IF type_geom = 'ST_MultiLineString' or type_geom = 'ST_LineString' THEN 
                INSERT INTO logger.logtable(username,    address,           timechange,             tableschema,       tablename,    action, context,        geom_line,          gidnum) VALUES 
                                           (session_user,inet_client_addr(),current_timestamp,      TG_TABLE_SCHEMA,   TG_TABLE_NAME,TG_OP,  result_context, ST_Multi(NEW.geom), NEW.gid);
                RETURN NEW;

            ELSIF type_geom = 'ST_MultiPolygon' or type_geom = 'ST_Polygon' THEN 
                INSERT INTO logger.logtable(username,    address,           timechange,             tableschema,       tablename,    action, context,        geom_polygon,       gidnum) VALUES 
                                           (session_user,inet_client_addr(),current_timestamp,      TG_TABLE_SCHEMA,   TG_TABLE_NAME,TG_OP,  result_context, ST_Multi(NEW.geom), NEW.gid);
                RETURN NEW;

            ELSIF type_geom = 'ST_MultiPoint' or type_geom = 'ST_Point' THEN 
                INSERT INTO logger.logtable(username,    address,           timechange,             tableschema,       tablename,    action, context,        geom_point,         gidnum) VALUES 
                                           (session_user,inet_client_addr(),current_timestamp,      TG_TABLE_SCHEMA,   TG_TABLE_NAME,TG_OP,  result_context, ST_Multi(NEW.geom), NEW.gid);
                RETURN NEW;

            END IF;

        END IF;

    END IF;

    RETURN NULL;

EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;

END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION logger.log_logger()
  OWNER TO postgres;