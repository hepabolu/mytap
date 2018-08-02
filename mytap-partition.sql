-- PARTITIONS
-- ==========

-- Table level tests on partitioning

USE tap;

DELIMITER //

/************************************************************************************/
-- _has_partition( schema, table, partition, description )
DROP FUNCTION IF EXISTS _has_partition //
CREATE FUNCTION _has_partition(sname VARCHAR(64), tname VARCHAR(64), part VARCHAR(64))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE ret BOOLEAN;

  SELECT 1 INTO ret
  FROM `information_schema`.`partitions`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `partition_name` = part
  LIMIT 1;

  RETURN COALESCE(ret, 0);
END //

-- has_partition( schema, table, partition, description )
DROP FUNCTION IF EXISTS has_partition //
CREATE FUNCTION has_partition(sname VARCHAR(64), tname VARCHAR(64), part VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Partition ', quote_ident(tname), '.', quote_ident(part),
      ' should exist');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
  END IF;

    RETURN ok(_has_partition(sname, tname, part), description);
END //


-- hasnt_partition( schema, table, partition, description )
DROP FUNCTION IF EXISTS hasnt_partition //
CREATE FUNCTION hasnt_partition(sname VARCHAR(64), tname VARCHAR(64), part VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Partition ', quote_ident(tname), '.', quote_ident(part),
      ' should not exist');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
    END IF;

    RETURN ok(NOT _has_partition(sname, tname, part), description);
END //


/************************************************************************/
-- SUBPARTITION
-- _has_subpartition( schema, table, sub, description )
DROP FUNCTION IF EXISTS _has_subpartition //
CREATE FUNCTION _has_subpartition(sname VARCHAR(64), tname VARCHAR(64), subp VARCHAR(64))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE ret BOOLEAN;

  SELECT 1 INTO ret
  FROM `information_schema`.`partitions`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `subpartition_name` = subp;

  RETURN COALESCE(ret, 0);
END //

-- has_subpartition( schema, table, subpartition, description )
DROP FUNCTION IF EXISTS has_subpartition //
CREATE FUNCTION has_subpartition(sname VARCHAR(64), tname VARCHAR(64), subp VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Subpartition ', quote_ident(tname),
      '.' , quote_ident(subp), ' should exist');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
  END IF;

  RETURN ok(_has_subpartition(sname, tname, subp), description);
END //


-- hasnt_subpartition( schema, table, subpartition, description )
DROP FUNCTION IF EXISTS hasnt_subpartition //
CREATE FUNCTION hasnt_subpartition(sname VARCHAR(64), tname VARCHAR(64), subp VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Subpartition ', quote_ident(tname),
       '.', quote_ident(subp), ' should not exist');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
    END IF;

  RETURN ok(NOT _has_subpartition(sname, tname, subp), description);
END //


/****************************************************************************/
-- PARTITION EXPRESSION

DROP FUNCTION IF EXISTS _partition_expression  //
CREATE FUNCTION _partition_expression(sname VARCHAR(64), tname VARCHAR(64), part VARCHAR(64))
RETURNS LONGTEXT
DETERMINISTIC
BEGIN
  DECLARE ret LONGTEXT;

  SELECT TRIM(`partition_expression`) INTO ret
  FROM `information_schema`.`partitions`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `partition_name` = part
  LIMIT 1;

  RETURN COALESCE(ret, NULL);
END //

DROP FUNCTION IF EXISTS partition_expression_is//
CREATE FUNCTION partition_expression_is(sname VARCHAR(64), tname VARCHAR(64), part VARCHAR(64), expr LONGTEXT, description TEXT)
RETURNS LONGTEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = concat('Partition ', quote_ident(tname), '.', quote_ident(part),
      ' should have Partition Expression ', qv(TRIM(expr)));
  END IF;

  IF NOT _has_partition(sname, tname, part) THEN
    RETURN CONCAT(ok( FALSE, description), '\n',
      diag(CONCAT('Partition ', quote_ident(tname),'.', quote_ident(part),
        ' does not exist')));
  END IF;

  RETURN eq(_partition_expression(sname, tname, part), TRIM(expr), description);
END //


/****************************************************************************/
-- PARTITION EXPRESSION

