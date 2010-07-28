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
SELECT tap.eq(1, 1, NULL);
SELECT tap.eq(1, 1, 'Try two ints');
SELECT tap.eq(1.0, 1.0, 'Try two numbs');
SELECT tap.eq('c', 'c', 'Try two chars');
SELECT tap.eq('cbc', 'cbc', 'Try two strings');
SELECT tap.eq(null, null, 'Try two nulls');
SELECT tap.eq(1, 3, 'fail two ints');
SELECT tap.eq('cbc', 'bcb', 'fail two strings');
SELECT tap.eq('cbc', NULL, 'fail one null');
SELECT tap.not_eq('cbc', NULL, 'not_eq with null');
SELECT tap.not_eq('cbc', 'bcb', 'not_eq with strings');
SELECT tap.not_eq('cbc', 'cbc', 'not_eq with matching strings');
SELECT tap.not_eq(NULL, NULL, 'not_eq with NULLs');
select tap.diag('hey\nthere');
SELECT tap.ok(maxlen > 1, concat(character_set_name, ' should have length > 1'))
      FROM information_schema.character_sets;

SELECT tap.has_table('tap', '__tcache__');
CALL tap.finish();

ROLLBACK;
