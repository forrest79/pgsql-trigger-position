-- ############################################################################
-- ### ALTER ID COLUMN


-- ----------------------------------------------------------------------------
-- - WITHOUT GROUPS

CREATE TABLE tests.test_table_alter_id_without_group
(
  alter_id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  position integer,
  CONSTRAINT test_table_alter_id_without_group_pkey PRIMARY KEY (alter_id)
);

SELECT system.trigger_position_add('tests', 'test_table_alter_id_without_group', NULL, 'alter_id');

INSERT INTO tests.test_table_alter_id_without_group(name, position) VALUES
  ('first', NULL),
  ('second', NULL);
/*
 alter_id |  name  | position
----------+--------+----------
        1 | first  |        1
        2 | second |        2
*/
SELECT tests.assert_positions('tests.test_table_alter_id_without_group', ARRAY[1, 2], ARRAY[1, 2], 'alter_id');

UPDATE tests.test_table_alter_id_without_group SET position = 1 WHERE alter_id = 2;
/*
 alter_id |  name  | position
----------+--------+----------
        2 | second |        1
        1 | first  |        2
*/
SELECT tests.assert_positions('tests.test_table_alter_id_without_group', ARRAY[2, 1], ARRAY[1, 2], 'alter_id');

DELETE FROM tests.test_table_alter_id_without_group WHERE alter_id = 2;
/*
 alter_id | name  | position
----------+-------+----------
        1 | first |        1
*/
SELECT tests.assert_positions('tests.test_table_alter_id_without_group', ARRAY[1], ARRAY[1], 'alter_id');

SELECT system.trigger_position_remove('tests', 'test_table_alter_id_without_group');

DROP TABLE tests.test_table_alter_id_without_group;


-- ----------------------------------------------------------------------------
-- - WITH ONE GROUP

CREATE TABLE tests.test_table_alter_id_with_one_group
(
  alter_id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  country_id integer NOT NULL,
  position integer,
  CONSTRAINT test_table_alter_id_with_one_group_pkey PRIMARY KEY (alter_id)
);

SELECT system.trigger_position_add('tests', 'test_table_alter_id_with_one_group', 'country_id', 'alter_id');

INSERT INTO tests.test_table_alter_id_with_one_group(name, country_id, position) VALUES
  ('1-first', 1, NULL),
  ('1-second', 1, NULL),
  ('2-first', 2, NULL),
  ('2-second', 2, NULL);
/*
 alter_id |   name   | country_id | position
----------+----------+------------+----------
        1 | 1-first  |          1 |        1
        2 | 1-second |          1 |        2
        3 | 2-first  |          2 |        1
        4 | 2-second |          2 |        2
*/
SELECT tests.assert_positions('tests.test_table_alter_id_with_one_group', ARRAY[1, 2, 3, 4], ARRAY[1, 2, 1, 2], 'alter_id');

UPDATE tests.test_table_alter_id_with_one_group AS t
   SET position = x.position,
       country_id = x.country_id
  FROM (SELECT unnest(ARRAY[1, 4]) AS id, unnest(ARRAY[2, 3]) AS position, unnest(ARRAY[1, 1]) AS country_id) AS x
 WHERE t.alter_id = x.id;
/*
 alter_id |   name   | country_id | position
----------+----------+------------+----------
        2 | 1-second |          1 |        1
        1 | 1-first  |          1 |        2
        4 | 2-second |          1 |        3
        3 | 2-first  |          2 |        1
*/

SELECT tests.assert_positions('tests.test_table_alter_id_with_one_group', ARRAY[2, 1, 4, 3], ARRAY[1, 2, 3, 1], 'alter_id');

DELETE FROM tests.test_table_alter_id_with_one_group WHERE alter_id IN (2, 3);
/*
 alter_id |   name   | country_id | position
----------+----------+------------+----------
        1 | 1-first  |          1 |        1
        4 | 2-second |          1 |        2
*/
SELECT tests.assert_positions('tests.test_table_alter_id_with_one_group', ARRAY[1, 4], ARRAY[1, 2], 'alter_id');

