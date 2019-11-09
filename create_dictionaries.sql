-- SEQUENCE: logger.dictionaries_id_seq

-- DROP SEQUENCE logger.dictionaries_id_seq;

CREATE SEQUENCE logger.dictionaries_id_seq
    INCREMENT 1
    START 19
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE logger.dictionaries_id_seq
    OWNER TO postgres;


/*
    Creating logger.dictionaries containing list of non-spatial tables.
*/

-- Table: logger.dictionaries

-- DROP TABLE logger.dictionaries;

CREATE TABLE logger.dictionaries
(
    id integer NOT NULL DEFAULT nextval('logger.dictionaries_id_seq'::regclass),
    schema_name text COLLATE pg_catalog."default" NOT NULL,
    table_name text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT dictionaries_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE logger.dictionaries
    OWNER to postgres;
COMMENT ON TABLE logger.dictionaries
    IS 'Справочники для учета в QConsole';