DELIMITER //

/****************************************************************************/

-- internal function to check
DROP FUNCTION IF EXISTS _texists //
CREATE FUNCTION _texists (dbname TEXT, tname TEXT)
RETURNS BOOLEAN 
BEGIN
	declare b_result boolean;
	
	SELECT true into b_result
	  FROM information_schema.tables as db
	 WHERE db.table_schema = dbname
	   AND db.table_name = tname
	   AND db.table_type = 'BASE TABLE';
    
    return coalesce(b_result, false);

END //


-- has_table( schema, table, description )
DROP FUNCTION IF EXISTS has_table //
CREATE FUNCTION has_table (dbname TEXT, tname TEXT, description TEXT)
RETURNS TEXT 
BEGIN
	if description = '' then
		set description = concat('Table ', quote_ident(dbname), '.', quote_ident(tname), ' should exist' );
	end if;

    return ok( _texists( dbname, tname ), description );
END //


-- hasnt_table( schema, table, description )
DROP FUNCTION IF EXISTS hasnt_table //
CREATE FUNCTION hasnt_table (dbname TEXT, tname TEXT, description TEXT)
RETURNS TEXT 
BEGIN
	if description = '' then
		set description = concat('Table ', quote_ident(dbname), '.', quote_ident(tname), ' should not exist' );
	end if;

    return ok( NOT _texists( dbname, tname ), description );
END //

DELIMITER ;
