\set ECHO none
\i test/pgxntool/setup.sql
\i test/load.sql

/*
CREATE TABLE process(
  template text
  , parameter jsonb
  , result text
);
*/

-- Protect against infinite loops
SET statement_timeout = '2 s';
SELECT no_plan();
SELECT is(
  trunklet.process_language(
    'format'
    , text $$No parameters.$$
    , NULL::jsonb
  )
  , $$No parameters.$$
);
SELECT is(
  trunklet.process_language(
    'format'
    , text $$No parameters.$$
    , jsonb $${"Moo": "cow"}$$
  )
  , $$No parameters.$$
);

SELECT is(
  trunklet.process_language(
    'format'
    , text $$%nope%OLx%nope2%Os$$
    , NULL::jsonb
  )
  , 'NULLx'
  , $$Optional parameter.$$
);
SELECT is(
  trunklet.process_language(
    'format'
    , text $$%nope%OLx%nope2%Os$$
    , jsonb $${"Moo": "cow"}$$
  )
  , 'NULLx'
  , $$Optional parameter.$$
);

SELECT is(
  trunklet.process_language(
    'format'
    , text $$A %test%s test.$$
    , jsonb $${
        "test": "simple"
      }$$
  )
  , $$A simple test.$$
);

SELECT is(
  trunklet.process_language(
    'format'
    , text $$%% 1 %% 2 %%$$
    , jsonb $${"Moo": "cow"}$$
  )
  , $$% 1 % 2 %$$
);
SELECT is(
  trunklet.process_language(
    'format'
    , text $$%%%Moo%s%%%Moo%L%%%Moo%I%%$$
    , jsonb $${"Moo": "says cow"}$$
  )
  , $$%says cow%'says cow'%"says cow"%$$
);

SELECT is(
  trunklet.process_language(
    'format'
    , $$%start%s%middle%s%end%s$$::text
    , jsonb $${
        "start": "This is the start.\n",
        "middle": "This is the middle.\n",
        "end": "This is the end.\n"
      }$$
  )
  , $$This is the start.
This is the middle.
This is the end.
$$
);

SELECT is(
      trunklet.process_language(
        'format'
        , replace(
          $$%opt%OR%value%R%opt%OR%value%R$$
          , 'R'
          , replace
        )
        , j
      )
      , repeat( format(
        replace( '%R%R', 'R', replace )
        , NULL
        , j->>'value'
      ), 2 )
      , format( 'test optional handling with %s and %s', replace, j->>'value' )
    )
  FROM (
    SELECT replace, json_build_object('value', value) AS j
      FROM unnest('{s,L}'::text[]) WITH ORDINALITY r(replace, rn)
        , unnest(array[to_json(1.1), to_json(NULL::int), to_json('text'::text), to_json(true)])
            WITH ORDINALITY v(value, vn)
      -- Ensure consistent ordering against planner changes
      ORDER BY rn, vn
  ) optional_test
;

SELECT throws_ok(
  $$SELECT trunklet.process_language( 'format', 'some stuff%test parameter%OIsome more stuff', NULL::json )$$
  , '22004' -- null_value_not_allowed
  , 'SQL identifier format option ("I") not allowed with optional parameters'
);
-- Disabled check that the DETAIL is correct
/*
SAVEPOINT a;
\unset ON_ERROR_STOP
\set VERBOSITY default
\echo THIS ERROR IS OK!
SELECT 'DETAIL:  parameter "test parameter" at template position ' || strpos( 'some stuff%test parameter%OIsome more stuff', '%' );
SELECT trunklet.process_language( 'format', 'some stuff%test parameter%OIsome more stuff', NULL::json );
ROLLBACK TO a;
\set ON_ERROR_STOP 1
\set VERBOSITY VERBOSE
*/

SELECT throws_ok(
    format(
      $$SELECT trunklet.process_language( 'format', %L::text, %L::jsonb )$$
      , '%Moo%' || optional || specifier
      , '{"Moo":1}'
    )
    , format(
      'Unexpected character "%s" in format specifier "%s"'
      , specifier
      , optional || specifier
    )
  )
  FROM (
    SELECT specifier, optional
      FROM unnest('{"",a,S,i,l}'::text[]) WITH ORDINALITY s(specifier, sn)
        , unnest('{"",O}'::text[]) WITH ORDINALITY o(optional, opn)
      ORDER BY sn, opn
  ) specifier_test
