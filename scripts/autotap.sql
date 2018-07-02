-- AUTOTAP
-- =======
-- These procedures will create a series 'passing' tests for any
-- MySQL schema provided as a parameter.

-- Disclaimer
-- ----------
-- Caution is advised since the script cannot make any attempt
-- to verify the correctness of the schema at the point it is run,
-- it can only generate tests that reflect the existing state.
-- For this reason you should only run these routines once and
-- only against a schema that is assumed to be in a known good
-- state.

-- There will be some who will say that auto-generating tests
-- goes contrary to the whole idea of testing, I'm not going
-- to disagree. However, the prospect of spending weeks
-- retrofitting tests to an existing database is enough to put
-- anyone of the task without getting any further forward than
-- the same output generated in seconds by this script.

-- There is an issue under MySQL 5.7 in STRICT MODE for 
-- information_schema.routines which I haven't yet resolved. 
-- If you have problems with function or procedure tests
-- make sure mytap-routines.sql is 'sourced' with 
-- sql_mode = ''
-- ie SET @@SESSION.sql_mode = '';

-- Use
-- ---
-- # mysql < scripts/autotap.sql
-- # mysql --raw --skip-column-names --batch -e "call tap.autotap('schemaname')" > /wherever/test_schemaname.sql
-- # mysql --raw --skip-column-names --batch < /wherever/test_schemaname.sql


USE tap;

DELIMITER //


DROP PROCEDURE IF EXISTS autotap //
CREATE PROCEDURE autotap(sname VARCHAR(64))
main:BEGIN
  -- allow group_concat to be a decent size
  IF @@GLOBAL.group_concat_max_len <= 1024 THEN
    SET @@SESSION.group_concat_max_len = 32768;
  END IF;

  SET @test_schema = sname;

  -- SCHEMA LEVEL
  -- sanity check before continuing
  SELECT 1 INTO @found FROM `information_schema`.`schemata` WHERE `schema_name` =  @test_schema;

  IF @found != 1 THEN
    SELECT CONCAT("Unknown schema " , @test_schema);
    LEAVE main;
  END IF;

  SELECT '-- ***************************************************************';
  SELECT '-- myTAP Testing Script';
  SELECT '-- ====================';
  SELECT CONCAT('-- Generated: ', CURRENT_DATE);  
  SELECT '-- This database testing script has been created by the autotap';
  SELECT '-- utility. The tests generated are in the TAP format for use with';
  SELECT '-- myTAP and are based on the current state of schema objects,';
  SELECT '-- with the database assumed to be in a known good state. All tests';
  SELECT '-- will pass but that does not guarantee the correctness of the';
  SELECT '-- state represented by the tests.';
  SELECT '-- ';
  SELECT '-- After the script is generated, any subsequent DDL changes,'; 
  SELECT '-- whether additions, deletions or modifications, will cause some'; 
  SELECT '-- of the tests to fail. This is intentional.';
  SELECT '-- ';
  SELECT '-- The purpose of the utility is to assist the process of'; 
  SELECT '-- retrofitting testing to existing projects. You should still check'; 
  SELECT '-- that the schema state represents what you intend and you should';
  SELECT '-- modify this script by hand to account for all subsequent changes.';
  SELECT '-- ***************************************************************\n';

  SELECT '\n-- ***************************************************************';
  SELECT CONCAT('-- SCHEMA ', sname);
  SELECT '-- ***************************************************************\n';

  SELECT 'USE tap;';
  SELECT 'BEGIN;';
  SELECT 'CALL tap.no_plan();';
  SELECT CONCAT("SELECT tap.has_schema('", @test_schema, "','');");

-- TABLES
  SET @tables_sql = 
    "SELECT GROUP_CONCAT(CONCAT('`',`table_name`,'`')) INTO @schema_tables
     FROM information_schema.tables 
     WHERE `table_schema` = ? and table_type = 'BASE TABLE';";

  PREPARE stmt1 FROM @tables_sql; 
  EXECUTE stmt1 USING @test_schema;
  DEALLOCATE PREPARE stmt1;

  IF NOT ISNULL(@schema_tables) THEN
    SELECT '\n-- ***************************************************************';
    SELECT '-- TABLES ';
    SELECT '-- ***************************************************************\n';
    SELECT CONCAT("SELECT tap.tables_are('", @test_schema, "','", @schema_tables, "','');");

    CALL tap.table_checks(@test_schema);
  END IF;

