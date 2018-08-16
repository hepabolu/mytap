---
layout: default
title: Documentation
permalink: /documentation/
---

# {{ page.title }}

__Version: 1.0__

MyTAP is a unit testing framework for MySQL 5.x written using fuctions and
procedures. It includes a collection of TAP-emitting assertion functions, as
well as the ability to integrate with other TAP-emitting test frameworks.

# Installation

To install MyTAP into a MySQL database, just run `install.sh`:

```bash
./install.sh [-? -h -u -p -P -S -i -t -f filter]
```

Switches allow control of the user, password, host, port, and socket for the server instance. The -i and -t switches
allow the installer to run in install-only or test-only mode. The -f switch allows filtering of the block of tests
that sould be run. This will install all of the assertion functions suitable for the MySQL server version, as well
as a cache table, into a database named "tap".

# MyTAP Test Scripts

Here's an example of how to write a MyTAP test script:

```sql
-- Start a transaction.
BEGIN;

-- Plan the tests.
SELECT tap.plan(1);

-- Run the tests.
SELECT tap.pass( 'My test passed, w00t!' );

-- Finish the tests and clean up.
CALL tap.finish();
ROLLBACK;
```

Note how the TAP test functions are reference from another database so as to
keep them separate from your application database.

Now you're ready to run your test script!

```bash
% mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --database test --execute 'source test.sql'
1..1
ok 1 - My test passed, w00t!
```

