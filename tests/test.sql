CREATE FUNCTION trigger_disable(in_trigger_name text)
  RETURNS void AS
$BODY$
  SELECT set_config('app.trigger.' || in_trigger_name, 'disabled', FALSE);
$BODY$
  LANGUAGE sql VOLATILE;

CREATE FUNCTION trigger_enable(in_trigger_name text)
  RETURNS void AS
$BODY$
  SELECT set_config('app.trigger.' || in_trigger_name, NULL, FALSE);
$BODY$
  LANGUAGE sql VOLATILE;

CREATE FUNCTION trigger_is_enabled(in_trigger_name text)
  RETURNS boolean AS
$BODY$
  SELECT current_setting('app.trigger.' || in_trigger_name, TRUE) IS DISTINCT FROM 'disabled';
$BODY$
  LANGUAGE sql VOLATILE;

CREATE OR REPLACE FUNCTION trigger_position()
  RETURNS trigger AS
$BODY$
DECLARE
  in_group_columns text[];
  in_key_column text;
  in_position_column text;
  v_group_column_count integer;
BEGIN
  IF TG_LEVEL = 'ROW' THEN
    RAISE EXCEPTION 'trigger_position() has to be used only as STATEMENT trigger (called as ROW trigger)';
  END IF;

  IF TG_WHEN = 'BEFORE' THEN
    RAISE EXCEPTION 'trigger_position() has to be used only as AFTER STATEMENT (called BEFORE STATEMENT)';
  END IF;

  -- check if trigger is enabled and also skip in-recursion updates
  IF NOT trigger_is_enabled(TG_TABLE_NAME || '_position_trigger') OR NOT trigger_is_enabled(TG_TABLE_NAME || '_position_trigger_recursion') THEN
    RETURN NULL;
  END IF;

  in_group_columns = TG_ARGV[0]::text[];
  in_key_column = coalesce(TG_ARGV[1], 'id');
  in_position_column = coalesce(TG_ARGV[2], 'position');

  v_group_column_count = array_length(in_group_columns, 1);

  DECLARE
    v_from text;
    v_where_sql text DEFAULT '';
    v_where_sql_new text DEFAULT '';
    v_where_sql_old text DEFAULT '';
    v_where text;
    v_columns text DEFAULT '';
    v_columns_source_table text DEFAULT '';
  BEGIN
    PERFORM trigger_disable(TG_TABLE_NAME || '_position_trigger_recursion');

    IF v_group_column_count > 0 THEN
      IF TG_OP = 'INSERT' THEN
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
        v_where_sql = 'SELECT ' || v_where_sql || ' || '')'' AS conditions FROM table_new GROUP BY ' || v_columns;

        EXECUTE 'SELECT array_to_string(array_agg(conditions), '' OR '') FROM (' || v_where_sql || ') AS where_query' INTO v_where;

        IF v_where IS NOT NULL THEN
          v_from = '
            SELECT id, row_number() OVER (PARTITION BY ' || v_columns || ' ORDER BY position NULLS LAST, id) AS new_position, position AS old_position
              FROM (
                SELECT source_table.' || quote_ident(in_key_column) || ' AS id, source_table.' || quote_ident(in_position_column) || ' + 0.5 AS position, ' || v_columns_source_table || '
                  FROM ' || quote_ident(TG_TABLE_NAME) || ' AS source_table
                  LEFT JOIN table_new AS except_table ON except_table.' || quote_ident(in_key_column) || ' = source_table.' || quote_ident(in_key_column) || '
                 WHERE except_table.' || quote_ident(in_key_column) || ' IS NULL
                   AND (' || v_where || ')

                UNION

                SELECT ' || quote_ident(in_key_column) || ' AS id, ' || quote_ident(in_position_column) || ' AS position, ' || v_columns || '
                  FROM table_new
              ) AS merged
          ';
        END IF;
      ELSEIF TG_OP = 'UPDATE' THEN
        FOR i IN 1 .. v_group_column_count LOOP
          IF i = 1 THEN
            v_where_sql = v_where_sql || '''(';
          ELSE
            v_where_sql = v_where_sql || ' || '' AND ';
            v_columns = v_columns || ', ';
            v_columns_source_table = v_columns_source_table || ', ';
          END IF;
          v_where_sql = v_where_sql || 'source_table.' || in_group_columns[i] || ' = '' || t_new.' || quote_ident(in_group_columns[i]);
          v_columns = v_columns || 't_new.' || quote_ident(in_group_columns[i]);
          v_columns_source_table = v_columns_source_table || 'source_table.' || quote_ident(in_group_columns[i]);
        END LOOP;
        v_where_sql_new = 'SELECT ' || v_where_sql || ' || '')'' AS conditions FROM table_new AS t_new JOIN table_old AS t_old ON t_old.' || quote_ident(in_key_column) || ' = t_new.' || quote_ident(in_key_column) || ' WHERE t_new.' || quote_ident(in_position_column) || ' IS DISTINCT FROM t_old.' || quote_ident(in_position_column) || ' GROUP BY ' || v_columns;
        v_where_sql_old = 'SELECT ' || replace(v_where_sql, 't_new.', 't_old.') || ' || '')'' AS conditions FROM table_new AS t_new JOIN table_old AS t_old ON t_old.' || quote_ident(in_key_column) || ' = t_new.' || quote_ident(in_key_column) || ' WHERE t_new.' || quote_ident(in_position_column) || ' IS DISTINCT FROM t_old.' || quote_ident(in_position_column) || ' GROUP BY ' || replace(v_columns, 't_new.', 't_old.');

        EXECUTE 'SELECT array_to_string(array_agg(conditions), '' OR '') FROM (' || v_where_sql_new || ' UNION ' || v_where_sql_old || ') AS where_query' INTO v_where;

        IF v_where IS NOT NULL THEN
          v_from = '
            SELECT id, row_number() OVER (ORDER BY position NULLS LAST, id) AS new_position, position AS old_position
              FROM (
                SELECT source_table.' || quote_ident(in_key_column) || ' AS id, source_table.' || quote_ident(in_position_column) || ' + 0.5 AS position, ' || v_columns_source_table || '
                  FROM ' || quote_ident(TG_TABLE_NAME) || ' AS source_table
                  LEFT JOIN (
                    SELECT t_new.' || quote_ident(in_key_column) || '
                      FROM table_new AS t_new
                      JOIN table_old AS t_old ON t_old.' || quote_ident(in_key_column) || ' = t_new.' || quote_ident(in_key_column) || '
                     WHERE t_new.' || quote_ident(in_position_column) || ' IS DISTINCT FROM t_old.' || quote_ident(in_position_column) || '
                  ) AS except_table ON except_table.' || quote_ident(in_key_column) || ' = source_table.' || quote_ident(in_key_column) || '
                 WHERE except_table.' || quote_ident(in_key_column) || ' IS NULL
                   AND ' || v_where || '

                UNION

                SELECT t_new.' || quote_ident(in_key_column) || ' AS id, t_new.' || quote_ident(in_position_column) || ' AS position, ' || v_columns || '
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
            SELECT source_table.' || quote_ident(in_key_column) || ' AS id, row_number() OVER (PARTITION BY ' || v_columns || ' ORDER BY source_table.' || quote_ident(in_position_column) || ' NULLS LAST, source_table.' || quote_ident(in_key_column) || ') AS new_position, source_table.' || quote_ident(in_position_column) || ' AS old_position
              FROM ' || quote_ident(TG_TABLE_NAME) || ' AS source_table
             WHERE ' || v_where || '
          ';
        END IF;
      ELSE
        RAISE EXCEPTION 'Unknown TG_OP: %', TG_OP;
      END IF;
    ELSE
      IF TG_OP = 'INSERT' THEN
        v_from = '
          SELECT id, row_number() OVER (ORDER BY position NULLS LAST, id) AS new_position, position AS old_position
            FROM (
              SELECT source_table.' || quote_ident(in_key_column) || ' AS id, source_table.' || quote_ident(in_position_column) || ' + 0.5 AS position
                FROM ' || quote_ident(TG_TABLE_NAME) || ' AS source_table
                LEFT JOIN table_new AS except_table ON except_table.' || quote_ident(in_key_column) || ' = source_table.' || quote_ident(in_key_column) || '
               WHERE except_table.' || quote_ident(in_key_column) || ' IS NULL

              UNION

              SELECT ' || quote_ident(in_key_column) || ' AS id, ' || quote_ident(in_position_column) || ' AS position
                FROM table_new
            ) AS merged
        ';
      ELSEIF TG_OP = 'UPDATE' THEN
        v_from = '
          SELECT id, row_number() OVER (ORDER BY position NULLS LAST, id) AS new_position, position AS old_position
            FROM (
              SELECT source_table.' || quote_ident(in_key_column) || ' AS id, source_table.' || quote_ident(in_position_column) || ' + 0.5 AS position
                FROM ' || quote_ident(TG_TABLE_NAME) || ' AS source_table
                LEFT JOIN (
                  SELECT t_new.' || quote_ident(in_key_column) || '
                    FROM table_new AS t_new
                    JOIN table_old AS t_old ON t_old.' || quote_ident(in_key_column) || ' = t_new.' || quote_ident(in_key_column) || '
                   WHERE t_new.' || quote_ident(in_position_column) || ' IS DISTINCT FROM t_old.' || quote_ident(in_position_column) || '
                ) AS except_table ON except_table.' || quote_ident(in_key_column) || ' = source_table.' || quote_ident(in_key_column) || '
               WHERE except_table.' || quote_ident(in_key_column) || ' IS NULL

              UNION

              SELECT t_new.' || quote_ident(in_key_column) || ' AS id, t_new.' || quote_ident(in_position_column) || ' AS position
                FROM table_new AS t_new
                JOIN table_old AS t_old ON t_old.' || quote_ident(in_key_column) || ' = t_new.' || quote_ident(in_key_column) || '
               WHERE t_new.' || quote_ident(in_position_column) || ' IS DISTINCT FROM t_old.' || quote_ident(in_position_column) || '
            ) AS merged
        ';
      ELSEIF TG_OP = 'DELETE' THEN
        v_from = '
          SELECT ' || quote_ident(in_key_column) || ' AS id, row_number() OVER (ORDER BY ' || quote_ident(in_position_column) || ' NULLS LAST, ' || quote_ident(in_key_column) || ') AS new_position, ' || quote_ident(in_position_column) || ' AS old_position
            FROM ' || quote_ident(TG_TABLE_NAME) || '
        ';
      ELSE
        RAISE EXCEPTION 'Unknown TG_OP: %', TG_OP;
      END IF;
    END IF;

    IF v_from IS NOT NULL THEN
      EXECUTE '
        UPDATE ' || quote_ident(TG_TABLE_NAME) || ' AS source_table
           SET ' || quote_ident(in_position_column) || ' = changed.new_position
          FROM (SELECT id, new_position FROM (' || v_from || ') AS merged WHERE merged.new_position IS DISTINCT FROM merged.old_position) AS changed
         WHERE source_table.' || quote_ident(in_key_column) || ' = changed.id
      ';
    END IF;

    PERFORM trigger_enable(TG_TABLE_NAME || '_position_trigger_recursion');
  END;

  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;


CREATE TABLE public.test_table
(
  id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  position integer,
  CONSTRAINT test_table_pkey PRIMARY KEY (id)
);

CREATE TRIGGER test_table_position_trigger_insert
    AFTER INSERT ON test_table
    REFERENCING NEW TABLE AS table_new
    FOR EACH STATEMENT
    EXECUTE FUNCTION trigger_position();

CREATE TRIGGER test_table_position_trigger_update
    AFTER UPDATE ON test_table
    REFERENCING NEW TABLE AS table_new OLD TABLE AS table_old
    FOR EACH STATEMENT
    EXECUTE FUNCTION trigger_position();

CREATE TRIGGER test_table_position_trigger_delete
    AFTER DELETE ON test_table
    REFERENCING OLD TABLE AS table_old -- no need if there are no group columns
    FOR EACH STATEMENT
    EXECUTE FUNCTION trigger_position();



CREATE TABLE public.test_table2
(
  id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  country_id integer NOT NULL,
  town_id integer NOT NULL,
  position integer,
  CONSTRAINT test_table2_pkey PRIMARY KEY (id)
);

CREATE TRIGGER test_table2_position_trigger_insert
    AFTER INSERT ON test_table2
    REFERENCING NEW TABLE AS table_new
    FOR EACH STATEMENT
    EXECUTE FUNCTION trigger_position('{country_id,town_id}');

CREATE TRIGGER test_table2_position_trigger_update
    AFTER UPDATE ON test_table2
    REFERENCING NEW TABLE AS table_new OLD TABLE AS table_old
    FOR EACH STATEMENT
    EXECUTE FUNCTION trigger_position('{country_id,town_id}');

CREATE TRIGGER test_table2_position_trigger_delete
    AFTER DELETE ON test_table2
    REFERENCING OLD TABLE AS table_old
    FOR EACH STATEMENT
    EXECUTE FUNCTION trigger_position('{country_id,town_id}');
