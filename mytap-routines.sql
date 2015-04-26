DELIMITER //

/****************************************************************************/

-- internal function to check

DROP FUNCTION IF EXISTS _has_routine  //
CREATE FUNCTION _has_routine (dbname TEXT, rname TEXT, rtype varchar(10) )
RETURNS BOOLEAN 
BEGIN
  DECLARE b_result boolean;
  
        SELECT true into b_result
          FROM information_schema.routines as db
         WHERE db.routine_schema = dbname
           AND db.routine_name = rname
           AND db.routine_type = rtype;
    
    RETURN coalesce(b_result, false);
END //


-- has_function( schema, function, description )
DROP FUNCTION IF EXISTS has_function //
CREATE FUNCTION has_function ( dbname TEXT, rname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('Function ', 
            quote_ident(dbname), '.', quote_ident(rname), ' should exist' );
    END IF;

    RETURN ok( _has_routine( dbname, rname, 'FUNCTION' ), description );
END //

-- hasnt_function( schema, function, description )
DROP FUNCTION IF EXISTS hasnt_function //
CREATE FUNCTION hasnt_function ( dbname TEXT, rname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('Function ', 
            quote_ident(dbname), '.', quote_ident(rname), ' should not exist' );
    END IF;

    RETURN ok( NOT _has_routine( dbname, rname, 'FUNCTION' ), description );
END //


-- has_procedure( schema, procedure, description )
DROP FUNCTION IF EXISTS has_procedure //
CREATE FUNCTION has_procedure ( dbname TEXT, rname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('Procedure ', 
            quote_ident(dbname), '.', quote_ident(rname), ' should exist' );
    END IF;

    RETURN ok( _has_routine( dbname, rname, 'PROCEDURE' ), description );
END //

-- hasnt_procedure( schema, procedure, description )
DROP FUNCTION IF EXISTS hasnt_procedure //
CREATE FUNCTION hasnt_procedure ( dbname TEXT, rname TEXT, description TEXT )
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('Procedure ', 
            quote_ident(dbname), '.', quote_ident(rname), ' should not exist' );
    END IF;

    RETURN ok( NOT _has_routine( dbname, rname, 'PROCEDURE' ), description );
END //

/****************************************************************************/

DELIMITER ;