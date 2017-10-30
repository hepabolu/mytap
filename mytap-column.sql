DELIMITER //

/****************************************************************************/

-- internal function to check

DROP FUNCTION IF EXISTS _has_column  //
CREATE FUNCTION _has_column( dbname TEXT, tname TEXT, cname TEXT)
RETURNS BOOLEAN
BEGIN
	DECLARE b_result boolean;

        SELECT true into b_result
          FROM information_schema.columns as db
         WHERE db.table_schema = dbname
           AND db.table_name = tname
           AND db.column_name = cname;

    RETURN coalesce(b_result, false);
END //


-- has_column( schema, table, column, description )
DROP FUNCTION IF EXISTS has_column //
CREATE FUNCTION has_column( dbname TEXT, tname TEXT, cname TEXT, description TEXT)
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should exist' );
    END IF;

    RETURN ok( _has_column( dbname, tname, cname ), description );
END //


-- hasnt_column( schema, table, column, description )
DROP FUNCTION IF EXISTS hasnt_column //
CREATE FUNCTION hasnt_column ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should not exist' );
    END IF;

    RETURN ok( NOT _has_column( dbname, tname, cname ), description );
END //


/****************************************************************************/

-- NULLABLE
-- _col_nullable(schema, table, column)
DROP FUNCTION IF EXISTS _col_nullable //
CREATE FUNCTION _col_nullable(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64))
RETURNS VARCHAR(3)
BEGIN
    DECLARE ret VARCHAR(3);

    SELECT `is_nullable` INTO ret
    FROM `information_schema`.`columns`
    WHERE `table_schema` = sname
    AND `table_name` = tname
    AND `column_name` = cname;

    RETURN ret;
END //


-- col_is_null( schema, table, column )
DROP FUNCTION IF EXISTS col_is_null //
CREATE FUNCTION col_is_null(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), description TEXT )
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = concat('Column ',
      quote_ident(tname), '.', quote_ident(cname), ' should allow NULL');
  END IF;

  IF NOT _has_column(sname, tname, cname) THEN
    RETURN CONCAT(ok(FALSE,description), '\n',
      diag (CONCAT('    Column ', quote_ident(sname), '.', quote_ident(tname), '.', 
        quote_ident(cname), ' does not exist')));
  END IF;

  RETURN eq(_col_nullable(sname, tname, cname),'YES', description);
END //