-- VIEWS  
  SET @views_sql = 
    "SELECT GROUP_CONCAT(CONCAT('`',`table_name`,'`')) INTO @schema_views
     FROM information_schema.tables 
     WHERE `table_schema` = ? and table_type = 'VIEW';";

  PREPARE stmt2 FROM @views_sql; 
  EXECUTE stmt2 USING @test_schema;
  DEALLOCATE PREPARE stmt2;

  IF NOT ISNULL(@schema_views) THEN
    SELECT '\n-- ***************************************************************';
    SELECT '-- VIEWS ';
    SELECT '-- ***************************************************************\n';

    SELECT CONCAT("SELECT tap.views_are('", @test_schema, "','", @schema_views, "','');");
    CALL tap.view_properties(@test_schema);
 END IF;

-- EVENTS
  SET @events_sql = 
    "SELECT GROUP_CONCAT(CONCAT('`',`event_name`,'`')) INTO @schema_events
     FROM information_schema.events 
     WHERE `event_schema` = ?;";

  PREPARE stmt3 FROM @events_sql; 
  EXECUTE stmt3 USING @test_schema;
  DEALLOCATE PREPARE stmt3;

  IF NOT ISNULL(@schema_events) THEN
    SELECT '\n-- ***************************************************************';
    SELECT '-- EVENTS ';
    SELECT '-- ***************************************************************\n';

    SELECT CONCAT("SELECT tap.events_are('", @test_schema, "','", @schema_events, "','');");  
    CALL event_properties(@test_schema);
 END IF;

-- FUNCTIONS
  SET @functions_sql =
    "SELECT GROUP_CONCAT(CONCAT('`',`routine_name`,'`')) INTO @schema_functions
     FROM information_schema.routines 
     WHERE `routine_type` = 'FUNCTION'
     AND `routine_schema` = ?;";

  PREPARE stmt4 FROM @functions_sql;
  EXECUTE stmt4 USING @test_schema;
  DEALLOCATE PREPARE stmt4;

  IF NOT ISNULL(@schema_functions) THEN
    SELECT '\n-- ***************************************************************';
    SELECT '-- FUNCTIONS ';
    SELECT '-- ***************************************************************\n';
    SELECT CONCAT("SELECT tap.routines_are('", @test_schema, "','FUNCTION','", @schema_functions, "','');");

    CALL function_properties(@test_schema); 
  END IF;

-- PROCEDURES  
  SET @procedures_sql =
    "SELECT GROUP_CONCAT(CONCAT('`',`routine_name`,'`')) INTO @schema_procedures
     FROM information_schema.routines 
     WHERE `routine_type` = 'PROCEDURE' 
     AND `routine_schema` = ?;";

  PREPARE stmt5 FROM @procedures_sql; 
  EXECUTE stmt5 USING @test_schema;
  DEALLOCATE PREPARE stmt5;

  IF NOT ISNULL(@schema_procedures) THEN
    SELECT '\n-- ***************************************************************';
    SELECT '-- PROCEDURES ';
    SELECT '-- ***************************************************************\n';
    SELECT CONCAT("SELECT tap.routines_are('", @test_schema, "','PROCEDURE','", @schema_procedures, "','');");

    CALL procedure_properties(@test_schema); 
  END IF;

  SELECT 'CALL tap.finish();';
  SELECT 'ROLLBACK;';
END main //

/********************************************************************************/
-- SCHEMA LEVEL Checks
-- EVENT tests
DROP PROCEDURE IF EXISTS event_properties //
CREATE PROCEDURE event_properties(sname VARCHAR(64))
BEGIN
  DECLARE en VARCHAR(64);  -- event_name
  DECLARE es VARCHAR(18);  -- status
  DECLARE et VARCHAR(9);   -- event_type
  DECLARE fi VARCHAR(256); -- interval_field
  DECLARE iv VARCHAR(18);  -- interval_value
  DECLARE done INT DEFAULT FALSE;

  DECLARE schema_events CURSOR FOR
    SELECT `event_name`, `status`, `event_type`, `interval_field`,
    `interval_value`
    FROM `information_schema`.`events`
    WHERE `event_schema` = sname;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN schema_events;
  read_loop: LOOP
    FETCH schema_events INTO en, es, et, fi, iv;
    IF done THEN
      LEAVE read_loop;
      CLOSE schema_events;
    END IF;
    SELECT CONCAT('\n-- EVENT ', sname,'.', en, '\n');
    SELECT CONCAT("SELECT tap.has_event('", sname, "','", en,"','');");  
    SELECT CONCAT("SELECT tap.event_status_is('", sname, "','", en,"','", es,"','');");
    SELECT CONCAT("SELECT tap.event_type_is('", sname, "','", en,"','", et,"','');"); 
    IF et = 'RECURRING' THEN
      SELECT CONCAT("SELECT tap.event_interval_field_is('", sname, "','", en,"','", fi ,"','');");
      SELECT CONCAT("SELECT tap.event_interval_value_is('", sname, "','", en,"','", iv,"','');");
    END IF;

  END LOOP;
