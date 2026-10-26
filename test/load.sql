\i test/deps.sql

\set saved_verbosity :VERBOSITY
\set VERBOSITY terse
SELECT pg_temp._create();
\set VERBOSITY :saved_verbosity

-- BUG: someone is screwing up the search path...
SET search_path = public, tap;
