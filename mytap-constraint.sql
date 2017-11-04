-- CONSTRAINTS
-- ===========
-- PRIMARY KEY, FOREIGN KEY and UNIQUE constraints

-- Simple check on existence of named constraint without being concerned for its
-- composition
DELIMITER //

DROP FUNCTION IF EXISTS _has_constraint //
CREATE FUNCTION _has_constraint(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64))
RETURNS BOOLEAN
BEGIN
  DECLARE ret BOOLEAN;

  SELECT COUNT(*) INTO ret
  FROM `information_schema`.`table_constraints`
  WHERE `constraint_schema` = sname
  AND `table_name` = tname
  AND `constraint_name` = cname;

  RETURN IF(ret > 0 , 1, 0);
END //

-- check for the existence of named constraint
DROP FUNCTION IF EXISTS has_constraint //
CREATE FUNCTION has_constraint(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Constraint ', quote_ident(tname), '.', quote_ident(cname),
      ' should exist');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag( CONCAT('    Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
  END IF;

  RETURN ok(_has_constraint(sname, tname, cname), description);
END //

-- test for when constraint has been removed
DROP FUNCTION IF EXISTS hasnt_constraint //
CREATE FUNCTION hasnt_constraint(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Constraint ', quote_ident(tname),'.',quote_ident(cname),
      ' should not exist');
  END IF;

  IF NOT _has_table( sname, tname ) THEN
    RETURN CONCAT( ok( FALSE, description), '\n',
      diag( CONCAT('    Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
  END IF;

  RETURN ok(NOT _has_constraint(sname, tname, cname), description);
END //

/********************************************************************************/

-- PRIMARY KEY exists
DROP FUNCTION IF EXISTS has_pk //
CREATE FUNCTION has_pk(sname VARCHAR(64), tname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
      ' should have a Primary Key');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('   Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
  END IF;

  RETURN ok(_has_constraint(sname, tname, 'PRIMARY KEY'), description);
END //


DROP FUNCTION IF EXISTS hasnt_pk //
CREATE FUNCTION hasnt_pk(sname VARCHAR(64), tname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
      ' should not have a Primary Key');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('   Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
  END IF;

  RETURN ok(NOT _has_constraint(sname, tname, 'PRIMARY KEY'), description);
END //

-- Loose check on the existence of an FK on the table
DROP FUNCTION IF EXISTS has_fk //
CREATE FUNCTION has_fk(sname VARCHAR(64), tname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
      ' should have a Foreign Key');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('   Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
  END IF;

  RETURN ok(_has_constraint(sname, tname, 'FOREIGN KEY'), description);
END //

DROP FUNCTION IF EXISTS hasnt_fk //
CREATE FUNCTION hasnt_fk(sname VARCHAR(64), tname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
      ' should not have a Foreign Key');
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n', 
      diag(CONCAT('   Table ', quote_ident(sname), '.', quote_ident(tname),
        ' does not exist')));
  END IF;

  RETURN ok(NOT _has_constraint(sname, tname, 'FOREIGN KEY'), description);
END //


/***************************************************************************/
-- Constraint Type
-- FK, PK or UNIQUE 

DROP FUNCTION IF EXISTS _constraint_type //
CREATE FUNCTION _constraint_type(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64))
RETURNS VARCHAR(64)
BEGIN
  DECLARE ret VARCHAR(64);

  SELECT `constraint_type` INTO ret
  FROM `information_schema`.`table_constraints`
  WHERE `constraint_schema` = sname
  AND `table_name` = tname
  AND `constraint_name` = cname;

  RETURN ret;
END //

DROP FUNCTION IF EXISTS constraint_type_is //
CREATE FUNCTION constraint_type_is(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), ctype VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Constraint ', quote_ident(tname), '.', quote_ident(cname),
      ' should have Constraint Type ' , qv(ctype));
  END IF;
    
  IF NOT _has_constraint(sname, tname, cname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag( CONCAT('    Constraint ', quote_ident(tname), '.', quote_ident(cname),
        ' does not exist')));
  END IF;

  RETURN eq(_constraint_type(sname, tname, cname), ctype, description);
END //

/***************************************************************************/

-- FK Properties
-- on delete, on update. on match is ALWAYS None 

DROP FUNCTION IF EXISTS _fk_on_delete //
CREATE FUNCTION _fk_on_delete(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64))
RETURNS VARCHAR(64)
BEGIN
  DECLARE ret VARCHAR(64);

  SELECT `delete_rule` INTO ret
  FROM `information_schema`.`referential_constraints`
  WHERE `constraint_schema` = sname
  AND `table_name` = tname
  AND `constraint_name` = cname;

  RETURN ret;
END //

-- check for rule ON DELETE
DROP FUNCTION IF EXISTS fk_on_delete //
CREATE FUNCTION fk_on_delete(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), rule VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Constraint ', quote_ident(tname), '.', quote_ident(cname),
      ' should have rule ON DELETE ', qv(rule));
  END IF;

  IF NOT _has_constraint(sname, tname, cname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag( CONCAT('    Constraint ', quote_ident(tname), '.', quote_ident(cname),
        ' does not exist')));
  END IF;

  RETURN eq(_fk_on_delete(sname, tname, cname), rule, description);
END //

DROP FUNCTION IF EXISTS _fk_on_update //
CREATE FUNCTION _fk_on_update(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64))
RETURNS VARCHAR(64)
BEGIN
  DECLARE ret VARCHAR(64);

  SELECT `update_rule` INTO ret
  FROM `information_schema`.`referential_constraints`
  WHERE `constraint_schema` = sname
  AND `table_name` = tname
  AND `constraint_name` = cname;

  RETURN ret;
END //

-- check for rule ON UPDATE
DROP FUNCTION IF EXISTS fk_on_update //
CREATE FUNCTION fk_on_update(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), rule VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Constraint ', quote_ident(tname), '.', quote_ident(cname),
      ' should have rule ON UPDATE ' , qv(rule));
  END IF;

  IF NOT _has_constraint(sname, tname, cname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag( CONCAT('    Constraint ', quote_ident(tname), '.', quote_ident(cname),
        ' does not exist')));
  END IF;

  RETURN eq(_fk_on_update(sname, tname, cname), rule, description);
END //

/***************************************************************************/

DROP FUNCTION IF EXISTS _fk_ok //
CREATE FUNCTION _fk_ok(csch VARCHAR(64), ctab VARCHAR(64), ccol TEXT,
                       usch VARCHAR(64), utab VARCHAR(64), ucol TEXT)
RETURNS BOOLEAN
BEGIN
  DECLARE ret BOOLEAN;

  SELECT COUNT(*) INTO ret
  FROM 
    (
      SELECT kc.`constraint_schema` AS `csch`,
             kc.`table_name` AS `ctab`, 
             GROUP_CONCAT(kc.`column_name` ORDER BY kc.`ordinal_position`) AS `ccol`,
             kc.`referenced_table_schema` AS `usch`,
             kc.`referenced_table_name` AS `utab`,
             GROUP_CONCAT(kc.`referenced_column_name` ORDER BY `position_in_unique_constraint`) AS `ucol`
      FROM `information_schema`.`key_column_usage` kc 
      WHERE kc.`constraint_schema` = @csch AND kc.`referenced_table_schema` = @usch
      AND kc.`table_name` = @ctab AND kc.`referenced_table_name` = @utab
      GROUP BY `csch`,`ctab`,`usch`,`utab`
      HAVING GROUP_CONCAT(kc.`column_name` ORDER BY kc.`ordinal_position`) =
             GROUP_CONCAT(kc.`referenced_column_name` ORDER BY `position_in_unique_constraint`)
    ) fkey;

  RETURN COALESCE(ret,0);
END //

-- check that a foreign key points to the correct table and indexed columns key
-- cname and uname will likly be single columns but they may not be, the index
-- references will therefore have to be resolved before they can be compared
DROP FUNCTION IF EXISTS fk_ok //
CREATE FUNCTION fk_ok(csch VARCHAR(64), ctab VARCHAR(64), ccol TEXT, 
                      usch VARCHAR(64), utab VARCHAR(64), ucol TEXT, description TEXT) 
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Constraint Foreign Key ', quote_ident(ctab), '(', quote_ident(ccol),
      ') should reference ' , quote_ident(utab), '(', quote_ident(ucol), ')');
  END IF;

  IF NOT _has_table(csch, ctab) THEN
    RETURN CONCAT(ok(FALSE, description), '\n', 
      diag( CONCAT('    Table ', quote_ident(tname), '.', quote_ident(cname),
        ' does not exist')));
  END IF;

  IF NOT _has_table(usch, utab) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag( CONCAT('    Table ', quote_ident(tname), '.', quote_ident(cname),
        ' does not exist')));
  END IF;

  RETURN ok(_fk_ok(csch, ctab, ccol, usch, utab, ucol), description);