END//

-- VIEW tests
DROP PROCEDURE IF EXISTS view_properties //
CREATE PROCEDURE view_properties(sname VARCHAR(64))
BEGIN
  DECLARE tn VARCHAR(64);  -- table_name
  DECLARE co VARCHAR(8);   -- check_option 
  DECLARE iu VARCHAR(3);   -- is_updatable 
  DECLARE de VARCHAR(93);  -- definer
  DECLARE st VARCHAR(7);   -- security_type
  DECLARE done INT DEFAULT FALSE;

  DECLARE schema_views CURSOR FOR 
    SELECT `table_name`, `check_option`, `is_updatable`, `definer`,
    `security_type`
    FROM `information_schema`.`views`
    WHERE `table_schema` = sname;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN schema_views;
  read_loop: LOOP
    FETCH schema_views INTO tn, co, iu, de, st;
    IF done THEN
      LEAVE read_loop;
      CLOSE schema_views;
    END IF;
    SELECT CONCAT('\n-- VIEW ', sname,'.', tn, '\n');
    SELECT CONCAT("SELECT tap.has_view('", sname, "','", tn,"','');");
    SELECT CONCAT("SELECT tap.view_check_option_is('", sname, "','", tn,"',", qv(co),",'');");
    SELECT CONCAT("SELECT tap.view_is_updatable('", sname, "','", tn,"',", qv(iu),",'');");
    SELECT CONCAT("SELECT tap.view_definer_is('", sname, "','", tn,"',", qv(de),",'');");
    SELECT CONCAT("SELECT tap.view_security_type_is('", sname, "','", tn,"',", qv(st),",'');");
   END LOOP;
END//


-- FUNCTION tests
DROP PROCEDURE IF EXISTS function_properties //
CREATE PROCEDURE function_properties(sname VARCHAR(64))
BEGIN
  DECLARE rn VARCHAR(64);  -- routine_name
  DECLARE id VARCHAR(18);  -- is_deterministic
  DECLARE da VARCHAR(64);  -- sql_data_access 
  DECLARE dt VARCHAR(64);  -- data type
  DECLARE st VARCHAR(64);  -- security type
  DECLARE rd LONGTEXT;     -- routine_definition
  DECLARE done INT DEFAULT FALSE;

  DECLARE schema_functions CURSOR FOR 
    SELECT `routine_name`, `is_deterministic`, `data_type`, `sql_data_access`,
    `security_type`
    FROM `information_schema`.`routines`
    WHERE `routine_schema` = sname
    AND `routine_type` = 'FUNCTION';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN schema_functions;
  read_loop: LOOP
    FETCH schema_functions INTO rn, id, dt, da, st;
    IF done THEN
      LEAVE read_loop;
      CLOSE schema_functions;
    END IF;
    SELECT CONCAT('\n-- FUNCTION ', sname,'.', rn, '\n');
    SELECT CONCAT("SELECT tap.has_function('", sname, "','", rn,"','');");
    SELECT CONCAT("SELECT tap.function_is_deterministic('", sname, "','", rn,"','", id,"','');");
    SELECT CONCAT("SELECT tap.function_data_type_is('", sname, "','", rn,"','", dt,"','');"); 
    SELECT CONCAT("SELECT tap.function_security_type_is('", sname, "','", rn,"','", st,"','');");
    SELECT CONCAT("SELECT tap.function_sql_data_access_is('", sname, "','", rn,"','", da,"','');");

  END LOOP;
END//


