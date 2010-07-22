-- To run this and have it output TAP:
-- mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --database test --execute 'source /Users/david/Desktop/ok.sql'

CREATE SCHEMA IF NOT EXISTS tap;
USE tap;

DROP TABLE IF EXISTS __tcache__;
CREATE TABLE __tcache__ (
    id    INTEGER AUTO_INCREMENT PRIMARY KEY,
    cid   INTEGER NOT NULL,
    label TEXT    NOT NULL,
    value INTEGER NOT NULL,
    note  TEXT    NOT NULL
);
 
DELIMITER //

DROP FUNCTION IF EXISTS mytap_version;
CREATE FUNCTION mytap_version()
RETURNS NUMERIC
BEGIN
    RETURN 0.01;
END //

DROP FUNCTION IF EXISTS _get;
CREATE FUNCTION _get ( vlabel text ) RETURNS integer
BEGIN
    DECLARE ret integer;
    SELECT value INTO ret
      FROM __tcache__
     WHERE cid   = connection_id()
       AND label = vlabel LIMIT 1;
    RETURN ret;
END //

DROP FUNCTION IF EXISTS _set;
CREATE FUNCTION _set ( vlabel text, vvalue integer, vnote text ) RETURNS integer
BEGIN
    UPDATE __tcache__
       SET value = vvalue,
           note = coalesce(vnote, '')
     WHERE cid   = connection_id()
       AND label = vlabel;
    IF ROW_COUNT() = 0 THEN
        RETURN _add( vlabel, vvalue, vnote );
    END IF;
    RETURN vvalue;
END//

DROP PROCEDURE IF EXISTS _idset;
CREATE PROCEDURE _idset( vid integer, vvalue integer)
BEGIN
    UPDATE __tcache__
       SET value = vvalue
     WHERE id = vid;
END //

DROP FUNCTION IF EXISTS _add;
CREATE FUNCTION _add ( vlabel text, vvalue integer, vnote text )
RETURNS integer
BEGIN
    INSERT INTO __tcache__ (label, cid, value, note)
    VALUES (vlabel, connection_id(), vvalue, COALESCE(vnote, ''));
    RETURN vvalue;
END //

DROP FUNCTION IF EXISTS plan;
CREATE FUNCTION plan( numb integer) RETURNS TEXT
BEGIN
    DECLARE trash TEXT;
    -- Ugly hack to throw an exception.
    IF _get('plan') IS NOT NULL THEN
        SELECT `You tried to plan twice!` INTO trash;
    END IF;

    CREATE TEMPORARY TABLE IF NOT EXISTS __tresults__ (
        numb   INTEGER AUTO_INCREMENT PRIMARY KEY,
        ok     BOOLEAN NOT NULL DEFAULT 1,
        aok    BOOLEAN NOT NULL DEFAULT 1,
        descr  TEXT    NOT NULL,
        type   TEXT    NOT NULL,
        reason TEXT    NOT NULL
    );

    RETURN concat('1..', _set('plan', numb, NULL ));
END //

DROP PROCEDURE IF EXISTS no_plan;
CREATE PROCEDURE no_plan()
BEGIN
    DECLARE hide text;
    SET hide = plan(0);
END //

DROP FUNCTION IF EXISTS add_result;
CREATE FUNCTION add_result ( vok bool, vaok bool, vdescr text, vtype text, vreason text )
RETURNS integer
BEGIN
    INSERT INTO __tresults__ ( ok, aok, descr, type, reason )
    VALUES(vok, vaok, coalesce(vdescr, ''), coalesce(vtype, ''), coalesce(vreason, ''));
    RETURN last_insert_id();
END //

