/*
TAP Tests for table functions 

*/

BEGIN;

SELECT tap.plan(57);

-- setup for tests
DROP DATABASE IF EXISTS taptest;
CREATE DATABASE taptest;

-- This will be rolled back. :-)
DROP TABLE IF EXISTS taptest.sometab;
CREATE TABLE taptest.sometab(
    id      INT NOT NULL PRIMARY KEY,
    name    TEXT,
    numb    FLOAT(10, 2) DEFAULT NULL,
    myNum   INT(8) DEFAULT 24,
    myat    TIMESTAMP DEFAULT NOW(),
    plain   INT
) ENGINE=INNODB, CHARACTER SET utf8, COLLATE utf8_general_ci;

DROP TABLE IF EXISTS taptest.othertab;
CREATE TABLE taptest.othertab(
    id      INT NOT NULL PRIMARY KEY,
    name    TEXT,
    numb    FLOAT(10, 2) DEFAULT NULL,
    myNum   INT(8) DEFAULT 24,
    myat    TIMESTAMP DEFAULT NOW(),
    plain   INT
) ENGINE=INNODB, CHARACTER SET utf8, COLLATE utf8_general_ci;




/****************************************************************************/
-- has_table(sname VARCHAR(64), tname VARCHAR(64), description TEXT)

SELECT tap.check_test(
    tap.has_table('taptest', 'sometab', ''),
    true,
    'has_table() extant table',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.has_table('taptest', 'nonexistent', ''),
    false,
    'has_table() nonexistent table',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.has_table('taptest', 'sometab', ''),
    true,
    'has_table() default description',
    'Table taptest.sometab should exist',
    null,
    0
);

SELECT tap.check_test(
    tap.has_table('taptest', 'sometab', 'desc'),
    true,
    'has_table() description supplied',
    'desc',
    null,
    0
);



/****************************************************************************/
-- hasnt_table(sname VARCHAR(64), tname VARCHAR(64), description TEXT)

SELECT tap.check_test(
    tap.hasnt_table('taptest', 'nonexistent', ''),
    true,
    'hasnt_table() with nonexistent table',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.hasnt_table('taptest', 'sometab', ''),
    false,
    'hasnt_table() with extant table',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.hasnt_table('taptest', 'nonexisting', ''),
    true,
    'hasnt_table() default description',
    'Table taptest.nonexisting should not exist',
    null,
    0
);

SELECT tap.check_test(
    tap.hasnt_table('taptest', 'nonexisting', 'desc'),
    true,
    'hasnt_table() description supplied',
    'desc',
    null,
    0
);



/****************************************************************************/
-- table_engine_is(sname VARCHAR(64), tname VARCHAR(64), ename VARCHAR(32), description TEXT)

SELECT tap.check_test(
    tap.table_engine_is('taptest', 'sometab', 'INNODB', ''),
    true,
    'table_engine_is() with correct specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.table_engine_is('taptest', 'sometab', 'MYISAM', ''),
    false,
    'table_engine_is() with incorrect specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.table_engine_is('taptest', 'sometab', 'INNODB', ''),
    true,
    'table_engine_is() default description',
    'Table taptest.sometab should have Storage Engine INNODB',
    null,
    0
);

SELECT tap.check_test(
    tap.table_engine_is('taptest', 'sometab', 'INNODB', 'desc'),
    true,
    'table_engine_is() description supplied',
    'desc',
    null,
    0
);

SELECT tap.check_test(
    tap.table_engine_is('taptest', 'sometab', 'INVALID_ENGINE', ''),
    false,
    'table_engine_is() invalid engine supplied',
    null,
    'Storage Engine INVALID_ENGINE is not available',
    0
);

SELECT tap.check_test(
    tap.table_engine_is('taptest', 'nonexistant', 'INNODB', ''),
    false,
    'table_engine_is() invalid engine supplied',
    null,
    'Table taptest.nonexistant does not exist',
    0
);




/****************************************************************************/
-- table_collation_is(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), description TEXT)

SELECT tap.check_test(
    tap.table_collation_is('taptest', 'sometab', 'utf8_general_ci', ''),
    true,
    'table_collation_is() with correct specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.table_collation_is('taptest', 'sometab', 'utf8_bin', ''),
    false,
    'table_collation_is() with incorrect specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.table_collation_is('taptest', 'sometab', 'utf8_general_ci', ''),
    true,
    'table_collation_is() default description',
    'Table taptest.sometab should have Collation \'utf8_general_ci\'',
    null,
    0
);

