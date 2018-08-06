-- USER
-- ====

USE tap;

DELIMITER //

/****************************************************************************/

DROP FUNCTION IF EXISTS _has_user //
CREATE FUNCTION _has_user(hname CHAR(60), uname CHAR(32))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE ret BOOLEAN;

  SELECT 1 INTO ret
  FROM `mysql`.`user`
  WHERE `host` = hname
  AND `user` = uname;

  RETURN COALESCE(ret, 0);
END //


-- has_user( host, user, description )
DROP FUNCTION IF EXISTS has_user //
CREATE FUNCTION has_user(hname CHAR(60), uname CHAR(32), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('User \'', uname, '\'@\'', quote_ident(hname), '\' should exist');
  END IF;

  RETURN ok(_has_user (hname, uname), description);
END //


-- hasnt_user(host, user, description)
DROP FUNCTION IF EXISTS hasnt_user //
CREATE FUNCTION hasnt_user(hname CHAR(60), uname CHAR(32), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('User \'', uname, '\'@\'', hname, '\' should not exist');
  END IF;

  RETURN ok(NOT _has_user(hname, uname), description);
END //


/****************************************************************************/
-- long-form user definition

DROP FUNCTION IF EXISTS _has_user_at_host //
CREATE FUNCTION _has_user_at_host(uname CHAR(97))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE ret BOOLEAN;

  SELECT 1 INTO ret
  FROM `mysql`.`user`
  WHERE CONCAT(`user`, '@', `host`) = uname;

  RETURN COALESCE(ret, 0);
END //


-- has_user@host(userdef, description )
DROP FUNCTION IF EXISTS has_user_at_host //
CREATE FUNCTION has_user_at_host(uname CHAR(97), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  -- normalize for different quoting or none
  SET @uname = uname;
  SET @uname = REPLACE(@uname,'`','');
  SET @uname = REPLACE(@uname,'''','');

  IF description = '' THEN
    SET description = CONCAT('User ', uname, ' should exist');
  END IF;

  RETURN ok(_has_user_at_host(@uname), description);
END //


-- hasnt_user_at_host(userdef, description)
DROP FUNCTION IF EXISTS hasnt_user_at_host //
CREATE FUNCTION hasnt_user_at_host(uname CHAR(97), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  -- normalize for different quoting or none
  SET @uname = uname;
  SET @uname = REPLACE(@uname,'`','');
  SET @uname = REPLACE(@uname,'''','');

  IF description = '' THEN
    SET description = CONCAT('User ', uname, ' should not exist');
  END IF;

  RETURN ok(NOT _has_user_at_host(@uname), description);
END //


/****************************************************************************/

DELIMITER ;