-- col_not_null( schema, table, column, description )
DROP FUNCTION IF EXISTS col_not_null //
CREATE FUNCTION col_not_null(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = concat('Column ',
      quote_ident(tname), '.', quote_ident(cname), ' should be NOT NULL');
  END IF;

  IF NOT _has_column(sname, tname, cname) THEN
    RETURN CONCAT(ok(FALSE,description), '\n',
      diag (CONCAT('    Column ', quote_ident(sname), '.', quote_ident(tname), '.', 
        quote_ident(cname), ' does not exist')));
  END IF;

  RETURN eq(_col_nullable(sname, tname, cname),'NO', description);
END //


/****************************************************************************/

-- _col_has_primary_key ( schema, table, column )

DROP FUNCTION IF EXISTS _col_has_primary_key //
CREATE FUNCTION _col_has_primary_key ( dbname TEXT, tname TEXT, cname TEXT )
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;

    SELECT true into ret
      FROM information_schema.columns as db
     WHERE db.table_schema = dbname
       AND db.table_name = tname
       AND db.column_name = cname
       AND db.column_key = 'PRI';
    RETURN coalesce(ret, false);
END //

-- col_has_primary_key ( schema, table, column )
DROP FUNCTION IF EXISTS col_has_primary_key //
CREATE FUNCTION col_has_primary_key ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should have PRIMARY key' );
    END IF;

    RETURN ok( _col_has_primary_key(dbname, tname, cname), description );
END //

-- col_hasnt_primary_key( schema, table, column )
DROP FUNCTION IF EXISTS col_hasnt_primary_key //
CREATE FUNCTION col_hasnt_primary_key ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should not have PRIMARY key' );
    END IF;

    RETURN ok( NOT _col_has_primary_key(dbname, tname, cname), description );
END //

/****************************************************************************/

-- _col_has_index_key (schema, table, column )

DROP FUNCTION IF EXISTS _col_has_index_key //
CREATE FUNCTION _col_has_index_key ( dbname TEXT, tname TEXT, cname TEXT )
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;

    SELECT true into ret
      FROM information_schema.statistics as db
     WHERE db.table_schema = dbname
       AND db.table_name = tname
       AND db.column_name = cname
       AND db.index_name <> 'PRIMARY'
       limit 1;
    RETURN coalesce(ret, false);
END //

-- col_has_index_key ( schema, table, column )
DROP FUNCTION IF EXISTS col_has_index_key //
CREATE FUNCTION col_has_index_key ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should have INDEX key' );
    END IF;

    RETURN ok( _col_has_index_key(dbname, tname, cname), description );
END //

-- col_hasnt_index_key( schema, table, column )
DROP FUNCTION IF EXISTS col_hasnt_index_key //
CREATE FUNCTION col_hasnt_index_key ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should not have INDEX key' );
    END IF;

    RETURN ok( NOT _col_has_index_key(dbname, tname, cname), description );
END //


/****************************************************************************/
-- _col_has_named_index (schema, table, column )

DROP FUNCTION IF EXISTS _col_has_named_index //
CREATE FUNCTION _col_has_named_index ( dbname TEXT, tname TEXT, cname TEXT, kname TEXT )
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;

    SELECT true into ret
      FROM information_schema.statistics as db
     WHERE db.table_schema = dbname
       AND db.table_name = tname
       AND db.column_name = cname
       AND db.index_name = kname;
    RETURN coalesce(ret, false);
END //

-- col_has_named_index ( schema, table, column, keyname )
DROP FUNCTION IF EXISTS col_has_named_index //
CREATE FUNCTION col_has_named_index ( dbname TEXT, tname TEXT, cname TEXT, kname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    SET kname := coalesce(kname, cname); -- use the column name as index name if nothing is given
    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should have INDEX key ', quote_ident(kname) );
    END IF;

    RETURN ok( _col_has_named_index(dbname, tname, cname, kname), description );
END //

-- col_hasnt_named_index( schema, table, column, keyname )
DROP FUNCTION IF EXISTS col_hasnt_named_index //
CREATE FUNCTION col_hasnt_named_index ( dbname TEXT, tname TEXT, cname TEXT, kname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    SET kname := coalesce(kname, cname); -- use the column name as index name if nothing is given
    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should not have INDEX key ', kname );
    END IF;

    RETURN ok( NOT _col_has_named_index(dbname, tname, cname, kname), description );
END //


/****************************************************************************/
-- _col_has_pos_in_named_index (schema, table, column, position )

DROP FUNCTION IF EXISTS _col_has_pos_in_named_index //
CREATE FUNCTION _col_has_pos_in_named_index ( dbname TEXT, tname TEXT, cname TEXT, kname TEXT, position INT )
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;

    SELECT true into ret
      FROM information_schema.statistics as db
     WHERE db.table_schema = dbname
       AND db.table_name = tname
       AND db.column_name = cname
       AND db.index_name = kname
       AND db.seq_in_index = position;
    RETURN coalesce(ret, false);
END //


-- col_has_pos_in_named_index ( schema, table, column, keyname, position )
DROP FUNCTION IF EXISTS col_has_pos_in_named_index //
CREATE FUNCTION col_has_pos_in_named_index ( dbname TEXT, tname TEXT, cname TEXT, kname TEXT, position INT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    SET kname := coalesce(kname, cname); -- use the column name as index name if nothing is given

    IF NOT _col_has_named_index( dbname, tname, cname, kname ) THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should have INDEX key ', quote_ident(kname) );
        RETURN fail(concat('Error ', diag(description)));
    END IF;

    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should have position ', position, ' in INDEX ', quote_ident(kname) );
    END IF;

    RETURN ok( _col_has_pos_in_named_index(dbname, tname, cname, kname, position), description );
END //


-- col_hasnt_pos_in_named_index( schema, table, column, keyname, position )
DROP FUNCTION IF EXISTS col_hasnt_pos_in_named_index //
CREATE FUNCTION col_hasnt_pos_in_named_index ( dbname TEXT, tname TEXT, cname TEXT, kname TEXT, position INT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    SET kname := coalesce(kname, cname); -- use the column name as index name if nothing is given
    IF NOT _col_has_named_index( dbname, tname, cname, kname ) THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should have INDEX key ', quote_ident(kname) );
          RETURN fail(concat('Error ', diag(description)));
    END IF;
    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should not have position ', position, ' in INDEX ', quote_ident(kname) );
    END IF;

    RETURN ok( NOT _col_has_pos_in_named_index(dbname, tname, cname, kname, position), description );
END //

/****************************************************************************/

-- _col_has_type (schema, table, column, type )

DROP FUNCTION IF EXISTS _col_has_type //
CREATE FUNCTION _col_has_type ( dbname TEXT, tname TEXT, cname TEXT, ctype TEXT )
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;

    SELECT true into ret
      FROM information_schema.columns as db
     WHERE db.table_schema = dbname
       AND db.table_name = tname
       AND db.column_name = cname
       AND db.data_type = ctype;
    RETURN coalesce(ret, false);
END //


DROP FUNCTION IF EXISTS col_has_type //
CREATE FUNCTION col_has_type( dbname TEXT, tname TEXT, cname TEXT, ctype TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat( 'Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should have data type ', quote_ident(ctype) );
    END IF;

    RETURN ok( _col_has_type( dbname, tname, cname, ctype ), description );
END //


/*************************************************************************************/

DROP FUNCTION IF EXISTS _col_type //
CREATE FUNCTION _col_type(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64))
RETURNS LONGTEXT
BEGIN
  DECLARE ret LONGTEXT;

  SELECT `column_type` INTO ret
  FROM `information_schema`.`columns`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `column_name` = cname;
   
  RETURN COALESCE(ret, NULL);
END //

-- col_has_type is not available in pgTAP. The convention would have 
-- col_type_is which would output expected and actual for failed tests
DROP FUNCTION IF EXISTS col_type_is //
CREATE FUNCTION col_type_is( sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), ctype LONGTEXT, description TEXT )
RETURNS TEXT
BEGIN
  IF description = '' THEN
	SET description = CONCAT( 'Column ', quote_ident(tname), '.', quote_ident(cname), 
      ' should have column type ', quote_ident(ctype));
  END IF;

  IF NOT _has_column( sname, tname, cname ) THEN
	RETURN CONCAT(ok(FALSE,description),'\n',
	  diag(CONCAT('    Column ', quote_ident(tname), '.', quote_ident(cname), ' does not exist')));
  END IF;

  RETURN eq(_col_type( sname, tname, cname), ctype, description);
END //


/****************************************************************************/

-- _col_has_default (schema, table, column )

-- note: MySQL 5.5x does not distinguish between 'no default' and
-- 'null as default' and 'empty string as default'

DROP FUNCTION IF EXISTS _col_has_default //
CREATE FUNCTION _col_has_default ( dbname TEXT, tname TEXT, cname TEXT  )
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;

    SELECT true into ret
      FROM information_schema.columns as db
     WHERE db.table_schema = dbname
       AND db.table_name = tname
       AND db.column_name = cname
       AND db.column_default IS NOT NULL;
    RETURN coalesce(ret, false);
END //

DROP FUNCTION IF EXISTS col_has_default //
CREATE FUNCTION col_has_default ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat( 'Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should have a default' );
    END IF;

    RETURN ok( _col_has_default( dbname, tname, cname ), description );
END //

DROP FUNCTION IF EXISTS col_hasnt_default //
CREATE FUNCTION col_hasnt_default ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat( 'Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should not have a default' );
    END IF;

    RETURN ok( NOT _col_has_default( dbname, tname, cname ), description );
END //

/****************************************************************************/


DROP FUNCTION IF EXISTS _col_default//
CREATE FUNCTION _col_default(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64))
RETURNS LONGTEXT
BEGIN
  DECLARE ret LONGTEXT;

  SELECT `column_default` INTO ret
  FROM `information_schema`.`columns`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `column_name` = cname;

  RETURN ret ;
END //

DROP FUNCTION IF EXISTS col_default_is //
CREATE FUNCTION col_default_is(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), cdefault LONGTEXT, description TEXT )
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Column ',
      quote_ident(tname), '.', quote_ident(cname), ' should have as default ', quote_ident(cdefault));
  END IF;

  IF NOT _has_column(sname, tname, cname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
       diag(CONCAT('    Column ', quote_ident(tname), '.', quote_ident(cname), ' does not exist')));
  END IF;

  RETURN eq(_col_default(sname, tname, cname), cdefault, description);
END //



/****************************************************************************/
-- note: in MySQL 5.5x 'extra' default to ''

DROP FUNCTION IF EXISTS _col_extra_is //
CREATE FUNCTION _col_extra_is(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64))
RETURNS VARCHAR(30)
BEGIN
  DECLARE ret VARCHAR(30);

  SELECT `extra` INTO ret
  FROM `information_schema`.`columns`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `column_name` = cname;

  RETURN ret;