-- PROCEDURE tests
DROP PROCEDURE IF EXISTS procedure_properties //
CREATE PROCEDURE procedure_properties(sname VARCHAR(64))
BEGIN
  DECLARE rn VARCHAR(64);  -- routine_name
  DECLARE id VARCHAR(18);  -- is_deterministic
  DECLARE da VARCHAR(64);  -- sql_data_access 
  DECLARE st VARCHAR(64);  -- security type
  DECLARE rd LONGTEXT;     -- routine_definition
  DECLARE done INT DEFAULT FALSE;

  DECLARE schema_procedures CURSOR FOR 
    SELECT `routine_name`, `is_deterministic`, `sql_data_access`, `security_type`
    FROM `information_schema`.`routines`
    WHERE `routine_schema` = sname
    AND `routine_type` = 'PROCEDURE';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN schema_procedures;
  read_loop: LOOP
    FETCH schema_procedures INTO rn, id, da, st;
    IF done THEN
      LEAVE read_loop;
      CLOSE schema_procedures;
    END IF;
    SELECT CONCAT('\n-- PROCEDURES ', sname,'.', rn, '\n');
    SELECT CONCAT("SELECT tap.has_procedure('", sname, "','", rn,"','');");
    SELECT CONCAT("SELECT tap.procedure_is_deterministic('", sname, "','", rn,"','", id,"','');");
    SELECT CONCAT("SELECT tap.procedure_security_type_is('", sname, "','", rn,"','", st,"','');");
    SELECT CONCAT("SELECT tap.procedure_sql_data_access_is('", sname, "','", rn,"','", da,"','');");

  END LOOP;
END//



/********************************************************************************/
-- TABLE LEVEL
-- triggers, index, columns, constraints

DROP PROCEDURE IF EXISTS table_checks //
CREATE PROCEDURE table_checks(sname VARCHAR(64))
BEGIN
  DECLARE tn VARCHAR(64);   -- table_name
  DECLARE en VARCHAR(64);   -- engine
  DECLARE tc VARCHAR(32);   -- table_collation
  DECLARE done INT DEFAULT FALSE;

  -- BASE TABLES
  DECLARE `base_tables` CURSOR FOR 
    SELECT `table_name`, `engine`, `table_collation`
    FROM `information_schema`.`tables`
    WHERE `table_schema` = sname
    AND `table_type` = 'BASE TABLE';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN base_tables;
  read_loop: LOOP
    FETCH `base_tables` INTO tn, en, tc;
    IF done THEN
      LEAVE read_loop;
      CLOSE base_tables;
    END IF;
    SELECT '\n-- ***************************************************************';
    SELECT CONCAT('-- TABLE ', sname,'.',tn);
    SELECT '-- ***************************************************************\n';
    -- BASIC table tests
    SELECT CONCAT("SELECT tap.has_table('", sname, "','", tn, "','');");  
    SELECT CONCAT("SELECT tap.table_collation_is('", sname, "','",tn,"',", qv(tc), ",'');"); 
    SELECT CONCAT("SELECT tap.table_engine_is('", sname, "','",tn,"',", qv(en), ",'');"); 

    IF (SELECT COUNT(*) FROM `information_schema`.`columns`
        WHERE `table_schema` = sname AND `table_name` = tn) != 0 THEN
      SELECT '\n-- COLUMNS';
      CALL table_columns(sname,tn);
      CALL column_properties(sname,tn);
    END IF;

    IF (SELECT COUNT(*) FROM `information_schema`.`triggers`
        WHERE `trigger_schema` = sname AND `event_object_table` = tn) != 0 THEN
      SELECT '\n-- TRIGGERS';
      CALL table_triggers(sname,tn);
      CALL trigger_properties(sname,tn);
    END IF;

    IF (SELECT COUNT(*) FROM `information_schema`.`statistics` s
        LEFT JOIN `information_schema`.`table_constraints` c
          ON(c.`table_schema` = s.`table_schema` AND c.`table_name` = s.`table_name` AND c.`constraint_name` = s.`index_name`)
        WHERE s.`table_schema` = sname
        AND s.`table_name` = tn
        AND c.`constraint_name` IS NULL ) != 0 THEN
      SELECT '\n-- INDEXES';
      CALL table_indexes(sname,tn);
      CALL index_properties(sname,tn);
    END IF;

    IF (SELECT COUNT(*) FROM `information_schema`.`table_constraints`
        WHERE `table_schema` = sname AND `table_name` = tn) != 0 THEN
      SELECT '\n-- CONSTRAINTS';
      CALL table_constraints(sname,tn);
      CALL constraint_properties(sname,tn);
    END IF;

    IF (SELECT COUNT(*) FROM `information_schema`.`partitions`
        WHERE `table_schema` = sname AND `table_name` = tn AND `partition_name` IS NOT NULL) != 0 THEN
      SELECT '\n-- PARTITIONS';
      CALL table_partitions(sname,tn);
      CALL partition_properties(sname,tn);
    END IF;


  END LOOP;