SELECT system.trigger_position_remove('tests', 'test_table_alter_id_with_one_group');

DROP TABLE tests.test_table_alter_id_with_one_group;


-- ----------------------------------------------------------------------------
-- - WITH TWO GROUPS

CREATE TABLE tests.test_table_alter_id_with_two_groups
(
  alter_id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  country_id integer NOT NULL,
  town_id integer NOT NULL,
  position integer,
  CONSTRAINT test_table_alter_id_with_two_groups_pkey PRIMARY KEY (alter_id)
);

SELECT system.trigger_position_add('tests', 'test_table_alter_id_with_two_groups', 'country_id,town_id', 'alter_id');

INSERT INTO tests.test_table_alter_id_with_two_groups(name, country_id, town_id, position) VALUES
  ('1-1-multi-last1', 1, 1, NULL),
  ('1-1-multi-last2', 1, 1, NULL),
  ('1-2-multi-last1', 1, 2, NULL),
  ('1-2-multi-first', 1, 2, NULL),
  ('2-1-multi-last2', 2, 1, NULL),
  ('2-1-multi-second', 2, 1, NULL);
/*
 alter_id |       name       | country_id | town_id | position
----------+------------------+------------+---------+----------
        1 | 1-1-multi-last1  |          1 |       1 |        1
        2 | 1-1-multi-last2  |          1 |       1 |        2
        3 | 1-2-multi-last1  |          1 |       2 |        1
        4 | 1-2-multi-first  |          1 |       2 |        2
        5 | 2-1-multi-last2  |          2 |       1 |        1
        6 | 2-1-multi-second |          2 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_alter_id_with_two_groups', ARRAY[1, 2, 3, 4, 5, 6], ARRAY[1, 2, 1, 2, 1, 2], 'alter_id');

UPDATE tests.test_table_alter_id_with_two_groups AS t
   SET position = x.position,
       country_id = x.country_id,
       town_id = x.town_id
  FROM (SELECT unnest(ARRAY[2, 3, 5]) AS id, unnest(ARRAY[1, 2, 3]) AS position, unnest(ARRAY[1, 1, 1]) AS country_id, unnest(ARRAY[1, 2, 2]) AS town_id) AS x
 WHERE t.alter_id = x.id;
/*
 alter_id |       name       | country_id | town_id | position
----------+------------------+------------+---------+----------
        2 | 1-1-multi-last2  |          1 |       1 |        1
        1 | 1-1-multi-last1  |          1 |       1 |        2
        4 | 1-2-multi-first  |          1 |       2 |        1
        3 | 1-2-multi-last1  |          1 |       2 |        2
        5 | 2-1-multi-last2  |          1 |       2 |        3
        6 | 2-1-multi-second |          2 |       1 |        1
*/
SELECT tests.assert_positions('tests.test_table_alter_id_with_two_groups', ARRAY[2, 1, 4, 3, 5, 6], ARRAY[1, 2, 1, 2, 3, 1], 'alter_id');

DELETE FROM tests.test_table_alter_id_with_two_groups WHERE alter_id IN (2, 3, 6);
/*
 alter_id |      name       | country_id | town_id | position
----------+-----------------+------------+---------+----------
        1 | 1-1-multi-last1 |          1 |       1 |        1
        4 | 1-2-multi-first |          1 |       2 |        1
        5 | 2-1-multi-last2 |          1 |       2 |        2
*/
SELECT tests.assert_positions('tests.test_table_alter_id_with_two_groups', ARRAY[1, 4, 5], ARRAY[1, 1, 2], 'alter_id');

SELECT system.trigger_position_remove('tests', 'test_table_alter_id_with_two_groups');

DROP TABLE tests.test_table_alter_id_with_two_groups;



-- ############################################################################
-- ### ALTER POSITION COLUMN


-- ----------------------------------------------------------------------------
-- WITHOUT GROUPS

CREATE TABLE tests.test_table_alter_pos_without_group
(
  id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  alter_position integer,
  CONSTRAINT test_table_alter_pos_without_group_pkey PRIMARY KEY (id)
);

