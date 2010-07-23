MyTAP 0.01
==========

MyTAP is a unit testing framework for MySQL 5.x written using fuctions and
procedures. It includes a collection of TAP-emitting assertion functions, as
well as the ability to integrate with other TAP-emitting test frameworks.

Installation
============

To install MyTAP into a MySQL database, just run `mytap.sql`:

    mysql -u root < mytap.sql

This will install all of the assertion functions, as well as a cache table,
into a database named "tap".

MyTAP Test Scripts
==================

Here's an example of how to write a MyTAP test script:

    -- Start a transaction.
    BEGIN;

    -- Plan the tests.
    SELECT tap.plan(1);

    -- Run the tests.
    SELECT tap.pass( 'My test passed, w00t!' );

    -- Finish the tests and clean up.
    CALL tap.finish();
    ROLLBACK;

Note how the TAP test functions are reference from another database so as to
keep them separate from your application database.

Now you're ready to run your test script!

    % mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --database test --execute 'source test.sql'
    1..1
    ok 1 - My test passed, w00t!

Using MyTAP
===========

The purpose of MyTAP is to provide a wide range of testing utilities that
output TAP. TAP, or the "Test Anything Protocol", is an emerging standard for
representing the output from unit tests. It owes its success to its format as
a simple text-based interface that allows for practical machine parsing and
high legibility for humans. TAP started life as part of the test harness for
Perl but now has implementations in C/C++, Python, PHP, JavaScript, Perl,
PostgreSQL, and now MySQL.

I love it when a plan comes together
------------------------------------

Before anything else, you need a testing plan. This basically declares how
many tests your script is going to run to protect against premature failure.

The preferred way to do this is to declare a plan by calling the `plan()`
function:

    SELECT tap.plan( 42 );

There are rare cases when you will not know beforehand how many tests your
script is going to run. In this case, you can declare that you have no plan.
(Try to avoid using this as it weakens your test.)

    CALL tap.no_plan();

Often, though, you'll be able to calculate the number of tests, like so:

    SELECT plan( COUNT(*) )
      FROM foo;

At the end of your script, you should always tell MyTAP that the tests have
completed, so that it can output any diagnostics about failures or a
discrepancy between the planned number of tests and the number actually run:

    CALL tap.finish();

Test names
----------

By convention, each test is assigned a number in order. This is largely done
automatically for you. However, it's often very useful to assign a name to
each test. Would you rather see this?

      ok 4
      not ok 5
      ok 6

Or this?

      ok 4 - basic multi-variable
      not ok 5 - simple exponential
      ok 6 - force == mass * acceleration

The latter gives you some idea of what failed. It also makes it easier to find
the test in your script, simply search for "simple exponential".

Many test functions take a name argument. It's optional, but highly suggested
that you use it.

I'm ok, you're not ok
---------------------

The basic purpose of MyTAP--and of any TAP-emitting test framework, for that
matter--is to print out either "ok #" or "not ok #", depending on whether a
given test succeeded or failed. Everything else is just gravy.

All of the following functions return "ok" or "not ok" depending on whether
the test succeeded or failed.

### `ok( boolean, description )` ###
### `ok( boolean )` ###

    SELECT tap.ok( @this = @that, @description );

This function simply evaluates any expression (`@this = @that` is just a
simple example) and uses that to determine if the test succeeded or failed. A
true expression passes, a false one fails. Very simple.