END//

-- TABLE LEVEL CHECKS
-- triggers, index, column, constraints

DROP PROCEDURE IF EXISTS table_columns //
CREATE PROCEDURE table_columns(sname VARCHAR(64), tname VARCHAR(64))
BEGIN
  SET @sname = sname;
  SET @tname = tname;

  SET @cols_sql = 
    "SELECT GROUP_CONCAT(CONCAT('`',`column_name`,'`')) INTO @cols
     FROM information_schema.columns
     WHERE `table_schema` = ?
     AND `table_name` = ?;";

  PREPARE stmt FROM @cols_sql;
  EXECUTE stmt USING @sname, @tname;
  DEALLOCATE PREPARE stmt;

  SELECT CONCAT("SELECT tap.columns_are('", @sname, "','",@tname,"','", @cols,"','');");
END //


DROP PROCEDURE IF EXISTS table_constraints //
CREATE PROCEDURE table_constraints(sname VARCHAR(64), tname VARCHAR(64))
BEGIN
  SET @sname = sname;
  SET @tname = tname;

  SET @constraints_sql =
    "SELECT GROUP_CONCAT(CONCAT('`',`cn`,'`')) INTO @cons
     FROM 
      (
        SELECT DISTINCT `constraint_name` AS cn
        FROM `information_schema`.`table_constraints`
        WHERE `table_schema` = ?
        AND `table_name` = ?
      ) cons";

  PREPARE stmt FROM @constraints_sql;
  EXECUTE stmt USING @sname, @tname;
  DEALLOCATE PREPARE stmt;

  SELECT CONCAT("SELECT tap.constraints_are('", @sname, "','",@tname,"','", @cons,"','');");
END //

DROP PROCEDURE IF EXISTS table_indexes //
CREATE PROCEDURE table_indexes(sname VARCHAR(64), tname VARCHAR(64))
BEGIN
  SET @sname = sname;
  SET @tname = tname;

  SET @indxs_sql = 
    "SELECT GROUP_CONCAT(CONCAT('`',`index_name`,'`')) INTO @indxs
     FROM 
      (
        SELECT DISTINCT s.`index_name`
        FROM `information_schema`.`statistics` s
        LEFT JOIN `information_schema`.`table_constraints` c
        ON (c.`table_schema` = s.`table_schema` AND c.`table_name` = s.`table_name` AND c.`constraint_name` = s.`index_name`)
        WHERE s.`table_schema` = ?
        AND s.`table_name` = ?
        AND c.`constraint_name` IS NULL
      ) indx";

  PREPARE stmt FROM @indxs_sql;
  EXECUTE stmt USING @sname, @tname;
  DEALLOCATE PREPARE stmt;

  SELECT CONCAT("SELECT tap.indexes_are('", sname, "','",tname,"','", @indxs,"','');");
END //

DROP PROCEDURE IF EXISTS table_triggers //
CREATE PROCEDURE table_triggers(sname VARCHAR(64), tname VARCHAR(64))
BEGIN
  SET @sname = sname;
  SET @tname = tname;

  SET @trgrs_sql = 
    "SELECT GROUP_CONCAT(CONCAT('`',`trigger_name`,'`')) INTO @trgrs
     FROM information_schema.triggers 
     WHERE `event_object_schema` = ?
     AND `event_object_table` = ?;";

  PREPARE stmt FROM @trgrs_sql;
  EXECUTE stmt USING @sname, @tname;
  DEALLOCATE PREPARE stmt;

  SELECT CONCAT("SELECT tap.triggers_are('", sname, "','",tname,"','", @trgrs,"','');");
END //


-- Property checks on schema objects defined for tables

