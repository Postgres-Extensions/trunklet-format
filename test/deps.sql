-- Note: pgTap is loaded by setup.sql

-- Add any test dependency statements here
--CREATE EXTENSION IF NOT EXISTS trunklet;

-- Have to reset our search_path
--SET search_path = public,tap;

CREATE OR REPLACE FUNCTION pg_temp._create() RETURNS void LANGUAGE plpgsql
SET client_min_messages = WARNING -- Necessary due to CASCADE
AS $body$
DECLARE
  c_mode CONSTANT text := current_setting('trunklet_format.test_load_mode'); -- Set by the Makefile
BEGIN
-- No IF NOT EXISTS because we'll be confused if we're not loading the new stuff
  IF c_mode = 'fresh' THEN
    CREATE EXTENSION "trunklet-format" CASCADE;
  ELSIF c_mode = 'update' THEN
    -- 0.2.0 did not require extension_drop, so updating from it needs it created first
    CREATE EXTENSION IF NOT EXISTS extension_drop CASCADE;
    EXECUTE format(
      'CREATE EXTENSION "trunklet-format" VERSION %L CASCADE'
      , current_setting('trunklet_format.test_update_from')
    );
    ALTER EXTENSION "trunklet-format" UPDATE;
    IF (SELECT extversion FROM pg_extension WHERE extname = 'trunklet-format')
        IS DISTINCT FROM (SELECT default_version FROM pg_available_extensions WHERE name = 'trunklet-format')
    THEN
      RAISE EXCEPTION 'ALTER EXTENSION UPDATE did not reach the default version';
    END IF;
  ELSE
    RAISE EXCEPTION 'unknown trunklet_format.test_load_mode "%"', c_mode;
  END IF;
END
$body$;

