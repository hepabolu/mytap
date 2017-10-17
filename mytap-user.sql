DELIMITER //

/****************************************************************************/
-- USER DEFINITION


-- _has_user( host, user )
DROP FUNCTION IF EXISTS _has_user //
CREATE FUNCTION _has_user(hname CHAR(60), uname CHAR(32))
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM `mysql`.`user`
     WHERE `host` = hname
       AND `user` = uname;
    RETURN COALESCE(ret, 0);
END //


-- has_user( host, user, description )
DROP FUNCTION IF EXISTS has_user //
CREATE FUNCTION has_user (hname CHAR(60), uname CHAR(32), description TEXT)
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('User ', quote_ident(uname), '@', quote_ident(hname), ' should exist' );
    END IF;

    RETURN ok( _has_user ( hname, uname ), description );
END //


-- hasnt_user( host, user, description )
DROP FUNCTION IF EXISTS hasnt_user //
CREATE FUNCTION hasnt_user (hname CHAR(60), uname CHAR(32), description TEXT)
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('User ', quote_ident(uname), '@', quote_ident(hname), ' shouldnt exist' );
    END IF;

    RETURN ok( NOT _has_user( hname, uname ), description );
END //


/****************************************************************************/

-- check user is not disabled 

-- _user_ok( host, user )
DROP FUNCTION IF EXISTS _user_ok //
CREATE FUNCTION _user_ok(hname CHAR(60), uname CHAR(32))
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM `mysql`.`user`
     WHERE `host` = hname
       AND `user` = uname
       AND UPPER(password_expired) <> 'Y'
       AND UPPER(account_locked) <> 'Y';
    RETURN COALESCE(ret, 0);
END //


-- user_ok(host, user, description )
DROP FUNCTION IF EXISTS user_ok //
CREATE FUNCTION user_ok (hname CHAR(60), uname CHAR(32), description TEXT)
RETURNS TEXT
BEGIN

    IF NOT _has_user( hname, uname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('   User ', quote_ident(uname), '@', quote_ident(hname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('User ', quote_ident(uname), '@',
            quote_ident(hname), ' should not be locked or have expired password' );
    END IF;

    RETURN ok( _user_ok( hname, uname ), description );
END //


-- user_not_ok(host, user, description )
DROP FUNCTION IF EXISTS user_not_ok //
CREATE FUNCTION user_not_ok (hname CHAR(60), uname CHAR(32), description TEXT)
RETURNS TEXT
BEGIN

    IF NOT _has_user( hname, uname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('   User ', quote_ident(uname), '@', quote_ident(hname), ' does no exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('User ', quote_ident(uname), '@',
            quote_ident(hname), ' should be locked out or password expired' );
    END IF;

    RETURN ok( NOT _user_ok( hname, uname ), description );
END //


/****************************************************************************/

-- PASSWORD LIFETIME

-- _user_has_lifetime( host, user )
DROP FUNCTION IF EXISTS _user_has_lifetime //
CREATE FUNCTION _user_has_lifetime (hname CHAR(60), uname CHAR(32))
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM `mysql`.`user`
     WHERE `Host` = hname
       AND `User` = uname
       AND `password_lifetime` IS NOT NULL;
    RETURN COALESCE(ret, 0);
END //


-- user_has_lifetime( host, user, description )
DROP FUNCTION IF EXISTS user_has_lifetime//
CREATE FUNCTION user_has_lifetime(hname CHAR(60), uname CHAR(32), description TEXT)
RETURNS TEXT
BEGIN

    IF NOT _has_user( hname, uname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('   User ', quote_ident(uname), '@', quote_ident(hname), ' does not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Password for User ', quote_ident(uname), '@', quote_ident(hname), ' expires' );
    END IF;

    RETURN ok( _user_has_lifetime( hname, uname ), description );
END //


-- user_hasnt_lifetime( host, user, description )
DROP FUNCTION IF EXISTS user_hasnt_lifetime //
CREATE FUNCTION user_hasnt_lifetime(hname CHAR(60), uname CHAR(32), description TEXT)
RETURNS TEXT
BEGIN

    IF NOT _has_user( hname, uname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('   User ', quote_ident(uname), '@', quote_ident(hname), ' is not exist' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Password for User ', quote_ident(uname), '@', quote_ident(hname), ' should NOT expire' );
    END IF;

    RETURN ok( NOT _user_has_lifetime( hname, uname ), description );
END //


/****************************************************************************/


DELIMITER ;
