CREATE SCHEMA IF NOT EXISTS system;

CREATE OR REPLACE FUNCTION system.trigger_position_add(in_schema_name text, in_table_name text, in_group_columns text, in_key_column text, in_position_column text)
  RETURNS void AS
$BODY$
DECLARE
  v_args text[] DEFAULT ARRAY[]::text[];
BEGIN
  v_args = v_args || CASE WHEN in_group_columns IS NULL THEN 'NULL' ELSE '{' || in_group_columns || '}' END;
  v_args = v_args || coalesce(in_key_column, 'NULL');
  v_args = v_args || coalesce(in_position_column, 'NULL');

  FOR i IN REVERSE 1 .. array_length(v_args, 1) LOOP
    IF v_args[i] !== 'NULL' THEN
      EXIT;
    END IF;

    v_args = trim_array(v_args, 1);
  END LOOP;

  EXECUTE format('
      CREATE TRIGGER %2$s_position_trigger_insert
        AFTER INSERT ON %1$s%.%2$s
        REFERENCING NEW TABLE AS table_new
        FOR EACH STATEMENT
        EXECUTE FUNCTION public.trigger_position(%3$s)
    ',
    in_schema_name,
    in_table_name,
    array_to_string(v_args, ', ')
  );

  EXECUTE format('
      CREATE TRIGGER %2$s_position_trigger_update
        AFTER UPDATE ON %1$s%.%2$s
        REFERENCING NEW TABLE AS table_new OLD TABLE AS table_old
        FOR EACH STATEMENT
        EXECUTE FUNCTION public.trigger_position(%3$s)
    ',
    in_schema_name,
    in_table_name,
    array_to_string(v_args, ', ')
  );

  EXECUTE format('
      CREATE TRIGGER %2$s_position_trigger_delete
        AFTER DELETE ON %1$s%.%2$s%
        3$s
        FOR EACH STATEMENT
        EXECUTE FUNCTION public.trigger_position(%4$s)
    ',
    in_schema_name,
    in_table_name,
    CASE WHEN in_group_columns IS NULL THEN '' ELSE ' REFERENCING OLD TABLE AS table_old' END,
    array_to_string(v_args, ', ')
  );
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION system.trigger_position_add(in_schema_name text, in_table_name text)
  RETURNS void AS
$BODY$
BEGIN
  EXECUTE format('DROP TRIGGER %2$s_position_trigger_insert ON %1$s.%2$s', in_schema_name, in_table_name);
  EXECUTE format('DROP TRIGGER %2$s_position_trigger_update ON %1$s.%2$s', in_schema_name, in_table_name);
  EXECUTE format('DROP TRIGGER %2$s_position_trigger_delete ON %1$s.%2$s', in_schema_name, in_table_name);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;