DROP FUNCTION IF EXISTS ok;
CREATE FUNCTION ok(aok BOOLEAN, descr TEXT) RETURNS TEXT
BEGIN
    DECLARE todo_why TEXT;
    DECLARE ok BOOLEAN;
    DECLARE test_num INTEGER;

    SET todo_why = _todo();

    SET ok = CASE
        WHEN aok THEN aok
        WHEN todo_why IS NULL THEN COALESCE(aok, 0)
        ELSE 1
    END;

    SET test_num = add_result(
        ok,
        COALESCE(aok, false),
        descr,
        CASE WHEN todo_why IS NULL THEN '' ELSE 'todo' END,
        COALESCE(todo_why, '')
    );

    RETURN concat(CASE aok WHEN TRUE THEN '' ELSE 'not ' END,
        'ok ', _set( 'curr_test', test_num, NULL ),
        CASE descr WHEN '' THEN '' ELSE COALESCE( concat(' - ', substr(diag( descr ), 3)), '' ) END,
        COALESCE( concat(' ', diag( concat('TODO ', todo_why) )), ''),
        CASE WHEN aok THEN '' ELSE concat('\n',
            diag(concat('Failed ',
                CASE WHEN todo_why IS NULL THEN '' ELSE '(TODO) ' END,
                'test ', test_num,
                CASE descr WHEN '' THEN '' ELSE COALESCE(concat(': "', descr, '"'), '') END,
                CASE WHEN aok IS NULL THEN concat('\n', diag('    (test result was NULL)')) ELSE '' END
        ))) END
    );
END //

DROP FUNCTION IF EXISTS num_failed;
CREATE FUNCTION num_failed () RETURNS INTEGER
BEGIN
    DECLARE ret integer;
    SELECT COUNT(*) INTO ret
      FROM __tresults__
     WHERE ok  = 0;
    RETURN ret;
END //

DROP FUNCTION IF EXISTS _finish;
CREATE FUNCTION _finish ( curr_test INTEGER,  exp_tests INTEGER, num_faild INTEGER)
RETURNS TEXT
BEGIN
    DECLARE ret TEXT DEFAULT '';
    DECLARE plural CHAR DEFAULT '';
    IF exp_tests = 1 THEN SET plural = 's'; END IF;

    IF curr_test IS NULL THEN
        -- Ugly hack to throw an exception.
        SELECT `# No tests run!` INTO ret;
    END IF;

    IF exp_tests = 0 OR exp_tests IS NULL THEN
         -- No plan. Output one now.
        SET exp_tests = curr_test;
        SET ret = concat(ret, '1..', COALESCE(exp_tests, 0));
    END IF;

    IF curr_test <> exp_tests THEN
        SET ret = concat(ret, diag(concat(
            'Looks like you planned ', exp_tests, ' test',
            plural, ' but ran ', curr_test
        )));
    ELSEIF num_faild > 0 THEN
        SET ret = concat(ret, diag(concat(
            'Looks like you failed ', num_faild, ' test',
            CASE num_faild WHEN 1 THEN '' ELSE 's' END,
            ' of ', exp_tests
        )));
    END IF;

    -- Clean up our mess.
    DELETE FROM __tcache__;
    RETURN ret;
END //

DROP PROCEDURE IF EXISTS finish;
CREATE PROCEDURE finish ()
BEGIN
    DECLARE msg TEXT;
    SET msg = _finish(
        _get('curr_test'),
        _get('plan'),
        num_failed()
    );
    if msg IS NOT NULL AND msg <> '' THEN SELECT msg; END IF;
END //

DROP FUNCTION IF EXISTS diag;
CREATE FUNCTION diag ( msg text ) RETURNS TEXT
BEGIN
    RETURN concat('# ', replace(
       replace(
            replace( msg, '\r\n', '\n# ' ),
            '\n',
            '\n# '
        ),
        '\r',
        '\n# '
    ));
END //

DROP FUNCTION IF EXISTS _get_latest_value;
CREATE FUNCTION _get_latest_value ( vlabel text )
RETURNS integer
BEGIN
    DECLARE ret integer;
    SELECT value INTO ret
      FROM __tcache__
     WHERE cid = connection_id()
       AND label = vlabel
       AND id = (SELECT MAX(id) FROM __tcache__ WHERE cid = connection_id() AND label = vlabel)
     LIMIT 1;
    RETURN ret;
END //

