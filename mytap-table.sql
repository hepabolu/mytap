DELIMITER //

/****************************************************************************/


-- _has_table( schema, table )
DROP FUNCTION IF EXISTS _has_table //
CREATE FUNCTION _has_table(dbname TEXT, tname TEXT)
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM `information_schema`.`tables`
     WHERE `table_name` = tname
       AND `table_schema` = dbname
       AND `table_type` = 'BASE TABLE';
    RETURN COALESCE(ret, 0);
END //


-- has_table( schema, table, description )
DROP FUNCTION IF EXISTS has_table //
CREATE FUNCTION has_table (dbname TEXT, tname TEXT, description TEXT)
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('Table ',
            quote_ident(dbname), '.', quote_ident(tname), ' should exist' );
    END IF;

    RETURN ok( _has_table( dbname, tname ), description );
END //


-- hasnt_table( schema, table, description )
DROP FUNCTION IF EXISTS hasnt_table //
CREATE FUNCTION hasnt_table (dbname TEXT, tname TEXT, description TEXT)
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = CONCAT('Table ',
            quote_ident(dbname), '.', quote_ident(tname), ' should not exist' );
    END IF;

    RETURN ok( NOT _has_table( dbname, tname ), description );
END //

/****************************************************************************/


-- _has_trigger( schema, table, trigger, description )
DROP FUNCTION IF EXISTS _has_trigger //
CREATE FUNCTION _has_trigger(dbname TEXT, tname TEXT, triggername TEXT)
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM information_schema.triggers
     WHERE event_object_table = tname
       AND trigger_schema = dbname
       AND trigger_name = triggername;
    RETURN COALESCE(ret, 0);
END //

-- has_trigger( schema, table, trigger, description )
DROP FUNCTION IF EXISTS has_trigger //

CREATE FUNCTION has_trigger( dbname TEXT, tname TEXT, triggername TEXT, description TEXT )
RETURNS text CHARSET utf8
BEGIN

    IF description = '' THEN
        SET description = CONCAT('Trigger ', quote_ident(dbname), '.',
            quote_ident(tname), '.', quote_ident(triggername), ' should exist' );
    END IF;

    IF NOT _has_table( dbname, tname ) THEN
        RETURN CONCAT(ok( FALSE, description), '\n', 
        diag(CONCAT('   Table ', quote_ident(dbname), '.', quote_ident(tname), ' does not exist')));
    END IF;

    RETURN ok( _has_trigger( dbname, tname, triggername ), description );
END //

-- hasnt_trigger( schema, table, trigger, description )
DROP FUNCTION IF EXISTS hasnt_trigger //

CREATE FUNCTION hasnt_trigger( dbname TEXT, tname TEXT, triggername TEXT, description TEXT )
RETURNS text CHARSET utf8
BEGIN
    IF description = '' THEN
        SET description = CONCAT('Trigger ', quote_ident(dbname), '.',
            quote_ident(tname), '.', quote_ident(triggername), ' should not exist' );
    END IF;

    IF NOT _has_table( dbname, tname ) THEN
        RETURN CONCAT(ok( FALSE, description), '\n', 
        diag(CONCAT('   Table ', quote_ident(dbname), '.', quote_ident(tname), ' does not exist')));
    END IF;

    RETURN ok(NOT _has_trigger( dbname, tname, triggername ), description );
END //



/**************************************************************************/

-- Loose check on the existence of a named constraint on the table

-- _has_constraint( schema, table, constraint type)
DROP FUNCTION IF EXISTS _has_constraint //
CREATE FUNCTION _has_constraint(dbname TEXT, tname TEXT, ctype TEXT)
RETURNS BOOLEAN
BEGIN
  DECLARE ret BOOLEAN;
  
  SELECT 1 INTO ret
  FROM `information_schema`.`table_constraints`
  WHERE `table_schema` = dbname
  AND `table_name` = tname
  AND `constraint_type` = ctype
  LIMIT 1;
  
  RETURN COALESCE(ret, 0);
END //


