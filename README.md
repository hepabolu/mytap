MyTAP 0.07
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

Yeah, that's rather a lot of options to have to remember to get valid tap. I
suggest that you install
[TAP::Parser::SourceHandler::MyTAP](http://search.cpan.org/dist/TAP-Parser-SourceHandler-MyTAP)
instead and just use its [`my_prove`](http://search.cpan.org/perldoc?my_prove)
utility:

    % my_prove -u root --database test test.sql

Using MyTAP
===========

The purpose of MyTAP is to provide a wide range of testing utilities that
output TAP. TAP, or the "Test Anything Protocol", is an emerging standard for
representing the output from unit tests. It owes its success to its format as
a simple text-based interface that allows for practical machine parsing and
high legibility for humans. TAP started life as part of the test harness for
Perl but now has implementations in C/C++, Python, PHP, JavaScript, Perl,
PostgreSQL, and now MySQL.

More information on the use of MyTAP can be found in the [documentation](https://hepabolu.github.io/mytap).


To Do
-----
* Port lot of other assertion functions from [pgTAP](http://pgtap.org/).

Public Repository
-----------------

The source code for MyTAP is available on
[GitHub](http://github.com/hepabolu/mytap/). Please feel free to fork and
contribute!

Authors
------

* [David E. Wheeler](http://justatheory.com/)
* [Hepabolu](https://github.com/hepabolu/mytap)

Credits
-------

* Michael Schwern and chromatic for Test::More.
* Adrian Howard for Test::Exception.

Copyright and License
---------------------

Copyright (c) 2010 David E. Wheeler, Helma van der Linden. Some rights reserved.

The full license is available in a separate LICENSE file.