Yeah, that's rather a lot of options to have to remember to get valid tap. I
suggest that you install
[TAP::Parser::SourceHandler::MyTAP](http://search.cpan.org/dist/TAP-Parser-SourceHandler-MyTAP)
instead and just use its [`my_prove`](http://search.cpan.org/perldoc?my_prove)
utility:

```bash
% my_prove -u root --database test test.sql
```

# Using MyTAP

The purpose of MyTAP is to provide a wide range of testing utilities that
output TAP. TAP, or the "Test Anything Protocol", is an emerging standard for
representing the output from unit tests. It owes its success to its format as
a simple text-based interface that allows for practical machine parsing and
high legibility for humans. TAP started life as part of the test harness for
Perl but now has implementations in C/C++, Python, PHP, JavaScript, Perl,
PostgreSQL, and now MySQL.

## I love it when a plan comes together

Before anything else, you need a testing plan. This basically declares how
many tests your script is going to run to protect against premature failure.

The preferred way to do this is to declare a plan by calling the `plan()`
function:

```sql
SELECT tap.plan( 42 );
```

There are rare cases when you will not know beforehand how many tests your
script is going to run. In this case, you can declare that you have no plan.
(Try to avoid using this as it weakens your test.)

```sql
CALL tap.no_plan();
```

Often, though, you'll be able to calculate the number of tests, like so:

```sql
SELECT plan( COUNT(*) )
  FROM foo;
```

At the end of your script, you should always tell MyTAP that the tests have
completed, so that it can output any diagnostics about failures or a
discrepancy between the planned number of tests and the number actually run:

```sql
CALL tap.finish();
```

## Test names

By convention, each test is assigned a number in order. This is largely done
automatically for you. However, it's often very useful to assign a name to
each test. Would you rather see this?

```
ok 4
not ok 5
ok 6
```

Or this?

```
ok 4 - basic multi-variable
not ok 5 - simple exponential
ok 6 - force == mass * acceleration
```

The latter gives you some idea of what failed. It also makes it easier to find
the test in your script, simply search for "simple exponential".

Many test functions take a name argument. It's optional, but highly suggested
that you use it.

## I'm ok, you're not ok

The basic purpose of MyTAP--and of any TAP-emitting test framework, for that
matter--is to print out either "ok #" or "not ok #", depending on whether a
given test succeeded or failed. Everything else is just gravy.

All of the following functions return "ok" or "not ok" depending on whether
the test succeeded or failed.

### `ok( boolean, description )` ###

```sql
SELECT tap.ok( @this = @that, @description );
```

This function simply evaluates any expression (`@this = @that` is just a
simple example) and uses that to determine if the test succeeded or failed. A
true expression passes, a false one fails. Very simple.

For example:

```sql
SELECT tap.ok( 9 ^ 2 = 81,    'simple exponential' );
SELECT tap.ok( 9 < 10,        'simple comparison' );
SELECT tap.ok( 'foo' ~ '^f',  'simple regex' );
SELECT tap.ok( active,        concat(name, ' widget active' ))
  FROM widgets;
```

(Mnemonic:  "This is ok.")

The `@description` is a very short description of the test that will be printed
out. It makes it very easy to find a test in your script when it fails and
gives others an idea of your intentions. The description is optional, but we
*very* strongly encourage its use.

Should an `ok()` fail, it will produce some diagnostics:

```
not ok 18 - sufficient mucus
#     Failed test 18: "sufficient mucus"
```

Furthermore, should the boolean test result argument be passed as a `NULL`,
`ok()` will assume a test failure and attach an additional diagnostic:

```
not ok 18 - sufficient mucus
#     Failed test 18: "sufficient mucus"
#     (test result was NULL)
```

### `eq( anyelement, anyelement, description )` ###
### `not_eq( anyelement, anyelement, description )` ###

```sql
SELECT tap.eq(   @this, @that, @description );
SELECT tap.not_eq( @this, @that, @description );
```

Similar to `ok()`, `eq()` and `not_eq()` compare their two arguments with `=`
AND `<>`, respectively, and use the result of that to determine if the test
succeeded or failed. So these:

```sql
-- Is the ultimate answer 42?
SELECT tap.eq( ultimate_answer(), 42, 'Meaning of Life' );

-- foo() doesn't return empty
SELECT tap.not_eq( foo(), '', 'Got some foo' );
```

are similar to these:

```sql
SELECT tap.ok(   ultimate_answer() =  42, 'Meaning of Life' );
SELECT tap.isnt( foo()             <> '', 'Got some foo'    );
```

(Mnemonic: "This is that." "This isn't that.")

*Note:* `NULL`s are not treated as unknowns by `eq()` or `not_eq()`. That
is, if `@this` and `@that` are both `NULL`, the test will pass, and if only
one of them is `NULL`, the test will fail.

So why use these test functions? They produce better diagnostics on failure.
`ok()` cannot know what you are testing for (beyond the description), but
`eq()` and `not_eq()` know what the test was and why it failed. For
example this test:

```sql
SELECT tap.eq( 'waffle', 'yarblokos', 'Is foo the same as bar?' );
```

Will produce something like this:

```
# Failed test 17:  "Is foo the same as bar?"
#         have: waffle
#         want: yarblokos
```

So you can figure out what went wrong without re-running the test.

You are encouraged to use `eq()` and `not_eq()` over `ok()` where
possible.

### `matches( anyelement, regex, description )` ###

```sql
SELECT matches( @this, '^that', @description );
```

Similar to `eq()`, `matches()` matches `@this` against the regex `/^that/`.

So this:

```sql
SELECT matches( @this, '^that', 'this is like that' );
```

is similar to:

```sql
SELECT ok( @this REGEXP '^that', 'this is like that' );
```

(Mnemonic "This matches that".)

Its advantages over `ok()` are similar to that of `eq()` and `not_eq()`: Better
diagnostics on failure.

### `doesnt_match( anyelement, regex, description )` ###

```sql
SELECT doesnt_match( @this, '^that', @description );
```

This functions works exactly as `matches()` does, only it checks if `@this`
*does not* match the given pattern.

### `alike( anyelement, pattern, description )` ###

```sql
SELECT alike( @this, 'that%', @description );
```

Similar to `matches()`, `alike()` matches `@this` against the SQL `LIKE`
pattern 'that%'. So this:

```sql
SELECT alike( @this, 'that%', 'this is alike that' );
```

is similar to:

```sql
SELECT ok( @this LIKE 'that%', 'this is like that' );
```

(Mnemonic "This is like that".)

Its advantages over `ok()` are similar to that of `eq()` and `not_eq()`:
Better diagnostics on failure.

### `unalike( anyelement, pattern, description )` ###

```sql
SELECT unalike( @this, 'that%', @description );
```

Works exactly as `alike()`, only it checks if `@this` *does not* match the
given pattern.

### `pass( description )` ###
### `fail( description )` ###

```sql
SELECT tap.pass( @description );
SELECT tap.fail( @description );
```

Sometimes you just want to say that the tests have passed. Usually the case is
you've got some complicated condition that is difficult to wedge into an
`ok()`. In this case, you can simply use `pass()` (to declare the test ok) or
`fail()` (for not ok). They are synonyms for `ok(1, @description)` and
`ok(0, @description)`.

Use these functions very, very, very sparingly.

## The Schema Things

Need to make sure that your database is designed just the way you think it
should be? Use these test functions and rest easy.

A note on comparisons: MyTAP uses a simple equivalence test (`=`) to compare
identifier names.

2018-07-21 Update: because the number of tests available has been expanded considerably, the individual tests are moved to a different file for better overview. You can now find them under [Tests]({{ site.baseurl}}/tests/).


# No Test for the Wicked

There is more to MyTAP. Oh *so* much more! You can output your own
[diagnostics](#Diagnostics). You can write [conditional
tests](#Conditional+Tests) based on the output of [utility
functions](#Utility+Functions). You can [batch up tests in
functions](#Tap+That+Batch). Read on to learn all about it.

## Diagnostics

If you pick the right test function, you'll usually get a good idea of what
went wrong when it failed. But sometimes it doesn't work out that way. So here
we have ways for you to write your own diagnostic messages which are safer
than just `\echo` or `SELECT foo`.

### `diag( text )` ###

Returns a diagnostic message which is guaranteed not to interfere with
test output. Handy for this sort of thing:

```sql
-- Output a diagnostic message if the collation is not en_US.UTF-8.
SELECT tap.diag(concat(
     'These tests expect CHARACTER_SET_DATABASE to be en_US.UTF-8,\n',
     'but yours is set to ', VARIABLE_VALUE, '.\n',
     'As a result, some tests may fail. YMMV.'
))
  FROM information_schema.global_variables
 WHERE VARIABLE_NAME = 'CHARACTER_SET_DATABASE'
   AND VARIABLE_VALUE <> 'utf-8'
```

Which would produce:

```
# These tests expect CHARACTER_SET_DATABASE to be en_US.UTF-8,
# but yours is set to latin1.
# As a result, some tests may fail. YMMV.
```

## Conditional Tests

Sometimes running a test under certain conditions will cause the test script
or function to die. A certain function or feature isn't implemented (such as
`information_schema.global_variables()` prior to MySQL 5.1), some resource
isn't available (like a replication), or a third party library isn't
available. In these cases it's necessary to skip tests, or declare that they
are supposed to fail but will work in the future (a todo test).

### `skip( how_many, why )` ###

Outputs SKIP test results. Use it in a conditional expression within a
`SELECT` statement to replace the output of a test that you otherwise would
have run.

```sql
SELECT CASE WHEN mysql_version() < 501000
    THEN skip(1, 'ExtractValue() not supported before 5.1' )
    ELSE ok( ExtractValue('<a><b/></a>', 'count(/a/b)'), 'ExtractValue should work')
END;

SELECT CASE WHEN mysql_version() < 501000
    THEN skip(2, 'ExtractValue() not supported before 5.1' )
    ELSE concat(
        ok( ExtractValue('<a><b/></a>', 'count(/a/b)'), 'ExtractValue should work'),
        '\n',
        ok( ExtractValue('<a><b/></a>', 'count(/a/b)'), 'ExtractValue should work')
    )
END;
```

Note how use of the conditional `CASE` statement has been used to determine
whether or not to run a couple of tests. If they are to be run, they are run
through `concat()`, so that we can run a few tests in the same query. If we
don't want to run them, we call `skip()` and tell it how many tests we're
skipping.

### `todo( how_many, why )` ###

Declares a series of tests that you expect to fail and why. Perhaps it's
because you haven't fixed a bug or haven't finished a new feature:

```sql
SELECT todo(2, 'URIGeller not finished');

SET card 'Eight of clubs';
SELECT eq( yourCard(), @card, 'Is THIS your card?' );
SELECT eq( bendSpoon(), 'bent', 'Spoon bending, how original' );
```

With `todo()`, `@how_many` specifies how many tests are expected to fail.
myTAP will run the tests normally, but print out special flags indicating they
are "todo" tests. The test harness will interpret these failures as ok. Should
any todo test pass, the harness will report it as an unexpected success. You
then know that the thing you had todo is done and can remove the call to
`todo()`.

The nice part about todo tests, as opposed to simply commenting out a block of
tests, is that they're like a programmatic todo list. You know how much work
is left to be done, you're aware of what bugs there are, and you'll know
immediately when they're fixed.

### `todo_start( why )` ###

This function allows you declare all subsequent tests as TODO tests, up until
the `todo_end()` function is called.

The `todo()` syntax is generally pretty good about figuring out whether or not
we're in a TODO test. However, often we find it difficult to specify the
*number* of tests that are TODO tests. Thus, you can instead use
`todo_start()` and `todo_end()` to more easily define the scope of your TODO
tests.

Note that you can nest TODO tests, too:

```sql
SELECT todo_start('working on this');
-- lots of code
SELECT todo_start('working on that');
-- more code
SELECT todo_end();
SELECT todo_end();
```

This is generally not recommended, but large testing systems often have weird
internal needs.

The `todo_start()` and `todo_end()` function should also work with the
`todo()` function, although it's not guaranteed and its use is also
discouraged:

```sql
SELECT todo_start('working on this');
-- lots of code
SELECT todo(2, 'working on that');
-- Two tests for which the above line applies
-- Followed by more tests scoped till the following line.
SELECT todo_end();
```

We recommend that you pick one style or another of TODO to be on the safe
side.

### todo_end() ###

Stops running tests as TODO tests. This function is fatal if called without a
preceding `todo_start()` method call.

### in_todo() ###

Returns true if the test is currently inside a TODO block.

## Utility Functions

Along with the usual array of testing, planning, and diagnostic functions,
pTAP provides a few extra functions to make the work of testing more pleasant.

### `mytap_version()` ###

```sql
SELECT mytap_version();
```

Returns the version of MyTAP installed in the server. The value is `NUMERIC`,
and thus suitable for comparing to a decimal value.

### `mysql_version()` ###

```sql
SELECT mysql_version();
```

Returns an integer representation of the server version number. This function
is useful for determining whether or not certain tests should be run or
skipped (using `skip()`) depending on the version of MySQL. For example:

```sql
SELECT CASE WHEN mysql_version() < 501000
    THEN skip('ExtractValue() not supported before 5.1' )
    ELSE ok( ExtractValue('<a><b/></a>', 'count(/a/b)'), 'ExtractValue should work')
END;
```
The revision level is in the hundreds position, the minor version in the ten
thousands position, and the major version in the hundred thousands position
and above (assuming MySQL 10 is ever released, it will be in the millions
position).

# Compose Yourself

So, you've been using MyTAP for a while, and now you want to write your own
test functions. Go ahead; I don't mind. In fact, I encourage it. How? Why,
by providing a function you can use to test your tests, of course!

But first, a brief primer on writing your own test functions. There isn't much
to it, really. Just write your function to do whatever comparison you want. As
long as you have a boolean value indicating whether or not the test passed,
you're golden. Just then use `ok()` to ensure that everything is tracked
appropriately by a test script.

For example, say that you wanted to create a function to ensure that two text
values always compare case-insensitively. Sure you could do this with
`eq()` and the `LOWER()` function, but if you're doing this all the time,
you might want to simplify things. Here's how to go about it:

```sql
DROP FUNCTION IF EXITS lc_is
DELIMITER //
CREATE FUNCTION lc_is (have TEXT, want TEXT, descr TEXT)
RETURNS TEXT
BEGIN
    IF LOWER(have) = LOWER(want) THEN
        RETURN ok(1, descr);
    END IF;
    RETURN concat(ok( 0, descr ), '\n', diag(concat(
           '    Have: ', have,
         '\n    Want: ', want
    )));
END //

DELIMITER ;
```

Yep, that's it. The key is to always use MyTAP's `ok()` function to guarantee
that the output is properly formatted, uses the next number in the sequence,
and the results are properly recorded in the database for summarization at
the end of the test script. You can also provide diagnostics as appropriate;
just append them to the output of `ok()` as we've done here.

Of course, you don't have to directly use `ok()`; you can also use another
MyTAP function that ultimately calls `ok()`. IOW, while the above example
is instructive, this version is easier on the eyes:

```sql
CREATE FUNCTION lc_is ( have TEXT, want TEXT, descr TEXT )
RETURNS TEXT
BEGIN
     RETURN eq( LOWER(have), LOWER(want), descr);
END //
```
But either way, let MyTAP handle recording the test results and formatting the
output.

## Testing Test Functions

Now you've written your test function. So how do you test it? Why, with this
handy-dandy test function!

### `check_test( test_output, is_ok, name, want_description, want_diag, match_diag )` ###

```sql
SELECT check_test(
    lc_eq('This', 'THAT', 'not eq'),
    0,
    'lc_eq fail',
    'not eq',
    '    Want: this\n    Have: that'
);

SELECT check_test(
    lc_eq('This', 'THIS', 'eq'),
    1
);
```

This function runs anywhere between one and three tests against a test
function. For the impatient, the arguments are:

* `@test_output` - The output from your test. Usually it's just returned by a
  call to the test function itself. Required.
* `@is_ok` - Boolean indicating whether or not the test is expected to pass.
  Required.
* `@name` - A brief name for your test, to make it easier to find failures in
  your test script. Optional.
* `@want_description` - Expected test description to be output by the test.
  Optional. Use an empty string to test that no description is output.
* `@want_diag` - Expected diagnostic message output during the execution of
  a test. Must always follow whatever is output by the call to `ok()`.
  Optional. Use an empty string to test that no description is output.
* `@match_diag` - Use `matches()` to compare the diagnostics rather than
  `@eq()`. Useful for those situations where you're not sure what will be
  in the output, but you can match it with a regular expression.

Now, on with the detailed documentation. At its simplest, you just pass in the
output of your test function (and it must be one and **only one** test
function's output, or you'll screw up the count, so don't do that!) and a
boolean value indicating whether or not you expect the test to have passed.
That looks something like the second example above.

All other arguments are optional, but I recommend that you *always* include a
short test name to make it easier to track down failures in your test script.
`check_test()` uses this name to construct descriptions of all of the tests it
runs. For example, without a short name, the above example will yield output
like so:

```
not ok 14 - Test should pass
```

Yeah, but which test? So give it a very succinct name and you'll know what
test. If you have a lot of these, it won't be much help. So give each call
to `check_test()` a name:

```sql
SELECT check_test(
    lc_eq('This', 'THIS', 'eq'),
    true,
    'Simple lc_eq test',
);
```

Then you'll get output more like this:

```sql
not ok 14 - Simple lc_test should pass
```

Which will make it much easier to find the failing test in your test script.

The optional fourth argument is the description you expect to be output. This
is especially important if your test function generates a description when
none is passed to it. You want to make sure that your function generates the
test description you think it should! This will cause a second test to be run
on your test function. So for something like this:

```sql
SELECT check_test(
    lc_eq( ''this'', ''THIS'' ),
    true,
    'lc_eq() test',
    'this is THIS'
);
```
The output then would look something like this, assuming that the `lc_eq()`
function generated the proper description (the above example does not):

```
ok 42 - lc_eq() test should pass
ok 43 - lc_eq() test should have the proper description
```
See how there are two tests run for a single call to `check_test()`? Be sure
to adjust your plan accordingly. Also note how the test name was used in the
descriptions for both tests.

If the test had failed, it would output a nice diagnostics. Internally it just
uses `eq()` to compare the strings:

```
# Failed test 43:  "lc_eq() test should have the proper description"
#         have: 'this is this'
#         want: 'this is THIS'
```

The fifth argument, `@want_diag`, which is also optional, compares the
diagnostics generated during the test to an expected string. Such diagnostics
**must** follow whatever is output by the call to `ok()` in your test. Your
test function should not call `diag()` until after it calls `ok()` or things
will get truly funky.

Assuming you've followed that rule in your `lc_eq()` test function, see what
happens when a `lc_eq()` fails. Write your test to test the diagnostics like
so:

```sql
SELECT * FROM check_test(
    lc_eq( ''this'', ''THat'' ),
    false,
    'lc_eq() failing test',
    'this is THat',
    '    Want: this\n    Have: THat'
);
```

This of course triggers a third test to run. The output will look like so:

```
ok 44 - lc_eq() failing test should fail
ok 45 - lc_eq() failing test should have the proper description
ok 46 - lc_eq() failing test should have the proper diagnostics
```
And of course, it the diagnostic test fails, it will output diagnostics just
like a description failure would, something like this:

```
# Failed test 46:  "lc_eq() failing test should have the proper diagnostics"
#         have:     Have: this
#     Want: that
#         want:     Have: this
#     Want: THat
```

If you pass in the optional sixth argument, `@match_diag`, the `@want_diag`
argument will be compared to the actual diagnostic output using `matches()`
instead of `eq()`. This allows you to use a regular expression in the
`@want_diag` argument to match the output, for those situations where some
part of the output might vary, such as time-based diagnostics.

I realize that all of this can be a bit confusing, given the various haves and
wants, but it gets the job done. Of course, if your diagnostics use something
other than indented "have" and "want", such failures will be easier to read.
But either way, *do* test your diagnostics!

## To Do

* Port lot of other assertion functions from [pgTAP](http://pgtap.org/).

## Public Repository

The source code for MyTAP is available on
[GitHub](http://github.com/hepabolu/mytap/). Please feel free to fork and
contribute!
