DELIMITER //

/****************************************************************************/
-- CHARACTER SET DEFINITIONS


-- internal function to check
-- _has_charset( charset )
DROP FUNCTION IF EXISTS _has_charset //
CREATE FUNCTION _has_charset(cname TEXT)
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM information_schema.character_sets
     WHERE `character_set_name` = cname;
    RETURN COALESCE(ret, 0);
END //


-- has_charset( charset, description )
DROP FUNCTION IF EXISTS has_charset //
CREATE FUNCTION has_charset (cname TEXT, description TEXT)
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('Charset ', quote_ident(cname), ' should be available' );
    END IF;

    RETURN ok( _has_charset ( cname ), description );
END //


-- hasnt_charset( charset_name, description )
DROP FUNCTION IF EXISTS hasnt_charset //
CREATE FUNCTION hasnt_charset (cname TEXT, description TEXT)
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('Charset ', quote_ident(cname), ' should not be available' );
    END IF;

    RETURN ok( NOT _has_charset( cname ), description );
END //


-- Aliases for above
-- has_character_set( charset, description )
DROP FUNCTION IF EXISTS has_character_set //
CREATE FUNCTION has_character_set (cname TEXT, description TEXT)
RETURNS TEXT
BEGIN
    RETURN has_charset ( cname, description );
END //


-- hasnt_character_set( charset_name, description )
DROP FUNCTION IF EXISTS hasnt_character_set //
CREATE FUNCTION hasnt_character_set (cname TEXT, description TEXT)
RETURNS TEXT
BEGIN
    RETURN hasnt_charset( cname, description );
END //



DELIMITER ;
