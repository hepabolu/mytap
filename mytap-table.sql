DELIMITER //

/****************************************************************************/


-- _has_table(schema, table)
DROP FUNCTION IF EXISTS _has_table //
CREATE FUNCTION _has_table(sname VARCHAR(64), tname VARCHAR(64))
RETURNS BOOLEAN
DETERMINISTIC
COMMENT 'Internal boolean test for the existence of a named table/view within the given schema.'
BEGIN
  DECLARE ret BOOLEAN;

  SELECT 1 INTO ret
  FROM `information_schema`.`tables`
  WHERE `table_name` = tname
  AND `table_schema` = sname;

  RETURN COALESCE(ret, 0);
END //


-- has_table(schema, table, description)
DROP FUNCTION IF EXISTS has_table //
CREATE FUNCTION has_table(sname VARCHAR(64), tname VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
COMMENT 'Test that a named table exists within the given schema.'
BEGIN
  IF description = '' THEN
    SET description = concat('Table ',
      quote_ident(sname), '.', quote_ident(tname), ' should exist');
  END IF;

  RETURN ok(_has_table(sname, tname), description);
END //


-- hasnt_table(schema, table, description)
DROP FUNCTION IF EXISTS hasnt_table //
CREATE FUNCTION hasnt_table(sname VARCHAR(64), tname VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
COMMENT 'Test that a named table does not exists within the given schema.'
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Table ',
      quote_ident(sname), '.', quote_ident(tname), ' should not exist');
  END IF;

  RETURN ok(NOT _has_table(sname, tname), description);
END //


/**************************************************************************/

-- TABLE STORAGE ENGINE DEFINITIONS

DROP FUNCTION IF EXISTS _table_engine//
CREATE FUNCTION _table_engine(sname VARCHAR(64), tname VARCHAR(64))
RETURNS VARCHAR(32)
DETERMINISTIC
COMMENT 'Internal function to return the engine type for a named table.'
BEGIN
  DECLARE ret VARCHAR(32);

  SELECT `engine` INTO ret
  FROM `information_schema`.`tables`
  WHERE `table_schema` = sname
  AND `table_name` = tname;

  RETURN COALESCE(ret, NULL);
END //


-- table_engine_is(schema, table, engine, description)
DROP FUNCTION IF EXISTS table_engine_is //
CREATE FUNCTION table_engine_is(sname VARCHAR(64), tname VARCHAR(64), ename VARCHAR(32), description TEXT)
RETURNS TEXT
DETERMINISTIC
COMMENT 'Confirm the engine for a table matches value provided.'
BEGIN
  IF description = '' THEN
    SET description = concat('Table ', quote_ident(sname), '.',
      quote_ident(tname), ' should have Storage Engine ',  quote_ident(ename));
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname), ' does not exist')));
  END IF;

  IF NOT _has_engine(ename) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Storage Engine ', quote_ident(ename), ' is not available')));
  END IF;

  RETURN eq(_table_engine(sname, tname), ename , description);
END //


/**************************************************************************/

-- TABLE COLLATION DEFINITION

-- _table_collation(schema, table)
DROP FUNCTION IF EXISTS _table_collation //
CREATE FUNCTION _table_collation(sname VARCHAR(64), tname VARCHAR(64))
RETURNS VARCHAR(32)
DETERMINISTIC
COMMENT 'Internal function to return the default collation for a named table.'
BEGIN
  DECLARE ret VARCHAR(32);

  SELECT `table_collation` INTO ret
  FROM `information_schema`.`tables`
  WHERE `table_schema` = sname
  AND `table_name` = tname;

  RETURN COALESCE(ret, NULL);
END //


