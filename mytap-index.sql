-- INDEX check functions

DELIMITER //

/**************************************************************************/

-- Check constituent parts of an index covers partial index 
DROP FUNCTION IF EXISTS _index_def //
CREATE FUNCTION _index_def(sname VARCHAR(64), tname VARCHAR(64), iname VARCHAR(64))
RETURNS TEXT
DETERMINISTIC
BEGIN
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(CONCAT('`', `column_name`, '`'),
  IF(`sub_part` IS NULL, '', CONCAT('(', `sub_part`, ')'))) AS 'column_name' INTO ret
  FROM `information_schema`.`statistics`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `index_name` = iname
  ORDER BY `seq_in_index`;

  RETURN ret;
END //

-- The named index should comprise ...
-- pgTAP has this test as part of has_index, which is possible with postgres function overloading
-- a separate function is required for mysql.
-- Includes a test for partial index in format `name`(n)
-- Quote everything in the 'want' CSL string with backticks and no spaces

DROP FUNCTION IF EXISTS index_is //
CREATE FUNCTION index_is(sname VARCHAR(64), tname VARCHAR(64), iname VARCHAR(64), want TEXT, description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Index ', quote_ident(tname), '.', quote_ident(iname),
      ' should exist on ' , want);
  END IF;

  IF NOT _has_index(sname, tname, iname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Index ', quote_ident(tname), '.', quote_ident(iname),
        ' does not exist' )));
  END IF;

  RETURN eq(_index_def(sname, tname, iname), want, description);
END //


-- Check constituent parts of an index
-- We expect a comma separated list of quoted identifiers

