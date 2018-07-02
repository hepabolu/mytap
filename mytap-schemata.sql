-- SCHEMA
-- ======

DELIMITER //

/****************************************************************************/

-- has_schema( schema)
DROP FUNCTION IF EXISTS _has_schema //
CREATE FUNCTION _has_schema(sname VARCHAR(64))
RETURNS BOOLEAN
DETERMINISTIC
COMMENT 'Boolean test for existence of named schema.'
BEGIN
  DECLARE ret BOOLEAN;

  SELECT 1 INTO ret
  FROM `information_schema`.`schemata`
  WHERE `schema_name` = sname;

  RETURN COALESCE(ret, 0);
END //


-- has_schema( schema, description )
DROP FUNCTION IF EXISTS has_schema //
CREATE FUNCTION has_schema(sname VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
COMMENT 'Confirm named schema exists.'
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Schema ', quote_ident(sname), ' should exist');
  END IF;

  RETURN ok(_has_schema(sname), description);
END //


-- hasnt_schema( schema, description )
DROP FUNCTION IF EXISTS hasnt_schema //
CREATE FUNCTION hasnt_schema(sname VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
COMMENT 'Confirm named schema does not exist.'
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Schema ', quote_ident(sname), ' should not exist');
  END IF;

  RETURN ok(NOT _has_schema(sname), description);
END //

/****************************************************************************/

-- DEFAULT SCHEMA COLLATION DEFINITIONS

-- _schema_collation_is( schema, collation )
DROP FUNCTION IF EXISTS _schema_collation_is //
CREATE FUNCTION _schema_collation_is(sname VARCHAR(64))
RETURNS VARCHAR(32)
DETERMINISTIC
COMMENT 'Internal function to get the default collation for a named schema.'
BEGIN
  DECLARE ret VARCHAR(32);

  SELECT `default_collation_name` INTO ret
  FROM `information_schema`.`schemata`
  WHERE `schema_name` = sname;

  RETURN COALESCE(ret, NULL);
END //


-- schema_collation_is( schema, collation, description )
DROP FUNCTION IF EXISTS schema_collation_is //
CREATE FUNCTION schema_collation_is(sname VARCHAR(64), cname VARCHAR(32), description TEXT)
RETURNS TEXT
DETERMINISTIC
COMMENT 'Confirm the default collation for a schema matches value provided.'
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Schema ', quote_ident(sname), ' should have Collation ',  qv(cname));
  END IF;

  IF NOT _has_schema(sname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Schema ', quote_ident(sname), ' does not exist')));
  END IF;

  IF NOT _has_collation(cname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Collation ', quote_ident(cname), ' is not available')));
  END IF;

  RETURN eq(_schema_collation_is(sname), cname , description);
END //


/****************************************************************************/

-- DEFAULT CHARACTER SET DEFINITION

-- _schema_charset_is( schema, charset )
DROP FUNCTION IF EXISTS _schema_charset_is //
CREATE FUNCTION _schema_charset_is(sname VARCHAR(64))
RETURNS VARCHAR(32)
DETERMINISTIC
COMMENT 'Internal fuction to return the default collation for a named schema.'
BEGIN
  DECLARE ret VARCHAR(32);

  SELECT `default_character_set_name` INTO ret
  FROM `information_schema`.`schemata`
  WHERE `schema_name` = sname;

  RETURN COALESCE(ret, NULL);
END //


-- schema_charset_is( schema, charset, description )
DROP FUNCTION IF EXISTS schema_charset_is //
CREATE FUNCTION schema_charset_is(sname VARCHAR(64), cname VARCHAR(32), description TEXT)
RETURNS TEXT
DETERMINISTIC
COMMENT 'Confirm the default character set for a schema matches value provided.'
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Schema ', quote_ident(sname),
      ' should use Character Set ',  quote_ident(cname));
  END IF;

  IF NOT _has_schema(sname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Schema ', quote_ident(sname), ' does not exist')));
  END IF;

  IF NOT _has_charset(cname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Character Set ', quote_ident(cname), ' is not available')));
  END IF;

  RETURN eq(_schema_charset_is(sname), cname, description);
END //

-- alias
DROP FUNCTION IF EXISTS schema_character_set_is //
CREATE FUNCTION schema_character_set_is(sname VARCHAR(64), cname VARCHAR(32), description TEXT)
RETURNS TEXT
DETERMINISTIC
COMMENT 'Alias for schema_charset_is(sname, cname, description).'
BEGIN
  RETURN schema_charset_is(sname, cname, description);
END //

/****************************************************************/

-- Listing schemas
DROP FUNCTION IF EXISTS _missing_schemas //
CREATE FUNCTION _missing_schemas() 
RETURNS TEXT
DETERMINISTIC
COMMENT 'Internal function to identify schemas listed in input to schemas_are(want, description) which are not defined'
BEGIN
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(quote_ident(`ident`)) INTO ret
  FROM
    (
      SELECT `ident`
      FROM `idents1`
      WHERE `ident` NOT IN
        (
          SELECT `schema_name`
          FROM `information_schema`.`schemata`
        )
    ) msng;

  RETURN COALESCE(ret, '');
END //

DROP FUNCTION IF EXISTS _extra_schemas //
CREATE FUNCTION _extra_schemas()
RETURNS TEXT
DETERMINISTIC
COMMENT 'Internal function to identify defined schemas that are not list in input to schemas_are(want, description)'
BEGIN
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(quote_ident(`ident`)) INTO ret
  FROM 
    (
      SELECT `schema_name` AS `ident` 
      FROM `information_schema`.`schemata`
      WHERE `schema_name` NOT IN 
        (
          SELECT `ident`
          FROM `idents2`
        )
    ) xtra;

  RETURN COALESCE(ret, '');
END //


DROP FUNCTION IF EXISTS schemas_are //
CREATE FUNCTION schemas_are(want TEXT, description TEXT)
RETURNS TEXT
DETERMINISTIC
COMMENT 'Test for the existence of named schemas. Identifies both missing as well as extra schemas.'
BEGIN
  DECLARE sep       CHAR(1) DEFAULT ',';
  DECLARE seplength INTEGER DEFAULT CHAR_LENGTH(sep);
  DECLARE missing   TEXT;
  DECLARE extras    TEXT;

  IF description = '' THEN
    SET description = 'The correct Schemas should be defined';
  END IF;

  SET want = _fixCSL(want);

  IF want IS NULL THEN
    RETURN CONCAT(ok(FALSE,description),'\n',
      diag(CONCAT('Invalid character in comma separated list of expected schemas\n',
                  'Identifier must not contain NUL Byte or extended characters (> U+10000)')));
  END IF;

  IF want IS NULL THEN
    RETURN CONCAT(ok(FALSE,description),'\n',
      diag(CONCAT('Invalid character in comma separated list of expected schemas\n', want)));
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

  SET missing = _missing_schemas();
  SET extras  = _extra_schemas();

  RETURN _are('schemas', extras, missing, description);
END //


DELIMITER ;
