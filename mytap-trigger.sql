-- TRIGGERS
-- ========

-- Table level checks

USE tap;

DELIMITER //

/************************************************************************************/
-- _has_trigger( schema, table, trigger, description )
DROP FUNCTION IF EXISTS _has_trigger //
CREATE FUNCTION _has_trigger(sname VARCHAR(64), tname VARCHAR(64), trgr VARCHAR(64))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE ret BOOLEAN;

  SELECT 1 INTO ret
  FROM `information_schema`.`triggers`
  WHERE `trigger_schema` = sname
  AND `event_object_table` = tname
  AND `trigger_name` = trgr;

  RETURN COALESCE(ret, 0);
END //

-- has_trigger( schema, table, trigger, description)
DROP FUNCTION IF EXISTS has_trigger //
CREATE FUNCTION has_trigger(sname VARCHAR(64), tname VARCHAR(64), trgr VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Trigger ', quote_ident(tname), '.', quote_ident(trgr),
      ' should exist');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
  END IF;

    RETURN ok(_has_trigger(sname, tname, trgr), description);
END //


-- hasnt_trigger( schema, table, trigger, description)
DROP FUNCTION IF EXISTS hasnt_trigger //
CREATE FUNCTION hasnt_trigger(sname VARCHAR(64), tname VARCHAR(64), trgr VARCHAR(64), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Trigger ', quote_ident(tname), '.', quote_ident(trgr),
      ' should not exist');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
    END IF;

    RETURN ok(NOT _has_trigger(sname, tname, trgr), description);
END //


/****************************************************************************/
-- EVENT MANIPULATION
-- { INSERT | UPDATE | DELETE }

DROP FUNCTION IF EXISTS _trigger_event  //
CREATE FUNCTION _trigger_event(sname VARCHAR(64), tname VARCHAR(64), trgr VARCHAR(64))
RETURNS VARCHAR(6)
DETERMINISTIC
BEGIN
  DECLARE ret VARCHAR(6);

  SELECT `event_manipulation` INTO ret
  FROM `information_schema`.`triggers`
  WHERE `event_object_schema` = sname
  AND `event_object_table` = tname
  AND `trigger_name` = trgr;

  RETURN COALESCE(ret, NULL);
END //

DROP FUNCTION IF EXISTS trigger_event_is//
CREATE FUNCTION trigger_event_is(sname VARCHAR(64), tname VARCHAR(64), trgr VARCHAR(64), evnt VARCHAR(6), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = concat('Trigger ', quote_ident(tname), '.', quote_ident(trgr),
      ' Event should occur for ', qv(UPPER(evnt)));
  END IF;

  IF NOT _has_trigger(sname, tname, trgr) THEN
    RETURN CONCAT(ok( FALSE, description), '\n',
      diag(CONCAT('Trigger ', quote_ident(tname),'.', quote_ident(trgr),
        ' does not exist')));
  END IF;

  RETURN eq(_trigger_event(sname, tname, trgr), evnt, description);
END //


/****************************************************************************/
-- ACTION_TIMING
-- { BEFORE | AFTER }

DROP FUNCTION IF EXISTS _trigger_timing  //
CREATE FUNCTION _trigger_timing(sname VARCHAR(64), tname VARCHAR(64), trgr VARCHAR(64))
RETURNS VARCHAR(6)
DETERMINISTIC
BEGIN
  DECLARE ret VARCHAR(6);

  SELECT `action_timing` INTO ret
  FROM `information_schema`.`triggers`
  WHERE `event_object_schema` = sname
  AND `event_object_table` = tname
  AND `trigger_name` = trgr;

  RETURN COALESCE(ret, NULL);
END //

DROP FUNCTION IF EXISTS trigger_timing_is//
CREATE FUNCTION trigger_timing_is(sname VARCHAR(64), tname VARCHAR(64), trgr VARCHAR(64), timing VARCHAR(6), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Trigger ', quote_ident(tname), '.', quote_ident(trgr),
      ' should have Timing ', qv(UPPER(timing)));
  END IF;

  IF NOT _has_trigger(sname, tname, trgr) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Trigger ', quote_ident(tname),'.', quote_ident(trgr),
        ' does not exist')));
  END IF;

  RETURN eq(_trigger_timing(sname, tname, trgr), timing, description);
END //


/****************************************************************************/
-- ACTION_ORDER
-- Number