DROP FUNCTION IF EXISTS _subpartition_expression  //
CREATE FUNCTION _subpartition_expression(sname VARCHAR(64), tname VARCHAR(64), subp VARCHAR(64))
RETURNS LONGTEXT
DETERMINISTIC
BEGIN
  DECLARE ret LONGTEXT;

  SELECT TRIM(`subpartition_expression`) INTO ret
  FROM `information_schema`.`partitions`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `subpartition_name` = subp;

  RETURN COALESCE(ret, NULL);
END //

DROP FUNCTION IF EXISTS subpartition_expression_is//
CREATE FUNCTION subpartition_expression_is(sname VARCHAR(64), tname VARCHAR(64), subp VARCHAR(64), expr LONGTEXT, description TEXT)
RETURNS LONGTEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = concat('Subpartition ', quote_ident(tname), '.', quote_ident(subp),
      ' should have Subpartition Expression ', qv(TRIM(expr)));
  END IF;

  IF NOT _has_subpartition(sname, tname, subp) THEN
    RETURN CONCAT(ok( FALSE, description), '\n',
      diag(CONCAT('Subpartition ', quote_ident(tname), '.', quote_ident(subp),
        ' does not exist')));
  END IF;

  RETURN eq(_subpartition_expression(sname, tname, subp), TRIM(expr), description);
END //


/****************************************************************************/
-- PARTITION METHOD

DROP FUNCTION IF EXISTS _partition_method //
CREATE FUNCTION _partition_method(sname VARCHAR(64), tname VARCHAR(64), part VARCHAR(64))
RETURNS VARCHAR(18)
DETERMINISTIC
BEGIN
DECLARE ret VARCHAR(18);

  SELECT `partition_method` INTO ret
  FROM `information_schema`.`partitions`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `partition_name` = part
  LIMIT 1;

  RETURN COALESCE(ret, NULL);
END //

DROP FUNCTION IF EXISTS partition_method_is//
CREATE FUNCTION partition_method_is(sname VARCHAR(64), tname VARCHAR(64), part VARCHAR(64), pmeth VARCHAR(18), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  DECLARE valid ENUM('RANGE', 'LIST', 'HASH', 'LINEAR HASH', 'KEY', 'LINEAR KEY');
  
  DECLARE EXIT HANDLER FOR 1265
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag('Partitioning Method must be { RANGE | LIST | HASH | LINEAR HASH | KEY | LINEAR KEY }'));

  IF description = '' THEN
    SET description = CONCAT('Partition ', quote_ident(tname), '.', quote_ident(part),
      ' should have Partition Method ', qv(pmeth));
  END IF;

  SET valid = pmeth;

  IF NOT _has_partition(sname, tname, part) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Partition ', quote_ident(tname),'.', quote_ident(part),
        ' does not exist')));
  END IF;

  RETURN eq(_partition_method(sname, tname, part), pmeth, description);
END //

/****************************************************************************/
-- SUBPARTITION METHOD

DROP FUNCTION IF EXISTS _subpartition_method //
CREATE FUNCTION _subpartition_method(sname VARCHAR(64), tname VARCHAR(64), subp VARCHAR(64))
RETURNS VARCHAR(12)
DETERMINISTIC
BEGIN
DECLARE ret VARCHAR(12);

  SELECT `subpartition_method` INTO ret
  FROM `information_schema`.`partitions`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `subpartition_name` = subp;

  RETURN COALESCE(ret, NULL);
END //

DROP FUNCTION IF EXISTS subpartition_method_is//
CREATE FUNCTION subpartition_method_is(sname VARCHAR(64), tname VARCHAR(64), subp VARCHAR(64), smeth VARCHAR(18), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  DECLARE valid ENUM('HASH', 'LINEAR HASH', 'KEY', 'LINEAR KEY');
  
  DECLARE EXIT HANDLER FOR 1265
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag('Subpartition Method must be { HASH | LINEAR HASH | KEY | LINEAR KEY }'));

  IF description = '' THEN
    SET description = CONCAT('Subpartition ', quote_ident(tname), '.', quote_ident(subp),
      ' should have SubPartition Method ', qv(smeth));
  END IF;

  SET valid = smeth;

  IF NOT _has_subpartition(sname, tname, subp) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Subpartition ', quote_ident(tname),'.', quote_ident(subp),
        ' does not exist')));
  END IF;

  RETURN eq(_subpartition_method(sname, tname, subp), smeth, description);
END //


