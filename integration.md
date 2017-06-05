---
layout: default
title: Integration
permalink: /integration/
---

# MyTAP Integration

So you've caught the database testing bug and now you want to
integrate MyTAP tests into your project's test suite. Excellent. You've
come to the right place. Just find your favorite programming language
below and follow along. Don't see your language here yet? If you figure
out how to do it, please send us the instructions!

## Perl

Chances are, if you're writing Perl applications, you're already using
[Test::More](http://search.cpan.org/perldoc/Test::More)
and [Test::Harness](http://search.cpan.org/perldoc/Test::More) to write and run your tests. If you use [Module::Build](http://search.cpan.org/perldoc/Module::Build) to build your application, here's how to hook in MyTAP tests so that they run right along with your Perl tests.

### Requirements

* [Module::Build](http://search.cpan.org/perldoc/Module::Build) 0.36 or later
* [TAP::Parser::SourceHandler::MySQL](http://search.cpan.org/perldoc/TAP::Parser::SourceHandler::MySQL) 3.22 or later

### Instructions

* Put your tests in the `t/` directory of your project, just like the Perl tests. Give them a suffix of “.my”, leaving your Perl tests with a suffix of “.t”. You don't need to set any special variables in the test scripts. They can be as simple as this:

```
    BEGIN;
    SELECT tap.plan( 1 );
    SELECT tap.pass('W00t!');
    CALL tap.finish();
    ROLLBACK;
```

* In `Build.PL`, configure Module::Build like so:

```
    use strict;
    use warnings;
    use Module::Build::DB;    

    Module::Build::DB->new(
        module_name        => 'My::App,
        test_file_exts     => [qw(.t .my)],
        configure_requires => {
            'Module::Build => '0.36',
        },
        build_requires     => {
            'Module::Build                      => '0.36',
            'TAP::Parser::SourceHandler::MySQL' => '3.22',
        },
        tap_harness_args => {
            sources => {
                Perl  => undef,
                MyTAP => {
                    database => 'try',
                    username => 'root',
                    suffix   => '.my',
                },
            },
        },
    )->create_build_script;
```

What this does is tell Module::Build to use TAP::Harness to run tests, rather than Test::Harness, and it tells it to use the MyTAP source handler to run tests with file names ending in “.my”.

* Tweak this as necessary to match your configuration. For example, the database you connect to may not be “try”, and the user may not be “root”. You might also need to specify a host name and port; consult the [TAP::Parser::SourceHandler::MyTAP](http://search.cpan.org/perldoc?TAP::Parser::SourceHandler::MyTAP) documentation to decide what other options you might need to specify. And of course, you should fill in more parameters to `new()` (you probably already have them).

* Now you can run your tests as usual:

```
    ./Build test
    t/perl.t......ok
    t/mytap.my....ok
    All tests successful.
    Files=2, Tests=6,  0 wallclock secs ( 0.03 usr  0.01 sys +  0.03 c 0.02 csys =  0.09 CPU)
    Result: PASS
```

* Profit. Have fun!

Support for running MyTAP tests with [ExtUtils::MakeMaker](http://search.cpan.org/perldoc/ExtUtils::MakeMaker) is planned, as well. Just bug Schwern to commit the patch and release a new version!

## PHP

We're sure there's a way to integrate MyTAP tests with [PHPUnit](http://www.phpunit.de/) or [SnapTest](http://code.google.com/p/snaptest/). If you figure it out, please send the instructions to the [pgtap-users](http://lists.pgfoundry.org/mailman/listinfo/pgtap-users) mail list and we'll add
them to this page!

## Python

We're sure there's a way to integrate MyTAP tests with [PyUnit](http://pyunit.sourceforge.net/). Certainly with [PyTAP](http://git.codesimply.com/?p=PyTAP.git;a=summary/). If you figure it out, please send the instructions to the [pgtap-users](http://lists.pgfoundry.org/mailman/listinfo/pgtap-users) mail list and we'll add
them to this page!

