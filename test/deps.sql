-- Note: pgTap is loaded by setup.sql

-- Add any test dependency statements here
--CREATE EXTENSION IF NOT EXISTS trunklet;

-- Have to reset our search_path
--SET search_path = public,tap;

CREATE OR REPLACE FUNCTION pg_temp._create() RETURNS void LANGUAGE plpgsql
SET client_min_messages = WARNING -- Necessary due to CASCADE
AS $body$
BEGIN
-- No IF NOT EXISTS because we'll be confused if we're not loading the new stuff
  CREATE EXTENSION "trunklet-format" CASCADE;
END
$body$;