For example:

    SELECT tap.ok( 9 ^ 2 = 81,    'simple exponential' );
    SELECT tap.ok( 9 < 10,        'simple comparison' );
    SELECT tap.ok( 'foo' ~ '^f',  'simple regex' );
    SELECT tap.ok( active = true, name ||  widget active' )
      FROM widgets;

(Mnemonic:  "This is ok.")

The `@description` is a very short description of the test that will be printed
out. It makes it very easy to find a test in your script when it fails and
gives others an idea of your intentions. The description is optional, but we
*very* strongly encourage its use.

Should an `ok()` fail, it will produce some diagnostics:

    not ok 18 - sufficient mucus
    #     Failed test 18: "sufficient mucus"

Furthermore, should the boolean test result argument be passed as a `NULL`,
`ok()` will assume a test failure and attach an additional diagnostic:

    not ok 18 - sufficient mucus
    #     Failed test 18: "sufficient mucus"
    #     (test result was NULL)

### `is_eq( anyelement, anyelement, description )` ###
### `is_eq( anyelement, anyelement )` ###
### `isnt_eq( anyelement, anyelement, description )` ###
### `isnt_eq( anyelement, anyelement )` ###

    SELECT tap.is_eq(   @this, @that, @description );
    SELECT tap.isnt_eq( @this, @that, @description );

Similar to `ok()`, `is_eq()` and `isnt_eq()` compare their two arguments with
`=` AND `<>`, respectively, and use the result of that to determine if the
test succeeded or failed. So these:

    -- Is the ultimate answer 42?
    SELECT tap.is_eq( ultimate_answer(), 42, 'Meaning of Life' );

    -- foo() doesn't return empty
    SELECT tap.isnt_eq( foo(), '', 'Got some foo' );

are similar to these:

    SELECT tap.ok(   ultimate_answer() =  42, 'Meaning of Life' );
    SELECT tap.isnt( foo()             <> '', 'Got some foo'    );

(Mnemonic: "This is that." "This isn't that.")

*Note:* `NULL`s are not treated as unknowns by `is_eq()` or `isnt_eq()`. That
is, if `@this` and `@that` are both `NULL`, the test will pass, and if only
one of them is `NULL`, the test will fail.

So why use these test functions? They produce better diagnostics on failure.
`ok()` cannot know what you are testing for (beyond the description), but
`is_eq()` and `isnt_eq()` know what the test was and why it failed. For
example this test:

    SELECT tap.is_eq( 'waffle', 'yarblokos', 'Is foo the same as bar?' );

Will produce something like this:

    # Failed test 17:  "Is foo the same as bar?"
    #         have: waffle
    #         want: yarblokos

So you can figure out what went wrong without re-running the test.

You are encouraged to use `is_eq()` and `isnt_eq()` over `ok()` where
possible.

### `pass( description )` ###
### `pass()` ###
### `fail( description )` ###
### `fail()` ###

    SELECT tap.pass( @description );
    SELECT tap.fail( @description );

Sometimes you just want to say that the tests have passed. Usually the case is
you've got some complicated condition that is difficult to wedge into an
`ok()`. In this case, you can simply use `pass()` (to declare the test ok) or
`fail()` (for not ok). They are synonyms for `ok(1, @description)` and
`ok(0, @description)`.

Use these functions very, very, very sparingly.

The Schema Things
=================

Need to make sure that your database is designed just the way you think it
should be? Use these test functions and rest easy.

A note on comparisons: pgTAP uses a simple equivalence test (`=`) to compare

### `has_table( table, description )` ###
### `has_table( table )` ###

    SELECT has_table(
        'sometable',
        'I got sometable'
    );

This function tests whether or not a table exists in the database. The first
argument is a table name and the second is the (optional) test description. If
you omit the test description, it will be set to "Table `:table` should
exist".

No Test for the Wicked
======================

There is more to MyTAP. Oh *so* much more! You can output your own
[diagnostics](#Diagnostics). You can write [conditional
tests](#Conditional+Tests) based on the output of [utility
functions](#Utility+Functions). You can [batch up tests in
functions](#Tap+That+Batch). Read on to learn all about it.

Diagnostics
-----------

If you pick the right test function, you'll usually get a good idea of what
went wrong when it failed. But sometimes it doesn't work out that way. So here
we have ways for you to write your own diagnostic messages which are safer
than just `\echo` or `SELECT foo`.

### `diag( text )` ###

Returns a diagnostic message which is guaranteed not to interfere with
test output. Handy for this sort of thing:

    -- Output a diagnostic message if the collation is not en_US.UTF-8.
    SELECT tap.diag(concat(
         'These tests expect CHARACTER_SET_DATABASE to be en_US.UTF-8,\n',
         'but yours is set to ', VARIABLE_VALUE, '.\n',
         'As a result, some tests may fail. YMMV.'
    ))
      FROM information_schema.global_variables
     WHERE VARIABLE_NAME = 'CHARACTER_SET_DATABASE'
       AND VARIABLE_VALUE <> 'utf-8'

Which would produce:

    # These tests expect CHARACTER_SET_DATABASE to be en_US.UTF-8,
    # but yours is set to latin1.
    # As a result, some tests may fail. YMMV. 

Utility Functions
-----------------

Along with the usual array of testing, planning, and diagnostic functions,
pTAP provides a few extra functions to make the work of testing more pleasant.

### `mytap_version()` ###

    SELECT mytap_version();

Returns the version of MyTAP installed in the server. The value is `NUMERIC`,
and thus suitable for comparing to a decimal value.

Compose Yourself
================

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
`is_eq()` and the `LOWER()` function, but if you're doing this all the time,
you might want to simplify things. Here's how to go about it:

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


Yep, that's it. The key is to always use MyTAP's `ok()` function to guarantee
that the output is properly formatted, uses the next number in the sequence,
and the results are properly recorded in the database for summarization at
the end of the test script. You can also provide diagnostics as appropriate;
just append them to the output of `ok()` as we've done here.

Of course, you don't have to directly use `ok()`; you can also use another
MyTAP function that ultimately calls `ok()`. IOW, while the above example
is instructive, this version is easier on the eyes:

    CREATE FUNCTION lc_is ( have TEXT, want TEXT, descr TEXT )
    RETURNS TEXT
    BEGIN
         RETURN is( LOWER(have), LOWER(want), descr);
    END //

But either way, let MyTAP handle recording the test results and formatting the
output.

To Do
-----
* Port lot of other assertion functions from [pgTAP](http://pgtap.org/).

Public Repository
-----------------

The source code for MyTAP is available on
[GitHub](http://github.com/theory/mytap/). Please feel free to fork and
contribute!

Author
------

[David E. Wheeler](http://justatheory.com/)

Credits
-------

* Michael Schwern and chromatic for Test::More.
* Adrian Howard for Test::Exception.

Copyright and License
---------------------

Copyright (c) 2010 David E. Wheeler. Some rights reserved.

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose, without fee, and without a written agreement is
hereby granted, provided that the above copyright notice and this paragraph
and the following two paragraphs appear in all copies.

IN NO EVENT SHALL KINETICODE BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING
OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF KINETICODE HAS
BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

KINETICODE SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND
KINETICODE HAS NO OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
ENHANCEMENTS, OR MODIFICATIONS.
