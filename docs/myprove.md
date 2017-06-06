---
layout: default
title: My_prove
---

# Running tests with my_prove

As stated on the [Documentation]({% link documentation.md %}) page it is possible to use `my_prove` to run the test harness for your tests.

# Installation

Install the perl module `TAP::Parser::SourceHandler::MyTAP` either from [CPAN](http://search.cpan.org/~dwheeler/TAP-Parser-SourceHandler-MyTAP-3.27/) or by cloning the [GitHub repository](https://github.com/theory/tap-parser-sourcehandler-mytap.git). 

Since the CPAN version (3.27) lags behind the GitHub version (3.28) the GitHub version is installed.

```bash
git clone https://github.com/theory/tap-parser-sourcehandler-mytap.git
# shorten the directory name
mv tap-parser-sourcehandler-mytap myprove
cd myprove
perl Build.PL
```

If necessary install dependencies

```bash
./Build installdeps
./Build manifest
```

Then build the module

```bash
./Build
./Build test
./Build install
```

my_prove is located in myprove/bin

There is a convenience script in `scripts/install_my_prove.sh` that executes these statements.

# Documentation

An explanation of all the commandline parameters of `my_prove` can be found on [CPAN](http://search.cpan.org/~dwheeler/TAP-Parser-SourceHandler-MyTAP-3.27/bin/my_prove).

# Running tests with a shell script

To run the tests with a shell script you can use the MySQL script as explained in [documentation]({% link documentation.md %}).
It shows a line for each TAP test result. Check out the `runtests.sh`. It runs the tests of the MyTAP tests.

If you run this script the output will look like this:

```bash
$ ./runtests.sh USER PAASWORD
============= updating tap =============
============= hastap =============
1..30
ok 1 - tap.has_table(non-existent table) should fail
ok 2 - tap.has_table(non-existent table) should have the proper description
ok 3 - tap.has_table(non-existent table) should have the proper diagnostics
ok 4 - tap.has_table(non-existent schema, tab) should fail
ok 5 - tap.has_table(non-existent schema, tab) should have the proper description
ok 6 - tap.has_table(non-existent schema, tab) should have the proper diagnostics
ok 7 - tap.has_table(sch, tab) should pass
ok 8 - tap.has_table(sch, tab) should have the proper description
ok 9 - tap.has_table(sch, tab) should have the proper diagnostics
ok 10 - tap.has_table(sch, tab, descr) should pass
ok 11 - tap.has_table(sch, tab, descr) should have the proper description
ok 12 - tap.has_table(sch, tab, descr) should have the proper diagnostics
ok 13 - tap.has_table(sch, view, descr) should fail
ok 14 - tap.has_table(sch, view, descr) should have the proper description
ok 15 - tap.has_table(sch, view, descr) should have the proper diagnostics
ok 16 - tap.hasnt_table(non-existent table) should pass
ok 17 - tap.hasnt_table(non-existent table) should have the proper description
ok 18 - tap.hasnt_table(non-existent table) should have the proper diagnostics
ok 19 - tap.hasnt_table(non-existent schema, tab) should pass
ok 20 - tap.hasnt_table(non-existent schema, tab) should have the proper description
ok 21 - tap.hasnt_table(non-existent schema, tab) should have the proper diagnostics
ok 22 - tap.hasnt_table(sch, tab) should fail
ok 23 - tap.hasnt_table(sch, tab) should have the proper description
ok 24 - tap.hasnt_table(sch, tab) should have the proper diagnostics
ok 25 - tap.hasnt_table(sch, tab, descr) should pass
ok 26 - tap.hasnt_table(sch, tab, descr) should have the proper description
ok 27 - tap.hasnt_table(sch, tab, descr) should have the proper diagnostics
ok 28 - tap.hasnt_table(sch, view, descr) should pass

...

ok 27 - has_procedure( sch, non func, desc ) should have the proper diagnostics
ok 28 - hasnt_procedure( sch, func ) should fail
ok 29 - hasnt_procedure( sch, func ) should have the proper description
ok 30 - hasnt_procedure( sch, func ) should have the proper diagnostics
ok 31 - hasnt_procedure( sch, func, desc ) should fail
ok 32 - hasnt_procedure( sch, func, desc ) should have the proper description
ok 33 - hasnt_procedure( sch, func, desc ) should have the proper diagnostics
ok 34 - hasnt_procedure( sch, non func, desc ) should pass
ok 35 - hasnt_procedure( sch, non func, desc ) should have the proper description
ok 36 - hasnt_procedure( sch, non func, desc ) should have the proper diagnostics
```

# Run tests with my_prove

If you use `my_prove` to run the same tests through a TAP test harness which sums up the tests and summarized the results.

When you follow the installation instructions above, running the same tests as in the previous section will look like this:

```bash
$ myprove/bin/my_prove -u USER -p PASSWORD tests/*

tests/coltap.my ....... ok       
tests/eq.my ........... ok     
tests/hastap.my ....... ok     
tests/matching.my ..... ok     
tests/moretap.my ...... ok     
tests/routinestap.my .. ok     
tests/todotap.my ...... ok     
tests/utils.my ........ ok   
tests/viewtap.my ...... ok     
All tests successful.
Files=9, Tests=560,  1 wallclock secs ( 0.08 usr  0.03 sys +  0.05 cusr  0.03 csys =  0.19 CPU)
Result: PASS
```


This gives a better overview of the tests.
