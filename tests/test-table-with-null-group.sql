-- ----------------------------------------------------------------------------
-- - WITH ONE GROUP

CREATE TABLE tests.test_table_with_one_group_null
(
  id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  country_id integer,
  position integer,
  CONSTRAINT test_table_with_one_group_null_pkey PRIMARY KEY (id)
);

SELECT system.trigger_position_add('tests', 'test_table_with_one_group_null', 'country_id');

INSERT INTO tests.test_table_with_one_group_null(name, country_id, position) VALUES
  ('NULL-first', NULL, NULL);

INSERT INTO tests.test_table_with_one_group_null(name, country_id, position) VALUES
  ('NULL-second', NULL, NULL),
  ('2-first', 2, NULL),
  ('2-second', 2, NULL);
/*
 id |    name     | country_id | position
----+-------------+------------+----------
  3 | 2-first     |          2 |        1
  4 | 2-second    |          2 |        2
  1 | NULL-first  |            |        1
  2 | NULL-second |            |        2
*/
SELECT tests.assert_positions('tests.test_table_with_one_group_null', ARRAY[1, 2, 3, 4], ARRAY[1, 2, 1, 2]);

UPDATE tests.test_table_with_one_group_null
   SET position = 1
 WHERE id = 2;

UPDATE tests.test_table_with_one_group_null
   SET position = 3,
       country_id = 2
 WHERE id = 1;

UPDATE tests.test_table_with_one_group_null
   SET position = NULL,
       country_id = 1
 WHERE id = 3;

UPDATE tests.test_table_with_one_group_null
   SET position = NULL,
       country_id = NULL
 WHERE id = 4;
/*
 id |    name     | country_id | position
----+-------------+------------+----------
  3 | 2-first     |          1 |        1
  1 | NULL-first  |          2 |        1
  2 | NULL-second |            |        1
  4 | 2-second    |            |        2
*/

SELECT tests.assert_positions('tests.test_table_with_one_group_null', ARRAY[2, 4, 3, 1], ARRAY[1, 2, 1, 1]);

DELETE FROM tests.test_table_with_one_group_null WHERE id IN (1, 2);
/*
 id |   name   | country_id | position
----+----------+------------+----------
  3 | 2-first  |          1 |        1
  4 | 2-second |            |        1
*/
SELECT tests.assert_positions('tests.test_table_with_one_group_null', ARRAY[3, 4], ARRAY[1, 1]);

SELECT system.trigger_position_remove('tests', 'test_table_with_one_group_null');

DROP TABLE tests.test_table_with_one_group_null;


-- ----------------------------------------------------------------------------
-- - WITH TWO GROUPS

CREATE TABLE tests.test_table_with_two_groups_null
(
  id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  country_id integer,
  town_id integer,
  position integer,
  CONSTRAINT test_table_with_two_groups_null_pkey PRIMARY KEY (id)
);

SELECT system.trigger_position_add('tests', 'test_table_with_two_groups_null', 'country_id,town_id');

INSERT INTO tests.test_table_with_two_groups_null(name, country_id, town_id, position) VALUES
  ('NULL-NULL-first', NULL, NULL, NULL);

INSERT INTO tests.test_table_with_two_groups_null(name, country_id, town_id, position) VALUES
  ('1-NULL-first', 1, NULL, NULL);

INSERT INTO tests.test_table_with_two_groups_null(name, country_id, town_id, position) VALUES
  ('NULL-NULL-second', NULL, NULL, NULL),
  ('1-NULL-second', 1, NULL, NULL),
  ('2-1-first', 2, 1, NULL),
  ('2-1-second', 2, 1, NULL);
/*
 id |       name       | country_id | town_id | position
----+------------------+------------+---------+----------
  2 | 1-NULL-first     |          1 |         |        1
  4 | 1-NULL-second    |          1 |         |        2
  5 | 2-1-first        |          2 |       1 |        1
  6 | 2-1-second       |          2 |       1 |        2
  1 | NULL-NULL-first  |            |         |        1
  3 | NULL-NULL-second |            |         |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups_null', ARRAY[1, 3, 2, 4, 5, 6], ARRAY[1, 2, 1, 2, 1, 2]);

UPDATE tests.test_table_with_two_groups_null
   SET position = 1,
       country_id = 2,
       town_id = 1
 WHERE id = 1;

UPDATE tests.test_table_with_two_groups_null
   SET position = NULL,
       country_id = NULL,
       town_id = 1
 WHERE id = 2;

UPDATE tests.test_table_with_two_groups_null
   SET position = 1,
       country_id = NULL,
       town_id = NULL
 WHERE id = 5;

UPDATE tests.test_table_with_two_groups_null
   SET position = 1
 WHERE id = 3;

UPDATE tests.test_table_with_two_groups_null
   SET country_id = NULL,
       town_id = 1
 WHERE id = 4;
/*
 id |       name       | country_id | town_id | position
----+------------------+------------+---------+----------
  1 | NULL-NULL-first  |          2 |       1 |        1
  6 | 2-1-second       |          2 |       1 |        2
  4 | 1-NULL-second    |            |       1 |        1
  2 | 1-NULL-first     |            |       1 |        2
  3 | NULL-NULL-second |            |         |        1
  5 | 2-1-first        |            |         |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups_null', ARRAY[1, 6, 4, 2, 3, 5], ARRAY[1, 2, 1, 2, 1, 2]);

DELETE FROM tests.test_table_with_two_groups_null WHERE id IN (1, 2, 3);
/*
 id |     name      | country_id | town_id | position
----+---------------+------------+---------+----------
  6 | 2-1-second    |          2 |       1 |        1
  4 | 1-NULL-second |            |       1 |        1
  5 | 2-1-first     |            |         |        1
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups_null', ARRAY[6, 4, 5], ARRAY[1, 1, 1]);

SELECT system.trigger_position_remove('tests', 'test_table_with_two_groups_null');

DROP TABLE tests.test_table_with_two_groups_null;
