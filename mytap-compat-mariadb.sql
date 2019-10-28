/* References:
 - https://jira.mariadb.org/browse/MDEV-10959
 - https://mariadb.com/kb/en/library/account-locking/
*/

DROP VIEW IF EXISTS tap.mysql__user;
CREATE SQL SECURITY INVOKER VIEW tap.mysql__user AS
SELECT
    u.`user`
    , u.`host`
    /* ... */
    , u.`password_expired`
    , CASE JSON_EXTRACT(gp.Priv, '$.account_locked')
        WHEN TRUE THEN 'Y'
        ELSE 'N'
        END AS `account_locked`
    , JSON_EXTRACT(gp.Priv, '$.password_lifetime') AS password_lifetime
FROM
    `mysql`.`user` AS u
    JOIN `mysql`.`global_priv` AS gp USING (`user`)
;
