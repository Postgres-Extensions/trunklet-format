-- Note: pgTap is loaded by setup.sql

-- Add any test dependency statements here
--CREATE EXTENSION IF NOT EXISTS trunklet;
-- Terse around statements that create extensions: verbose output adds a LOCATION line
-- (pl_exec.c line number, varies by PostgreSQL version) to extension_drop's deprecation warning
\set saved_verbosity :VERBOSITY
\set VERBOSITY terse
DO $$ BEGIN
  IF current_setting('server_version_num')::int < 100000 THEN
    CREATE EXTENSION IF NOT EXISTS cat_tools;
    CREATE EXTENSION IF NOT EXISTS trunklet;
    CREATE EXTENSION IF NOT EXISTS extension_drop;
  END IF;
END$$;
\set VERBOSITY :saved_verbosity

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

