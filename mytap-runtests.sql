USE tap;

DELIMITER //

DROP PROCEDURE IF EXISTS _run_proc_by_prefix //
CREATE PROCEDURE _run_proc_by_prefix(db_ TEXT, prefix_ TEXT)
BEGIN
    DECLARE no_more_proc_to_call BOOLEAN DEFAULT 0;
    DECLARE proc_to_call TEXT;

    DECLARE c CURSOR FOR
        SELECT ROUTINE_NAME
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE
            ROUTINE_TYPE = 'PROCEDURE'
            AND ROUTINE_SCHEMA = db_
            AND ROUTINE_NAME LIKE CONCAT(prefix_, '%')
        ORDER BY ROUTINE_NAME;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_proc_to_call = 1;

    OPEN c;
    l: LOOP
        FETCH c INTO proc_to_call;
        IF no_more_proc_to_call = 1 THEN
            LEAVE l;
        END IF;

        SET @call_sql = CONCAT('CALL ', db_, '.', proc_to_call, '()');
        PREPARE call_sql FROM @call_sql;
        EXECUTE call_sql;
        DEALLOCATE PREPARE call_sql;
    END LOOP;
    CLOSE c;
END //


DROP PROCEDURE IF EXISTS _runtests //
CREATE PROCEDURE _runtests(db_ TEXT, random_seed INT UNSIGNED)
BEGIN
    DECLARE no_more_test_to_call BOOLEAN DEFAULT 0;
    DECLARE test_to_call TEXT;
    DECLARE c CURSOR FOR
        SELECT ROUTINE_NAME
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE
            ROUTINE_TYPE = 'PROCEDURE'
            AND ROUTINE_SCHEMA = db_
            AND ROUTINE_NAME LIKE 'test%'
        ORDER BY
            IF(random_seed IS NULL, NULL, RAND(random_seed))
            , ROUTINE_NAME;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_test_to_call = 1;

    IF random_seed IS NULL THEN
        SELECT '# Running tests...';
    ELSE
        SELECT CONCAT('# Running tests in random order with seed ', random_seed, '...');
    END IF;


    CALL _run_proc_by_prefix(db_, 'startup');

    OPEN c;
    l: LOOP
        FETCH c INTO test_to_call;
        IF no_more_test_to_call = 1 THEN
            LEAVE l;
        END IF;

        CALL _run_proc_by_prefix(db_, 'setup');
        SET @call_sql = CONCAT('CALL ', db_, '.', test_to_call, '()');
        PREPARE call_sql FROM @call_sql;
        EXECUTE call_sql;
        DEALLOCATE PREPARE call_sql;
        CALL _run_proc_by_prefix(db_, 'teardown');
    END LOOP;
    CLOSE c;

    CALL _run_proc_by_prefix(db_, 'shutdown');
END //

DROP PROCEDURE IF EXISTS runtests //
CREATE procedure runtests(db_ TEXT)
BEGIN
    CALL _runtests(db_, NULL);
END //

DROP PROCEDURE IF EXISTS runtests_random //
CREATE PROCEDURE runtests_random(db_ TEXT)
BEGIN
    CALL _runtests(db_, FLOOR(RAND() * POW(2, 32)));
END //

DROP PROCEDURE IF EXISTS runtests_random_with_seed //
CREATE PROCEDURE runtests_random_with_seed(db_ TEXT, random_seed INT UNSIGNED)
BEGIN
    CALL _runtests(db_, random_seed);
END //

DELIMITER ;