SELECT tap.check_test(
    tap.table_collation_is('taptest', 'sometab', 'utf8_general_ci', 'desc'),
    true,
    'table_collation_is() description supplied',
    'desc',
    null,
    0
);

SELECT tap.check_test(
    tap.table_collation_is('taptest', 'sometab', 'INVALID_COLLATION', ''),
    false,
    'table_collation_is() invalid engine supplied',
    null,
    'Collation INVALID_COLLATION is not available',
    0
);

SELECT tap.check_test(
    tap.table_collation_is('taptest', 'nonexistent', 'utf8_general_ci', ''),
    false,
    'table_collation_is() nonexistent table supplied',
    null,
    'Table taptest.nonexistent does not exist',
    0
);



/****************************************************************************/
-- table_character_set_is(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(32), description TEXT)

SELECT tap.check_test(
    tap.table_character_set_is('taptest', 'sometab', 'utf8', ''),
    true,
    'table_character_set_is() with correct specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.table_character_set_is('taptest', 'sometab', 'latin1', ''),
    false,
    'table_character_set_is() with incorrect specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.table_character_set_is('taptest', 'sometab', 'utf8', ''),
    true,
    'table_character_set_is() default description',
    'Table taptest.sometab should have Character set \'utf8\'',
    null,
    0
);

SELECT tap.check_test(
    tap.table_character_set_is('taptest', 'sometab', 'utf8', 'desc'),
    true,
    'table_character_set_is() description supplied',
    'desc',
    null,
    0
);

SELECT tap.check_test(
    tap.table_character_set_is('taptest', 'sometab', 'INVALID', ''),
    false,
    'table_character_set_is() invalid charset supplied',
    null,
    'Character set INVALID is not available',
    0
);

SELECT tap.check_test(
    tap.table_character_set_is('taptest', 'nonexistent', 'utf8', ''),
    false,
    'table_character_set_is() nonexistent table supplied',
    null,
    'Table taptest.nonexistent does not exist',
    0
);



/****************************************************************************/
-- tables_are(sname VARCHAR(64), want TEXT, description TEXT)


SELECT tap.check_test(
    tap.tables_are('taptest', '`sometab`,`othertab`', ''),
    true,
    'tables_are() correct specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.tables_are('taptest', '`sometab`,`nonexistent`', ''),
    false,
    'tables_are() incorrect specification',
    null,
    null,
    0
);


-- Note the diagnostic test here is dependent on the space after the hash
-- and before the line feed and the number of spaces before
-- the table names, which must = 7
SELECT tap.check_test(
    tap.tables_are('taptest', '`sometab`,`nonexistent`', ''),
    false,
    'tables_are() diagnostic',
    null,
    '# 
    Extra tables:
       `othertab`
    Missing tables:
       `nonexistent`',
    0
);

SELECT tap.check_test(
    tap.tables_are('taptest', '`sometab`,`othertab`', ''),
    true,
    'tables_are() default description',
    'Schema taptest should have the correct Tables',
    null,
    0
);

SELECT tap.check_test(
    tap.tables_are('taptest',  '`sometab`,`othertab`', 'desc'),
    true,
    'tables_are() description supplied',
    'desc',
    null,
    0
);


/****************************************************************************/
-- table_sha1_is(sname VARCHAR(64), tname VARCHAR(64), sha1 VARCHAR(40), description TEXT)


-- if othertab definition is changed, run create table command on
-- new definition and recalculate sha1 with
-- SELECT tap._table_sha1('taptest','sometab');
SELECT tap.check_test(
    tap.table_sha1_is('taptest', 'sometab', 'c87b4a7e95b2110bba4a4c5c1ac451c7bec18869', ''),
    true,
    'table_sha1() full specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.table_sha1_is('taptest', 'sometab', 'c87b4a7e95', ''),
    true,
    'table_sha1() partial specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.table_sha1_is('taptest', 'sometab', '0123456789',''),
    false,
    'table_sha1() incorrect specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.table_sha1_is('taptest', 'nonexistent', 'c87b4a7e95b2110bba4a4c5c1ac451c7bec18869',''),
    false,
    'table_sha1() nonexistent table',
    null,
    'Table taptest.nonexistent does not exist',
    0
);


SELECT tap.check_test(
    tap.table_sha1_is('taptest', 'sometab', 'c87b4a7e95b2110bba4a4c5c1ac451c7bec18869', ''),
    true,
    'table_sha1() default description',
    'Table taptest.sometab definition should match expected value',
    null,
    0
);



/****************************************************************************/

-- Finish the tests and clean up.

call tap.finish();
DROP DATABASE IF EXISTS taptest;
ROLLBACK;
