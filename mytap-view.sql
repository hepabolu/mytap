DELIMITER //

/****************************************************************************/

-- internal function to check if a view exists
DROP FUNCTION IF EXISTS _has_view //
CREATE FUNCTION _has_view (dbname TEXT, vname TEXT)
RETURNS BOOLEAN 
BEGIN
 	DECLARE ret boolean;
	
 	SELECT true INTO ret
 	  FROM information_schema.tables as db
 	 WHERE db.table_schema = dbname
 	   AND db.table_name = vname
 	   AND db.table_type = 'VIEW';
    
     RETURN coalesce(ret, false);

END //

-- has_view ( schema, view )
DROP FUNCTION IF EXISTS has_view //
CREATE FUNCTION has_view(dbname TEXT, vname TEXT, description TEXT) RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('View ', 
          quote_ident(dbname), '.', quote_ident(vname), ' should exist' );
    END IF;

    RETURN ok( _has_view( dbname, vname ), description );
END //

-- hasnt_view ( schema, view )
DROP FUNCTION IF EXISTS hasnt_view //
CREATE FUNCTION hasnt_view(dbname TEXT, vname TEXT, description TEXT) RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('View ', 
          quote_ident(dbname), '.', quote_ident(vname), ' should not exist' );
    END IF;

    RETURN ok( NOT _has_view( dbname, vname ), description );
END //

/****************************************************************************/

-- internal function to check view security
DROP FUNCTION IF EXISTS _has_security //
CREATE FUNCTION _has_security(dbname TEXT, vname TEXT, vsecurity TEXT)
RETURNS BOOLEAN
BEGIN
    DECLARE ret boolean;

    SELECT true INTO ret
      FROM information_schema.views as db
     WHERE db.table_schema = dbname
       AND db.table_name = vname
       AND db.security_type = vsecurity;
    
     RETURN coalesce(ret, false);

END //

-- has_security_invoker ( schema, view )
DROP FUNCTION IF EXISTS has_security_invoker //
CREATE FUNCTION has_security_invoker(dbname TEXT, vname TEXT, description TEXT) RETURNS TEXT
BEGIN
    IF NOT _has_view( dbname, vname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    View ', quote_ident(dbname), '.', quote_ident(vname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('View ', 
          quote_ident(dbname), '.', quote_ident(vname), ' should have security INVOKER' );
    END IF;

    RETURN ok( _has_security( dbname, vname, 'INVOKER' ), description );
END //

-- has_security_definer ( schema, view )
DROP FUNCTION IF EXISTS has_security_definer //
CREATE FUNCTION has_security_definer(dbname TEXT, vname TEXT, description TEXT) RETURNS TEXT
BEGIN
    IF NOT _has_view( dbname, vname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    View ', quote_ident(dbname), '.', quote_ident(vname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('View ', 
          quote_ident(dbname), '.', quote_ident(vname), ' should have security DEFINER' );
    END IF;

    RETURN ok( _has_security( dbname, vname, 'DEFINER' ), description );
END //


/****************************************************************************/

DELIMITER ;