;
-- Disabled check that the DETAIL is correct
/*
SAVEPOINT a;
\unset ON_ERROR_STOP
\set VERBOSITY default
\echo THIS ERROR IS OK!
SELECT 'DETAIL:  parameter "Moo" at template position ' || strpos( 'more%Moo%OSmore', '%' );
SELECT trunklet.process_language('format', 'more%Moo%OSmore', NULL::json);
ROLLBACK TO a;
\echo THIS ERROR IS OK!
SELECT 'DETAIL:  parameter "Moo" at template position ' || strpos( 'more%Moo%OSmore', '%' );
SELECT trunklet.process_language('format', 'more%Moo%lmore', NULL::json);
ROLLBACK TO a;
\set ON_ERROR_STOP 1
\set VERBOSITY VERBOSE
*/

SELECT throws_like(
    format(
      $$SELECT trunklet.process_language( 'format', %L::text, %L::jsonb )$$
      , replace(input, 's', replacement)
      , param
    )
    , 'parameter "mia" not found'
  )
  FROM (
    SELECT input, param, replacement
      FROM unnest(array['%mia%s ', ' %mia%s', ' %mia%s ', '%mia%s']) WITH ORDINALITY i(input, inn)
        , unnest(array['{"Moo":1}', NULL]) WITH ORDINALITY p(param, pn)
        , unnest('{s,I,L}'::text[]) WITH ORDINALITY u(replacement, un)
      ORDER BY inn, pn, un
  ) missing_param_test
;

CREATE TEMP VIEW extract_test AS
  SELECT *
    FROM ( VALUES
          ( 1, '{s1}'::text[], '{ "s1": "string 1" }'::jsonb         , 'single string'::text )
        , ( 2, '{num}'       , '{ "num": 1.1 }'                      , 'number' )
        , ( 3, '{t,f,"null"}', '{ "t":true,"f":false,"null":null }'  , 'multiple' )
        , ( 4, '{num,bogus}' , '{ "num": 1.1 }'                      , 'num & bogus' )
        , ( 5, '{bogus}'     , NULL                                  , 'bogus' )
      ) AS v( pos, extract_list, expected, description )
    ORDER BY pos
;

SELECT is(
    trunklet.extract_parameters(
      'format'
      , '{
        "s1": "string 1",
        "s2": "string 2",
        "num": 1.1,
        "t": true,
        "f": false,
        "null": null
      }'::jsonb
      , extract_list
    )::jsonb
    , expected
    , 'Test extract_paramaters() for ' || description
  )
  FROM extract_test
;

/*
 * Common syntax checking code
 */
SELECT throws_ok(
    format(
      $$SELECT trunklet.$$ || format
      , j
    )
    , format( 'parameters must be a JSON object, not %s', jsonb_typeof(j->'value') )
    , format(
      $$SELECT trunklet.$$ || format
      , j
    )
  )
  FROM (
    SELECT format, jsonb_build_object('value', value) AS j
      FROM unnest(array[
          $$process_language('format', 'template', (%L::jsonb)->'value')$$
        , $$extract_parameters('format', (%L::jsonb)->'value', '{a}'::text[])$$
      ]) WITH ORDINALITY f(format, fn)
        , unnest(array[to_json(1.1), to_json('text'::text), to_json(true), to_json(array[1,2,3])])
            WITH ORDINALITY v(value, vn)
      ORDER BY fn, vn
  ) non_object_test
;
SELECT throws_ok(
    format(
      $$SELECT trunklet.$$ || format
      , format( '{"%s":1}', key )
    )
    , NULL
    , 'parameter names may not contain "%"'
    , format || ': parameter names may not contain "%"'
  )
  FROM (
    SELECT format, key
      FROM unnest(array[
          $$process_language('format', 'template', %L::jsonb)$$
        , $$extract_parameters('format', %L::jsonb, '{a}'::text[])$$
      ]) WITH ORDINALITY f(format, fn)
        , unnest('{% key,key %,k%k}'::text[]) WITH ORDINALITY k(key, kn)
      ORDER BY fn, kn
  ) bad_key_test
;
SELECT throws_ok(
    format(
      $$SELECT trunklet.$$ || format
      , j
    )
    , format( '%s is not supported as a parameter type', jsonb_typeof(j->'value') )
  )
  FROM (
    SELECT format, jsonb_build_object('value', value) AS j
      FROM unnest(array[
          $$process_language('format', 'template', %L::jsonb)$$
        , $$extract_parameters('format', %L::jsonb, '{a}'::text[])$$
      ]) WITH ORDINALITY f(format, fn)
        , unnest(array['{"key":"value"}'::json, to_json(array[1,2,3])]) WITH ORDINALITY v(value, vn)
      ORDER BY fn, vn
  ) bad_type_test
;

\i test/pgxntool/finish.sql

-- vi: expandtab ts=2 sw=2