END //

/*******************************************************************/
-- Check that the proper constraints are defined

DROP FUNCTION IF EXISTS _missing_constraints //
CREATE FUNCTION _missing_constraints(sname VARCHAR(64), tname VARCHAR(64)) 
RETURNS TEXT
BEGIN 
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(quote_ident(`ident`)) INTO ret
  FROM
    (
      SELECT `ident`
      FROM `idents1`
      WHERE `ident` NOT IN
        (
          SELECT `constraint_name`
          FROM `information_schema`.`table_constraints`
          WHERE `table_schema` = sname
          AND `table_name` = tname
        )
    ) msng;

  RETURN COALESCE(ret, '');
END //

DROP FUNCTION IF EXISTS _extra_constraints //
CREATE FUNCTION _extra_constraints(sname VARCHAR(64), tname VARCHAR(64)) 
RETURNS TEXT
BEGIN
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(quote_ident(`ident`)) into ret FROM
    (
      SELECT DISTINCT `constraint_name` AS `ident`
      FROM `information_schema`.`table_constraints`
      WHERE `table_schema` = sname
      AND `table_name` = tname
      AND `constraint_name` NOT IN 
        (
          SELECT `ident`
          FROM `idents2`
        )
    ) xtra;

  RETURN COALESCE(ret, '');
END //


DROP FUNCTION IF EXISTS constraints_are //
CREATE FUNCTION constraints_are(sname VARCHAR(64), tname VARCHAR(64),  want TEXT, description TEXT)
RETURNS TEXT
BEGIN
  DECLARE sep       CHAR(1) DEFAULT ',';
  DECLARE seplength INTEGER DEFAULT CHAR_LENGTH(sep);

  IF description = '' THEN
    SET description = CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname),
      ' should have the correct Constraints');
  END IF;

  IF NOT _has_table( sname, tname ) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag( CONCAT('    Table ', quote_ident(sname), '.', quote_ident(tname),
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

  SET @missing = _missing_constraints(sname, tname);
  SET @extras  = _extra_constraints(sname, tname);
        
  RETURN _are('constraints', @extras, @missing, description);
END //


DELIMITER ;