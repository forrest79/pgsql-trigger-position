# PostgreSQL - auto manage positions with a trigger

[![License](https://img.shields.io/badge/license-BSD-blue.svg)](https://github.com/forrest79/pgsql-trigger-position/blob/master/LICENSE.md)
[![Build](https://github.com/forrest79/pgsql-trigger-position/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/forrest79/pgsql-trigger-position/actions/workflows/build.yml)

Trigger position is a PostgreSQL trigger function that can simply manage your position/ordering columns for your tables. This trigger function guarantees unbroken number series for your positions (`1, 2, 3...`).

It can handle positions for simple table and also for the complex tables, where different groups have different positions.

Tested on PostgreSQL 11, 12, 13, 14, 15, 16 and 17.   

## How to use

After trigger position is set on a table, handling positions is very easy. If you insert/update row with a `NULL` value as a position, this record will be placed at the end.
If you set the concrete position, row will have this position and the other rows will be correctly reordered. If you delete any row, other rows will be correctly reordered.

How to define it? Distribution contains 3 SQL definition files.

### Structure

The main is `dist/trigger-position-structure.sql`. This file must be part of your DB schema. There are three helper SQL functions:

- `public.trigger_is_enabled(in_trigger_name text)`
- `public.trigger_enable(in_trigger_name text)`
- `public.trigger_disable(in_trigger_name text)`

These functions are used to control trigger recursion and/or can disable trigger. You can use it also in your own functions.

Enabling and disabling trigger is not made via `ALTER TABLE ... DISABLE/ENABLE TRIGGER ...` (which needs locks) but uses `set_config()/current_config()` to set custom setting just for active session.

If you want to disable default trigger position functionality just call `SELECT trigger_disable('<TABLE_NAME_WITH_SCHEMA>_trigger_position')`, make your INSERT/UPDATE/DELETE and call `SELECT trigger_enable('<TABLE_NAME_WITH_SCHEMA>_trigger_position')`.

The main part is trigger function `public.trigger_position()`. It accepts 3 optional parameters - array of groups, ID column name (if differs from `id`) and position column name (if differs from `position`).

To activate trigger on a table, you must define 3 triggers - `AFTER INSERT STATEMENT TRIGGER`, `AFTER UPDATE STATEMENT TRIGGER` and `AFTER DELETE STATEMENT TRIGGER`.

All with the same parameters for trigger function `trigger_position`. Because of referencing tables, you must define 3 triggers and not only one (`REFERNCING ... AS table_old/new` is important here).

Example:

- simple table `example` without groups

```sql
CREATE TABLE public.example
(
  id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  position integer,
  PRIMARY KEY (id)
);

CREATE TRIGGER example_position_trigger_insert
    AFTER INSERT
    ON public.example
    REFERENCING NEW TABLE AS table_new
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.trigger_position();

CREATE TRIGGER example_position_trigger_update
    AFTER UPDATE 
    ON public.example
    REFERENCING NEW TABLE AS table_new OLD TABLE AS table_old
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.trigger_position();

CREATE TRIGGER example_position_trigger_delete
    AFTER DELETE
    ON public.example
    REFERENCING OLD TABLE AS table_old
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.trigger_position();
```

- table `example_with_group` with two groups:

```sql
CREATE TABLE public.example_with_group
(
  id integer GENERATED ALWAYS AS IDENTITY,
  group_name integer NOT NULL,
  sub_group_name integer NOT NULL,
  name text NOT NULL,
  position integer,
  PRIMARY KEY (id)
);

CREATE TRIGGER example_with_group_position_trigger_insert
    AFTER INSERT
    ON public.example_with_group
    REFERENCING NEW TABLE AS table_new
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.trigger_position('{group_name,sub_group_name}');

CREATE TRIGGER example_with_group_position_trigger_update
    AFTER UPDATE 
    ON public.example_with_group
    REFERENCING NEW TABLE AS table_new OLD TABLE AS table_old
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.trigger_position('{group_name,sub_group_name}');

CREATE TRIGGER example_with_group_position_trigger_delete
    AFTER DELETE
    ON public.example_with_group
    REFERENCING OLD TABLE AS table_old
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.trigger_position('{group_name,sub_group_name}');
```

- table `example_key` with alternate ID column:

```sql
CREATE TABLE public.example_key
(
  key integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  position integer,
  PRIMARY KEY (key)
);

CREATE TRIGGER example_key_position_trigger_insert
    AFTER INSERT
    ON public.example_key
    REFERENCING NEW TABLE AS table_new
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.trigger_position('{}', 'key');

...
```

- table `example_pos` with alternate position column:

```sql
CREATE TABLE public.example_pos
(
  id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  pos integer,
  PRIMARY KEY (id)
);

CREATE TRIGGER example_pos_position_trigger_insert
    AFTER INSERT
    ON public.example_pos
    REFERENCING NEW TABLE AS table_new
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.trigger_position('{}', 'id', 'pos');

...
```

> `NULL` value in `position` column means - move this row to the end - because of it - the `position` column must be NULLable

> For bigger tables with groups, it is a good thought to add index for some or all group columns 

> There are two limitations:
> - multi-inserts - when you're inserting rows to existing positions, these rows are moving to the new positions, and it could collide with your other inserts, and the final positions can differ from what are you expecting - _see tests_
> - CTE queries - when you're doing more operations (INSERT and UPDATE and DELETE) on one table, some are not caught by the trigger - to be honest - I don't know why, but I'm not expecting these types of queries in real life - _see tests_ 

### Control

To simplify creating and removing position triggers, you can also import file `dist/trigger-position-control.sql`. It creates new schema `system` and add 2 new SQL functions:

- `system.trigger_position_add(in_schema_name text, in_table_name text, in_group_columns text DEFAULT NULL, in_key_column text DEFAULT NULL, in_position_column text DEFAULT NULL)`
- `system.trigger_position_remove(in_schema_name text, in_table_name text)`

Function `system.trigger_position_add()` as the name implies create all 3 triggers for a table:

```sql
SELECT system.trigger_position_add('public', 'example'); -- without groups
SELECT system.trigger_position_add('public', 'example', 'group_name'); -- with one group (not array syntax, just names separated with a comma)
SELECT system.trigger_position_add('public', 'example', 'group_name,sub_group_name'); -- with two groups (not array syntax, just names separated with a comma)
SELECT system.trigger_position_add('public', 'example', NULL, 'key'); -- with alternate ID column
SELECT system.trigger_position_add('public', 'example', NULL, NULL, 'position'); -- with alternate position column
SELECT system.trigger_position_add('public', 'example', 'group_name,sub_group_name', 'key', 'position'); -- all together
```

Function `system.trigger_position_remove()` is the opposite and removes the triggers. It needs just schema and table name.

### Check

Even if the trigger is properly tested, file `dist/trigger-position-check.sql` contains SQL that generates controls SELECTs for all tables with trigger position.

Just run the SQL and then run all generated SELECTs. If SELECT return 0 rows, everything is OK. Only rows with bad position are returned.

## How it works

> Mostly for my future me :-)

The basic idea is simple (and not mine, but my former colleague [Martin Major](https://github.com/MartinMajor)) - correct positions are computed with PostgreSQL window function [`row_number()`](https://www.postgresql.org/docs/current/functions-window.html).

This guarantees unbroken numeric series. The magic is to mix existing rows with new/updated/deleted rows in the correct order and partition it with the correct groups.

First, we will discuss the easy situation, where there are no groups, and we want to order the whole table:

- on DELETE is the situation very easy, just sort all remaining rows in the table and update changed positions
- on INSERT, we take all rows from table except the new ones (they in the referencing table `table_new`) and we say, that their position is plus `0.1` - this is because when we're inserting some row on the existing position, the old row should be after this new one. These row we will `UNION` with newly inserted rows from table `table_new` and the result is correctly sorted
- UPDATE is a tricky one. First, we will perform it only if there is some row with changed position. Then we will take all existing rows from the table, except rows with changed position (we can detect it from referencing tables `table_new` and `table_old`), also set position plus `0.1` and `UNION` this with rows with changed position. We need to do here one more trick - if for some row has the new position greater than the old position - we need to add `0.2` to the row position. Because the row is moved down, we must put if after the existing one

The part with groups is more complex. Because we don't want to recalculate the whole table with all groups, we need to get only groups with a "significant change" and update only these. What is a significant change?
- group has significant change if there is some new or removed row (so all groups from rows in referencing tables `table_new` or `table_old` for INSERT or DELETE)
- group has significant change if some row from group has changed position (we can detect it from referencing tables `table_new` and `table_old`)
- and group has also significant change if some group has changed (we can detect it from referencing tables `table_new` and `table_old`) and we need to recalculate new group and also old group

For INSERT or DELETE, the algorithm is similar to the table without groups. We just don't do recalculation for the whole table, but first, we generate condition that will take only groups with a significant change - that's all groups in `table_new` or `table_old`.

UPDATE is the most complex part of the whole algorithm. We need to detect changes in the old groups and in the new groups together and recalculate all these data.

We have many helper variables generated here. First SQL conditions that detects changed group (`v_where_some_group_is_changed`) and not changed group (`v_where_all_groups_are_same`). These are not working with actual data from referencing tables, just with group columns definitions.

Changed group is the one where at least one group column is changed from old to new. Not changed group is the one, when all old and new group columns are the same.

Groups can be NULLable so using `IS DISTINCT FROM` and `IS NOT DISTINCT FROM` looks like a good choice, but with this, PostgreSQL can't use indexes on the group columns. So because of performance, the conditions are a little more complex.   

Next helpers are for conditions that work with actual data from referencing tables and detects all groups with some significant change for old data (`v_table_old_where_sql`) and new data (`v_table_new_where_sql`).

With all these helper variables, we can prepare SELECT that take all existing rows from the table where some group has some significant change in old or new data, except updated data where some position is changed or some group is changed. In these rows is also the trick with plus `0.1` for position. These rows are `UNION` with updated data, where position is changed or some group is changed. There is also the trick with plus `0.2` to position, if new position is greater than old position, but here only for rows, where the group is not changed. It is because when a group is changed, you want to put record before the existing one and only for moving in the current group you must add if after.   

> Optimizations: whole trigger tries to be as efficient as it could, so in general
> - no action is taken if no rows were inserted, updated or deleted - execution is stopped as soon as possible
> - no action is taken if no significant change is made for update
> - updates are only rows with change position in final recalculation
> - there is UPDATE at the end of the position trigger that will run the position trigger again (in this case nothing is updated so no new UPDATE is made here) - to avoid this recursion a check is here made with `trigger_disable` and `trigger_enable` functions (maybe you want to ignore some your internal stuff here too - for example auditing changes)

### Tests

There are several scenarios that (I hope) cover all possible actions:

- `tests/test-table-without-group.sql` - simple table without any group column
- `tests/test-table-with-one-group.sql` - table with one group column
- `tests/test-table-with-two-groups.sql` - table with two group columns
- `tests/test-table-with-null-group.sql` - table with one and table with two group columns where value can be `NULL`
- `tests/test-alter-id-position-columns.sql` - simple table without any group column, table with one group column and table with two group columns with a different `id` and `position` column

Some tests helpers is also defined in `tests/tests-structure.sql`.

Tests are run in a separate database that is removed at the end.

To run the tests, you just need to provide password to `postgres` user via variable `PGPASSWORD`. For example:

```bash
PGPASSWORD=postgres tests/run-tests
```

### ToDo?

- add settings to group column not by its value, but just NULL/NOT NULL (can be solved with generated columns right now, it can be handy for columns like `deleted_datetime` - when `NULL` is for active records and timestamp is for deleted records - but with this, deleted record can't be sorted with `position` - every timestamp will have `position = 1`...)
- tests: rewrite test scenarios to separate test cases - every test has defined data, and it's not depending on the previous test 