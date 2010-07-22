-- To run this and have it output TAP:
-- mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --database test --execute 'source /Users/david/Desktop/ok.sql'

SOURCE mytap.sql 

BEGIN;

-- SELECT plan(5);
CALL no_plan();
-- SELECT plan(4);
SELECT ok(1, NULL);
SELECT ok(1, NULL);
SELECT ok(1, 'hey');
SELECT ok(0, 'you');
SELECT ok(1 = 1, 'try an expresssion');
SELECT is_eq(1, 1, NULL);
SELECT is_eq(1, 1, 'Try two ints');
SELECT is_eq(1.0, 1.0, 'Try two numbs');
SELECT is_eq('c', 'c', 'Try two chars');
SELECT is_eq('cbc', 'cbc', 'Try two strings');
SELECT is_eq(null, null, 'Try two nulls');
SELECT is_eq(1, 3, 'fail two ints');
SELECT is_eq('cbc', 'bcb', 'fail two strings');
SELECT is_eq('cbc', NULL, 'fail one null');
SELECT isnt_eq('cbc', NULL, 'isnt_eq with null');
SELECT isnt_eq('cbc', 'bcb', 'isnt_eq with strings');
SELECT isnt_eq('cbc', 'cbc', 'isnt_eq with matching strings');
SELECT isnt_eq(NULL, NULL, 'isnt_eq with NULLs');
select diag('hey\nthere');
SELECT has_table('__tcache__');
CALL finish();

ROLLBACK;
