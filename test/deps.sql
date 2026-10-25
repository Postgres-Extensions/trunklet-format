-- Note: pgTap is loaded by setup.sql

-- Terse: verbose output adds a LOCATION line (pl_exec.c line number) to trunklet's
-- deprecation warning when the extension loads, which differs between PostgreSQL versions
\set VERBOSITY terse

-- Add any test dependency statements here
--CREATE EXTENSION IF NOT EXISTS trunklet;
DO $$ BEGIN
  IF current_setting('server_version_num')::int < 100000 THEN
    CREATE EXTENSION IF NOT EXISTS cat_tools;
    CREATE EXTENSION IF NOT EXISTS trunklet;
    CREATE EXTENSION IF NOT EXISTS extension_drop;
  END IF;
END$$;

-- Have to reset our search_path
--SET search_path = public,tap;

CREATE OR REPLACE FUNCTION pg_temp._create() RETURNS void LANGUAGE plpgsql
SET client_min_messages = WARNING -- Necessary due to CASCADE
AS $body$
BEGIN
-- No IF NOT EXISTS because we'll be confused if we're not loading the new stuff
  IF current_setting('server_version_num')::int < 100000 THEN
    CREATE EXTENSION "trunklet-format" ;
  ELSE
    EXECUTE $exec$CREATE EXTENSION "trunklet-format" CASCADE$exec$;
  END IF;
END
$body$;