-- PRIMARY KEY exists
DROP FUNCTION IF EXISTS has_pk //
CREATE FUNCTION has_pk(sname VARCHAR(64), tname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('A Primary Key should be defined for Table ', 
			quote_ident(sname), '.', quote_ident(tname));
  END IF;

  IF NOT _has_table( sname, tname ) THEN
    RETURN CONCAT(ok( FALSE, description), '\n', 
      diag(CONCAT('   Table ', quote_ident(sname), '.', quote_ident(tname), ' does not exist')));
  END IF;

  RETURN ok(_has_constraint(sname, tname, 'PRIMARY KEY'), description);
END //


DROP FUNCTION IF EXISTS hasnt_pk //
CREATE FUNCTION hasnt_pk(sname VARCHAR(64), tname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('A Primary Key shouldn\'t be defined for Table ', 
			quote_ident(sname), '.', quote_ident(tname));
  END IF;

  IF NOT _has_table( sname, tname ) THEN
    RETURN CONCAT(ok( FALSE, description), '\n', 
			diag(CONCAT('   Table ', quote_ident(sname), '.', quote_ident(tname), ' does not exist')));
  END IF;

  RETURN ok(NOT _has_constraint(sname, tname, 'PRIMARY KEY'), description);
END //

-- Loose check on the existence of an FK on the table
DROP FUNCTION IF EXISTS has_fk //
CREATE FUNCTION has_fk(sname VARCHAR(64), tname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('A Foreign Key should be defined for Table ', 
			quote_ident(sname), '.', quote_ident(tname));
  END IF;

  IF NOT _has_table( sname, tname ) THEN
    RETURN CONCAT(ok( FALSE, description), '\n', 
			diag(CONCAT('   Table ', quote_ident(sname), '.', quote_ident(tname), ' does not exist')));
  END IF;

  RETURN ok(_has_constraint(sname, tname, 'FOREIGN KEY'), description);
END //

DROP FUNCTION IF EXISTS hasnt_fk //
CREATE FUNCTION hasnt_fk( sname VARCHAR(64), tname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Foreign Key should NOT be defined for Table ', 
			quote_ident(sname), '.', quote_ident(tname));
  END IF;

  IF NOT _has_table( dbname, tname ) THEN
    RETURN CONCAT(ok( FALSE, description), '\n', 
			diag(CONCAT('   Table ', quote_ident(sname), '.', quote_ident(tname), ' does not exist')));
  END IF;

  RETURN ok(NOT _has_constraint(sname, tname, 'FOREIGN KEY'), description);
END //


/**************************************************************************/

-- TABLE STORAGE ENGINE DEFINITIONS

DROP FUNCTION IF EXISTS _table_engine//
CREATE FUNCTION _table_engine(sname VARCHAR(64), tname VARCHAR(64))
RETURNS VARCHAR(32)
BEGIN
  DECLARE ret VARCHAR(32);
  
  SELECT `engine` INTO ret
  FROM `information_schema`.`tables`
  WHERE `table_schema` = sname
  AND `table_name` = tname;
  
  RETURN COALESCE(ret, NULL);
END //


-- table_engine_is( schema, table, engine, description )
DROP FUNCTION IF EXISTS table_engine_is //
CREATE FUNCTION table_engine_is( sname VARCHAR(64), tname VARCHAR(64), ename VARCHAR(32), description TEXT )
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = concat('Table ', quote_ident(sname), '.',
      quote_ident(tname), ' should use Storage Engine ',  quote_ident(ename));
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n', 
      diag(CONCAT('    Table ', quote_ident(sname), '.', quote_ident(tname), ' does not exist')));
  END IF;

  IF NOT _has_engine( ename ) THEN
    RETURN CONCAT(ok(FALSE, description), '\n', 
      diag(CONCAT('    Storare Engine ', quote_ident(ename), ' is not available')));
  END IF;

  RETURN eq(_table_engine(sname, tname), ename , description);
END //


/**************************************************************************/

-- TABLE COLLATION DEFINITION

-- _table_collation( schema, table )
DROP FUNCTION IF EXISTS _table_collation //
CREATE FUNCTION _table_collation(sname VARCHAR(64), tname VARCHAR(64))
RETURNS VARCHAR(32)
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
BEGIN
  IF description = '' THEN
    SET description = concat('Table ', quote_ident(sname), '.',
      quote_ident(tname), ' should use Collation ',  quote_ident(cname));
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok( FALSE, description), '\n', 
      diag( CONCAT('    Table ', quote_ident(sname), '.', 
				quote_ident(tname), ' does not exist' )));
  END IF;

  IF NOT _has_collation(cname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n', 
      diag (CONCAT('    Collation ', quote_ident(cname), ' is not available' )));
  END IF;

  RETURN eq(_table_collation(sname, tname), cname, description);
END //


/**************************************************************************/

-- TABLE CHARACTER SET DEFINITION
-- This info is available in show create table though it is not stored directly
-- and can be derived from the prefix of the table collation. 

-- _table_character_set( schema, table, collation )
DROP FUNCTION IF EXISTS _table_character_set //
CREATE FUNCTION _table_character_set(sname VARCHAR(64), tname VARCHAR(64))
RETURNS VARCHAR(32)
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


-- table_character_set_is( schema, table, character_set, description )
DROP FUNCTION IF EXISTS table_character_set_is //
CREATE FUNCTION table_character_set_is(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(32), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Table ', quote_ident(sname), '.',
      quote_ident(tname), ' should have Character Set ',  quote_ident(cname));
  END IF;

  IF NOT _has_table(sname, tname) THEN
    RETURN CONCAT(ok( FALSE, description), '\n', 
      diag(CONCAT('    Table ', quote_ident(sname), '.', quote_ident(tname), ' does not exist')));
  END IF;

  IF NOT _has_charset( cname ) THEN
    RETURN CONCAT(ok(FALSE, description), '\n', 
	    diag(CONCAT('    Character Set ', quote_ident(cname), ' is not available')));
  END IF;

  RETURN eq(_table_character_set( sname, tname), cname, description);
END //


/*******************************************************************/
-- Check that the proper tables are defined

DROP FUNCTION IF EXISTS _missing_tables //
CREATE FUNCTION _missing_tables(sname VARCHAR(64)) 
RETURNS TEXT
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
CREATE FUNCTION tables_are( sname VARCHAR(64), want TEXT, description TEXT) 
RETURNS TEXT
BEGIN
	DECLARE sep       CHAR(1) DEFAULT ','; 
  DECLARE seplength INTEGER DEFAULT CHAR_LENGTH(sep);
  DECLARE missing   TEXT; 
  DECLARE extras    TEXT;

  IF description = '' THEN 
		SET description = 'The correct tables should be defined';
	END IF;

  IF NOT _has_schema(sname) THEN
		RETURN CONCAT( ok( FALSE, description), '\n', 
      diag( CONCAT('    Schema ', quote_ident(sname), ' does not exist' )));
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

  SET missing = _missing_tables(sname);
  SET extras  = _extra_tables(sname);
        
  RETURN _are('tables', extras, missing, description);
END //


DELIMITER ;
