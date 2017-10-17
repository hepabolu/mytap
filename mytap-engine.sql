DELIMITER //

/****************************************************************************/
-- STORAGE ENGINE DEFINITIONS

-- _has_engine( storage_engine )
DROP FUNCTION IF EXISTS _has_engine //
CREATE FUNCTION _has_engine(ename TEXT)
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM information_schema.engines
     WHERE engine = ename
       AND (UPPER(support) = 'YES' OR UPPER(support) = 'DEFAULT');
    RETURN COALESCE(ret, 0);
END //


-- has_engine( storage_engine, description )
DROP FUNCTION IF EXISTS has_engine //
CREATE FUNCTION has_engine (ename TEXT, description TEXT)
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('storage engine ', quote_ident(ename), ' should be available' );
    END IF;

    RETURN ok( _has_engine ( ename ), description );
END //


-- _engine_is_default ( storage_engine )
DROP FUNCTION IF EXISTS _engine_is_default //
CREATE FUNCTION _engine_is_default(ename TEXT)
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM information_schema.engines
     WHERE engine = ename
       AND support = 'DEFAULT';
    RETURN COALESCE(ret, 0);
END //


-- engine_is_default ( storage_engine, description )
-- only one engine will be the default so no isnt check required
DROP FUNCTION IF EXISTS engine_is_default //
CREATE FUNCTION engine_is_default (ename TEXT, description TEXT)
RETURNS TEXT
BEGIN

    IF NOT _has_engine( ename ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Storage engine ', quote_ident(ename), ' is not available' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('storage engine ',
            quote_ident(ename), ' should be the default' );
    END IF;

    RETURN ok( _engine_is_default( ename ), description );
END //


DELIMITER ;