DROP PROCEDURE IF EXISTS constraint_properties //
CREATE PROCEDURE constraint_properties(sname VARCHAR(64), tname VARCHAR(64))
BEGIN
  DECLARE cn VARCHAR(64); -- constraint_name
  DECLARE ct VARCHAR(64); -- constraint_type
  DECLARE ur VARCHAR(64); -- update rule for fk
  DECLARE dr VARCHAR(64); -- delete rule for fk
  DECLARE rs VARCHAR(64); -- referenced schema for fk
  DECLARE rt VARCHAR(64); -- referenced table for fk
  DECLARE cc TEXT;        -- concatenation of the cols that make up a named indexed
  DECLARE rc TEXT;        -- concatenation of the referenced cols for fk

  DECLARE done INT DEFAULT FALSE;

  -- INDEX  
  DECLARE table_constraints CURSOR FOR 
    SELECT c.`constraint_name`, c.`constraint_type`, r.`update_rule`, r.`delete_rule`,
    u.`referenced_table_schema`, u.`referenced_table_name`,
    GROUP_CONCAT(CONCAT('`', u.`column_name`, '`') ORDER BY u.`ordinal_position`),
    GROUP_CONCAT(CONCAT('`', u.`referenced_column_name`, '`') ORDER BY u.`ordinal_position`)
    FROM `information_schema`.`table_constraints` c
    JOIN `information_schema`.`key_column_usage` u
    USING (`constraint_schema`,`table_name`,`constraint_name`)
    LEFT JOIN `information_schema`.`referential_constraints` r
    USING (`constraint_schema`,`table_name`,`constraint_name`)
    WHERE c.`table_schema` = sname
    AND c.`table_name` = tname
    GROUP BY c.`constraint_name`, c.`constraint_type`, r.`update_rule`, r.`delete_rule`,
    u.`referenced_table_schema`, u.`referenced_table_name`;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN table_constraints;
  read_loop: LOOP
    FETCH table_constraints INTO cn, ct, ur, dr, rs, rt, cc, rc;
    IF done THEN
      LEAVE read_loop;
      CLOSE table_constraints;
    END IF;
    SELECT CONCAT('\n-- CONSTRAINT ', tname,'.', cn, '\n');
    SELECT CONCAT("SELECT tap.has_constraint('", sname, "','",tname,"','", cn,"','');");
    SELECT CONCAT("SELECT tap.constraint_type_is('", sname, "','",tname,"','", cn,"','", ct ,"','');");

    IF ct = 'PRIMARY KEY' THEN
       SELECT CONCAT("SELECT tap.col_is_pk('", sname, "','",tname,"','", cc,"','');");
    END IF;

    IF ct = 'FOREIGN KEY' THEN
       SELECT CONCAT("SELECT tap.fk_on_delete('", sname, "','",tname,"','", cn,"','", dr,"','');");
       SELECT CONCAT("SELECT tap.fk_on_update('", sname, "','",tname,"','", cn,"','", ur,"','');");
    END IF;

  END LOOP;
END//

DROP PROCEDURE IF EXISTS column_properties //
CREATE PROCEDURE column_properties(sname VARCHAR(64), tname VARCHAR(64))
BEGIN
  DECLARE cn VARCHAR(64);  -- column_name
  DECLARE nu VARCHAR(3);   -- is_nullable
  DECLARE cd LONGTEXT;     -- column_default
  DECLARE ex VARCHAR(30);  -- extra
  DECLARE dt VARCHAR(64);  -- data_type
  DECLARE ct LONGTEXT;     -- column_type
  DECLARE cs VARCHAR(32);  -- character_set_name
  DECLARE co VARCHAR(32);  -- collation_name
  DECLARE done INT DEFAULT FALSE;

