DELIMITER //

/****************************************************************************/

-- internal function to check

DROP FUNCTION IF EXISTS _has_table //
CREATE FUNCTION _has_table(dbname TEXT, tname TEXT)
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM information_schema.tables
     WHERE table_name = tname
       AND table_schema = dbname
       AND table_type = 'BASE TABLE';
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
        SET description = concat('Table ',
            quote_ident(dbname), '.', quote_ident(tname), ' should not exist' );
    END IF;

    RETURN ok( NOT _has_table( dbname, tname ), description );
END //


DELIMITER ;