/****************************************************************************/
-- Number of PARTITIONS and SUBPARTITIONS defined for a table
-- might be more suitable test if the partition names are subject to change 
-- NON NDB can have 8196

DROP FUNCTION IF EXISTS _partition_count  //
CREATE FUNCTION _partition_count(sname VARCHAR(64), tname VARCHAR(64))
RETURNS SMALLINT
DETERMINISTIC
BEGIN
  DECLARE ret SMALLINT;

  SELECT COUNT(*) INTO ret
  FROM `information_schema`.`partitions`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `partition_name` IS NOT NULL;

  RETURN COALESCE(ret, 0);
END //

DROP FUNCTION IF EXISTS partition_count_is//
CREATE FUNCTION partition_count_is(sname VARCHAR(64), tname VARCHAR(64), cnt SMALLINT, description TEXT)
RETURNS LONGTEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
      ' should have a Partition Count of ', qv(cnt));
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok( FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname),'.', quote_ident(tname),
        ' does not exist')));
  END IF;

  RETURN eq(_partition_count(sname, tname), cnt, description);
END //


/****************************************************************************/
-- Check that the proper partitions are defined

DROP FUNCTION IF EXISTS _missing_partitions //
CREATE FUNCTION _missing_partitions(sname VARCHAR(64), tname VARCHAR(64))
RETURNS TEXT
DETERMINISTIC
BEGIN
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(qi(`ident`)) INTO ret
  FROM
    (
      SELECT `ident`
      FROM `idents1`
      WHERE `ident` NOT IN
        (
          SELECT COALESCE(`subpartition_name` COLLATE utf8_general_ci, `partition_name` COLLATE utf8_general_ci)
          FROM `information_schema`.`partitions`
          WHERE `table_schema` = sname
          AND `table_name` = tname
        )
       GROUP BY 1
     ) msng;

  RETURN COALESCE(ret, '');
END //

DROP FUNCTION IF EXISTS _extra_partitions //
CREATE FUNCTION _extra_partitions(sname VARCHAR(64), tname VARCHAR(64))
RETURNS TEXT
DETERMINISTIC
BEGIN
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(qi(`ident`)) INTO ret
  FROM
    (
      SELECT COALESCE(`subpartition_name`,`partition_name`) AS `ident`
      FROM `information_schema`.`partitions`
      WHERE `table_schema` = sname
      AND `table_name` = tname
      AND COALESCE(`subpartition_name` COLLATE utf8_general_ci,`partition_name` COLLATE utf8_general_ci) NOT IN 
        (
          SELECT `ident`
          FROM `idents2`
        ) 
      GROUP BY 1  
    ) xtra;

  RETURN COALESCE(ret, '');
END //


DROP FUNCTION IF EXISTS partitions_are //
CREATE FUNCTION partitions_are(sname VARCHAR(64), tname VARCHAR(64), want TEXT, description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  DECLARE sep       CHAR(1) DEFAULT ',';
  DECLARE seplength INTEGER DEFAULT CHAR_LENGTH(sep);
  DECLARE missing   TEXT;
  DECLARE extras    TEXT;

  IF description = '' THEN 
     SET description = CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
      ' should have the correct partitions');
  END IF;

  IF NOT _has_table(sname,tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
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

  SET missing = _missing_partitions(sname,tname);
  SET extras  = _extra_partitions(sname,tname);

  RETURN _are('partitions', extras, missing, description);
END //


/*****************************************************************************/

-- Version 8.0.11 does not have generic partitioning, it is now
-- included in the individual engines
-- This test is therefore redundant since the test for INNODB
-- will satify the test

-- partitioning enabled
DROP FUNCTION IF EXISTS _has_partitioning //
CREATE FUNCTION _has_partitioning()
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE ret BOOLEAN;

  SELECT 1 INTO ret
  FROM `information_schema`.`plugins`
  WHERE `plugin_type`='STORAGE ENGINE'
  AND `plugin_name` = 'partition'
  AND `plugin_status` = 'active';

  RETURN COALESCE(ret, 0);
END //

-- enabled and active
DROP FUNCTION IF EXISTS has_partitioning //
CREATE FUNCTION has_partitioning(description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = 'Partitioning should be active';
  END IF;

  IF tap.mysql_version() >= 800011 THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag('Partitioning support is part of specific ENGINE post 8.0.11'));
  END IF;

RETURN ok(_has_partitioning(), description);
END //


DELIMITER ;
