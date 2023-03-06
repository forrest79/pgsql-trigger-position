CREATE TABLE tests.test_table_with_one_group
(
  id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  country_id integer NOT NULL,
  position integer,
  CONSTRAINT test_table_with_one_group_pkey PRIMARY KEY (id)
);

-- CHECK QUERY: SELECT * FROM tests.test_table_with_one_group ORDER BY country_id, position;

SELECT system.trigger_position_add('tests', 'test_table_with_one_group', 'country_id');

----------

-- ID: 1, COUNTRY_ID: 1, POSITION: 1 (NULL)
INSERT INTO tests.test_table_with_one_group(name, country_id, position) VALUES ('1-first', 1, NULL);
/*
 id |  name   | country_id | position
----+---------+------------+----------
  1 | 1-first |          1 |        1
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[1], ARRAY[1]);

-- ID: 2, COUNTRY_ID: 1, POSITION: 2 (NULL)
INSERT INTO tests.test_table_with_one_group(name, country_id, position) VALUES ('1-second', 1, NULL);
/*
 id |   name   | country_id | position
----+----------+------------+----------
  1 | 1-first  |          1 |        1
  2 | 1-second |          1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[1, 2], ARRAY[1, 2]);

-- ID: 3, COUNTRY_ID: 1, POSITION: 3
INSERT INTO tests.test_table_with_one_group(name, country_id, position) VALUES ('1-third', 1, 3);
/*
 id |   name   | country_id | position
----+----------+------------+----------
  1 | 1-first  |          1 |        1
  2 | 1-second |          1 |        2
  3 | 1-third  |          1 |        3
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[1, 2, 3], ARRAY[1, 2, 3]);

-- ID: 4, COUNTRY_ID: 2, POSITION: 1 (NULL)
INSERT INTO tests.test_table_with_one_group(name, country_id, position) VALUES ('2-first', 2, NULL);
/*
 id |   name   | country_id | position
----+----------+------------+----------
  1 | 1-first  |          1 |        1
  2 | 1-second |          1 |        2
  3 | 1-third  |          1 |        3
  4 | 2-first  |          2 |        1
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[1, 2, 3, 4], ARRAY[1, 2, 3, 1]);

-- ID: 5, COUNTRY_ID: 2, POSITION: 2
INSERT INTO tests.test_table_with_one_group(name, country_id, position) VALUES ('2-second', 2, 2);
/*
 id |   name   | country_id | position
----+----------+------------+----------
  1 | 1-first  |          1 |        1
  2 | 1-second |          1 |        2
  3 | 1-third  |          1 |        3
  4 | 2-first  |          2 |        1
  5 | 2-second |          2 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[1, 2, 3, 4, 5], ARRAY[1, 2, 3, 1, 2]);

-- ID: 6, COUNTRY_ID: 1, POSITION: 1
INSERT INTO tests.test_table_with_one_group(name, country_id, position) VALUES ('1-new-first', 1, 1);
/*
 id |    name     | country_id | position
----+-------------+------------+----------
  6 | 1-new-first |          1 |        1
  1 | 1-first     |          1 |        2
  2 | 1-second    |          1 |        3
  3 | 1-third     |          1 |        4
  4 | 2-first     |          2 |        1
  5 | 2-second    |          2 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[6, 1, 2, 3, 4, 5], ARRAY[1, 2, 3, 4, 1, 2]);

-- ID: 7, COUNTRY_ID: 2, POSITION: 2
INSERT INTO tests.test_table_with_one_group(name, country_id, position) VALUES ('2-new-second', 2, 2);
/*
 id |     name      | country_id | position
----+---------------+------------+----------
  6 | 1-new-first   |          1 |        1
  1 | 1-first       |          1 |        2
  2 | 1-second      |          1 |        3
  3 | 1-third       |          1 |        4
  4 | 2-first       |          2 |        1
  7 | 2-new-second  |          2 |        2
  5 | 2-second      |          2 |        3
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[6, 1, 2, 3, 4, 7, 5], ARRAY[1, 2, 3, 4, 1, 2, 3]);

-- ID: 8, COUNTRY_ID: 2, POSITION: 4 (200)
INSERT INTO tests.test_table_with_one_group(name, country_id, position) VALUES ('2-new-last', 2, 200);
/*
 id |     name     | country_id | position
----+--------------+------------+----------
  6 | 1-new-first  |          1 |        1
  1 | 1-first      |          1 |        2
  2 | 1-second     |          1 |        3
  3 | 1-third      |          1 |        4
  4 | 2-first      |          2 |        1
  7 | 2-new-second |          2 |        2
  5 | 2-second     |          2 |        3
  8 | 2-new-last   |          2 |        4
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[6, 1, 2, 3, 4, 7, 5, 8], ARRAY[1, 2, 3, 4, 1, 2, 3, 4]);

-- DELETE NON EXISTING
DELETE FROM tests.test_table_with_one_group WHERE id = 9;
/*
 id |     name     | country_id | position
----+--------------+------------+----------
  6 | 1-new-first  |          1 |        1
  1 | 1-first      |          1 |        2
  2 | 1-second     |          1 |        3
  3 | 1-third      |          1 |        4
  4 | 2-first      |          2 |        1
  7 | 2-new-second |          2 |        2
  5 | 2-second     |          2 |        3
  8 | 2-new-last   |          2 |        4
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[6, 1, 2, 3, 4, 7, 5, 8], ARRAY[1, 2, 3, 4, 1, 2, 3, 4]);

-- DELETE FIRST COUNTRY_ID: 1 - ID: 6, LAST COUNTRY_ID: 2 - ID: 8
DELETE FROM tests.test_table_with_one_group WHERE id IN (6, 8);
/*
 id |     name     | country_id | position
----+--------------+------------+----------
  1 | 1-first      |          1 |        1
  2 | 1-second     |          1 |        2
  3 | 1-third      |          1 |        3
  4 | 2-first      |          2 |        1
  7 | 2-new-second |          2 |        2
  5 | 2-second     |          2 |        3
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[1, 2, 3, 4, 7, 5], ARRAY[1, 2, 3, 1, 2, 3]);

-- DELETE SECOND COUNTRY_ID: 2 - ID: 7
DELETE FROM tests.test_table_with_one_group WHERE id = 7;
/*
 id |   name   | country_id | position
----+----------+------------+----------
  1 | 1-first  |          1 |        1
  2 | 1-second |          1 |        2
  3 | 1-third  |          1 |        3
  4 | 2-first  |          2 |        1
  5 | 2-second |          2 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[1, 2, 3, 4, 5], ARRAY[1, 2, 3, 1, 2]);

-- UPDATE NON EXISTING
UPDATE tests.test_table_with_one_group SET position = 2 WHERE id = 6;
/*
 id |   name   | country_id | position
----+----------+------------+----------
  1 | 1-first  |          1 |        1
  2 | 1-second |          1 |        2
  3 | 1-third  |          1 |        3
  4 | 2-first  |          2 |        1
  5 | 2-second |          2 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[1, 2, 3, 4, 5], ARRAY[1, 2, 3, 1, 2]);

-- MOVE FIRST TO SECOND COUNTRY_ID: 2 - ID: 4 -> POSITION: 2
UPDATE tests.test_table_with_one_group SET position = 2 WHERE id = 4;
/*
 id |   name   | country_id | position
----+----------+------------+----------
  1 | 1-first  |          1 |        1
  2 | 1-second |          1 |        2
  3 | 1-third  |          1 |        3
  5 | 2-second |          2 |        1
  4 | 2-first  |          2 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[1, 2, 3, 5, 4], ARRAY[1, 2, 3, 1, 2]);

-- MOVE SECOND TO FIRST COUNTRY_ID: 1 - ID: 2 -> POSITION: 1
UPDATE tests.test_table_with_one_group SET position = 1 WHERE id = 2;
/*
 id |   name   | country_id | position
----+----------+------------+----------
  2 | 1-second |          1 |        1
  1 | 1-first  |          1 |        2
  3 | 1-third  |          1 |        3
  5 | 2-second |          2 |        1
  4 | 2-first  |          2 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[2, 1, 3, 5, 4], ARRAY[1, 2, 3, 1, 2]);

-- MOVE SECOND COUNTRY_ID: 1 TO FIRST COUNTRY_ID: 2 - ID: 1 -> COUNTRY_ID: 2 -> POSITION: 1
UPDATE tests.test_table_with_one_group SET country_id = 2, position = 1 WHERE id = 1;
/*
 id |   name   | country_id | position
----+----------+------------+----------
  2 | 1-second |          1 |        1
  3 | 1-third  |          1 |        2
  1 | 1-first  |          2 |        1
  5 | 2-second |          2 |        2
  4 | 2-first  |          2 |        3
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[2, 3, 1, 5, 4], ARRAY[1, 2, 1, 2, 3]);

-- MOVE SECOND COUNTRY_ID: 1 TO SECOND COUNTRY_ID: 2 - ID: 3 -> COUNTRY_ID: 2 -> POSITION: 2 (keep)
UPDATE tests.test_table_with_one_group SET country_id = 2 WHERE id = 3;
/*
 id |   name   | country_id | position
----+----------+------------+----------
  2 | 1-second |          1 |        1
  1 | 1-first  |          2 |        1
  3 | 1-third  |          2 |        2
  5 | 2-second |          2 |        3
  4 | 2-first  |          2 |        4
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[2, 1, 3, 5, 4], ARRAY[1, 1, 2, 3, 4]);

-- MOVE THIRD COUNTRY_ID: 2 TO THIRD COUNTRY_ID: 1 - ID: 5 -> POSITION: 2 (keep)
UPDATE tests.test_table_with_one_group SET country_id = 1 WHERE id = 5;
/*
 id |   name   | country_id | position
----+----------+------------+----------
  2 | 1-second |          1 |        1
  5 | 2-second |          1 |        2
  1 | 1-first  |          2 |        1
  3 | 1-third  |          2 |        2
  4 | 2-first  |          2 |        3
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[2, 5, 1, 3, 4], ARRAY[1, 2, 1, 2, 3]);

-- MOVE FIRST COUNTRY_ID: 2 TO LAST COUNTRY_ID: 1 - ID: 1 -> POSITION: 3 (20)
UPDATE tests.test_table_with_one_group SET country_id = 1, position = 20 WHERE id = 1;
/*
 id |   name   | country_id | position
----+----------+------------+----------
  2 | 1-second |          1 |        1
  5 | 2-second |          1 |        2
  1 | 1-first  |          1 |        3
  3 | 1-third  |          2 |        1
  4 | 2-first  |          2 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[2, 5, 1, 3, 4], ARRAY[1, 2, 3, 1, 2]);

-- MOVE SECOND COUNTRY_ID: 2 TO THIRD COUNTRY_ID: 1 - ID: 4 -> POSITION: 3
UPDATE tests.test_table_with_one_group SET country_id = 1, position = 3 WHERE id = 4;
/*
 id |   name   | country_id | position
----+----------+------------+----------
  2 | 1-second |          1 |        1
  5 | 2-second |          1 |        2
  4 | 2-first  |          1 |        3
  1 | 1-first  |          1 |        4
  3 | 1-third  |          2 |        1
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[2, 5, 4, 1, 3], ARRAY[1, 2, 3, 4, 1]);

-- MOVE THIRD COUNTRY_ID: 1 TO SECOND COUNTRY_ID: 2 - ID: 4 -> POSITION: 2
UPDATE tests.test_table_with_one_group SET country_id = 2, position = 2 WHERE id = 4;
/*
 id |   name   | country_id | position
----+----------+------------+----------
  2 | 1-second |          1 |        1
  5 | 2-second |          1 |        2
  1 | 1-first  |          1 |        3
  3 | 1-third  |          2 |        1
  4 | 2-first  |          2 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[2, 5, 1, 3, 4], ARRAY[1, 2, 3, 1, 2]);

-- MOVE FIRST COUNTRY_ID: 2 TO FIRST - ID: 3 -> POSITION: 1 (0)
UPDATE tests.test_table_with_one_group SET position = 0 WHERE id = 3;
/*
 id |   name   | country_id | position
----+----------+------------+----------
  2 | 1-second |          1 |        1
  5 | 2-second |          1 |        2
  1 | 1-first  |          1 |        3
  3 | 1-third  |          2 |        1
  4 | 2-first  |          2 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[2, 5, 1, 3, 4], ARRAY[1, 2, 3, 1, 2]);

-- MOVE SECOND COUNTRY_ID: 2 TO FIRST - ID: 4 -> POSITION: 1 (0)
UPDATE tests.test_table_with_one_group SET position = 0 WHERE id = 4;
/*
 id |   name   | country_id | position
----+----------+------------+----------
  2 | 1-second |          1 |        1
  5 | 2-second |          1 |        2
  1 | 1-first  |          1 |        3
  4 | 2-first  |          2 |        1
  3 | 1-third  |          2 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[2, 5, 1, 4, 3], ARRAY[1, 2, 3, 1, 2]);

-- MULTI-INSERT
-- - LAST COUNTRY_ID: 1 ID: 9 -> POSITION: 4 (NULL)
-- - LAST COUNTRY_ID: 1 ID: 10 -> POSITION: 5 (NULL)
-- - LAST COUNTRY_ID: 2 ID: 11 -> POSITION: 5 (NULL)
-- - FIRST COUNTRY_ID: 2 ID: 12 -> POSITION: 1
-- - LAST COUNTRY_ID: 2 ID: 13 -> POSITION: 6 (NULL)
-- - SECOND COUNTRY_ID: 2 ID: 14 -> POSITION: 3 (2) -- IS MOVED TO 3, BECAUSE IN MULTI-INSERT PREVIOUS FIRST (ID: 4) IS NEW SECOND AND IT IS PREFERRED TO NEW SECOND (ID: 14)
INSERT INTO tests.test_table_with_one_group(name, country_id, position) VALUES
  ('1-multi-last1', 1, NULL),
  ('1-multi-last2', 1, NULL),
  ('2-multi-last1', 2, NULL),
  ('2-multi-first', 2, 1),
  ('2-multi-last2', 2, NULL),
  ('2-multi-second', 2, 2);
/*
 id |      name      | country_id | position
----+----------------+------------+----------
  2 | 1-second       |          1 |        1
  5 | 2-second       |          1 |        2
  1 | 1-first        |          1 |        3
  9 | 1-multi-last1  |          1 |        4
 10 | 1-multi-last2  |          1 |        5
 12 | 2-multi-first  |          2 |        1
  4 | 2-first        |          2 |        2
 14 | 2-multi-second |          2 |        3
  3 | 1-third        |          2 |        4
 11 | 2-multi-last1  |          2 |        5
 13 | 2-multi-last2  |          2 |        6
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[2, 5, 1, 9, 10, 12, 4, 14, 3, 11, 13], ARRAY[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 6]);

-- MULTI-UPDATE
-- - FIFTH COUNTRY_ID: 1 TO FIRST ID: 10 -> POSITION: 1
-- - SECOND COUNTRY_ID: 1 TO FIFTH ID: 5 -> POSITION: 5
-- - FIRST COUNTRY_ID: 2 TO SECOND ID: 12 -> POSITION: 2
-- - FIFTH COUNTRY_ID: 2 TO COUNTRY_ID: 1 ID: 11 -> POSITION: 6
UPDATE tests.test_table_with_one_group AS t
   SET position = x.position,
       country_id = x.country_id
  FROM (SELECT unnest(ARRAY[10, 5, 12, 11]) AS id, unnest(ARRAY[1, 5, 2, 6]) AS position, unnest(ARRAY[1, 1, 2, 1]) AS country_id) AS x
 WHERE t.id = x.id;
/*
 id |      name      | country_id | position
----+----------------+------------+----------
 10 | 1-multi-last2  |          1 |        1
  2 | 1-second       |          1 |        2
  1 | 1-first        |          1 |        3
  9 | 1-multi-last1  |          1 |        4
  5 | 2-second       |          1 |        5
 11 | 2-multi-last1  |          1 |        6
  4 | 2-first        |          2 |        1
 12 | 2-multi-first  |          2 |        2
 14 | 2-multi-second |          2 |        3
  3 | 1-third        |          2 |        4
 13 | 2-multi-last2  |          2 |        5
*/
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[10, 2, 1, 9, 5, 11, 4, 12, 14, 3, 13], ARRAY[1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5]);

-- THIS IS NOT WORKING :-( LAST UPDATE HAS NO RECORD IN table_new AND table_old
-- CTE (real SQL commands order is this)
-- - INSERT LAST COUNTRY_ID: 1 - ID: 15 -> POSITION: 7 (NULL)
-- - DELETE SECOND COUNTRY_ID: 2 - ID: 12
-- - MOVE NEW SEVENTH COUNTRY_ID: 1 TO FIRST - ID: 15 -> POSITION: 1
/*
WITH upd AS (
  UPDATE tests.test_table_with_one_group SET position = 1 WHERE id = 15
), del AS (
  DELETE FROM tests.test_table_with_one_group WHERE id = 12
)
INSERT INTO tests.test_table_with_one_group(name, country_id, position) VALUES ('cte-first', 1, NULL);
SELECT tests.assert_positions('tests.test_table_with_one_group', ARRAY[15, 10, 2, 1, 9, 5, 11, 4, 14, 3, 13], ARRAY[1, 2, 3, 4, 5, 6, 7, 1, 2, 3, 4]);
*/

----------

SELECT system.trigger_position_remove('tests', 'test_table_with_one_group');

DROP TABLE tests.test_table_with_one_group;
