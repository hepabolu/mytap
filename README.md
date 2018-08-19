![MySQL 5.5](https://img.shields.io/badge/MySQL%205.5-tested-orange.svg) 
![MySQL 5.6](https://img.shields.io/badge/MySQL%205.6-tested-orange.svg) 
![MySQL 5.7](https://img.shields.io/badge/MySQL%205.7-tested-orange.svg) 
![MySQL 8.0](https://img.shields.io/badge/MySQL%208.0-tested-orange.svg) 
[![Build Status](https://travis-ci.org/hepabolu/mytap.svg?branch=master)](https://travis-ci.org/hepabolu/mytap)


MyTAP 1.0
==========

MyTAP is a unit testing framework for MySQL 5.x written using fuctions and
procedures. It includes a collection of TAP-emitting assertion functions, as
well as the ability to integrate with other TAP-emitting test frameworks.

Installation
============

To install MyTAP to a MySQL server, just run the install script from the mytap directory:

    # ./install.sh

This assumes local server access or user and host credentials in ~/.my.cnf.

The installer will create a database called `tap` with 2 tables, import the
base package and any version specific patches. When installation has completed,
the test suite will run automatically. Any errors at this point should be
raised as issues because it will likely indicate a change in the MySQL
`information_schema` or a bug in a MySQL release against which myTAP has not
been tested.

For installations on remote servers, non-standard port numbers, or where client
credentials are not stored, provide the appropriate short or long-form switches
for the required parameters. e.g. 
    
    # ./install.sh --port 3310
    # ./install.sh --user root --password rootpassword 2>/dev/null
    # ./install.sh -h 127.0.0.1 -P 3310 --u root --p rootpassword 2>/dev/null


The installer can run a subset of the tests with the --filter option

    # ./install.sh --filter table

 or, to skip the tests entirely

    # ./install.sh --no-tests

Finally, it is also possible to run the installer in test-only mode (useful for
developers) with

    # ./install.sh --no-install

Short-form versions of all of these switches exist, for full details

    # ./install.sh --help


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
* [Paul Campbell](https://github.com/animalcarpet)

Credits
-------

* Michael Schwern and chromatic for Test::More.
* Adrian Howard for Test::Exception.

Copyright and License
---------------------

Copyright (c) 2010 David E. Wheeler, Helma van der Linden. Some rights reserved.

The full license is available in a separate LICENSE file.

