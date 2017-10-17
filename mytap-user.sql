DELIMITER //

/****************************************************************************/
-- USER DEFINITION


-- _has_user( host, user )
DROP FUNCTION IF EXISTS _has_user //
CREATE FUNCTION _has_user(hname TEXT , uname TEXT)
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM `mysql`.`user`
     WHERE `Host` = hnane
       AND `User` = uname;
    RETURN COALESCE(ret, 0);
END //


-- has_user( host, user, description )
DROP FUNCTION IF EXISTS has_user //
CREATE FUNCTION has_user (hname TEXT, uname TEXT, description TEXT)
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('User ', quote_ident(hname), '.', quote_ident(uname), ' should be defined' );
    END IF;

    RETURN ok( _has_user ( hname, uname ), description );
END //


-- hasnt_user( host, user, description )
DROP FUNCTION IF EXISTS hasnt_user //
CREATE FUNCTION hasnt_user (hname TEXT, uname TEXT, description TEXT)
RETURNS TEXT
BEGIN
    IF description = '' THEN
        SET description = concat('User ', quote_ident(hname), '.', quote_ident(uname), ' should not be defined' );
    END IF;

    RETURN ok( NOT _has_user( hname, uname ), description );
END //


/****************************************************************************/

-- check user is not disabled 

-- _user_ok( host, user )
DROP FUNCTION IF EXISTS _user_ok //
CREATE FUNCTION _user_ok(hname TEXT, uname TEXT)
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
CREATE FUNCTION user_ok (hname TEXT, uname TEXT, description TEXT)
RETURNS TEXT
BEGIN

    IF NOT _has_user( hname, uname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('   User ', quote_ident(hname), '.', quote_ident(uname), ' is not defined' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('User ', quote_ident(hname), '.',
            quote_ident(uname), ' should not be locked or have expired password' );
    END IF;

    RETURN ok( _user_ok( hname, uname ), description );
END //


-- user_not_ok(host, user, description )
DROP FUNCTION IF EXISTS user_not_ok //
CREATE FUNCTION user_not_ok (hname TEXT , uname TEXT, description TEXT)
RETURNS TEXT
BEGIN

    IF NOT _has_user( hname, uname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('   User ', quote_ident(hname), '.', quote_ident(uname), ' is not defined' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('User ', quote_ident(hname), '.',
            quote_ident(uname), ' should be locked out or password expired' );
    END IF;

    RETURN ok( NOT _user_ok( hname, uname ), description );
END //


/****************************************************************************/

-- PASSWORD LIFETIME

-- _user_has_lifetime( host, user )
DROP FUNCTION IF EXISTS _user_has_lifetime //
CREATE FUNCTION _user_has_lifetime(hname TEXT , uname TEXT)
RETURNS BOOLEAN
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM `mysql`.`user`
     WHERE `Host` = hnane
       AND `User` = uname
       AND `password_lifetime` IS NOT NULL;
    RETURN COALESCE(ret, 0);
END //


-- user_has_lifetime( host, user, description )
DROP FUNCTION IF EXISTS user_has_lifetime//
CREATE FUNCTION user_has_lifetime(hname TEXT, uname TEXT, description TEXT)
RETURNS TEXT
BEGIN

    IF NOT _has_user( hname, uname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('   User ', quote_ident(hname), '.', quote_ident(uname), ' is not defined' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Password for User ', quote_ident(hname), '.', quote_ident(uname), ' should expire' );
    END IF;

    RETURN ok( _user_has_lifetime( hname, uname ), description );
END //


-- user_hasnt_lifetime( host, user, description )
DROP FUNCTION IF EXISTS user_hasnt_lifetime //
CREATE FUNCTION user_hasnt_lifetime(hname TEXT, uname TEXT, description TEXT)
RETURNS TEXT
BEGIN

    IF NOT _has_user( hname, uname ) THEN
        RETURN fail(concat('Error ',
               diag (concat('   User ', quote_ident(hname), '.', quote_ident(uname), ' is not defined' ))));
    END IF;

    IF description = '' THEN
        SET description = concat('Password for User ', quote_ident(hname), '.', quote_ident(uname), ' should NOT expire' );
    END IF;

    RETURN ok( NOT _user_has_lifetime( hname, uname ), description );
END //


/****************************************************************************/


DELIMITER ;