DROP FUNCTION IF EXISTS _get_latest_id;
CREATE FUNCTION _get_latest_id ( vlabel text )
RETURNS integer
BEGIN
    DECLARE ret integer;
    SELECT id INTO ret
      FROM __tcache__
     WHERE cid = connection_id()
       AND label = vlabel
       AND id = (SELECT MAX(id) FROM __tcache__ WHERE cid = connection_id() AND label = vlabel)
     LIMIT 1;
    RETURN ret;
END //

DROP FUNCTION IF EXISTS _todo;
CREATE FUNCTION _todo() RETURNS TEXT
BEGIN
    -- Get the latest id and value, because todo() might have been called
    -- again before the todos ran out for the first call to todo(). This
    -- allows them to nest.
    DECLARE todos   INTEGER;
    DECLARE todo_id INTEGER;
    SET todos = _get_latest_value('todo');

    IF todos IS NULL THEN
        -- No todos.
        RETURN NULL;
    END IF;

    SET todo_id = _get_latest_id('todo');
    IF todos = 0 THEN
        -- Todos depleted. Clean up.
        DELETE FROM __tcache__ WHERE id = todo_id;
        RETURN NULL;
    END IF;
    -- Decrement the count of counted todos and return the reason.
    IF todos <> -1 THEN
        CALL _idset(todo_id, todos - 1);
    END IF;

    IF todos = 1 THEN
        -- This was the last todo, so delete the record.
        DELETE FROM __tcache__ WHERE id = todo_id;
    END IF;

    RETURN _get_note_by_id(todo_id);
END //

DROP FUNCTION IF EXISTS _get_note_by_id;
CREATE FUNCTION _get_note_by_id ( vid integer ) RETURNS text
BEGIN
    DECLARE ret TEXT;
    SELECT note INTO ret FROM __tcache__ WHERE id = vid  LIMIT 1;
    RETURN ret;
END //

DROP FUNCTION IF EXISTS _is_eq;
CREATE FUNCTION _is_eq( have TEXT, want TEXT) RETURNS BOOLEAN
BEGIN
    RETURN (have IS NOT NULL AND want IS NOT NULL AND have = want)
        OR (have IS NULL AND want IS NULL)
        OR 0;
END;

DROP FUNCTION IF EXISTS is_eq;
CREATE FUNCTION is_eq( have TEXT, want TEXT, descr TEXT) RETURNS TEXT
BEGIN
    IF _is_eq(have, want) THEN RETURN ok(1, descr); END IF;

    -- Fail.
    RETURN concat( ok(0, descr), '\n', diag(concat(
           '        have: ', COALESCE(have, 'NULL'),
         '\n        want: ', COALESCE(want, 'NULL')
    )));
END //

DROP FUNCTION IF EXISTS isnt_eq;
CREATE FUNCTION isnt_eq( have TEXT, want TEXT, descr TEXT) RETURNS TEXT
BEGIN
    IF NOT _is_eq(have, want) THEN RETURN ok(1, descr); END IF;

    -- Fail.
    RETURN concat( ok(0, descr), '\n', diag(concat(
           '        have: ', COALESCE(have, 'NULL'),
         '\n        want: anything else'
    )));
END //

DROP FUNCTION IF EXISTS pass;
CREATE FUNCTION pass(descr TEXT) RETURNS TEXT
BEGIN
    RETURN ok(1, descr);
END //

DROP FUNCTION IF EXISTS fail;
CREATE FUNCTION fail(descr TEXT) RETURNS TEXT
BEGIN
    RETURN ok(0, descr);
END //

DROP FUNCTION IF EXISTS has_table;
CREATE FUNCTION has_table(tname TEXT) RETURNS TEXT
BEGIN
    DECLARE ret BOOLEAN;
    SELECT 1
      INTO ret
      FROM information_schema.tables
     WHERE table_name = tname
       AND table_schema = DATABASE()
       AND table_type <> 'SYSTEM VIEW';
    RETURN ok(ret, concat('Table ', quote(tname), ' should exist'));
END //

DELIMITER ;