END //

DROP FUNCTION IF EXISTS col_extra_is //
CREATE FUNCTION col_extra_is(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), cextra VARCHAR(30), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT( 'Column ',
      quote_ident(tname), '.', quote_ident(cname), 
        ' should have as extra ', quote_ident(cextra));
    END IF;

    IF NOT _has_column(sname, tname, cname) THEN
      RETURN CONCAT(ok(FALSE, description), '\n',
        diag (CONCAT('    Column ', quote_ident(sname), '.', quote_ident(tname), 
          '.', quote_ident(cname), ' does not exist')));
    END IF;

    RETURN eq(_col_extra_is(sname, tname, cname), cextra, description);
END //


/****************************************************************************/

-- COLUMN CHARACTER SET
-- Character set can be set on a col so should test individually too.
-- CHARSET is a reserved word in mysql and will be familiar to those
-- coming from a PHP background so include both forms.
-- _is style test should return expected and found values on failure

DROP FUNCTION IF EXISTS col_charset_is //
CREATE FUNCTION col_charset_is(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), cset VARCHAR(32), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
	SET description = CONCAT('Column ', quote_ident(tname), '.', quote_ident(cname), 
      ' should have Character Set ' , quote_ident(cset));
  END IF;

  IF NOT _has_column(sname, tname, cname) THEN
    RETURN CONCAT(ok( FALSE, description), '\n',
	  diag( CONCAT('    Column ', quote_ident(tname), '.', quote_ident(cname), ' does not exist')));
  END IF;

  RETURN eq(_col_charset(sname, tname, cname), cset, description);