SELECT system.trigger_position_add('tests', 'test_table_alter_pos_without_group', NULL, 'id', 'alter_position');

INSERT INTO tests.test_table_alter_pos_without_group(name, alter_position) VALUES
  ('first', NULL),
  ('second', NULL);
/*
 id |  name  | alter_position
----+--------+----------------
  1 | first  |              1
  2 | second |              2
*/
SELECT tests.assert_positions('tests.test_table_alter_pos_without_group', ARRAY[1, 2], ARRAY[1, 2], 'id', 'alter_position');

UPDATE tests.test_table_alter_pos_without_group SET alter_position = 1 WHERE id = 2;
/*
 id |  name  | alter_position
----+--------+----------------
  2 | second |              1
  1 | first  |              2
*/
SELECT tests.assert_positions('tests.test_table_alter_pos_without_group', ARRAY[2, 1], ARRAY[1, 2], 'id', 'alter_position');

DELETE FROM tests.test_table_alter_pos_without_group WHERE id = 2;
/*
 id | name  | alter_position
----+-------+----------------
  1 | first |              1
*/
SELECT tests.assert_positions('tests.test_table_alter_pos_without_group', ARRAY[1], ARRAY[1], 'id', 'alter_position');

SELECT system.trigger_position_remove('tests', 'test_table_alter_pos_without_group');

DROP TABLE tests.test_table_alter_pos_without_group;


-- ----------------------------------------------------------------------------
-- WITH ONE GROUP

CREATE TABLE tests.test_table_alter_pos_with_one_group
(
  id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  country_id integer NOT NULL,
  alter_position integer,
  CONSTRAINT test_table_alter_pos_with_one_group_pkey PRIMARY KEY (id)
);

SELECT system.trigger_position_add('tests', 'test_table_alter_pos_with_one_group', 'country_id', NULL, 'alter_position');

INSERT INTO tests.test_table_alter_pos_with_one_group(name, country_id, alter_position) VALUES
  ('1-first', 1, NULL),
  ('1-second', 1, NULL),
  ('2-first', 2, NULL),
  ('2-second', 2, NULL);
/*
 id |   name   | country_id | alter_position
----+----------+------------+----------------
  1 | 1-first  |          1 |              1
  2 | 1-second |          1 |              2
  3 | 2-first  |          2 |              1
  4 | 2-second |          2 |              2
*/
SELECT tests.assert_positions('tests.test_table_alter_pos_with_one_group', ARRAY[1, 2, 3, 4], ARRAY[1, 2, 1, 2], 'id', 'alter_position');

UPDATE tests.test_table_alter_pos_with_one_group AS t
   SET alter_position = x.position,
       country_id = x.country_id
  FROM (SELECT unnest(ARRAY[1, 4]) AS id, unnest(ARRAY[2, 3]) AS position, unnest(ARRAY[1, 1]) AS country_id) AS x
 WHERE t.id = x.id;
/*
 id |   name   | country_id | alter_position
----+----------+------------+----------------
  2 | 1-second |          1 |              1
  1 | 1-first  |          1 |              2
  4 | 2-second |          1 |              3
  3 | 2-first  |          2 |              1
*/
SELECT tests.assert_positions('tests.test_table_alter_pos_with_one_group', ARRAY[2, 1, 4, 3], ARRAY[1, 2, 3, 1], 'id', 'alter_position');

DELETE FROM tests.test_table_alter_pos_with_one_group WHERE id IN (2, 3);
/*
 id |   name   | country_id | alter_position
----+----------+------------+----------------
  1 | 1-first  |          1 |              1
  4 | 2-second |          1 |              2
*/
SELECT tests.assert_positions('tests.test_table_alter_pos_with_one_group', ARRAY[1, 4], ARRAY[1, 2], 'id', 'alter_position');

SELECT system.trigger_position_remove('tests', 'test_table_alter_pos_with_one_group');

DROP TABLE tests.test_table_alter_pos_with_one_group;


