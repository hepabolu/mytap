/*
TAP Tests for user functions 
*/

BEGIN;

SELECT tap.plan(44);

-- setup for tests
DROP USER IF EXISTS '__tapuser__'@'localhost';
CREATE USER '__tapuser__'@'localhost' IDENTIFIED BY '__dgfjhasdkfa__'
PASSWORD EXPIRE NEVER ACCOUNT UNLOCK;

DROP USER IF EXISTS '__locked__'@'localhost';
CREATE USER '__locked__'@'localhost' IDENTIFIED BY '__dgfjhasdkfa__'
PASSWORD EXPIRE INTERVAL 180 DAY ACCOUNT LOCK;



/****************************************************************************/
-- has_user(hname CHAR(60), uname CHAR(32), description TEXT)

SELECT tap.check_test(
    tap.has_user('localhost', '__tapuser__', ''),
    true,
    'has_user() extant user',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.has_user('127.0.0.1', 'nonexistent', ''),
  false,
    'has_user() nonexistent user',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.has_user('localhost', '__tapuser__', ''),
    true,
    'has_user() default description',
    'User \'__tapuser__\'@\'localhost\' should exist',
    null,
    0
);

SELECT tap.check_test(
    tap.has_user('localhost', '__tapuser__', 'desc'),
    true,
    'has_user() description supplied',
    'desc',
    null,
    0
);



/****************************************************************************/
-- hasnt_user(hname CHAR(60), uname CHAR(32), description TEXT)

SELECT tap.check_test(
    tap.hasnt_user('localhost', '__nouser__', ''),
    true,
    'hasnt_user() extant user',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.hasnt_user('localhost', '__tapuser__', ''),
    false,
    'hasnt_user() nonexistent user',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.hasnt_user('localhost', '__nouser__', ''),
    true,
    'hasnt_user() default description',
    'User \'__nouser__\'@\'localhost\' should not exist',
    null,
    0
);

SELECT tap.check_test(
    tap.hasnt_user('localhost', '__tapuser__', 'desc'),
    false,
    'hasnt_user() description supplied',
    'desc',
    null,
    0
);


/****************************************************************************/
-- user_ok(hname CHAR(60), uname CHAR(32), description TEXT)
-- account lock test

SELECT tap.check_test(
    tap.user_ok('localhost', '__tapuser__', ''),
    true,
    'user_ok() correct specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.user_ok('localhost', '__locked__', ''),
    false,
    'user_ok() locked user',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.user_ok('localhost', '__tapuser__', ''),
    true,
    'user_ok() default description',
    'User \'__tapuser__\'@\'localhost\' should not be locked or have expired password',
    null,
    0
);

SELECT tap.check_test(
    tap.user_ok('localhost', '__tapuser__', 'desc'),
    true,
    'user_ok() description supplied',
    'desc',
    null,
    0
);

SELECT tap.check_test(
    tap.user_ok('localhost', '__nouser__', ''),
    false,
    'user_ok() user not found diagnostic',
    null,
    'User \'__nouser__\'@\'localhost\' does not exist',
    0
);


/****************************************************************************/
-- user_not_ok(hname CHAR(60), uname CHAR(32), description TEXT)


SELECT tap.check_test(
    tap.user_not_ok('localhost', '__locked__', ''),
    true,
    'user_not_ok() correct specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.user_not_ok('localhost', '__tapuser__', ''),
    false,
    'user_not_ok() unlocked user',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.user_not_ok('localhost', '__locked__', ''),
    true,
    'user_not_ok() default description',
    'User \'__locked__\'@\'localhost\' should be locked out or have an expired password',
    null,
    0
);

SELECT tap.check_test(
    tap.user_not_ok('localhost', '__locked__', 'desc'),
    true,
    'user_not_ok() description supplied',
    'desc',
    null,
    0
);

SELECT tap.check_test(
    tap.user_not_ok('localhost', '__nouser__', ''),
    false,
    'user_not_ok() user not found diagnostic',
    null,
    'User \'__nouser__\'@\'localhost\' does not exist',
    0
);


/****************************************************************************/
-- user_has_lifetime(hname CHAR(60), uname CHAR(32), description TEXT)

SELECT tap.check_test(
    tap.user_has_lifetime('localhost', '__locked__', ''),
    true,
    'user_has_lifetime() correct specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.user_has_lifetime('localhost', '__tapuser__', ''),
    false,
    'user_has_lifetime() with no lifetime',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.user_has_lifetime('localhost', '__locked__', ''),
    true,
    'user_has_lifetime() default description',
    'User \'__locked__\'@\'localhost\' Password should expire',
    null,
    0
);

SELECT tap.check_test(
    tap.user_has_lifetime('localhost', '__locked__', 'desc'),
    true,
    'user_has_lifetime() description supplied',
    'desc',
    null,
    0
);

SELECT tap.check_test(
    tap.user_has_lifetime('localhost', '__nouser__', ''),
    false,
    'user_has_lifetime() user not found diagnostic',
    null,
    'User \'__nouser__\'@\'localhost\' does not exist',
    0
);


/****************************************************************************/
-- user_hasnt_lifetime(hname CHAR(60), uname CHAR(32), description TEXT)


SELECT tap.check_test(
    tap.user_hasnt_lifetime('localhost', '__tapuser__', ''),
    true,
    'user_hasnt_lifetime() correct specification',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.user_hasnt_lifetime('localhost', '__locked__', ''),
    false,
    'user_hasnt_lifetime() locked user',
    null,
    null,
    0
);

SELECT tap.check_test(
    tap.user_hasnt_lifetime('localhost', '__tapuser__', ''),
    true,
    'user_hasnt_lifetime() default description',
    'User \'__tapuser__\'@\'localhost\' Password should not expire',
    null,
    0
);

SELECT tap.check_test(
    tap.user_hasnt_lifetime('localhost', '__tapuser__', 'desc'),
    true,
    'user_hasnt_lifetime() description supplied',
    'desc',
    null,
    0
);

SELECT tap.check_test(
    tap.user_hasnt_lifetime('localhost', '__nouser__', ''),
    false,
    'user_hasnt_lifetime() user not found diagnostic',
    null,
    'User \'__nouser__\'@\'localhost\' does not exist',
    0
);



/****************************************************************************/

-- Finish the tests and clean up.

call tap.finish();
DROP USER '__tapuser__'@'localhost';
DROP USER '__locked__'@'localhost';
ROLLBACK;
