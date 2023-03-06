CREATE SCHEMA IF NOT EXISTS tests;

CREATE OR REPLACE FUNCTION tests.assert_positions(in_table_name text, in_ids integer[], in_positions integer[], in_id_column text DEFAULT 'id', in_position_column text DEFAULT 'position')
  RETURNS void AS
$BODY$
DECLARE
  v_check_sql text;
  v_count integer;
  v_rows jsonb;
BEGIN
  IF array_length(in_ids, 1) != array_length(in_positions, 1) THEN
    RAISE EXCEPTION 'Array of the ids (%) and array of the positions (%) must have the same length', in_ids, in_positions;
  END IF;

  SELECT 'SELECT COUNT(*) FROM (' || array_to_string(array_agg(item), ' UNION ') || ') AS x' INTO v_check_sql FROM (
    SELECT 'SELECT ' || in_id_column || ', ' || in_position_column || ' FROM ' || in_table_name || ' WHERE ' || in_id_column || ' = ' || unnest(in_ids) || ' AND ' || in_position_column || ' = ' || unnest(in_positions) AS item
  ) AS x;

  EXECUTE v_check_sql INTO v_count;

  IF v_count != array_length(in_ids, 1) THEN
    EXECUTE 'SELECT json_agg(t) FROM ' || in_table_name || ' AS t' INTO v_rows;
    RAISE EXCEPTION '[Assert failure] Real "%" table content is: %', in_table_name, jsonb_pretty(v_rows);
  END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;


/*
-- DEBUG HELPERS

DECLARE
  r record;
...

FOR r IN
    EXECUTE 'SELECT * FROM table_new'
LOOP
  RAISE NOTICE 'ROW: %', to_json(r);
END LOOP;
*/
