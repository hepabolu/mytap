DELIMITER //

/****************************************************************************/

-- internal function to check

DROP FUNCTION IF EXISTS _has_column  //
CREATE FUNCTION _has_column (dbname TEXT, tname TEXT, cname TEXT )
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
CREATE FUNCTION has_column ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
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

-- _col_is_nullable ( schema, table, column, bool )

DROP FUNCTION IF EXISTS _col_is_nullable //
CREATE FUNCTION _col_is_nullable ( dbname TEXT, tname TEXT, cname TEXT, cbool varchar(3))
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;

    SELECT true into ret
      FROM information_schema.columns as db
     WHERE db.table_schema = dbname
       AND db.table_name = tname
       AND db.column_name = cname
       AND db.is_nullable = cbool;
    RETURN coalesce(ret, false);
END //

-- col_is_null( schema, table, column )
DROP FUNCTION IF EXISTS col_is_null //
CREATE FUNCTION col_is_null ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Column ', 
            quote_ident(tname), '.', quote_ident(cname), ' should allow NULL' );
    END IF;

    RETURN ok( _col_is_nullable(dbname, tname, cname, 'YES'), description );
END //

-- col_not_null( schema, table, column, description )
DROP FUNCTION IF EXISTS col_not_null //
CREATE FUNCTION col_not_null ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Column ', 
            quote_ident(tname), '.', quote_ident(cname), ' should not allow NULL' );
    END IF;

    RETURN ok( _col_is_nullable(dbname, tname, cname, 'NO'), description );
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
       AND db.index_name <> 'PRIMARY';
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
       AND db.column_type = ctype;
    RETURN coalesce(ret, false);
END //

DROP FUNCTION IF EXISTS col_has_type //
CREATE FUNCTION col_has_type ( dbname TEXT, tname TEXT, cname TEXT, ctype TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat( 'Column ', 
            quote_ident(tname), '.', quote_ident(cname), ' should have type ', quote_ident(ctype) );
    END IF;

    RETURN ok( _col_has_type( dbname, tname, cname, ctype ), description );
END //

/****************************************************************************/

DELIMITER ;