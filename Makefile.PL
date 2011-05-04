#!/usr/bin/env perl

use 5.008001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'TSS',
    AUTHOR        => 'Sergey Zasenko <undef@cpan.org>',
    LICENSE       => 'perl',
    ABSTRACT_FROM => 'lib/TSS.pm',
    VERSION_FROM  => 'lib/TSS.pm',

    BUILD_REQUIRES => {'Test::More' => '0.88'},
    PREREQ_PM      => {
        'Math::Polynom' => 0,
        'Math::BigInt'  => 0,
    },
    META_MERGE =>
      {resources => {repository => 'http://github.com/und3f/tss',}}
);