-- ----------------------------------------------------------------------------
-- WITH TWO GROUPS

CREATE TABLE tests.test_table_alter_pos_with_two_groups
(
  id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  country_id integer NOT NULL,
  town_id integer NOT NULL,
  alter_position integer,
  CONSTRAINT test_table_alter_pos_with_two_groups_pkey PRIMARY KEY (id)
);

SELECT system.trigger_position_add('tests', 'test_table_alter_pos_with_two_groups', 'country_id,town_id', NULL, 'alter_position');

INSERT INTO tests.test_table_alter_pos_with_two_groups(name, country_id, town_id, alter_position) VALUES
  ('1-1-multi-last1', 1, 1, NULL),
  ('1-1-multi-last2', 1, 1, NULL),
  ('1-2-multi-last1', 1, 2, NULL),
  ('1-2-multi-first', 1, 2, NULL),
  ('2-1-multi-last2', 2, 1, NULL),
  ('2-1-multi-second', 2, 1, NULL);
/*
 id |       name       | country_id | town_id | alter_position
----+------------------+------------+---------+----------------
  1 | 1-1-multi-last1  |          1 |       1 |              1
  2 | 1-1-multi-last2  |          1 |       1 |              2
  3 | 1-2-multi-last1  |          1 |       2 |              1
  4 | 1-2-multi-first  |          1 |       2 |              2
  5 | 2-1-multi-last2  |          2 |       1 |              1
  6 | 2-1-multi-second |          2 |       1 |              2
*/
SELECT tests.assert_positions('tests.test_table_alter_pos_with_two_groups', ARRAY[1, 2, 3, 4, 5, 6], ARRAY[1, 2, 1, 2, 1, 2], 'id', 'alter_position');

UPDATE tests.test_table_alter_pos_with_two_groups AS t
   SET alter_position = x.position,
       country_id = x.country_id,
       town_id = x.town_id
  FROM (SELECT unnest(ARRAY[2, 3, 5]) AS id, unnest(ARRAY[1, 2, 3]) AS position, unnest(ARRAY[1, 1, 1]) AS country_id, unnest(ARRAY[1, 2, 2]) AS town_id) AS x
 WHERE t.id = x.id;
/*
 id |       name       | country_id | town_id | alter_position
----+------------------+------------+---------+----------------
  2 | 1-1-multi-last2  |          1 |       1 |              1
  1 | 1-1-multi-last1  |          1 |       1 |              2
  4 | 1-2-multi-first  |          1 |       2 |              1
  3 | 1-2-multi-last1  |          1 |       2 |              2
  5 | 2-1-multi-last2  |          1 |       2 |              3
  6 | 2-1-multi-second |          2 |       1 |              1
*/
SELECT tests.assert_positions('tests.test_table_alter_pos_with_two_groups', ARRAY[2, 1, 4, 3, 5, 6], ARRAY[1, 2, 1, 2, 3, 1], 'id', 'alter_position');

DELETE FROM tests.test_table_alter_pos_with_two_groups WHERE id IN (2, 3, 6);
/*
 id |      name       | country_id | town_id | alter_position
----+-----------------+------------+---------+----------------
  1 | 1-1-multi-last1 |          1 |       1 |              1
  4 | 1-2-multi-first |          1 |       2 |              1
  5 | 2-1-multi-last2 |          1 |       2 |              2
*/
SELECT tests.assert_positions('tests.test_table_alter_pos_with_two_groups', ARRAY[1, 4, 5], ARRAY[1, 1, 2], 'id', 'alter_position');

SELECT system.trigger_position_remove('tests', 'test_table_alter_pos_with_two_groups');

DROP TABLE tests.test_table_alter_pos_with_two_groups;



-- ############################################################################
-- ### ALTER ID AND POSITION COLUMN


-- ----------------------------------------------------------------------------
-- WITHOUT GROUPS

CREATE TABLE tests.test_table_alter_id_pos_without_group
(
  alter_id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  alter_position integer,
  CONSTRAINT test_table_alter_id_pos_without_group_pkey PRIMARY KEY (alter_id)
);

