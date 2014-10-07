#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Int::Range::Parser' ) || print "Bail out!\n";
}

diag( "Testing Data::Int::Range::Parser $Data::Int::Range::Parser::VERSION, Perl $], $^X" );
