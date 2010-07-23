-- To run this and have it output TAP:
-- mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --database test --execute 'source /Users/david/Desktop/ok.sql'

BEGIN;

SELECT tap.plan(55);
-- CALL no_plan();
SELECT tap.ok(1, NULL);
SELECT tap.ok(1, NULL);
SELECT tap.ok(1, 'hey');
SELECT tap.ok(0, 'you');
SELECT tap.ok(1 = 1, 'try an expresssion');
SELECT tap.is_eq(1, 1, NULL);
SELECT tap.is_eq(1, 1, 'Try two ints');
SELECT tap.is_eq(1.0, 1.0, 'Try two numbs');
SELECT tap.is_eq('c', 'c', 'Try two chars');
SELECT tap.is_eq('cbc', 'cbc', 'Try two strings');
SELECT tap.is_eq(null, null, 'Try two nulls');
SELECT tap.is_eq(1, 3, 'fail two ints');
SELECT tap.is_eq('cbc', 'bcb', 'fail two strings');
SELECT tap.is_eq('cbc', NULL, 'fail one null');
SELECT tap.isnt_eq('cbc', NULL, 'isnt_eq with null');
SELECT tap.isnt_eq('cbc', 'bcb', 'isnt_eq with strings');
SELECT tap.isnt_eq('cbc', 'cbc', 'isnt_eq with matching strings');
SELECT tap.isnt_eq(NULL, NULL, 'isnt_eq with NULLs');
select tap.diag('hey\nthere');
SELECT tap.ok(maxlen > 1, concat(character_set_name, ' should have length > 1'))
      FROM information_schema.character_sets;

SELECT tap.has_table('__tcache__');
CALL tap.finish();

ROLLBACK;