SELECT system.trigger_position_add('tests', 'test_table_alter_id_pos_without_group', NULL, 'alter_id', 'alter_position');

INSERT INTO tests.test_table_alter_id_pos_without_group(name, alter_position) VALUES
  ('first', NULL),
  ('second', NULL);
/*
 alter_id |  name  | alter_position
----------+--------+----------------
        1 | first  |              1
        2 | second |              2
*/
SELECT tests.assert_positions('tests.test_table_alter_id_pos_without_group', ARRAY[1, 2], ARRAY[1, 2], 'alter_id', 'alter_position');

UPDATE tests.test_table_alter_id_pos_without_group SET alter_position = 1 WHERE alter_id = 2;
/*
 alter_id |  name  | alter_position
----------+--------+----------------
        2 | second |              1
        1 | first  |              2
*/
SELECT tests.assert_positions('tests.test_table_alter_id_pos_without_group', ARRAY[2, 1], ARRAY[1, 2], 'alter_id', 'alter_position');

DELETE FROM tests.test_table_alter_id_pos_without_group WHERE alter_id = 2;
/*
 alter_id | name  | alter_position
----------+-------+----------------
        1 | first |              1
*/
SELECT tests.assert_positions('tests.test_table_alter_id_pos_without_group', ARRAY[1], ARRAY[1], 'alter_id', 'alter_position');

SELECT system.trigger_position_remove('tests', 'test_table_alter_id_pos_without_group');

DROP TABLE tests.test_table_alter_id_pos_without_group;


-- ----------------------------------------------------------------------------
-- WITH ONE GROUP

CREATE TABLE tests.test_table_alter_id_pos_with_one_group
(
  alter_id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  country_id integer NOT NULL,
  alter_position integer,
  CONSTRAINT test_table_alter_id_pos_with_one_group_pkey PRIMARY KEY (alter_id)
);

SELECT system.trigger_position_add('tests', 'test_table_alter_id_pos_with_one_group', 'country_id', 'alter_id', 'alter_position');

INSERT INTO tests.test_table_alter_id_pos_with_one_group(name, country_id, alter_position) VALUES
  ('1-first', 1, NULL),
  ('1-second', 1, NULL),
  ('2-first', 2, NULL),
  ('2-second', 2, NULL);
/*
 alter_id |   name   | country_id | alter_position
----------+----------+------------+----------------
        1 | 1-first  |          1 |              1
        2 | 1-second |          1 |              2
        3 | 2-first  |          2 |              1
        4 | 2-second |          2 |              2
*/
SELECT tests.assert_positions('tests.test_table_alter_id_pos_with_one_group', ARRAY[1, 2, 3, 4], ARRAY[1, 2, 1, 2], 'alter_id', 'alter_position');

UPDATE tests.test_table_alter_id_pos_with_one_group AS t
   SET alter_position = x.position,
       country_id = x.country_id
  FROM (SELECT unnest(ARRAY[1, 4]) AS id, unnest(ARRAY[2, 3]) AS position, unnest(ARRAY[1, 1]) AS country_id) AS x
 WHERE t.alter_id = x.id;
/*
 alter_id |   name   | country_id | alter_position
----------+----------+------------+----------------
        2 | 1-second |          1 |              1
        1 | 1-first  |          1 |              2
        4 | 2-second |          1 |              3
        3 | 2-first  |          2 |              1
*/
SELECT tests.assert_positions('tests.test_table_alter_id_pos_with_one_group', ARRAY[2, 1, 4, 3], ARRAY[1, 2, 3, 1], 'alter_id', 'alter_position');

DELETE FROM tests.test_table_alter_id_pos_with_one_group WHERE alter_id IN (2, 3);
/*
 alter_id |   name   | country_id | alter_position
----------+----------+------------+----------------
        1 | 1-first  |          1 |              1
        4 | 2-second |          1 |              2
*/
SELECT tests.assert_positions('tests.test_table_alter_id_pos_with_one_group', ARRAY[1, 4], ARRAY[1, 2], 'alter_id', 'alter_position');

