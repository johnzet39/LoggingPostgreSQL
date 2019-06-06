-- SCHEMA: schema_spr

-- DROP SCHEMA schema_spr ;

CREATE SCHEMA schema_spr
    AUTHORIZATION postgres;

GRANT ALL ON SCHEMA schema_spr TO postgres;

GRANT USAGE ON SCHEMA schema_spr TO PUBLIC;


-- SEQUENCE: schema_spr.dictionaries_id_seq

-- DROP SEQUENCE schema_spr.dictionaries_id_seq;

CREATE SEQUENCE schema_spr.dictionaries_id_seq
    INCREMENT 1
    START 19
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE schema_spr.dictionaries_id_seq
    OWNER TO postgres;


/*
    Creating schema_spr.dictionaries containing list of non-spatial tables.
*/

-- Table: schema_spr.dictionaries

-- DROP TABLE schema_spr.dictionaries;

CREATE TABLE schema_spr.dictionaries
(
    id integer NOT NULL DEFAULT nextval('schema_spr.dictionaries_id_seq'::regclass),
    schema_name text COLLATE pg_catalog."default" NOT NULL,
    table_name text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT dictionaries_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE schema_spr.dictionaries
    OWNER to postgres;
COMMENT ON TABLE schema_spr.dictionaries
    IS 'Справочники для учета в QConsole';