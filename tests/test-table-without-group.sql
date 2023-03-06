CREATE TABLE tests.test_table_without_group
(
  id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  position integer,
  CONSTRAINT test_table_without_group_pkey PRIMARY KEY (id)
);

-- CHECK QUERY: SELECT * FROM tests.test_table_without_group ORDER BY position;

SELECT system.trigger_position_add('tests', 'test_table_without_group');

----------

-- ID: 1, POSITION: 1 (NULL)
INSERT INTO tests.test_table_without_group(name, position) VALUES ('first', NULL);
/*
 id | name  | position
----+-------+----------
  1 | first |        1
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[1], ARRAY[1]);

-- ID: 2, POSITION: 2 (NULL)
INSERT INTO tests.test_table_without_group(name, position) VALUES ('second', NULL);
/*
 id |  name  | position
----+--------+----------
  1 | first  |        1
  2 | second |        2
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[1, 2], ARRAY[1, 2]);

-- ID: 3, POSITION: 3
INSERT INTO tests.test_table_without_group(name, position) VALUES ('third', 3);
/*
 id |  name  | position
----+--------+----------
  1 | first  |        1
  2 | second |        2
  3 | third  |        3
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[1, 2, 3], ARRAY[1, 2, 3]);

-- ID: 4, POSITION: 1
INSERT INTO tests.test_table_without_group(name, position) VALUES ('new-first', 1);
/*
 id |   name    | position
----+-----------+----------
  4 | new-first |        1
  1 | first     |        2
  2 | second    |        3
  3 | third     |        4
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[4, 1, 2, 3], ARRAY[1, 2, 3, 4]);

-- ID: 5, POSITION: 2
INSERT INTO tests.test_table_without_group(name, position) VALUES ('new-second', 2);
/*
 id |    name    | position
----+------------+----------
  4 | new-first  |        1
  5 | new-second |        2
  1 | first      |        3
  2 | second     |        4
  3 | third      |        5
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[4, 5, 1, 2, 3], ARRAY[1, 2, 3, 4, 5]);

-- ID: 6, POSITION: 6 (20)
INSERT INTO tests.test_table_without_group(name, position) VALUES ('new-last', 20);
/*
 id |    name    | position
----+------------+----------
  4 | new-first  |        1
  5 | new-second |        2
  1 | first      |        3
  2 | second     |        4
  3 | third      |        5
  6 | new-last   |        6
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[4, 5, 1, 2, 3, 6], ARRAY[1, 2, 3, 4, 5, 6]);

-- DELETE NON EXISTING
DELETE FROM tests.test_table_without_group WHERE id = 7;
/*
 id |    name    | position
----+------------+----------
  4 | new-first  |        1
  5 | new-second |        2
  1 | first      |        3
  2 | second     |        4
  3 | third      |        5
  6 | new-last   |        6
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[4, 5, 1, 2, 3, 6], ARRAY[1, 2, 3, 4, 5, 6]);

-- DELETE LAST - ID: 6
DELETE FROM tests.test_table_without_group WHERE id = 6;
/*
 id |    name    | position
----+------------+----------
  4 | new-first  |        1
  5 | new-second |        2
  1 | first      |        3
  2 | second     |        4
  3 | third      |        5
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[4, 5, 1, 2, 3], ARRAY[1, 2, 3, 4, 5]);

-- DELETE FIRST - ID: 4
DELETE FROM tests.test_table_without_group WHERE id = 4;
/*
 id |    name    | position
----+------------+----------
  5 | new-second |        1
  1 | first      |        2
  2 | second     |        3
  3 | third      |        4
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[5, 1, 2, 3], ARRAY[1, 2, 3, 4]);

-- DELETE SECOND - ID: 1
DELETE FROM tests.test_table_without_group WHERE id = 1;
/*
 id |    name    | position
----+------------+----------
  5 | new-second |        1
  2 | second     |        2
  3 | third      |        3
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[5, 2, 3], ARRAY[1, 2, 3]);

-- UPDATE NON EXISTING
UPDATE tests.test_table_without_group SET position = 2 WHERE id = 6;
/*
 id |    name    | position
----+------------+----------
  5 | new-second |        1
  2 | second     |        2
  3 | third      |        3
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[5, 2, 3], ARRAY[1, 2, 3]);

-- MOVE FIRST TO SECOND - ID: 5 -> POSITION: 2
UPDATE tests.test_table_without_group SET position = 2 WHERE id = 5;
/*
 id |    name    | position
----+------------+----------
  2 | second     |        1
  5 | new-second |        2
  3 | third      |        3
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[2, 5, 3], ARRAY[1, 2, 3]);

-- MOVE FIRST TO THIRD - ID: 2 -> POSITION: 3
UPDATE tests.test_table_without_group SET position = 3 WHERE id = 2;
/*
 id |    name    | position
----+------------+----------
  5 | new-second |        1
  3 | third      |        2
  2 | second     |        3
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[5, 3, 2], ARRAY[1, 2, 3]);

-- MOVE FIRST TO LAST - ID: 5 -> POSITION: 3 (NULL)
UPDATE tests.test_table_without_group SET position = NULL WHERE id = 5;
/*
 id |    name    | position
----+------------+----------
  3 | third      |        1
  2 | second     |        2
  5 | new-second |        3
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[3, 2, 5], ARRAY[1, 2, 3]);

-- MOVE SECOND TO THIRD - ID: 3 -> POSITION: 3
UPDATE tests.test_table_without_group SET position = 3 WHERE id = 2;
/*
 id |    name    | position
----+------------+----------
  3 | third      |        1
  5 | new-second |        2
  2 | second     |        3
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[3, 5, 2], ARRAY[1, 2, 3]);

-- MOVE SECOND TO FIRST - ID: 5 -> POSITION: 1
UPDATE tests.test_table_without_group SET position = 1 WHERE id = 5;
/*
 id |    name    | position
----+------------+----------
  5 | new-second |        1
  3 | third      |        2
  2 | second     |        3
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[5, 3, 2], ARRAY[1, 2, 3]);

-- MOVE THIRD TO FIRST - ID: 2 -> POSITION: 0
UPDATE tests.test_table_without_group SET position = 0 WHERE id = 2;
/*
 id |    name    | position
----+------------+----------
  2 | second     |        1
  5 | new-second |        2
  3 | third      |        3
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[2, 5, 3], ARRAY[1, 2, 3]);

-- MOVE THIRD TO SECOND - ID: 3 -> POSITION: 2
UPDATE tests.test_table_without_group SET position = 2 WHERE id = 3;
/*
 id |    name    | position
----+------------+----------
  2 | second     |        1
  3 | third      |        2
  5 | new-second |        3
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[2, 3, 5], ARRAY[1, 2, 3]);

-- MULTI-INSERT
-- - LAST ID: 8 -> POSITION: 4 (NULL)
-- - FIRST ID: 9 -> POSITION: 1
INSERT INTO tests.test_table_without_group(name, position) VALUES
  ('multi-last', NULL),
  ('multi-first', 1);
/*
 id |    name     | position
----+-------------+----------
  8 | multi-first |        1
  2 | second      |        2
  3 | third       |        3
  5 | new-second  |        4
  7 | multi-last  |        5
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[8, 2, 3, 5, 7], ARRAY[1, 2, 3, 4, 5]);

-- MULTI-UPDATE
-- - FIFTH TO FIRST ID: 7 -> POSITION: 1
-- - SECOND TO FIFTH ID: 2 -> POSITION: 5
UPDATE tests.test_table_without_group AS t
   SET position = x.position
  FROM (SELECT unnest(ARRAY[7, 2]) AS id, unnest(ARRAY[1, 5]) AS position) AS x
 WHERE t.id = x.id;
/*
 id |    name     | position
----+-------------+----------
  7 | multi-last  |        1
  8 | multi-first |        2
  3 | third       |        3
  5 | new-second  |        4
  2 | second      |        5
*/
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[7, 8, 3, 5, 2], ARRAY[1, 2, 3, 4, 5]);

-- THIS IS NOT WORKING :-( LAST UPDATE HAS NO RECORD IN table_new AND table_old
-- CTE (real SQL commands order is this)
-- - INSERT LAST ID: 9 -> POSITION: 6 (NULL)
-- - DELETE SECOND ID: 8
-- - MOVE NEW LAST TO FIRST ID: 9 -> POSITION: 1
/*
WITH upd AS (
  UPDATE tests.test_table_without_group SET position = 1 WHERE id = 7
), del AS (
  DELETE FROM tests.test_table_without_group WHERE id = 8
)
INSERT INTO tests.test_table_without_group(name, position) VALUES ('cte-first', NULL);
SELECT tests.assert_positions('tests.test_table_without_group', ARRAY[9, 7, 3, 5, 2], ARRAY[1, 2, 3, 4, 5]);
*/

----------

SELECT system.trigger_position_remove('tests', 'test_table_without_group');

DROP TABLE tests.test_table_without_group;