SELECT system.trigger_position_remove('tests', 'test_table_alter_id_pos_with_one_group');

DROP TABLE tests.test_table_alter_id_pos_with_one_group;


-- ----------------------------------------------------------------------------
-- WITH TWO GROUPS

CREATE TABLE tests.test_table_alter_id_pos_with_two_groups
(
  alter_id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  country_id integer NOT NULL,
  town_id integer NOT NULL,
  alter_position integer,
  CONSTRAINT test_table_alter_id_pos_with_two_groups_pkey PRIMARY KEY (alter_id)
);

SELECT system.trigger_position_add('tests', 'test_table_alter_id_pos_with_two_groups', 'country_id,town_id', 'alter_id', 'alter_position');

INSERT INTO tests.test_table_alter_id_pos_with_two_groups(name, country_id, town_id, alter_position) VALUES
  ('1-1-multi-last1', 1, 1, NULL),
  ('1-1-multi-last2', 1, 1, NULL),
  ('1-2-multi-last1', 1, 2, NULL),
  ('1-2-multi-first', 1, 2, NULL),
  ('2-1-multi-last2', 2, 1, NULL),
  ('2-1-multi-second', 2, 1, NULL);
/*
 alter_id |       name       | country_id | town_id | alter_position
----------+------------------+------------+---------+----------------
        1 | 1-1-multi-last1  |          1 |       1 |              1
        2 | 1-1-multi-last2  |          1 |       1 |              2
        3 | 1-2-multi-last1  |          1 |       2 |              1
        4 | 1-2-multi-first  |          1 |       2 |              2
        5 | 2-1-multi-last2  |          2 |       1 |              1
        6 | 2-1-multi-second |          2 |       1 |              2
*/
SELECT tests.assert_positions('tests.test_table_alter_id_pos_with_two_groups', ARRAY[1, 2, 3, 4, 5, 6], ARRAY[1, 2, 1, 2, 1, 2], 'alter_id', 'alter_position');

UPDATE tests.test_table_alter_id_pos_with_two_groups AS t
   SET alter_position = x.position,
       country_id = x.country_id,
       town_id = x.town_id
  FROM (SELECT unnest(ARRAY[2, 3, 5]) AS id, unnest(ARRAY[1, 2, 3]) AS position, unnest(ARRAY[1, 1, 1]) AS country_id, unnest(ARRAY[1, 2, 2]) AS town_id) AS x
 WHERE t.alter_id = x.id;
/*
 alter_id |       name       | country_id | town_id | alter_position
----------+------------------+------------+---------+----------------
        2 | 1-1-multi-last2  |          1 |       1 |              1
        1 | 1-1-multi-last1  |          1 |       1 |              2
        4 | 1-2-multi-first  |          1 |       2 |              1
        3 | 1-2-multi-last1  |          1 |       2 |              2
        5 | 2-1-multi-last2  |          1 |       2 |              3
        6 | 2-1-multi-second |          2 |       1 |              1
*/
SELECT tests.assert_positions('tests.test_table_alter_id_pos_with_two_groups', ARRAY[2, 1, 4, 3, 5, 6], ARRAY[1, 2, 1, 2, 3, 1], 'alter_id', 'alter_position');

DELETE FROM tests.test_table_alter_id_pos_with_two_groups WHERE alter_id IN (2, 3, 6);
/*
 alter_id |      name       | country_id | town_id | alter_position
----------+-----------------+------------+---------+----------------
        1 | 1-1-multi-last1 |          1 |       1 |              1
        4 | 1-2-multi-first |          1 |       2 |              1
        5 | 2-1-multi-last2 |          1 |       2 |              2
*/
SELECT tests.assert_positions('tests.test_table_alter_id_pos_with_two_groups', ARRAY[1, 4, 5], ARRAY[1, 1, 2], 'alter_id', 'alter_position');

SELECT system.trigger_position_remove('tests', 'test_table_alter_id_pos_with_two_groups');

DROP TABLE tests.test_table_alter_id_pos_with_two_groups;
