CREATE TABLE tests.test_table_with_two_groups
(
  id integer GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  country_id integer NOT NULL,
  town_id integer NOT NULL,
  position integer,
  CONSTRAINT test_table_with_two_groups_pkey PRIMARY KEY (id)
);

-- CHECK QUERY: SELECT * FROM tests.test_table_with_two_groups ORDER BY country_id, town_id, position;

SELECT system.trigger_position_add('tests', 'test_table_with_two_groups', 'country_id,town_id');

----------

-- ID: 1, COUNTRY_ID: 1, TOWN_ID: 1, POSITION: 1 (NULL)
INSERT INTO tests.test_table_with_two_groups(name, country_id, town_id, position) VALUES ('1-1-first', 1, 1, NULL);
/*
 id |   name    | country_id | town_id | position
----+-----------+------------+---------+----------
  1 | 1-1-first |          1 |       1 |        1
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[1], ARRAY[1]);

-- ID: 2, COUNTRY_ID: 1, TOWN_ID: 1, POSITION: 2 (NULL)
INSERT INTO tests.test_table_with_two_groups(name, country_id, town_id, position) VALUES ('1-1-second', 1, 1, NULL);
/*
 id |    name    | country_id | town_id | position
----+------------+------------+---------+----------
  1 | 1-1-first  |          1 |       1 |        1
  2 | 1-1-second |          1 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[1, 2], ARRAY[1, 2]);

-- ID: 3, COUNTRY_ID: 1, TOWN_ID: 1, POSITION: 3
INSERT INTO tests.test_table_with_two_groups(name, country_id, town_id, position) VALUES ('1-1-third', 1, 1, 3);
/*
 id |    name    | country_id | town_id | position
----+------------+------------+---------+----------
  1 | 1-1-first  |          1 |       1 |        1
  2 | 1-1-second |          1 |       1 |        2
  3 | 1-1-third  |          1 |       1 |        3
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[1, 2, 3], ARRAY[1, 2, 3]);

-- ID: 4, COUNTRY_ID: 1, TOWN_ID: 2, POSITION: 1 (NULL)
INSERT INTO tests.test_table_with_two_groups(name, country_id, town_id, position) VALUES ('1-2-first', 1, 2, NULL);
/*
 id |    name    | country_id | town_id | position
----+------------+------------+---------+----------
  1 | 1-1-first  |          1 |       1 |        1
  2 | 1-1-second |          1 |       1 |        2
  3 | 1-1-third  |          1 |       1 |        3
  4 | 1-2-first  |          1 |       2 |        1
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[1, 2, 3, 4], ARRAY[1, 2, 3, 1]);

-- ID: 5, COUNTRY_ID: 1, TOWN_ID: 2, POSITION: 2
INSERT INTO tests.test_table_with_two_groups(name, country_id, town_id, position) VALUES ('1-2-second', 1, 2, 2);
/*
 id |    name    | country_id | town_id | position
----+------------+------------+---------+----------
  1 | 1-1-first  |          1 |       1 |        1
  2 | 1-1-second |          1 |       1 |        2
  3 | 1-1-third  |          1 |       1 |        3
  4 | 1-2-first  |          1 |       2 |        1
  5 | 1-2-second |          1 |       2 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[1, 2, 3, 4, 5], ARRAY[1, 2, 3, 1, 2]);

-- ID: 6, COUNTRY_ID: 2, TOWN_ID: 1, POSITION: 1
INSERT INTO tests.test_table_with_two_groups(name, country_id, town_id, position) VALUES ('2-1-first', 2, 1, 1);
/*
 id |    name    | country_id | town_id | position
----+------------+------------+---------+----------
  1 | 1-1-first  |          1 |       1 |        1
  2 | 1-1-second |          1 |       1 |        2
  3 | 1-1-third  |          1 |       1 |        3
  4 | 1-2-first  |          1 |       2 |        1
  5 | 1-2-second |          1 |       2 |        2
  6 | 2-1-first  |          2 |       1 |        1
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[1, 2, 3, 4, 5, 6], ARRAY[1, 2, 3, 1, 2, 1]);

-- ID: 7, COUNTRY_ID: 2, TOWN_ID: 1, POSITION: 1
INSERT INTO tests.test_table_with_two_groups(name, country_id, town_id, position) VALUES ('2-1-new-first', 2, 1, 1);
/*
 id |     name      | country_id | town_id | position
----+---------------+------------+---------+----------
  1 | 1-1-first     |          1 |       1 |        1
  2 | 1-1-second    |          1 |       1 |        2
  3 | 1-1-third     |          1 |       1 |        3
  4 | 1-2-first     |          1 |       2 |        1
  5 | 1-2-second    |          1 |       2 |        2
  7 | 2-1-new-first |          2 |       1 |        1
  6 | 2-1-first     |          2 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[1, 2, 3, 4, 5, 7, 6], ARRAY[1, 2, 3, 1, 2, 1, 2]);

-- ID: 8, COUNTRY_ID: 1, TOWN_ID: 1, POSITION: 2
INSERT INTO tests.test_table_with_two_groups(name, country_id, town_id, position) VALUES ('1-1-new-second', 1, 1, 2);
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  1 | 1-1-first      |          1 |       1 |        1
  8 | 1-1-new-second |          1 |       1 |        2
  2 | 1-1-second     |          1 |       1 |        3
  3 | 1-1-third      |          1 |       1 |        4
  4 | 1-2-first      |          1 |       2 |        1
  5 | 1-2-second     |          1 |       2 |        2
  7 | 2-1-new-first  |          2 |       1 |        1
  6 | 2-1-first      |          2 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[1, 8, 2, 3, 4, 5, 7, 6], ARRAY[1, 2, 3, 4, 1, 2, 1, 2]);

-- ID: 9, COUNTRY_ID: 1, TOWN_ID: 1, POSITION: 4
INSERT INTO tests.test_table_with_two_groups(name, country_id, town_id, position) VALUES ('1-1-new-fourth', 1, 1, 4);
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  1 | 1-1-first      |          1 |       1 |        1
  8 | 1-1-new-second |          1 |       1 |        2
  2 | 1-1-second     |          1 |       1 |        3
  9 | 1-1-new-fourth |          1 |       1 |        4
  3 | 1-1-third      |          1 |       1 |        5
  4 | 1-2-first      |          1 |       2 |        1
  5 | 1-2-second     |          1 |       2 |        2
  7 | 2-1-new-first  |          2 |       1 |        1
  6 | 2-1-first      |          2 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[1, 8, 2, 9, 3, 4, 5, 7, 6], ARRAY[1, 2, 3, 4, 5, 1, 2, 1, 2]);

-- ID: 10, COUNTRY_ID: 1, TOWN_ID: 2, POSITION: 3 (200)
INSERT INTO tests.test_table_with_two_groups(name, country_id, town_id, position) VALUES ('1-2-new-last', 1, 2, 200);
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  1 | 1-1-first      |          1 |       1 |        1
  8 | 1-1-new-second |          1 |       1 |        2
  2 | 1-1-second     |          1 |       1 |        3
  9 | 1-1-new-fourth |          1 |       1 |        4
  3 | 1-1-third      |          1 |       1 |        5
  4 | 1-2-first      |          1 |       2 |        1
  5 | 1-2-second     |          1 |       2 |        2
 10 | 1-2-new-last   |          1 |       2 |        3
  7 | 2-1-new-first  |          2 |       1 |        1
  6 | 2-1-first      |          2 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[1, 8, 2, 9, 3, 4, 5, 10, 7, 6], ARRAY[1, 2, 3, 4, 5, 1, 2, 3, 1, 2]);

-- DELETE NON EXISTING
DELETE FROM tests.test_table_with_two_groups WHERE id = 11;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  1 | 1-1-first      |          1 |       1 |        1
  8 | 1-1-new-second |          1 |       1 |        2
  2 | 1-1-second     |          1 |       1 |        3
  9 | 1-1-new-fourth |          1 |       1 |        4
  3 | 1-1-third      |          1 |       1 |        5
  4 | 1-2-first      |          1 |       2 |        1
  5 | 1-2-second     |          1 |       2 |        2
 10 | 1-2-new-last   |          1 |       2 |        3
  7 | 2-1-new-first  |          2 |       1 |        1
  6 | 2-1-first      |          2 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[1, 8, 2, 9, 3, 4, 5, 10, 7, 6], ARRAY[1, 2, 3, 4, 5, 1, 2, 3, 1, 2]);

-- DELETE FIRST COUNTRY_ID: 1, TOWN_ID: 1 - ID: 1, LAST COUNTRY_ID: 1, TOWN_ID: 2 - ID: 10
DELETE FROM tests.test_table_with_two_groups WHERE id IN (1, 10);
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  8 | 1-1-new-second |          1 |       1 |        1
  2 | 1-1-second     |          1 |       1 |        2
  9 | 1-1-new-fourth |          1 |       1 |        3
  3 | 1-1-third      |          1 |       1 |        4
  4 | 1-2-first      |          1 |       2 |        1
  5 | 1-2-second     |          1 |       2 |        2
  7 | 2-1-new-first  |          2 |       1 |        1
  6 | 2-1-first      |          2 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[8, 2, 9, 3, 4, 5, 7, 6], ARRAY[1, 2, 3, 4, 1, 2, 1, 2]);

-- DELETE SECOND COUNTRY_ID: 1, TOWN_ID: 1 - ID: 2
DELETE FROM tests.test_table_with_two_groups WHERE id = 2;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  8 | 1-1-new-second |          1 |       1 |        1
  9 | 1-1-new-fourth |          1 |       1 |        2
  3 | 1-1-third      |          1 |       1 |        3
  5 | 1-2-second     |          1 |       2 |        1
  4 | 1-2-first      |          1 |       2 |        2
  7 | 2-1-new-first  |          2 |       1 |        1
  6 | 2-1-first      |          2 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[8, 9, 3, 4, 5, 7, 6], ARRAY[1, 2, 3, 1, 2, 1, 2]);

-- UPDATE NON EXISTING
UPDATE tests.test_table_with_two_groups SET position = 2 WHERE id = 10;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  8 | 1-1-new-second |          1 |       1 |        1
  9 | 1-1-new-fourth |          1 |       1 |        2
  3 | 1-1-third      |          1 |       1 |        3
  5 | 1-2-second     |          1 |       2 |        1
  4 | 1-2-first      |          1 |       2 |        2
  7 | 2-1-new-first  |          2 |       1 |        1
  6 | 2-1-first      |          2 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[8, 9, 3, 4, 5, 7, 6], ARRAY[1, 2, 3, 1, 2, 1, 2]);

-- UPDATE NO CHANGE
UPDATE tests.test_table_with_two_groups SET position = 1 WHERE id = 8;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  8 | 1-1-new-second |          1 |       1 |        1
  9 | 1-1-new-fourth |          1 |       1 |        2
  3 | 1-1-third      |          1 |       1 |        3
  5 | 1-2-second     |          1 |       2 |        1
  4 | 1-2-first      |          1 |       2 |        2
  7 | 2-1-new-first  |          2 |       1 |        1
  6 | 2-1-first      |          2 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[8, 9, 3, 4, 5, 7, 6], ARRAY[1, 2, 3, 1, 2, 1, 2]);

-- MOVE FIRST TO SECOND COUNTRY_ID: 1, TOWN_ID: 1 - ID: 8 -> POSITION: 2
UPDATE tests.test_table_with_two_groups SET position = 2 WHERE id = 8;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  9 | 1-1-new-fourth |          1 |       1 |        1
  8 | 1-1-new-second |          1 |       1 |        2
  3 | 1-1-third      |          1 |       1 |        3
  4 | 1-2-first      |          1 |       2 |        1
  5 | 1-2-second     |          1 |       2 |        2
  7 | 2-1-new-first  |          2 |       1 |        1
  6 | 2-1-first      |          2 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[9, 8, 3, 4, 5, 7, 6], ARRAY[1, 2, 3, 1, 2, 1, 2]);

-- MOVE SECOND TO FIRST COUNTRY_ID: 1, TOWN_ID: 2 - ID: 5 -> POSITION: 1
UPDATE tests.test_table_with_two_groups SET position = 1 WHERE id = 5;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  9 | 1-1-new-fourth |          1 |       1 |        1
  8 | 1-1-new-second |          1 |       1 |        2
  3 | 1-1-third      |          1 |       1 |        3
  5 | 1-2-second     |          1 |       2 |        1
  4 | 1-2-first      |          1 |       2 |        2
  7 | 2-1-new-first  |          2 |       1 |        1
  6 | 2-1-first      |          2 |       1 |        2
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[9, 8, 3, 5, 4, 7, 6], ARRAY[1, 2, 3, 1, 2, 1, 2]);

-- MOVE SECOND COUNTRY_ID: 1, TOWN_ID: 1 TO FIRST COUNTRY_ID: 2, TOWN_ID: 1 - ID: 8 -> COUNTRY_ID: 2 -> POSITION: 1
UPDATE tests.test_table_with_two_groups SET country_id = 2, position = 1 WHERE id = 8;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  9 | 1-1-new-fourth |          1 |       1 |        1
  3 | 1-1-third      |          1 |       1 |        2
  5 | 1-2-second     |          1 |       2 |        1
  4 | 1-2-first      |          1 |       2 |        2
  8 | 1-1-new-second |          2 |       1 |        1
  7 | 2-1-new-first  |          2 |       1 |        2
  6 | 2-1-first      |          2 |       1 |        3
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[9, 3, 5, 4, 8, 7, 6], ARRAY[1, 2, 1, 2, 1, 2, 3]);

-- MOVE SECOND COUNTRY_ID: 1, TOWN_ID: 1 TO NEW FIRST COUNTRY_ID: 2, TOWN_ID: 2 - ID: 3 -> COUNTRY_ID: 2, TOWN_ID: 2 -> POSITION: 1 (keep)
UPDATE tests.test_table_with_two_groups SET country_id = 2, town_id = 2 WHERE id = 3;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  9 | 1-1-new-fourth |          1 |       1 |        1
  5 | 1-2-second     |          1 |       2 |        1
  4 | 1-2-first      |          1 |       2 |        2
  8 | 1-1-new-second |          2 |       1 |        1
  7 | 2-1-new-first  |          2 |       1 |        2
  6 | 2-1-first      |          2 |       1 |        3
  3 | 1-1-third      |          2 |       2 |        1
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[9, 5, 4, 8, 7, 6, 3], ARRAY[1, 1, 2, 1, 2, 3, 1]);

-- MOVE FIRST COUNTRY_ID: 2, TOWN_ID: 2 TO FIRST COUNTRY_ID: 1, TOWN_ID: 2 - ID: 3 -> POSITION: 1 (keep)
UPDATE tests.test_table_with_two_groups SET country_id = 1 WHERE id = 3;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  9 | 1-1-new-fourth |          1 |       1 |        1
  3 | 1-1-third      |          1 |       2 |        1
  5 | 1-2-second     |          1 |       2 |        2
  4 | 1-2-first      |          1 |       2 |        3
  8 | 1-1-new-second |          2 |       1 |        1
  7 | 2-1-new-first  |          2 |       1 |        2
  6 | 2-1-first      |          2 |       1 |        3
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[9, 3, 5, 4, 8, 7, 6], ARRAY[1, 1, 2, 3, 1, 2, 3]);

-- MOVE FIRST COUNTRY_ID: 1, TOWN_ID: 1 TO LAST COUNTRY_ID: 1, TOWN_ID: 2 - ID: 9 -> POSITION: 4 (20)
UPDATE tests.test_table_with_two_groups SET town_id = 2, position = 20 WHERE id = 9;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  3 | 1-1-third      |          1 |       2 |        1
  5 | 1-2-second     |          1 |       2 |        2
  4 | 1-2-first      |          1 |       2 |        3
  9 | 1-1-new-fourth |          1 |       2 |        4
  8 | 1-1-new-second |          2 |       1 |        1
  7 | 2-1-new-first  |          2 |       1 |        2
  6 | 2-1-first      |          2 |       1 |        3
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[3, 5, 4, 9, 8, 7, 6], ARRAY[1, 2, 3, 4, 1, 2, 3]);

-- MOVE SECOND COUNTRY_ID: 1, TOWN_ID: 2 TO THIRD COUNTRY_ID: 2, TOWN_ID: 1 - ID: 5 -> POSITION: 3
UPDATE tests.test_table_with_two_groups SET country_id = 2, town_id = 1, position = 3 WHERE id = 5;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  3 | 1-1-third      |          1 |       2 |        1
  4 | 1-2-first      |          1 |       2 |        2
  9 | 1-1-new-fourth |          1 |       2 |        3
  8 | 1-1-new-second |          2 |       1 |        1
  7 | 2-1-new-first  |          2 |       1 |        2
  5 | 1-2-second     |          2 |       1 |        3
  6 | 2-1-first      |          2 |       1 |        4
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[3, 4, 9, 8, 7, 5, 6], ARRAY[1, 2, 3, 1, 2, 3, 4]);

-- MOVE THIRD COUNTRY_ID: 1, TOWN_ID: 2 TO SECOND COUNTRY_ID: 2, TOWN_ID: 1 - ID: 9 -> POSITION: 2
UPDATE tests.test_table_with_two_groups SET country_id = 2, town_id = 1, position = 2 WHERE id = 9;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  3 | 1-1-third      |          1 |       2 |        1
  4 | 1-2-first      |          1 |       2 |        2
  8 | 1-1-new-second |          2 |       1 |        1
  9 | 1-1-new-fourth |          2 |       1 |        2
  7 | 2-1-new-first  |          2 |       1 |        3
  5 | 1-2-second     |          2 |       1 |        4
  6 | 2-1-first      |          2 |       1 |        5
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[3, 4, 8, 9, 7, 5, 6], ARRAY[1, 2, 1, 2, 3, 4, 5]);

-- MOVE FIRST COUNTRY_ID: 1, TOWN_ID: 2 TO FIRST - ID: 3 -> POSITION: 1 (0)
UPDATE tests.test_table_with_two_groups SET position = 0 WHERE id = 3;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  3 | 1-1-third      |          1 |       2 |        1
  4 | 1-2-first      |          1 |       2 |        2
  8 | 1-1-new-second |          2 |       1 |        1
  9 | 1-1-new-fourth |          2 |       1 |        2
  7 | 2-1-new-first  |          2 |       1 |        3
  5 | 1-2-second     |          2 |       1 |        4
  6 | 2-1-first      |          2 |       1 |        5
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[3, 4, 8, 9, 7, 5, 6], ARRAY[1, 2, 1, 2, 3, 4, 5]);

-- MOVE SECOND COUNTRY_ID: 2, TOWN_ID: 1 TO FIRST - ID: 9 -> POSITION: 1 (0)
UPDATE tests.test_table_with_two_groups SET position = 0 WHERE id = 9;
/*
 id |      name      | country_id | town_id | position
----+----------------+------------+---------+----------
  3 | 1-1-third      |          1 |       2 |        1
  4 | 1-2-first      |          1 |       2 |        2
  9 | 1-1-new-fourth |          2 |       1 |        1
  8 | 1-1-new-second |          2 |       1 |        2
  7 | 2-1-new-first  |          2 |       1 |        3
  5 | 1-2-second     |          2 |       1 |        4
  6 | 2-1-first      |          2 |       1 |        5
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[3, 4, 9, 8, 7, 5, 6], ARRAY[1, 2, 1, 2, 3, 4, 5]);

-- MULTI-INSERT
-- - LAST COUNTRY_ID: 1, TOWN_ID: 2 ID: 11 -> POSITION: 3 (NULL)
-- - LAST COUNTRY_ID: 1, TOWN_ID: 2 ID: 12 -> POSITION: 4 (NULL)
-- - LAST COUNTRY_ID: 2, TOWN_ID: 1 ID: 13 -> POSITION: 6 (NULL)
-- - FIRST COUNTRY_ID: 2, TOWN_ID: 1 ID: 14 -> POSITION: 1
-- - LAST COUNTRY_ID: 2, TOWN_ID: 1 ID: 15 -> POSITION: 8 (NULL)
-- - SECOND COUNTRY_ID: 2, TOWN_ID: 1 ID: 16 -> POSITION: 3 (2) -- IS MOVED TO 3, BECAUSE IN MULTI-INSERT PREVIOUS FIRST (ID: 9) IS NEW SECOND AND IT IS PREFERRED TO NEW SECOND (ID: 16)
-- - FIRST COUNTRY_ID: 3, TOWN_ID: 3 ID: 17 -> POSITION: 1 (NULL)
-- - FIRST COUNTRY_ID: 3, TOWN_ID: 4 ID: 18 -> POSITION: 1 (20)
INSERT INTO tests.test_table_with_two_groups(name, country_id, town_id, position) VALUES
  ('1-2-multi-last1', 1, 2, NULL),
  ('1-2-multi-last2', 1, 2, NULL),
  ('2-1-multi-last1', 2, 1, NULL),
  ('2-1-multi-first', 2, 1, 1),
  ('2-1-multi-last2', 2, 1, NULL),
  ('2-1-multi-second', 2, 1, 2),
  ('3-3-new-first', 3, 3, NULL),
  ('3-4-new-first', 3, 4, 20);
/*
 id |       name       | country_id | town_id | position
----+------------------+------------+---------+----------
  3 | 1-1-third        |          1 |       2 |        1
  4 | 1-2-first        |          1 |       2 |        2
 11 | 1-2-multi-last1  |          1 |       2 |        3
 12 | 1-2-multi-last2  |          1 |       2 |        4
 14 | 2-1-multi-first  |          2 |       1 |        1
  9 | 1-1-new-fourth   |          2 |       1 |        2
 16 | 2-1-multi-second |          2 |       1 |        3
  8 | 1-1-new-second   |          2 |       1 |        4
  7 | 2-1-new-first    |          2 |       1 |        5
  5 | 1-2-second       |          2 |       1 |        6
  6 | 2-1-first        |          2 |       1 |        7
 13 | 2-1-multi-last1  |          2 |       1 |        8
 15 | 2-1-multi-last2  |          2 |       1 |        9
 17 | 3-3-new-first    |          3 |       3 |        1
 18 | 3-4-new-first    |          3 |       4 |        1
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[3, 4, 11, 12, 14, 9, 16, 8, 7, 5, 6, 13, 15, 17, 18], ARRAY[1, 2, 3, 4, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 1]);

-- MULTI-UPDATE
-- - FOURTH COUNTRY_ID: 1, TOWN_ID: 2 TO FIRST ID: 12 -> POSITION: 1
-- - SECOND COUNTRY_ID: 2, TOWN_ID: 1 TO THIRD ID: 9 -> POSITION: 3
-- - FIRST COUNTRY_ID: 2, TOWN_ID: 1 TO COUNTRY_ID: 3, TOWN_ID: 3 ID: 14 -> POSITION: 1 (keep)
-- - FIRST COUNTRY_ID: 3, TOWN_ID: 4 TO COUNTRY_ID: 4, TOWN_ID: 4 ID: 18 -> POSITION: 1 (keep)
UPDATE tests.test_table_with_two_groups AS t
   SET position = x.position,
       country_id = x.country_id,
       town_id = x.town_id
  FROM (SELECT unnest(ARRAY[12, 9, 14, 18]) AS id, unnest(ARRAY[1, 3, 1, 1]) AS position, unnest(ARRAY[1, 2, 3, 4]) AS country_id, unnest(ARRAY[2, 1, 3, 4]) AS town_id) AS x
 WHERE t.id = x.id;
/*
 id |       name       | country_id | town_id | position
----+------------------+------------+---------+----------
 12 | 1-2-multi-last2  |          1 |       2 |        1
  3 | 1-1-third        |          1 |       2 |        2
  4 | 1-2-first        |          1 |       2 |        3
 11 | 1-2-multi-last1  |          1 |       2 |        4
 16 | 2-1-multi-second |          2 |       1 |        1
  9 | 1-1-new-fourth   |          2 |       1 |        2
  8 | 1-1-new-second   |          2 |       1 |        3
  7 | 2-1-new-first    |          2 |       1 |        4
  5 | 1-2-second       |          2 |       1 |        5
  6 | 2-1-first        |          2 |       1 |        6
 13 | 2-1-multi-last1  |          2 |       1 |        7
 15 | 2-1-multi-last2  |          2 |       1 |        8
 14 | 2-1-multi-first  |          3 |       3 |        1
 17 | 3-3-new-first    |          3 |       3 |        2
 18 | 3-4-new-first    |          4 |       4 |        1
*/
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[12, 3, 4, 11, 16, 9, 8, 7, 5, 6, 13, 15, 14, 17, 18], ARRAY[1, 2, 3, 4, 1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 1]);

