CREATE SCHEMA IF NOT EXISTS system;

CREATE OR REPLACE FUNCTION system.trigger_position_add(in_schema_name text, in_table_name text, in_group_columns text DEFAULT NULL, in_key_column text DEFAULT NULL, in_position_column text DEFAULT NULL)
  RETURNS void AS
$BODY$
DECLARE
  v_args text[] DEFAULT ARRAY[]::text[];
BEGIN
  v_args = v_args || ('''{' || coalesce(in_group_columns, '') || '}''');
  v_args = v_args || ('''' || coalesce(in_key_column, 'id') || '''');
  v_args = v_args || ('''' || coalesce(in_position_column, 'position') || '''');

  IF in_position_column IS NULL THEN
    v_args = v_args[:2];
    IF in_key_column IS NULL THEN
      v_args = v_args[:1];
      IF in_group_columns IS NULL THEN
        v_args = v_args[:0];
      END IF;
    END IF;
  END IF;

  EXECUTE format('
      CREATE TRIGGER %2$s_position_trigger_insert
        AFTER INSERT ON %1$s.%2$s
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
        AFTER UPDATE ON %1$s.%2$s
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
        AFTER DELETE ON %1$s.%2$s
        %3$s
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

CREATE OR REPLACE FUNCTION system.trigger_position_remove(in_schema_name text, in_table_name text)
  RETURNS void AS
$BODY$
BEGIN
  EXECUTE format('DROP TRIGGER %2$s_position_trigger_insert ON %1$s.%2$s', in_schema_name, in_table_name);
  EXECUTE format('DROP TRIGGER %2$s_position_trigger_update ON %1$s.%2$s', in_schema_name, in_table_name);
  EXECUTE format('DROP TRIGGER %2$s_position_trigger_delete ON %1$s.%2$s', in_schema_name, in_table_name);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;