DROP FUNCTION IF EXISTS _is_indexed //
CREATE FUNCTION _is_indexed(sname VARCHAR(64), tname VARCHAR(64), want TEXT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE ret BOOLEAN;

    SELECT COUNT(`indexdef`) INTO ret
    FROM
      (
        SELECT `table_name`, `index_name`,
        GROUP_CONCAT(CONCAT('`', `column_name`, '`') ORDER BY `seq_in_index`) AS `indexdef`
        FROM `information_schema`.`statistics`
        WHERE `table_schema` = sname
        AND `table_name` = tname
        GROUP BY `table_name`,`index_name`
      ) indices
    WHERE `indexdef` = want;

    RETURN IF(ret <> 0 , TRUE, FALSE);
END //


-- Simply, is there an index covering the columns supplied (in the order provided),
-- we only care that the names are quoted for the check and there are no spaces in the CSL

DROP FUNCTION IF EXISTS is_indexed //
CREATE FUNCTION is_indexed(sname VARCHAR(64), tname VARCHAR(64), want TEXT, description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN 
    SET description = CONCAT('Index for ', quote_ident(sname), '.', quote_ident(tname),
      ' should exist on ' , want);
  END IF;

  IF NOT _has_table( sname, tname ) THEN
    RETURN CONCAT(ok( FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist' )));
  END IF;

  RETURN ok(_is_indexed(sname, tname, want), description);
END //

/*****************************************************************************/
-- Simple check on existence of named index without being concerned for its
-- composition

DROP FUNCTION IF EXISTS _has_index //
CREATE FUNCTION _has_index(sname VARCHAR(64), tname VARCHAR(64), iname VARCHAR(64))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE ret BOOLEAN;

  SELECT 1 INTO ret
  FROM `information_schema`.`statistics`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `index_name` = iname
  LIMIT 1; -- for multi column index

  RETURN COALESCE(ret, 0);
END //

-- check for the existence of named index
DROP FUNCTION IF EXISTS has_index //
CREATE FUNCTION has_index(sname VARCHAR(64), tname VARCHAR(64), iname VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Index ', quote_ident(tname), '.', quote_ident(iname),
      ' should exist');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
  END IF;

  RETURN ok(_has_index( sname, tname, iname), description);
END //

-- test for when an index has been deleted, would also show in the extras list of indexes_are()
DROP FUNCTION IF EXISTS hasnt_index //
CREATE FUNCTION hasnt_index(sname VARCHAR(64), tname VARCHAR(64), iname VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Index ', quote_ident(tname), '.', quote_ident(iname),
      ' should not exist');
  END IF;
    
  IF NOT _has_table( sname, tname ) THEN
    RETURN CONCAT( ok( FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
  END IF;

  RETURN ok(NOT _has_index(sname, tname, iname), description);
END //


/*******************************************************************/
-- Checks for index properties

-- BTREE, FULLTEXT, SPATIAL
DROP FUNCTION IF EXISTS _index_type //
CREATE FUNCTION _index_type(sname VARCHAR(64), tname VARCHAR(64), iname VARCHAR(64))
RETURNS VARCHAR(16)
DETERMINISTIC
BEGIN
  DECLARE ret VARCHAR(16);

  SELECT `index_type` INTO ret
  FROM `information_schema`.`statistics`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `index_name` = iname
  LIMIT 1; -- for multi-col index

  RETURN COALESCE(ret, NULL);
END //


DROP FUNCTION IF EXISTS index_is_type //
CREATE FUNCTION index_is_type(sname VARCHAR(64), tname VARCHAR(64), iname VARCHAR(64), itype VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
     SET description = CONCAT('Index ', quote_ident(tname), '.', quote_ident(iname),
      ' should be of Type ', qv(itype));
  END IF;

  IF NOT _has_table( sname, tname ) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        'does not exist' )));
  END IF;


  -- REM index names a 
  IF NOT _has_index( sname, tname, iname ) THEN
    RETURN CONCAT(ok(FALSE,description),'\n',
      diag(CONCAT('Index ', quote_ident(tname), '.', quote_ident(iname), 
        ' does not exist')));
  END IF;

  RETURN eq(_index_type( sname, tname, iname), itype, description);
END //


/*******************************************************************/
-- Check that the proper indexes are defined
-- Table constraints are handled elsewhere

DROP FUNCTION IF EXISTS _missing_indexes //
CREATE FUNCTION _missing_indexes(sname VARCHAR(64), tname VARCHAR(64))
RETURNS TEXT
DETERMINISTIC
BEGIN 
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(quote_ident(`ident`)) INTO ret 
  FROM 
    (
      SELECT `ident`
      FROM `idents1`
      WHERE `ident` NOT IN
        (
          SELECT s.`index_name`
          FROM `information_schema`.`statistics` s
          LEFT JOIN `information_schema`.`table_constraints` c
            ON (s.`table_schema` = c.`table_schema`
                AND s.`table_name` = c.`table_name` 
                AND s.`index_name` = c.`constraint_name`)
          WHERE s.`table_schema` = sname
          AND s.`table_name` = tname
          AND c.`constraint_name` IS NULL
        )
    ) msng;

  RETURN COALESCE(ret, '');
END //

DROP FUNCTION IF EXISTS _extra_indexes //
CREATE FUNCTION _extra_indexes(sname VARCHAR(64), tname VARCHAR(64))
RETURNS TEXT
DETERMINISTIC
BEGIN
  DECLARE ret TEXT;
  -- we want only the indexes that are NOT in both tables
  -- constraints are handled separately
  SELECT GROUP_CONCAT(quote_ident(`ident`)) INTO ret
  FROM 
    (
      SELECT DISTINCT s.`index_name` AS `ident`
      FROM `information_schema`.`statistics` s 
      LEFT JOIN `information_schema`.`table_constraints` c
      ON (s.`table_schema` = c.`table_schema`
          AND s.`table_name` = c.`table_name` 
          AND s.`index_name` = c.`constraint_name`)
      WHERE c.`constraint_name` IS NULL
      AND s.`table_schema` = sname
      AND s.`table_name` = tname
      AND s.`index_name` NOT IN
        (
          SELECT `ident`
          FROM `idents2`
        )
    ) xtra;

  RETURN COALESCE(ret, '');
END //


DROP FUNCTION IF EXISTS indexes_are //
CREATE FUNCTION indexes_are(sname VARCHAR(64), tname VARCHAR(64),  want TEXT, description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  DECLARE sep       CHAR(1) DEFAULT ','; 
  DECLARE seplength INTEGER DEFAULT CHAR_LENGTH(sep);
  DECLARE missing   TEXT; 
  DECLARE extras    TEXT;

  IF description = '' THEN
   SET description = CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
      ' should have the correct indexes');
   END IF;
    
  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n', 
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist' )));
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

  SET missing = _missing_indexes(sname, tname);
  SET extras  = _extra_indexes(sname, tname);

  RETURN _are('indexes', extras, missing, description);
END //


DELIMITER ;
