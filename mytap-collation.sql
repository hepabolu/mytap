-- COLLATION
-- =========


DELIMITER //

/****************************************************************************/

-- _has_collation(collation)
DROP FUNCTION IF EXISTS _has_collation //
CREATE FUNCTION _has_collation(cname TEXT)
RETURNS BOOLEAN
BEGIN
  DECLARE ret BOOLEAN;
  
  SELECT 1 INTO ret
  FROM `information_schema`.`collations`
  WHERE `collation_name` = cname
  AND `is_compiled` = 'YES';
    
  RETURN COALESCE(ret, 0);
END //


-- has_collation(collation, description)
DROP FUNCTION IF EXISTS has_collation //
CREATE FUNCTION has_collation(cname TEXT, description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = concat('Collation ', quote_ident(cname), ' should be available');
  END IF; 

  RETURN ok(_has_collation(cname), description);
END //


-- hasnt_collation( collation_name, table, description )
DROP FUNCTION IF EXISTS hasnt_collation //
CREATE FUNCTION hasnt_collation(cname TEXT, description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = concat('Collation ', quote_ident(cname), '.', ' should not be available');
  END IF;

  RETURN ok(NOT _has_collation(cname), description);
END //


DELIMITER ;
