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
  c_has_group_columns CONSTANT bool DEFAULT array_length(in_group_columns, 1) > 0;
BEGIN
  IF TG_LEVEL = 'ROW' THEN
    RAISE EXCEPTION 'trigger_position() has to be used only as STATEMENT trigger (called as ROW trigger)';
  END IF;

  IF TG_WHEN = 'BEFORE' THEN
    RAISE EXCEPTION 'trigger_position() has to be used AFTER STATEMENT (called BEFORE STATEMENT)';
  END IF;

  -- check if trigger is enabled and also skip in-recursion updates
  IF NOT trigger_is_enabled(TG_TABLE_NAME || '_position_trigger') OR NOT trigger_is_enabled(TG_TABLE_NAME || '_position_trigger_recursion') THEN
    RETURN NULL;
  END IF;

  in_group_columns = TG_ARGV[0]::text[];
  in_key_column = coalesce(TG_ARGV[1], 'id');
  in_position_column = coalesce(TG_ARGV[2], 'position');

  DECLARE
    v_sql text;
    v_from text;
  BEGIN
    PERFORM trigger_disable(TG_TABLE_NAME || '_position_trigger_recursion');

    IF c_has_group_columns = TRUE THEN
      -- TODO
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
          SELECT ' || quote_ident(in_key_column) || ' AS id, row_number() OVER (ORDER BY ' || quote_ident(in_position_column) || ' NULLS LAST, id) AS new_position, ' || quote_ident(in_position_column) || ' AS old_position
            FROM ' || quote_ident(TG_TABLE_NAME) || '
        ';
      ELSE
        RAISE EXCEPTION 'Unknown TG_OP: %', TG_OP;
      END IF;

      v_sql = '
        UPDATE ' || quote_ident(TG_TABLE_NAME) || ' AS source_table
           SET ' || quote_ident(in_position_column) || ' = changed.new_position
          FROM (SELECT id, new_position FROM (' || v_from || ') AS merged WHERE merged.new_position IS DISTINCT FROM merged.old_position) AS changed
         WHERE source_table.' || quote_ident(in_key_column) || ' = changed.id
      ';
    END IF;

    EXECUTE v_sql;

    PERFORM trigger_enable(TG_TABLE_NAME || '_position_trigger_recursion');
  END;

  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;
