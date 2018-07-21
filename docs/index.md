---
layout: default
title: Home
---
# MyTAP

MyTAP is a suite of database functions that make it easy to write [TAP](http://testanything.org)-emitting unit tests in mysql scripts. The TAP output is suitable for harvesting, analysis, and reporting by a TAP harness, such as those used in Perl applications.

Why would you want to unit test your database? Well, there are a couple of scenarios in which it can be useful.

# Application Development

So you write MySQL-backed applications, maybe in [Rails](http://rubyonrails.org), or [Django](https://www.djangoproject.com), or [Catalyst](http://www.catalystframework.org), and because you’re an [agile developer](https://en.wikipedia.org/wiki/Agile_software_development), you write lots of tests to make sure that your application works as you practice iterative development. But, as one of the most important parts of your application, should you not also test the database? Sure, you write tests of your API, and the API covers the database, but that’s not really unit testing the database itself, is it?

MyTAP allows you to really test the database, not only verifying the structure of your schema, but also by exercising any views, procedures, functions, or triggers you write. Of course you could use your application’s unit-testing framework to test the database, but by writing your tests with MyTAP, you can keep your database tests simple. Consider these simple tests written with [Test::More](http://search.cpan.org/~exodist/Test-Simple-1.302085/lib/Test/More.pm) and the Perl [DBI](http://search.cpan.org/~timb/DBI-1.636/DBI.pm) to test a custom database function:

    use Test::More tests => 3;
    use DBI;    
    
    my $dbh = DBI->connect('dbi:mysql:database=try', ''root, '' );    
    
    # Start a transaction.
    $dbh->begin;
    END { $dbh->rollback; $dbh->disconnect; }
    my $domain_id = 1;
    my $src_id = 2;    
    
    # Insert stuff.
    ok $dbh->do(
        'SELECT insert_stuff( ?, ?, ?, ?)',
        undef, 'www.foo.com', '1, 2, 3', $domain_id, $src_id
    ), 'Inserting some stuff should return true;    
    
    # Grab the stuff records.
    ok my $stuff = $dbh->selectall_arrayref(q{
        SELECT stuff_id
          FROM domain_stuff
         WHERE domain_id = ?
           AND src_id    = ?
         ORDER BY stuff_id
    }, undef, $domain_id, $src_id), 'Fetch the domain stuff';    
    
    # Make sure we have the right stuff.
    is_deeply $stuff, [ 1, 2, 3 ], 'The rows should have the right stuff';

The upshot is that you have to connect to the database, set up transactions, execute the database functions, fetch back data into Perl data structures, and then compare values. Now consider the equivalent written with MyTAP:

    -- Start a transaction.
    BEGIN;
    SELECT tap.plan( 2 );
    SET @domain_id 1;
    SET @src_id 1;    
    
    -- Insert stuff.
    SELECT tap.ok(
        insert_stuff( 'www.foo.com', '1,2,3', @domain_id, @src_id ),
        'insert_stuff() should return true'
    );    
    
    -- Check for domain stuff records.
    SELECT tap.eq(
        GROUP_CONCAT(stuff_id),
        '1,2,3',
        'The stuff should have been associated with the domain'
    ) FROM domain_stuff
     WHERE domain_id = @domain_id
       AND src_id    = @src_id
     ORDER BY stuff_id;    
    
    CALL finish();
    ROLLBACK;

Now isn’t that a lot easier to read? Unlike the Perl tests, the MyTAP tests can just compare values directly in the database. There is no need to do any extra work to get the database interface to talk to the database, fetch data, convert it, etc. You just use SQL. And if you’re working hard to keep SQL in the database and application code in the application, why would you write database tests in Application code? Just write them in SQL and be done with it!

# Schema Validation

Even better is the scenario in which you need to test your database schema objects, to make sure that everything is where it should be. MyTAP provides a wealth of test functions that make schema testing a snap!:

    BEGIN;
    SELECT tap.plan( 4 );    
    
    SELECT tap.has_table( DATABASE(), 'domains' );
    SELECT tap.has_table( DATABASE(), 'stuff' );
    SELECT tap.has_table( DATABASE(), 'sources' );
    SELECT tap.has_table( DATABASE(), 'domain_stuff' );    
    
    CALL tap.finish();
    ROLLBACK;

And there are many more testing functions to be had. Read the [complete documentation]({{ site.baseurl}}/documentation/) for all the good stuff.

# Library Development

If you’re developing third-party libraries for MySQL, perhaps [writing functions and procedures](https://dev.mysql.com/doc/refman/5.5/en/create-procedure.html) or [user-defined functions](https://dev.mysql.com/doc/refman/5.5/en/adding-functions.html), agile development demands that you write tests as you go. MyTAP makes it easy. See its [own test suite](https://github.com/hepabolu/mytap/tree/master/tests) for a good example of such test-driven developement tests. Running them with [my_prove](http://search.cpan.org/~dwheeler/TAP-Parser-SourceHandler-MyTAP-3.27/bin/my_prove) looks like so:

    % my_prove -u root -D try tests/
    tests/eq.my ........ ok
    tests/hastap.my .... ok
    tests/matching.my .. ok
    tests/moretap.my ... ok
    tests/todotap.my ... ok
    tests/utils.my ..... ok
    All tests successful.
    Files=6, Tests=137,  1 wallclock secs
    (0.06 usr  0.03 sys +  0.01 cusr  0.02 csys =  0.12 CPU)
    Result: PASS


# Get Started

So, what are you waiting for? Download the latest version of MyTAP, or grab fork the [git repository](https://github.com/hepabolu/mytap), read the [documentation]({{ site.baseurl}}/documentation.html), and get going with those tests!