-- THIS IS NOT WORKING :-( LAST UPDATE HAS NO RECORD IN table_new AND table_old
-- CTE (real SQL commands order is this)
-- - INSERT LAST COUNTRY_ID: 1, TOWN_ID: 2 - ID: 19 -> POSITION: 5 (NULL)
-- - DELETE SECOND COUNTRY_ID: 1, TOWN_ID: 2 - ID: 4
-- - MOVE NEW FOURTH COUNTRY_ID: 1 TO FIRST - ID: 19 -> POSITION: 1
/*
WITH upd AS (
  UPDATE tests.test_table_with_two_groups SET position = 1 WHERE id = 19
), del AS (
  DELETE FROM tests.test_table_with_two_groups WHERE id = 4
)
INSERT INTO tests.test_table_with_two_groups(name, country_id, town_id, position) VALUES ('cte-first', 1, 2, NULL);
SELECT tests.assert_positions('tests.test_table_with_two_groups', ARRAY[19, 12, 3, 11, 16, 9, 8, 7, 5, 6, 13, 15, 14, 17, 18], ARRAY[1, 2, 3, 4, 1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 1]);
*/

----------

SELECT system.trigger_position_remove('tests', 'test_table_with_two_groups');

DROP TABLE tests.test_table_with_two_groups;