-- INDEX  
  DECLARE table_columns CURSOR FOR 
    SELECT `column_name`, `is_nullable`, `column_default`,
    `extra`, `data_type`, `column_type`, `character_set_name`, `collation_name`
    FROM `information_schema`.`columns`
    WHERE `table_schema` = sname
    AND `table_name` = tname ;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN table_columns;
  read_loop: LOOP
    FETCH table_columns INTO cn, nu, cd, ex, dt, ct, cs, co;
    IF done THEN
      LEAVE read_loop;
      CLOSE table_columns;
    END IF;
    SELECT CONCAT('\n-- COLUMN ', tname,'.', cn, '\n');
    SELECT CONCAT("SELECT tap.has_column('", sname, "','",tname,"','", cn,"','');");  
    IF nu = 1 THEN
      SELECT CONCAT("SELECT tap.col_is_null('", sname, "','",tname,"','", cn,"','');"); 
    END IF;
    SELECT CONCAT("SELECT tap.col_has_type('", sname, "','",tname,"','", cn,"',", qv(dt), ",'');");
    SELECT CONCAT("SELECT tap.col_column_type_is('", sname, "','",tname,"','", cn, "',", qv(ct), ",'');");
    SELECT CONCAT("SELECT tap.col_extra_is('", sname, "','",tname,"','", cn,"',", qv(ex), ",'');");
    SELECT CONCAT("SELECT tap.col_default_is('", sname, "','",tname,"','", cn,"',", qv(cd), ",'');");
    SELECT CONCAT("SELECT tap.col_charset_is('", sname, "','",tname,"','", cn,"',", qv(cs), ",'');");
    SELECT CONCAT("SELECT tap.col_collation_is('", sname, "','",tname,"','", cn,"',", qv(co), ",'');");
  END LOOP;
END//



DROP PROCEDURE IF EXISTS index_properties //
CREATE PROCEDURE index_properties(sname VARCHAR(64), tname VARCHAR(64))
BEGIN
  DECLARE ix VARCHAR(64); -- index_name
  DECLARE it VARCHAR(16); -- index_type
  DECLARE nu BIGINT;      -- non_unique
  DECLARE ip TEXT;        -- concatenation of the cols that make up a named indexed
  DECLARE done INT DEFAULT FALSE;

  -- INDEX
  DECLARE table_indexes CURSOR FOR
    SELECT s.`index_name`, s.`index_type`, s.`non_unique`,
    GROUP_CONCAT(CONCAT('`', s.`column_name`, '`') ORDER BY s.`seq_in_index`)
    FROM `information_schema`.`statistics` s
    LEFT JOIN `information_schema`.`table_constraints` c
    ON (c.`table_schema` = s.`table_schema` AND c.`table_name` = s.`table_name` AND c.`constraint_name` = s.`index_name`)
    WHERE s.`table_schema` = sname
    AND s.`table_name` = tname
    AND c.`constraint_name` IS NULL
    GROUP BY s.`index_name`, s.`index_type`, s.`non_unique`;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN table_indexes;
  read_loop: LOOP
    FETCH table_indexes INTO ix, it, nu, ip;
    IF done THEN
      LEAVE read_loop;
      CLOSE table_indexes;
    END IF;
    SELECT CONCAT('\n-- INDEX ', tname,'.', ix, '\n');
    SELECT CONCAT("SELECT tap.has_index('", sname, "','",tname,"','", ix,"','');");
    IF nu = 0 THEN
      SELECT CONCAT("SELECT tap.index_is_unique('", sname, "','",tname,"','", ix,"','');"); -- name-based check
      SELECT CONCAT("SELECT tap.col_is_unique('", sname, "','",tname,"','", ip ,"','');"); -- col check
    END IF;
    SELECT CONCAT("SELECT tap.index_is_type('", sname, "','",tname,"','", ix,"','", it ,"','');");
    SELECT CONCAT("SELECT tap.is_indexed('", sname, "','",tname,"','", ip ,"','');");

  END LOOP;
END//


DROP PROCEDURE IF EXISTS trigger_properties //
CREATE PROCEDURE trigger_properties(sname VARCHAR(64), tname VARCHAR(64))
BEGIN
  DECLARE tr VARCHAR(64); -- trigger_name
  DECLARE ao BIGINT(4);   -- action_order 
  DECLARE em VARCHAR(6);  -- event_manipulation 
  DECLARE ta VARCHAR(6);  -- action_timing 
  DECLARE sa LONGTEXT;    -- action_statement 
  DECLARE done INT DEFAULT FALSE;

  -- BASE TABLES  
  DECLARE `table_triggers` CURSOR FOR 
    SELECT `trigger_name`, `action_order`,`event_manipulation`,`action_timing`,`action_statement` 
    FROM `information_schema`.`triggers`
    WHERE `event_object_schema` = sname
    AND `event_object_table` = tname;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN table_triggers;
  read_loop: LOOP 
    FETCH `table_triggers` INTO tr, ao, em, ta, sa;
    IF done THEN
      CLOSE table_triggers;
      LEAVE read_loop;
    END IF;

    SELECT CONCAT('\n-- TRIGGER ', tname,'.', tr, '\n');
    SELECT CONCAT("SELECT tap.has_trigger('", sname, "','",tname,"','", tr,"','');");
    SELECT CONCAT("SELECT tap.trigger_is('", sname, "','",tname,"','", tr,"',", dqv(sa) ,",'');");
    SELECT CONCAT("SELECT tap.trigger_order_is('", sname, "','",tname,"','", tr,"',", ao ,",'');");
    SELECT CONCAT("SELECT tap.trigger_event_is('", sname, "','",tname,"','", tr,"','", em ,"','');");
    SELECT CONCAT("SELECT tap.trigger_timing_is('", sname, "','",tname,"','", tr,"','", ta ,"','');");

  END LOOP;
