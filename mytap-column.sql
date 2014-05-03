DELIMITER //

/****************************************************************************/

-- internal function to check
DROP FUNCTION IF EXISTS _cexists  //
CREATE FUNCTION _cexists (dbname TEXT, tname TEXT, cname TEXT )
RETURNS BOOLEAN 
BEGIN
	declare b_result boolean;
	
        SELECT true into b_result
          FROM information_schema.columns as db
         WHERE db.table_schema = dbname
           AND db.table_name = tname
           AND db.column_name = cname;
    
    return coalesce(b_result, false);
END //


-- has_column( schema, table, column, description )
DROP FUNCTION IF EXISTS has_column //
CREATE FUNCTION has_column ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
	if description = '' then
		set description = concat('Column ', quote_ident(tname), '.', quote_ident(cname), ' should exist' );
	end if;
	
    return ok( _cexists( dbname, tname, cname ), description );
END //


-- hasnt_column( schema, table, column, description )
DROP FUNCTION IF EXISTS hasnt_column //
CREATE FUNCTION hasnt_column ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN

	if description = '' then
		set description = concat('Column ', quote_ident(tname), '.', quote_ident(cname), ' should not exist' );
	end if;
	
    return ok( NOT _cexists( dbname, tname, cname ), description );
END //


/**************************/
-- _col_is_null( schema, table, column, desc, bool )
DROP FUNCTION IF EXISTS _col_is_nullable //
CREATE FUNCTION _col_is_nullable ( dbname TEXT, tname TEXT, cname TEXT, description TEXT, cbool varchar(3))
RETURNS TEXT
BEGIN
    IF NOT _cexists( dbname, tname, cname ) THEN
        RETURN concat(fail( description ), 'E\n',
               diag (concat('    Column ', quote_ident(dbname), '.', quote_ident(tname), '.', quote_ident(cname), ' does not exist' )));
    END IF;
    RETURN ok(
        EXISTS(
            SELECT true
              FROM information_schema.columns as db
             WHERE db.table_schema = dbname
               AND db.table_name = tname
               AND db.column_name = cname
               AND db.is_nullable = cbool
        ), description
    );
END //

-- col_not_null( schema, table, column, description )
DROP FUNCTION IF EXISTS col_not_null //
CREATE FUNCTION col_not_null ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
	if description = '' then
		set description = concat('Column ', quote_ident(tname), '.', quote_ident(cname), ' should not allow NULL' );
	end if;

    return _col_is_nullable( dbname, tname, cname, description, 'NO' );
END //


-- col_is_null( schema, table, column, description )
DROP FUNCTION IF EXISTS col_is_null //
CREATE FUNCTION col_is_null ( dbname TEXT, tname TEXT, cname TEXT, description TEXT )
RETURNS TEXT
BEGIN
	if description = '' then
		set description = concat('Column ', quote_ident(tname), '.', quote_ident(cname), ' should allow NULL' );
	end if;
	
    return _col_is_nullable( dbname, tname, cname, description, 'YES' );
END //

/****************************************************************************/

DELIMITER ;