DROP FUNCTION IF EXISTS table_collation_is //
CREATE FUNCTION table_collation_is(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
COMMENT 'Confirm the default collation for a table matches value provided.'
BEGIN
  IF description = '' THEN
    SET description = concat('Table ', quote_ident(sname), '.',
      quote_ident(tname), ' should have Collation ',  qv(cname));
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.',
        quote_ident(tname), ' does not exist')));
  END IF;

  IF NOT _has_collation(cname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Collation ', quote_ident(cname), ' is not available')));
  END IF;

  RETURN eq(_table_collation(sname, tname), cname, description);
END //


/**************************************************************************/

-- TABLE CHARACTER SET DEFINITION
-- This info is available in show create table though it is not stored directly
-- and can be derived from the prefix of the table collation.

-- _table_character_set(schema, table, collation)
DROP FUNCTION IF EXISTS _table_character_set //
CREATE FUNCTION _table_character_set(sname VARCHAR(64), tname VARCHAR(64))
RETURNS VARCHAR(32)
DETERMINISTIC
COMMENT 'Internal function to return the default character set for a named table.'
BEGIN
  DECLARE ret VARCHAR(32);

  SELECT c.`character_set_name` INTO ret
  FROM `information_schema`.`tables` AS t 
  INNER JOIN `information_schema`.`collation_character_set_applicability` AS c
    ON (t.`table_collation` = c.`collation_name`)
  WHERE t.`table_schema` = sname
  AND t.`table_name` = tname;

  RETURN COALESCE(ret, NULL);
END //


-- table_character_set_is(schema, table, character_set, description)
DROP FUNCTION IF EXISTS table_character_set_is //
CREATE FUNCTION table_character_set_is(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(32), description TEXT)
RETURNS TEXT
DETERMINISTIC
COMMENT 'Confirm the default character set for a table matches value provided.'
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Table ', quote_ident(sname), '.',
      quote_ident(tname), ' should have Character Set ',  qv(cname));
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
  END IF;

  IF NOT _has_charset(cname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Character Set ', quote_ident(cname), ' is not available')));
  END IF;

  RETURN eq(_table_character_set(sname, tname), cname, description);
END //


/*******************************************************************/
-- Check that the proper tables are defined

DROP FUNCTION IF EXISTS _missing_tables //
CREATE FUNCTION _missing_tables(sname VARCHAR(64))
RETURNS TEXT
DETERMINISTIC
COMMENT 'Internal function to identify tables that are listed in input to tables_are(schema, want, description) but are not defined'
BEGIN
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(qi(`ident`)) INTO ret
  FROM
    (
      SELECT `ident`
      FROM `idents1`
      WHERE `ident` NOT IN
        (
          SELECT `table_name`
          FROM `information_schema`.`tables`
          WHERE `table_schema` = sname
          AND `table_type` = 'BASE TABLE'
      )
   ) msng;

  RETURN COALESCE(ret, '');
END //

DROP FUNCTION IF EXISTS _extra_tables //
CREATE FUNCTION _extra_tables(sname VARCHAR(64))
RETURNS TEXT
DETERMINISTIC
COMMENT 'Internal function to identify defined tables that are not list in input to tables_are(schema, want, description)'
BEGIN
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(qi(`ident`)) INTO ret
  FROM 
    (
      SELECT `table_name` AS `ident` 
      FROM `information_schema`.`tables`
      WHERE `table_schema` = sname
      AND `table_type` = 'BASE TABLE'
      AND `table_name` NOT IN
        (
          SELECT `ident`
          FROM `idents2`
        )
  ) xtra;

  RETURN COALESCE(ret, '');
END //


DROP FUNCTION IF EXISTS tables_are //
CREATE FUNCTION tables_are(sname VARCHAR(64), want TEXT, description TEXT)
RETURNS TEXT
DETERMINISTIC
COMMENT 'Test for the existence of named tables. Identifies both missing as well as extra tables.'
BEGIN
  DECLARE sep       CHAR(1) DEFAULT ',';
  DECLARE seplength INTEGER DEFAULT CHAR_LENGTH(sep);

  IF description = '' THEN
    SET description = CONCAT('Schema ', quote_ident(sname),
      ' should have the correct Tables');
  END IF;

  IF NOT _has_schema(sname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Schema ', quote_ident(sname), ' does not exist')));
  END IF;

  SET want = _fixCSL(want);

  IF want IS NULL THEN
    RETURN CONCAT(ok(FALSE,description),'\n',
      diag(CONCAT('Invalid character in comma separated list of expected schemas\n',
                  'Identifier must not contain NUL Byte or extended characters (> U+10000)')));
  END IF;

  DROP TEMPORARY TABLE IF EXISTS idents1;
  CREATE TEMPORARY TABLE tap.idents1 (ident VARCHAR(64) PRIMARY KEY)
    ENGINE MEMORY CHARSET utf8 COLLATE utf8_general_ci;
  DROP TEMPORARY TABLE IF EXISTS idents2;
  CREATE TEMPORARY TABLE tap.idents2 (ident VARCHAR(64) PRIMARY KEY)
    ENGINE MEMORY CHARSET utf8 COLLATE utf8_general_ci;

  WHILE want != '' > 0 DO
    SET @val = TRIM(SUBSTRING_INDEX(want, sep, 1));
    SET @val = uqi(@val);
    IF  @val <> '' THEN 
      INSERT IGNORE INTO idents1 VALUE(@val);
      INSERT IGNORE INTO idents2 VALUE(@val);
    END IF;
    SET want = SUBSTRING(want, CHAR_LENGTH(@val) + seplength + 1);
  END WHILE;

  SET @missing = _missing_tables(sname);
  SET @extras  = _extra_tables(sname);

  RETURN _are('tables', @extras, @missing, description);
END //

/****************************************************************************/
-- CHECK FOR SCHEMA CHANGES
-- Get the SHA-1 from the table definition and it's constituent schema objects 
-- to for a simple test for changes. Excludes partitioning since the names might
-- change over the course of time through normal DLM operations.
-- Allows match against partial value to save typing as
-- 8 characters will give 16^8 combinations.
 
DROP FUNCTION IF EXISTS _table_sha1 //
CREATE FUNCTION _table_sha1(sname VARCHAR(64), tname VARCHAR(64))
RETURNS CHAR(40)
DETERMINISTIC
BEGIN
  DECLARE ret CHAR(40);

  SELECT SHA1(GROUP_CONCAT(sha)) INTO ret
  FROM 
    (   
      (SELECT SHA1( -- COLUMNS
        GROUP_CONCAT(
          SHA1(
            CONCAT_WS('',`table_catalog`,`table_schema`,`table_name`,`column_name`,
              `ordinal_position`,`column_default`,`is_nullable`,`data_type`,
              `character_set_name`,`character_maximum_length`,`character_octet_length`,
              `numeric_precision`,`numeric_scale`,`datetime_precision`,`collation_name`,
              `column_type`,`column_key`,`extra`,`privileges`,`column_comment`,
              `generation_expression`)
      ))) sha
      FROM `information_schema`.`columns`
      WHERE `table_schema` = sname
      AND `table_name` = tname
      ORDER BY `table_name` ASC,`column_name` ASC)
  UNION ALL
      (SELECT SHA1( -- CONSTRAINTS
        GROUP_CONCAT(
          SHA1(
            CONCAT_WS('',`constraint_catalog`,`constraint_schema`,`constraint_name`,
            `unique_constraint_catalog`,`unique_constraint_schema`,`unique_constraint_name`,
            `match_option`,`update_rule`,`delete_rule`,`table_name`,`referenced_table_name`)
      ))) sha
      FROM `information_schema`.`referential_constraints`
      WHERE `constraint_schema` = sname
      AND `table_name` = tname
      ORDER BY `table_name` ASC,`constraint_name` ASC)
  UNION ALL
      (SELECT SHA1( -- INDEXES
        GROUP_CONCAT(
          SHA1(
            CONCAT_WS('',`table_catalog`,`table_schema`,`table_name`,`index_name`,`non_unique`,
              `index_schema`,`index_name`,`seq_in_index`,`column_name`,`collation`,`cardinality`,
              `sub_part`,`packed`,`nullable`,`index_type`,`comment`,`index_comment`)
      ))) sha
      FROM `information_schema`.`statistics`
      WHERE `table_schema` = sname
      AND `table_name` = tname
      ORDER BY `table_name` ASC,`index_name` ASC,`seq_in_index` ASC)
  UNION ALL
      (SELECT SHA1( -- TRIGGERS
        GROUP_CONCAT(
          SHA1(
           CONCAT_WS('',`trigger_catalog`,`trigger_schema`,`trigger_name`,`event_manipulation`,
            `event_object_catalog`,`event_object_schema`,`event_object_table`,`action_order`,
            `action_condition`,`action_statement`,`action_orientation`,`action_timing`,
            `action_reference_old_table`,`action_reference_new_table`,`action_reference_old_row`,
            `action_reference_new_row`,`sql_mode`,`definer`,`database_collation`)
      ))) sha
      FROM `information_schema`.`triggers`
      WHERE `trigger_schema` = sname
      AND `event_object_table` = tname
      ORDER BY `event_object_table` ASC,`trigger_name` ASC)
  ) objects;

  RETURN COALESCE(ret, NULL);
END //

DROP FUNCTION IF EXISTS table_sha1_is //
CREATE FUNCTION table_sha1_is(sname VARCHAR(64), tname VARCHAR(64), sha1 VARCHAR(40), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
      ' definition should match expected value');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname), ' does not exist')));
  END IF;

  -- NB length of supplied value not of a SHA-1
  RETURN eq(LEFT(_table_sha1(sname, tname), LENGTH(sha1)), sha1, description);
END //


DELIMITER ;