END //

-- alias
DROP FUNCTION IF EXISTS col_character_set_is //
CREATE FUNCTION col_character_set_is(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), cset VARCHAR(32), description TEXT)
RETURNS TEXT
BEGIN
  RETURN col_charset_is(sname, tname, cname, cset, description);
END //


/****************************************************************************/

-- COLUMN COLLATION

DROP FUNCTION IF EXISTS _col_collation //
CREATE FUNCTION _col_collation(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(32))
RETURNS VARCHAR(32)
BEGIN
  DECLARE ret VARCHAR(32);
  
  SELECT `collation_name` INTO ret
  FROM `information_schema`.`columns`
  WHERE `table_schema` = sname
  AND `table_name` = tname
  AND `column_name` = cname;

  RETURN COALESCE(ret, NULL);
END //


DROP FUNCTION IF EXISTS col_collation_is //
CREATE FUNCTION col_collation_is(sname VARCHAR(64), tname VARCHAR(64), cname VARCHAR(64), ccoll VARCHAR(32), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Column ', quote_ident(tname), '.', 
	  quote_ident(cname), ' should have collation ' , quote_ident(ccoll));
  END IF;

  IF NOT _has_column( sname, tname, cname ) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
	  diag(CONCAT('    Column ', quote_ident(tname), '.', quote_ident(cname), 
		' does not exist')));
  END IF;

  RETURN eq(_col_collation(sname, tname, cname), ccoll, description);
END //


/*******************************************************************/
-- Check that only the correct columns are defined

DROP FUNCTION IF EXISTS _missing_columns //
CREATE FUNCTION _missing_columns(sname VARCHAR(64), tname VARCHAR(64)) 
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
		  SELECT `column_name`
		  FROM `information_schema`.`columns`
		  WHERE `table_schema` = sname
		  AND `table_name` = tname
		)
	) msng;

  RETURN COALESCE(ret, '');
END //

DROP FUNCTION IF EXISTS _extra_columns //
CREATE FUNCTION _extra_columns(sname VARCHAR(64), tname VARCHAR(64)) 
RETURNS TEXT
BEGIN
  DECLARE ret TEXT;
  SELECT GROUP_CONCAT(qi(`ident`)) into ret FROM 
    (
	  SELECT DISTINCT `column_name` AS `ident` 
      FROM `information_schema`.`columns`
      WHERE `table_schema` = sname
      AND `table_name` = tname
	  AND `column_name` NOT IN 
        (
          SELECT `ident`
          FROM `idents2`
        )
	) xtra;

  RETURN COALESCE(ret, '');
END //

DROP FUNCTION IF EXISTS columns_are //
CREATE FUNCTION columns_are(sname VARCHAR(64), tname VARCHAR(64), want TEXT, description TEXT) 
RETURNS TEXT
BEGIN
  DECLARE sep       CHAR(1) DEFAULT ','; 
  DECLARE seplength INTEGER DEFAULT CHAR_LENGTH(sep);
  DECLARE missing   TEXT; 
  DECLARE extras    TEXT;

  IF description = '' THEN 
	SET description = CONCAT('Table ', quote_ident(sname), '.', quote_ident(tname), 
      ' should have the correct columns');
  END IF;
    
  IF NOT _has_table(sname,tname) THEN
	RETURN CONCAT(ok(FALSE, description), '\n', 
      diag(CONCAT('    Table ', quote_ident(sname), '.', quote_ident(tname), ' does not exist' )));
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

  SET missing = _missing_columns(sname, tname);
  SET extras  = _extra_columns(sname, tname);
        
  RETURN _are('columns', extras, missing, description);
END //


DELIMITER ;
