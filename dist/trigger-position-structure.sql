CREATE OR REPLACE FUNCTION public.trigger_disable(in_trigger_name text)
  RETURNS void AS
$BODY$
  SELECT set_config('app.trigger.' || in_trigger_name, 'disabled', FALSE);
$BODY$
  LANGUAGE sql VOLATILE;

CREATE OR REPLACE FUNCTION public.trigger_enable(in_trigger_name text)
  RETURNS void AS
$BODY$
  SELECT set_config('app.trigger.' || in_trigger_name, NULL, FALSE);
$BODY$
  LANGUAGE sql VOLATILE;

CREATE OR REPLACE FUNCTION public.trigger_is_enabled(in_trigger_name text)
  RETURNS boolean AS
$BODY$
  SELECT current_setting('app.trigger.' || in_trigger_name, TRUE) IS DISTINCT FROM 'disabled';
$BODY$
  LANGUAGE sql VOLATILE;

CREATE OR REPLACE FUNCTION public.trigger_position()
  RETURNS trigger AS
$BODY$
DECLARE
  in_group_columns text[];
  in_key_column text;
  in_position_column text;
  v_table_name text;
  v_group_column_count integer;
BEGIN
  IF TG_LEVEL = 'ROW' THEN
    RAISE EXCEPTION 'trigger_position() has to be used only as STATEMENT trigger (called as ROW trigger)';
  END IF;

  IF TG_WHEN = 'BEFORE' THEN
    RAISE EXCEPTION 'trigger_position() has to be used only as AFTER STATEMENT (called BEFORE STATEMENT)';
  END IF;

  v_table_name = quote_ident(TG_TABLE_SCHEMA) || '.' || quote_ident(TG_TABLE_NAME);

  IF NOT public.trigger_is_enabled(v_table_name || '_position_trigger') OR NOT public.trigger_is_enabled(v_table_name || '_position_trigger_recursion') THEN
    RETURN NULL;
  END IF;

  in_group_columns = TG_ARGV[0]::text[];
  in_key_column = coalesce(TG_ARGV[1], 'id');
  in_position_column = coalesce(TG_ARGV[2], 'position');

  v_group_column_count = array_length(in_group_columns, 1);

  DECLARE
    v_from text;
    v_where_sql text DEFAULT '';
    v_where_sql_where text[] DEFAULT ARRAY[]::text[];
    v_where_sql_new text DEFAULT '';
    v_where_sql_old text DEFAULT '';
    v_where text;
    v_columns text DEFAULT '';
    v_columns_source_table text DEFAULT '';
    v_columns_t_new text DEFAULT '';
  BEGIN
    IF v_group_column_count > 0 THEN
      IF TG_OP = 'INSERT' THEN
        FOR i IN 1 .. v_group_column_count LOOP
          IF i = 1 THEN
            v_where_sql = v_where_sql || '''';
          ELSE
            v_where_sql = v_where_sql || ' || '' AND ';
            v_columns = v_columns || ', ';
            v_columns_source_table = v_columns_source_table || ', ';
          END IF;
          v_where_sql = v_where_sql || 'source_table.' || in_group_columns[i] || ' = '' || ' || quote_ident(in_group_columns[i]);
          v_columns = v_columns || quote_ident(in_group_columns[i]);
          v_columns_source_table = v_columns_source_table || 'source_table.' || quote_ident(in_group_columns[i]);
        END LOOP;
        v_where_sql = 'SELECT ' || v_where_sql || ' || '''' AS conditions FROM table_new GROUP BY ' || v_columns;

        EXECUTE 'SELECT array_to_string(array_agg(conditions), '' OR '') FROM (' || v_where_sql || ') AS where_query' INTO v_where;

        IF v_where IS NOT NULL THEN
          v_from = '
            SELECT id, row_number() OVER (PARTITION BY ' || v_columns || ' ORDER BY order_by_position NULLS LAST, id) AS computed_position, position AS actual_position
              FROM (
                SELECT source_table.' || quote_ident(in_key_column) || ' AS id, source_table.' || quote_ident(in_position_column) || ' + 0.1 AS order_by_position, source_table.' || quote_ident(in_position_column) || ' AS position, ' || v_columns_source_table || '
                  FROM ' || v_table_name || ' AS source_table
                  LEFT JOIN table_new AS except_table ON except_table.' || quote_ident(in_key_column) || ' = source_table.' || quote_ident(in_key_column) || '
                 WHERE except_table.' || quote_ident(in_key_column) || ' IS NULL
                   AND (' || v_where || ')

                UNION

                SELECT ' || quote_ident(in_key_column) || ' AS id, ' || quote_ident(in_position_column) || ' AS order_by_position, ' || quote_ident(in_position_column) || ' AS position, ' || v_columns || '
                  FROM table_new
              ) AS merged
          ';
        END IF;
      ELSEIF TG_OP = 'UPDATE' THEN
        FOR i IN 1 .. v_group_column_count LOOP
          IF i = 1 THEN
            v_where_sql = v_where_sql || '''';
          ELSE
            v_where_sql = v_where_sql || ' || '' AND ';
            v_columns = v_columns || ', ';
            v_columns_source_table = v_columns_source_table || ', ';
            v_columns_t_new = v_columns_t_new || ', ';
          END IF;
          v_where_sql = v_where_sql || 'source_table.' || in_group_columns[i] || ' = '' || t_new.' || quote_ident(in_group_columns[i]);
          v_where_sql_where = v_where_sql_where || ('t_new.' || in_group_columns[i] || ' != t_old.' || quote_ident(in_group_columns[i]));
          v_columns = v_columns || quote_ident(in_group_columns[i]);
          v_columns_source_table = v_columns_source_table || 'source_table.' || quote_ident(in_group_columns[i]);
          v_columns_t_new = v_columns_t_new || 't_new.' || quote_ident(in_group_columns[i]);
        END LOOP;

        v_where_sql_new = 'SELECT ' || v_where_sql || ' || '''' AS conditions FROM table_new AS t_new JOIN table_old AS t_old ON t_old.' || quote_ident(in_key_column) || ' = t_new.' || quote_ident(in_key_column) || ' WHERE t_new.' || quote_ident(in_position_column) || ' IS DISTINCT FROM t_old.' || quote_ident(in_position_column) || ' OR ' || array_to_string(v_where_sql_where, ' OR ') || ' GROUP BY ' || v_columns_t_new;
        v_where_sql_old = 'SELECT ' || replace(v_where_sql, 't_new.', 't_old.') || ' || '''' AS conditions FROM table_new AS t_new JOIN table_old AS t_old ON t_old.' || quote_ident(in_key_column) || ' = t_new.' || quote_ident(in_key_column) || ' WHERE t_new.' || quote_ident(in_position_column) || ' IS DISTINCT FROM t_old.' || quote_ident(in_position_column) || ' OR ' || array_to_string(v_where_sql_where, ' OR ') || ' GROUP BY ' || replace(v_columns_t_new, 't_new.', 't_old.');

        EXECUTE 'SELECT array_to_string(array_agg(conditions), '' OR '') FROM (' || v_where_sql_new || ' UNION ' || v_where_sql_old || ') AS where_query' INTO v_where;

        IF v_where IS NOT NULL THEN
          v_from = '
            SELECT id, row_number() OVER (PARTITION BY ' || v_columns || ' ORDER BY order_by_position NULLS LAST, id) AS computed_position, position AS actual_position
              FROM (
                SELECT source_table.' || quote_ident(in_key_column) || ' AS id, source_table.' || quote_ident(in_position_column) || ' + 0.1 AS order_by_position, source_table.' || quote_ident(in_position_column) || ' AS position, ' || v_columns_source_table || '
                  FROM ' || v_table_name || ' AS source_table
                  LEFT JOIN (
                    SELECT t_new.' || quote_ident(in_key_column) || '
                      FROM table_new AS t_new
                      JOIN table_old AS t_old ON t_old.' || quote_ident(in_key_column) || ' = t_new.' || quote_ident(in_key_column) || '
                     WHERE t_new.' || quote_ident(in_position_column) || ' IS DISTINCT FROM t_old.' || quote_ident(in_position_column) || '
                  ) AS except_table ON except_table.' || quote_ident(in_key_column) || ' = source_table.' || quote_ident(in_key_column) || '
                 WHERE except_table.' || quote_ident(in_key_column) || ' IS NULL
                   AND (' || v_where || ')

                UNION

                SELECT t_new.' || quote_ident(in_key_column) || ' AS id, t_new.' || quote_ident(in_position_column) || ' + CASE WHEN (t_new.' || quote_ident(in_position_column) || ' > t_old.' || quote_ident(in_position_column) || ') AND (' || replace(array_to_string(v_where_sql_where, ' AND '), '!=', '=') || ') THEN 0.2 ELSE 0 END AS order_by_position, t_new.' || quote_ident(in_position_column) || ' AS position, ' || v_columns_t_new || '
                  FROM table_new AS t_new
                  JOIN table_old AS t_old ON t_old.' || quote_ident(in_key_column) || ' = t_new.' || quote_ident(in_key_column) || '
                 WHERE t_new.' || quote_ident(in_position_column) || ' IS DISTINCT FROM t_old.' || quote_ident(in_position_column) || '
              ) AS merged
          ';
        END IF;
      ELSEIF TG_OP = 'DELETE' THEN
        FOR i IN 1 .. v_group_column_count LOOP
          IF i = 1 THEN
            v_where_sql = v_where_sql || '''(';
          ELSE
            v_where_sql = v_where_sql || ' || '' AND ';
            v_columns = v_columns || ', ';
            v_columns_source_table = v_columns_source_table || ', ';
          END IF;
          v_where_sql = v_where_sql || 'source_table.' || in_group_columns[i] || ' = '' || ' || quote_ident(in_group_columns[i]);
          v_columns = v_columns || quote_ident(in_group_columns[i]);
          v_columns_source_table = v_columns_source_table || 'source_table.' || quote_ident(in_group_columns[i]);
        END LOOP;
        v_where_sql = 'SELECT ' || v_where_sql || ' || '')'' AS conditions FROM table_old GROUP BY ' || v_columns;

        EXECUTE 'SELECT array_to_string(array_agg(conditions), '' OR '') FROM (' || v_where_sql || ') AS where_query' INTO v_where;

        IF v_where IS NOT NULL THEN
          v_from = '
            SELECT source_table.' || quote_ident(in_key_column) || ' AS id, row_number() OVER (PARTITION BY ' || v_columns || ' ORDER BY source_table.' || quote_ident(in_position_column) || ' NULLS LAST, source_table.' || quote_ident(in_key_column) || ') AS computed_position, source_table.' || quote_ident(in_position_column) || ' AS actual_position
              FROM ' || v_table_name || ' AS source_table
             WHERE ' || v_where || '
          ';
        END IF;
      ELSE
        RAISE EXCEPTION 'Unknown TG_OP: %', TG_OP;
      END IF;
    ELSE
      IF TG_OP = 'INSERT' THEN
        v_from = '
          SELECT id, row_number() OVER (ORDER BY order_by_position NULLS LAST, id) AS computed_position, position AS actual_position
            FROM (
              SELECT source_table.' || quote_ident(in_key_column) || ' AS id, source_table.' || quote_ident(in_position_column) || ' + 0.1 AS order_by_position, source_table.' || quote_ident(in_position_column) || ' AS position
                FROM ' || v_table_name || ' AS source_table
                LEFT JOIN table_new AS except_table ON except_table.' || quote_ident(in_key_column) || ' = source_table.' || quote_ident(in_key_column) || '
               WHERE except_table.' || quote_ident(in_key_column) || ' IS NULL

              UNION

              SELECT ' || quote_ident(in_key_column) || ' AS id, ' || quote_ident(in_position_column) || ' AS order_by_position, ' || quote_ident(in_position_column) || ' AS position
                FROM table_new
            ) AS merged
        ';
      ELSEIF TG_OP = 'UPDATE' THEN
        v_from = '
          SELECT id, row_number() OVER (ORDER BY order_by_position NULLS LAST, id) AS computed_position, position AS actual_position
            FROM (
              SELECT source_table.' || quote_ident(in_key_column) || ' AS id, source_table.' || quote_ident(in_position_column) || ' + 0.1 AS order_by_position, source_table.' || quote_ident(in_position_column) || ' AS position
                FROM ' || v_table_name || ' AS source_table
                LEFT JOIN (
                  SELECT t_new.' || quote_ident(in_key_column) || '
                    FROM table_new AS t_new
                    JOIN table_old AS t_old ON t_old.' || quote_ident(in_key_column) || ' = t_new.' || quote_ident(in_key_column) || '
                   WHERE t_new.' || quote_ident(in_position_column) || ' IS DISTINCT FROM t_old.' || quote_ident(in_position_column) || '
                ) AS except_table ON except_table.' || quote_ident(in_key_column) || ' = source_table.' || quote_ident(in_key_column) || '
               WHERE except_table.' || quote_ident(in_key_column) || ' IS NULL

              UNION

              SELECT t_new.' || quote_ident(in_key_column) || ' AS id, t_new.' || quote_ident(in_position_column) || ' + CASE WHEN t_new.' || quote_ident(in_position_column) || ' > t_old.' || quote_ident(in_position_column) || ' THEN 0.2 ELSE 0 END AS order_by_position, t_new.' || quote_ident(in_position_column) || ' AS position
                FROM table_new AS t_new
                JOIN table_old AS t_old ON t_old.' || quote_ident(in_key_column) || ' = t_new.' || quote_ident(in_key_column) || '
               WHERE t_new.' || quote_ident(in_position_column) || ' IS DISTINCT FROM t_old.' || quote_ident(in_position_column) || '
            ) AS merged
        ';
      ELSEIF TG_OP = 'DELETE' THEN
        v_from = '
          SELECT ' || quote_ident(in_key_column) || ' AS id, row_number() OVER (ORDER BY ' || quote_ident(in_position_column) || ' NULLS LAST, ' || quote_ident(in_key_column) || ') AS computed_position, ' || quote_ident(in_position_column) || ' AS actual_position
            FROM ' || v_table_name || '
        ';
      ELSE
        RAISE EXCEPTION 'Unknown TG_OP: %', TG_OP;
      END IF;
    END IF;

    IF v_from IS NOT NULL THEN
      PERFORM public.trigger_disable(v_table_name || '_position_trigger_recursion');

      EXECUTE '
        UPDATE ' || v_table_name || ' AS source_table
           SET ' || quote_ident(in_position_column) || ' = changed.computed_position
          FROM (SELECT id, computed_position FROM (' || v_from || ') AS merged WHERE merged.computed_position IS DISTINCT FROM merged.actual_position) AS changed
         WHERE source_table.' || quote_ident(in_key_column) || ' = changed.id
      ';

      PERFORM public.trigger_enable(v_table_name || '_position_trigger_recursion');
    END IF;
  END;

  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;
