DROP VIEW IF EXISTS tap.mysql__user;
CREATE SQL SECURITY INVOKER VIEW tap.mysql__user AS
SELECT * FROM `mysql`.`user`
;
