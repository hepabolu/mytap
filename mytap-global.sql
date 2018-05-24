/************************************************************************************/

-- Check the state of GLOBAL variables

DELIMITER //

DROP PROCEDURE IF EXISTS global_var //
CREATE PROCEDURE global_var(IN var VARCHAR(64), OUT val VARCHAR(1024))
DETERMINISTIC
BEGIN
  SET @statement = CONCAT('SELECT @@GLOBAL.', var, ' INTO @lval');

   PREPARE stmt FROM @statement;
   EXECUTE stmt;
   DEALLOCATE PREPARE stmt;

   SET val := @lval;
END //

DROP FUNCTION IF EXISTS global_is //
CREATE FUNCTION global_is(var VARCHAR(64), want VARCHAR(1024), description TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
  IF description = '' THEN
    SET description = CONCAT('GLOBAL variable ' , var, ' should be correctly set');
  END IF;

  CALL global_var(var, @val);

  RETURN eq(@val, want, description);
END //

DELIMITER ;

-- SELECT var_state('event_scheduler', 'ON','');
-- SET @val = '';
-- call global_var('event_scheduler', @val);
-- SELECT @val;

-- SELECT eq(@val,'ON','Event Sheduler Global Variable should be set correctly')