END //

-- TABLE LEVEL CHECKS
-- triggers, index, column, constraints

DROP PROCEDURE IF EXISTS table_partitions //
CREATE PROCEDURE table_partitions(sname VARCHAR(64), tname VARCHAR(64))
BEGIN
  SET @sname = sname;
  SET @tname = tname;

  SET @parts_sql =
    "SELECT GROUP_CONCAT(CONCAT('`',`ident`,'`')) INTO @parts
    FROM
      (
        SELECT COALESCE(`subpartition_name`,`partition_name`) AS `ident`
        FROM `information_schema`.`partitions`
        WHERE `table_schema` = ?
        AND `table_name` = ?
        AND `partition_name` IS NOT NULL
        GROUP BY `ident`
       ) part";

  PREPARE stmt FROM @parts_sql;
  EXECUTE stmt USING @sname, @tname;
  DEALLOCATE PREPARE stmt;

  SELECT CONCAT("SELECT tap.partitions_are('", @sname, "','",@tname,"','", @parts,"','');");
END //


DROP PROCEDURE IF EXISTS partition_properties //
CREATE PROCEDURE partition_properties(sname VARCHAR(64), tname VARCHAR(64))
BEGIN
  DECLARE pn VARCHAR(64); -- partition_name
  DECLARE sn VARCHAR(64); -- subpartition_name
  DECLARE pm VARCHAR(18); -- partition_method
  DECLARE sm VARCHAR(12); -- subpartition_method
  DECLARE pe LONGTEXT;    -- partition_expression
  DECLARE se LONGTEXT;    -- subpartition_expression
  DECLARE po BIGINT UNSIGNED; -- partition_ordinal_postion
  DECLARE so BIGINT UNSIGNED; -- subpartition_ordinal_postion
  DECLARE done INT DEFAULT FALSE;

  -- Get partitions and sub-partition records
  DECLARE `table_partitions` CURSOR FOR
    SELECT `partition_name`, `subpartition_name`,`partition_method`,`subpartition_method`,
           `partition_expression`,`subpartition_expression`, `partition_ordinal_position`,
           `subpartition_ordinal_position`
    FROM `information_schema`.`partitions`
    WHERE `table_schema` = sname
    AND `table_name` = tname
    AND `partition_name` IS NOT NULL;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN table_partitions;
  read_loop: LOOP
    FETCH `table_partitions` INTO pn, sn, pm, sm, pe, se, po, so;
    IF done THEN
      CLOSE table_partitions;
      LEAVE read_loop;
    END IF;

    SELECT CONCAT_WS('','\n-- PARTITIONS ', tname,'.', pn, '\n');
    CASE
      WHEN po = 1 OR so IS NULL THEN
      -- we don't want to print this for every subpartition
        SELECT CONCAT("SELECT tap.has_partition('", sname, "','",tname,"',", qv(pn),",'');");
        SELECT CONCAT("SELECT tap.partition_method_is('", sname, "','",tname,"',", qv(pn),",", qv(pm) ,",'');");
        SELECT CONCAT("SELECT tap.partition_expression_is('", sname, "','",tname,"',", qv(pn),",", qv(pe) ,",'');");

      WHEN so >= 1 THEN
        SELECT CONCAT("SELECT tap.has_subpartition('", sname, "','",tname,"',", qv(sn),",'');");
        SELECT CONCAT("SELECT tap.subpartition_method_is('", sname, "','",tname,"',", qv(sn),",", qv(sm) ,",'');");
        SELECT CONCAT("SELECT tap.subpartition_expression_is('", sname, "','",tname,"',", qv(sn),",", qv(se) ,",'');");

    END CASE;

  END LOOP;

END//



DELIMITER ;
