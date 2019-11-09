/*
    Creating the schema "logger"
    containing them main table "logtable"
*/

-- SCHEMA: logger

-- DROP SCHEMA logger ;

CREATE SCHEMA logger
    AUTHORIZATION postgres;

GRANT ALL ON SCHEMA logger TO postgres;
GRANT ALL ON SCHEMA logger TO PUBLIC;



/*
    Creating the main table "logtable"
    containing all change data
*/

-- Table: logger.logtable

-- DROP TABLE logger.logtable;

CREATE TABLE logger.logtable
(
  gid integer NOT NULL DEFAULT nextval('logger.logtable_gid_seq'::regclass),
  action text NOT NULL,
  username text NOT NULL,
  address text NOT NULL,
  timechange timestamp without time zone NOT NULL,
  tablename text NOT NULL,
  context text,
  geom_polygon geometry,
  geom_line geometry,
  geom_point geometry,
  gidnum integer,
  query text,
  tableschema text,
  CONSTRAINT logger_edit_pkey1 PRIMARY KEY (gid)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE logger.logtable
    OWNER to postgres;

GRANT ALL ON TABLE logger.logtable TO postgres;

GRANT INSERT, SELECT, TRUNCATE, REFERENCES, TRIGGER ON TABLE logger.logtable TO PUBLIC;