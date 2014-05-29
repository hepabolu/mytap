DELIMITER //

/****************************************************************************/

-- internal function to check if a view exists
DROP FUNCTION IF EXISTS _has_view //
CREATE FUNCTION _has_view (dbname TEXT, vname TEXT)
RETURNS BOOLEAN 
BEGIN
 	declare b_result boolean;
	
 	SELECT true into b_result
 	  FROM information_schema.tables as db
 	 WHERE db.table_schema = dbname
 	   AND db.table_name = vname
 	   AND db.table_type = 'VIEW';
    
     return coalesce(b_result, false);

END //

-- has_view ( schema, view )
DROP FUNCTION IF EXISTS has_view //
CREATE FUNCTION has_view(dbname TEXT, vname TEXT) RETURNS TEXT
BEGIN
    RETURN ok(
        _has_view(dbname, vname),
        concat('View ', quote_ident(dbname), '.', quote_ident(vname), ' should exist')
    );
END //

-- hasnt_view ( schema, view )
DROP FUNCTION IF EXISTS hasnt_view //
CREATE FUNCTION hasnt_view(dbname TEXT, vname TEXT) RETURNS TEXT
BEGIN
    RETURN ok(
        NOT _has_view(dbname, vname),
        concat('View ', quote_ident(dbname), '.', quote_ident(vname), ' should not exist')
    );
END //

DELIMITER ;
