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

  DECLARE
    c_alias CONSTANT TEXT DEFAULT '{$alias}';
    v_from text;
    v_source_table_where text;
    v_columns_template text;
    v_columns text;
  BEGIN
    IF array_length(in_group_columns, 1) > 0 THEN
      SELECT array_to_string(array_agg(quoted_template_col), ', ') INTO v_columns_template FROM (
        SELECT c_alias || quote_ident(col) AS quoted_template_col FROM unnest(in_group_columns) AS col
      ) AS tmp;

      v_columns = replace(v_columns_template, c_alias, '');

      IF TG_OP IN ('INSERT', 'DELETE') THEN
        DECLARE
          v_source_table_where_sql text;
        BEGIN
          SELECT format('''('' || %s || '')''', array_to_string(array_agg(condition), ' || '' AND '' || ')) INTO v_source_table_where_sql FROM (
            SELECT format('''source_table.%1$I IS NOT DISTINCT FROM '' || coalesce(%1$I::text, ''NULL'')', col) AS condition FROM unnest(in_group_columns) AS col
          ) AS tmp;

          EXECUTE format('
            SELECT array_to_string(array_agg(conditions), '' OR '')
              FROM (SELECT %s AS conditions FROM %s GROUP BY %s) AS tmp
          ', v_source_table_where_sql, CASE WHEN TG_OP = 'INSERT' THEN 'table_new' ELSE 'table_old' END, v_columns) INTO v_source_table_where;

          IF v_source_table_where IS NOT NULL THEN
            IF TG_OP = 'INSERT' THEN
              v_from = format('
                SELECT id, row_number() OVER (PARTITION BY %2$s ORDER BY order_by_position NULLS LAST, id) AS computed_position, position AS actual_position
                  FROM (
                    SELECT source_table.%5$I AS id, source_table.%6$I + 0.1 AS order_by_position, source_table.%6$I AS position, %4$s
                      FROM %1$s AS source_table
                      LEFT JOIN table_new AS except_table ON except_table.%5$I = source_table.%5$I
                     WHERE except_table.%5$I IS NULL
                       AND (%3$s)

                    UNION

                    SELECT %5$I AS id, %6$I AS order_by_position, %6$I AS position, %2$s
                      FROM table_new
                  ) AS merged
              ', v_table_name, v_columns, v_source_table_where, replace(v_columns_template, c_alias, 'source_table.'), in_key_column, in_position_column);
            ELSE
              v_from = format('
                SELECT source_table.%4$I AS id, row_number() OVER (PARTITION BY %2$s ORDER BY source_table.%5$I NULLS LAST, source_table.%4$I) AS computed_position, source_table.%5$I AS actual_position
                  FROM %1$s AS source_table
                 WHERE %3$s
              ', v_table_name, v_columns, v_source_table_where, in_key_column, in_position_column);
            END IF;
          END IF;
        END;
      ELSEIF TG_OP = 'UPDATE' THEN
        DECLARE
          v_where_some_group_is_changed text;
          v_where_all_groups_are_same text;
          v_table_new_where_sql text;
          v_table_old_where_sql text;
          v_columns_t_new text;
        BEGIN
          SELECT
            array_to_string(array_agg(condition_not_equal), ' OR '),
            array_to_string(array_agg(condition_equal), ' AND ')
            INTO v_where_some_group_is_changed, v_where_all_groups_are_same
          FROM (
            SELECT
              format('t_new.%1$I IS DISTINCT FROM t_old.%1$I', col) AS condition_not_equal,
              format('t_new.%1$I IS NOT DISTINCT FROM t_old.%1$I', col) AS condition_equal
            FROM unnest(in_group_columns) AS col
          ) AS tmp;

          v_columns_t_new = replace(v_columns_template, c_alias, 't_new.');

          SELECT
            format('SELECT %1$s || '''' AS conditions FROM table_new AS t_new JOIN table_old AS t_old ON t_old.%4$I = t_new.%4$I WHERE t_new.%5$I IS DISTINCT FROM t_old.%5$I OR %3$s GROUP BY %2$s', conditions_new, v_columns_t_new, v_where_some_group_is_changed, in_key_column, in_position_column),
            format('SELECT %1$s || '''' AS conditions FROM table_new AS t_new JOIN table_old AS t_old ON t_old.%4$I = t_new.%4$I WHERE t_new.%5$I IS DISTINCT FROM t_old.%5$I OR %3$s GROUP BY %2$s', conditions_old, replace(v_columns_template, c_alias, 't_old.'), v_where_some_group_is_changed, in_key_column, in_position_column)
            INTO v_table_new_where_sql, v_table_old_where_sql
          FROM (
            SELECT
              format('''('' || %s || '')''', array_to_string(array_agg(condition_new), ' || '' AND '' || ')) AS conditions_new,
              format('''('' || %s || '')''', array_to_string(array_agg(condition_old), ' || '' AND '' || ')) AS conditions_old
            FROM (
              SELECT
                format('''source_table.%1$I IS NOT DISTINCT FROM '' || coalesce(t_new.%1$I::text, ''NULL'')', col) AS condition_new,
                format('''source_table.%1$I IS NOT DISTINCT FROM '' || coalesce(t_old.%1$I::text, ''NULL'')', col) AS condition_old
              FROM unnest(in_group_columns) AS col
            ) AS tmp
          ) AS tmp;

          EXECUTE format('SELECT array_to_string(array_agg(conditions), '' OR '') FROM (%s UNION %s) AS tmp', v_table_new_where_sql, v_table_old_where_sql) INTO v_source_table_where;

          IF v_source_table_where IS NOT NULL THEN
            v_from = format('
              SELECT id, row_number() OVER (PARTITION BY %2$s ORDER BY order_by_position NULLS LAST, id) AS computed_position, position AS actual_position
                FROM (
                  SELECT source_table.%8$I AS id, source_table.%9$I + 0.1 AS order_by_position, source_table.%9$I AS position, %7$s
                    FROM %1$s AS source_table
                    LEFT JOIN (
                      SELECT t_new.%8$I
                        FROM table_new AS t_new
                        JOIN table_old AS t_old ON t_old.%8$I = t_new.%8$I
                       WHERE t_new.%9$I IS DISTINCT FROM t_old.%9$I OR %4$s
                    ) AS except_table ON except_table.%8$I = source_table.%8$I
                   WHERE except_table.%8$I IS NULL
                     AND (%3$s)

                  UNION

                  SELECT t_new.%8$I AS id, t_new.%9$I + CASE WHEN (t_new.%9$I > t_old.%9$I) AND (%5$s) THEN 0.2 ELSE 0 END AS order_by_position, t_new.%9$I AS position, %6$s
                    FROM table_new AS t_new
                    JOIN table_old AS t_old ON t_old.%8$I = t_new.%8$I
                   WHERE t_new.%9$I IS DISTINCT FROM t_old.%9$I OR %4$s
                ) AS merged
            ', v_table_name, v_columns, v_source_table_where, v_where_some_group_is_changed, v_where_all_groups_are_same, v_columns_t_new, replace(v_columns_template, c_alias, 'source_table.'), in_key_column, in_position_column);
          END IF;
        END;
      ELSE
        RAISE EXCEPTION 'Unknown TG_OP: %', TG_OP;
      END IF;
    ELSE
      IF TG_OP = 'INSERT' THEN
        v_from = format('
          SELECT id, row_number() OVER (ORDER BY order_by_position NULLS LAST, id) AS computed_position, position AS actual_position
            FROM (
              SELECT source_table.%2$I AS id, source_table.%3$I + 0.1 AS order_by_position, source_table.%3$I AS position
                FROM ' || v_table_name || ' AS source_table
                LEFT JOIN table_new AS except_table ON except_table.%2$I = source_table.%2$I
               WHERE except_table.%2$I IS NULL

              UNION

              SELECT %2$I AS id, %3$I AS order_by_position, %3$I AS position
                FROM table_new
            ) AS merged
        ', v_table_name, in_key_column, in_position_column);
      ELSEIF TG_OP = 'UPDATE' THEN
        v_from = format('
          SELECT id, row_number() OVER (ORDER BY order_by_position NULLS LAST, id) AS computed_position, position AS actual_position
            FROM (
              SELECT source_table.%2$I AS id, source_table.%3$I + 0.1 AS order_by_position, source_table.%3$I AS position
                FROM %1$s AS source_table
                LEFT JOIN (
                  SELECT t_new.%2$I
                    FROM table_new AS t_new
                    JOIN table_old AS t_old ON t_old.%2$I = t_new.%2$I
                   WHERE t_new.%3$I IS DISTINCT FROM t_old.%3$I
                ) AS except_table ON except_table.%2$I = source_table.%2$I
               WHERE except_table.%2$I IS NULL

              UNION

              SELECT t_new.%2$I AS id, t_new.%3$I + CASE WHEN t_new.%3$I > t_old.%3$I THEN 0.2 ELSE 0 END AS order_by_position, t_new.%3$I AS position
                FROM table_new AS t_new
                JOIN table_old AS t_old ON t_old.%2$I = t_new.%2$I
               WHERE t_new.%3$I IS DISTINCT FROM t_old.%3$I
            ) AS merged
        ', v_table_name, in_key_column, in_position_column);
      ELSEIF TG_OP = 'DELETE' THEN
        v_from = format('
          SELECT %2$I AS id, row_number() OVER (ORDER BY %3$I NULLS LAST, %2$I) AS computed_position, %3$I AS actual_position
            FROM %1$s
        ', v_table_name, in_key_column, in_position_column);
      ELSE
        RAISE EXCEPTION 'Unknown TG_OP: %', TG_OP;
      END IF;
    END IF;

    IF v_from IS NOT NULL THEN
      PERFORM public.trigger_disable(v_table_name || '_position_trigger_recursion');

      EXECUTE format('
        UPDATE %1$s AS source_table
           SET %4$I = changed.computed_position
          FROM (SELECT id, computed_position FROM (%2$s) AS merged WHERE merged.computed_position IS DISTINCT FROM merged.actual_position) AS changed
         WHERE source_table.%3$I = changed.id
      ', v_table_name, v_from, in_key_column, in_position_column);

      PERFORM public.trigger_enable(v_table_name || '_position_trigger_recursion');
    END IF;
  END;

  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;
