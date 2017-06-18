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

/****************************************************************************/

-- internal function to check

DROP FUNCTION IF EXISTS _has_trigger //

CREATE FUNCTION _has_trigger(dbname TEXT, tname TEXT, triggername TEXT)
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM information_schema.triggers
     WHERE event_object_table = tname
       AND trigger_schema = dbname
       AND trigger_name = triggername;
    RETURN COALESCE(ret, 0);
END //

-- has_trigger( schema, table, trigger, description )
DROP FUNCTION IF EXISTS has_trigger //

CREATE FUNCTION has_trigger( dbname TEXT, tname TEXT, triggername TEXT, description TEXT )
RETURNS text CHARSET utf8
BEGIN
    IF NOT _has_table( dbname, tname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Table ', quote_ident(dbname), '.', quote_ident(tname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Trigger ', quote_ident(dbname), '.',
            quote_ident(tname), '.', quote_ident(triggername), ' should exist' );
    END IF;

    RETURN ok( _has_trigger( dbname, tname, triggername ), description );
END //

-- hasnt_trigger( schema, table, trigger, description )
DROP FUNCTION IF EXISTS hasnt_trigger //

CREATE FUNCTION hasnt_trigger( dbname TEXT, tname TEXT, triggername TEXT, description TEXT )
RETURNS text CHARSET utf8
BEGIN
    IF NOT _has_table( dbname, tname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('    Table ', quote_ident(dbname), '.', quote_ident(tname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Trigger ', quote_ident(dbname), '.',
            quote_ident(tname), '.', quote_ident(triggername), ' should not exist' );
    END IF;

    RETURN ok(NOT _has_trigger( dbname, tname, triggername ), description );
END //


DELIMITER ;
