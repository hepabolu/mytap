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
-- _col_has_unique_index (schema, table, column )

DROP FUNCTION IF EXISTS _col_has_unique_index //
CREATE FUNCTION _col_has_unique_index ( dbname TEXT, tname TEXT, cname TEXT )
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;

    SELECT true into ret
      FROM information_schema.statistics as db
     WHERE db.table_schema = dbname
       AND db.table_name = tname
       AND db.column_name = cname
       AND db.index_name <> 'PRIMARY'
       AND db.non_unique = 0
       limit 1; /* only use the first entry */
    RETURN coalesce(ret, false);
END //

-- col_has_unique_index ( schema, table, column, keyname )
DROP FUNCTION IF EXISTS col_has_unique_index //
CREATE FUNCTION col_has_unique_index ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should have unique INDEX' );
    END IF;

    RETURN ok( _col_has_unique_index(dbname, tname, cname), description );
END //

-- col_hasnt_unique_index( schema, table, column, keyname )
DROP FUNCTION IF EXISTS col_hasnt_unique_index //
CREATE FUNCTION col_hasnt_unique_index ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should not have unique INDEX');
    END IF;

    RETURN ok( NOT _col_has_unique_index(dbname, tname, cname ), description );
END //

/****************************************************************************/
-- _col_has_non_unique_index (schema, table, column )

DROP FUNCTION IF EXISTS _col_has_non_unique_index //
CREATE FUNCTION _col_has_non_unique_index ( dbname TEXT, tname TEXT, cname TEXT )
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;

    SELECT true into ret
      FROM information_schema.statistics as db
     WHERE db.table_schema = dbname
       AND db.table_name = tname
       AND db.column_name = cname
       AND db.index_name <> 'PRIMARY'
       AND db.non_unique = 1
       limit 1; /* only use the first entry */
    RETURN coalesce(ret, false);
END //

-- col_has_non_unique_index ( schema, table, column, keyname )
DROP FUNCTION IF EXISTS col_has_non_unique_index //
CREATE FUNCTION col_has_non_unique_index ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should have non unique INDEX' );
    END IF;

    RETURN ok( _col_has_non_unique_index(dbname, tname, cname), description );
END //

-- col_hasnt_non_unique_index( schema, table, column, keyname )
DROP FUNCTION IF EXISTS col_hasnt_non_unique_index //
CREATE FUNCTION col_hasnt_non_unique_index ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should not have non unique INDEX');
    END IF;

    RETURN ok( NOT _col_has_non_unique_index(dbname, tname, cname), description );
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

-- _col_default_is (schema, table, column, default )

-- note: MySQL 5.5x does not distinguish between 'no default' and
-- 'null as default' and 'empty string as default'

DROP FUNCTION IF EXISTS _col_default_is //
CREATE FUNCTION _col_default_is ( dbname TEXT, tname TEXT, cname TEXT, cdefault TEXT  )
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;

    IF cdefault = '' OR cdefault IS NULL THEN
        SELECT true into ret
          FROM information_schema.columns as db
         WHERE db.table_schema = dbname
           AND db.table_name = tname
           AND db.column_name = cname
           AND db.column_default IS NULL;
    ELSE
        SELECT true into ret
          FROM information_schema.columns as db
         WHERE db.table_schema = dbname
           AND db.table_name = tname
           AND db.column_name = cname
           AND db.column_default = cdefault;
    END IF;
    RETURN coalesce(ret, false);
END //

DROP FUNCTION IF EXISTS col_default_is //
CREATE FUNCTION col_default_is ( dbname TEXT, tname TEXT, cname TEXT, cdefault TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat( 'Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should have as default ', quote_ident(cdefault) );
    END IF;

    RETURN ok( _col_default_is( dbname, tname, cname, cdefault ), description );
END //

/****************************************************************************/

-- _col_extra_is ( schema, table, column, extra )

-- note: in MySQL 5.5x 'extra' default to ''

DROP FUNCTION IF EXISTS _col_extra_is //
CREATE FUNCTION _col_extra_is ( dbname TEXT, tname TEXT, cname TEXT, cextra TEXT )
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;

    IF cextra IS NULL THEN
        set cextra = '';
    END IF;
    SELECT true into ret
      FROM information_schema.columns as db
     WHERE db.table_schema = dbname
       AND db.table_name = tname
       AND db.column_name = cname
       AND db.extra = cextra;

    RETURN coalesce(ret, false);
END //

DROP FUNCTION IF EXISTS col_extra_is //
CREATE FUNCTION col_extra_is ( dbname TEXT, tname TEXT, cname TEXT, cextra TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF NOT _has_column( dbname, tname, cname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat( 'Column ',
            quote_ident(tname), '.', quote_ident(cname), ' should have as extra ', quote_ident(cextra) );
    END IF;

    RETURN ok( _col_extra_is( dbname, tname, cname, cextra ), description );
END //

/****************************************************************************/

DELIMITER ;
