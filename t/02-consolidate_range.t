#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;
require Data::Int::Range::Parser;


##################################################################################
# Start testing
##################################################################################


subtest '_consolidate_range' => sub {
    my @ranges = ('1..6',2,3,'2..5');

    my $test_range = new_ok( 'Data::Int::Range::Parser');
    is( @{Data::Int::Range::Parser::_consolidate_range(\@ranges)}, @{['1..6']}, "Overlapping ranges cleaned.");
};



done_testing();
##################################################################################
1;



__END__