DROP FUNCTION IF EXISTS _trigger_order  //
CREATE FUNCTION _trigger_order(sname VARCHAR(64), tname VARCHAR(64), trgr VARCHAR(64))
RETURNS BIGINT
DETERMINISTIC
BEGIN
  DECLARE ret BIGINT;

  SELECT `action_order` INTO ret
  FROM `information_schema`.`triggers`
  WHERE `event_object_schema` = sname
  AND `event_object_table` = tname
  AND `trigger_name` = trgr;

  RETURN COALESCE(ret, NULL);
END //



-- Support for multiple triggers for the same event and action time was introduced in MySQL 5.7.2
-- Supported in the information_schema prior to that release so does not require splitting
-- to a separte version file but will always return 1 prior to version 5.7.2

DROP FUNCTION IF EXISTS trigger_order_is//
CREATE FUNCTION trigger_order_is(sname VARCHAR(64), tname VARCHAR(64), trgr VARCHAR(64), seq BIGINT, description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Trigger ', quote_ident(tname), '.', quote_ident(trgr),
      ' should have Action Order ', qv(seq));
  END IF;

  IF NOT _has_trigger(sname, tname, trgr) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Trigger ', quote_ident(tname),'.', quote_ident(trgr),
        ' does not exist')));
  END IF;

  RETURN eq(_trigger_order(sname, tname, trgr), seq, description);
END //


/****************************************************************************/
-- ACTION STATEMENT
-- What the trigger does. This might be difficult to test if the statement
-- list is long. 

DROP FUNCTION IF EXISTS _trigger_is //
CREATE FUNCTION _trigger_is(sname VARCHAR(64), tname VARCHAR(64), trgr VARCHAR(64))
RETURNS LONGTEXT
DETERMINISTIC
BEGIN
  DECLARE ret LONGTEXT;

  SELECT `action_statement` INTO ret
  FROM `information_schema`.`triggers`
  WHERE `event_object_schema` = sname
  AND `event_object_table` = tname
  AND `trigger_name` = trgr;

  RETURN COALESCE(ret, NULL);
END //

DROP FUNCTION IF EXISTS trigger_is//
CREATE FUNCTION trigger_is(sname VARCHAR(64), tname VARCHAR(64), trgr VARCHAR(64), act_state LONGTEXT, description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Trigger ', quote_ident(tname), '.', quote_ident(trgr), 
      ' should have the correct action');
  END IF;

  IF NOT _has_trigger(sname, tname, trgr) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('Trigger ', quote_ident(tname),'.', quote_ident(trgr),
        ' does not exist')));
  END IF;

  RETURN eq(_trigger_is(sname, tname, trgr), act_state, description);
END //


/****************************************************************************/

-- Check that the proper triggers are defined

DROP FUNCTION IF EXISTS _missing_triggers //
CREATE FUNCTION _missing_triggers(sname VARCHAR(64), tname VARCHAR(64))
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
          SELECT `trigger_name`
          FROM `information_schema`.`triggers`
          WHERE `trigger_schema` = sname
          AND `event_object_table` = tname
        )
     ) msng;

  RETURN COALESCE(ret, '');
END //

DROP FUNCTION IF EXISTS _extra_triggers //
CREATE FUNCTION _extra_triggers(sname VARCHAR(64), tname VARCHAR(64))
RETURNS TEXT
DETERMINISTIC
BEGIN
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(qi(`ident`)) INTO ret
  FROM 
    (
      SELECT `trigger_name` AS `ident` 
      FROM `information_schema`.`triggers`
      WHERE `trigger_schema` = sname
      AND `event_object_table` = tname
      AND `trigger_name` NOT IN 
        (
          SELECT `ident`
          FROM `idents2`
        )
    ) xtra;

  RETURN COALESCE(ret, '');
END //


DROP FUNCTION IF EXISTS triggers_are //
CREATE FUNCTION triggers_are(sname VARCHAR(64), tname VARCHAR(64), want TEXT, description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  DECLARE sep       CHAR(1) DEFAULT ',';
  DECLARE seplength INTEGER DEFAULT CHAR_LENGTH(sep);
  DECLARE missing   TEXT;
  DECLARE extras    TEXT;

  IF description = '' THEN 
     SET description = CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
      ' should have the correct Triggers');
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

  SET missing = _missing_triggers(sname,tname);
  SET extras  = _extra_triggers(sname,tname);

  RETURN _are('triggers', extras, missing, description);
END //


DELIMITER ;
