-- create SELECTs to check all rows positions in all tables with trigger_position

SELECT table_name, 'SELECT p.' || coalesce(args[2], 'id') || ', p.' || coalesce(args[3], 'position') || ' AS original_position, p.rn AS correct_position, * FROM (SELECT *, row_number() OVER (' || (CASE WHEN coalesce(args[1], '') = '' THEN '' ELSE 'PARTITION BY ' || replace(args[1], ',', ', ') || ' ' END) || 'ORDER BY ' || coalesce(args[3], 'position') || ') AS rn FROM ' || table_name ||') p WHERE p.' || coalesce(args[3], 'position') || ' != p.rn;' AS check_select
  FROM (
    SELECT event_object_schema || '.' || event_object_table AS table_name, action_statement,
	       regexp_matches(action_statement, 'trigger_position\((?:''\{(.*)\}'')?(?:, ''([a-zA-Z0-9_]+)'')?(?:, ''([a-zA-Z0-9_]+)'')?\)') AS args
     FROM information_schema.triggers
    WHERE action_statement ILIKE '%trigger_position(%'
      AND action_orientation = 'STATEMENT'
      AND action_timing = 'AFTER'
    GROUP BY 1, 2
) AS triggers ORDER BY table_name;
