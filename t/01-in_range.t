#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;
require Data::Int::Range::Parser;

##################################################################################
# Setup testing values
##################################################################################
my @range_vals   = (
    '-58..-60..-57..-55','-50..-45..-47','-30..-35','-20..',-10,'-5..-2',  # Negatives ranges
    1, 2, 3,                                                               # Single number groupings
    '5..10','11..','20..15', '21..23..25', '32..30..29..27',               # Positive ranges
);
my $group_token  = ',';
my $range_token  = '..';
my $range_string = join($group_token, @range_vals); 
# Do this after the join above since join's first argument takes a string, not a regex
($group_token, $range_token) = (quotemeta($group_token), quotemeta($range_token));

my @options = (
    {
        # test defaults
        ranges      => [$range_string],
    },
    { 
        # test custom group operator
        ranges      => [do { (my $rs = $range_string) =~ s/$group_token/;/g; $rs }],
        group_token => [';'], 
    },   
    { 
        # test custom range operator
        ranges      => [do { (my $rs = $range_string) =~ s/$range_token/##/g; $rs }],
        range_token => ['##'], 
    },   
    { 
        # test custom range operator AND custom range operator
        ranges      => [do { (my $rs = $range_string) =~ s/$group_token/;/g; $rs =~ s/$range_token/##/g; $rs }],
        group_token => [';'], 
        range_token => ['##'], 
    },   
    { 
        # test multiple ranges by splitting current ranges into 2 separate lists
        ranges      => [split(/$group_token/, $range_string, (scalar(@range_vals)/2))],
    },   

);
##################################################################################


# Is in range
{
    is( $test_range->in_range(2),   1, "Number matched exact range group." );
    is( $test_range->in_range(-10), 1, "Number (negative) matched exact range group." );

    is( $test_range->in_range(6),   1, "Number matched inside range group." );
    is( $test_range->in_range(-4),  1, "Number (negative) matched inside range group." );
    is( $test_range->in_range(5),   1, "Number matched against start of range." );
    is( $test_range->in_range(-5),  1, "Number (negative) matched against start of range." );
    is( $test_range->in_range(10),  1, "Number matched against end of range." );
    is( $test_range->in_range(-2),  1, "Number (negative) matched against end of range." );

    is( $test_range->in_range(11),  1, "Number matched against start of bad/infinite range." );
    is( $test_range->in_range(-20), 1, "Number (negative) matched against start of bad/infinite range." );

    is( $test_range->in_range(15),  1, "Number matched against start of backwards range." );
    is( $test_range->in_range(-30), 1, "Number (negative) matched against start of backwards range." );
    is( $test_range->in_range(20),  1, "Number matched against end of backwards range." );
    is( $test_range->in_range(-35), 1, "Number (negative) matched against end of backwards range." );

    is( $test_range->in_range(21),  1, "Number matched against start of invalid-style range." );
    is( $test_range->in_range(-45), 1, "Number (negative) matched against start of invalid-style range." );
    is( $test_range->in_range(23),  1, "Number matched against middle of invalid-style range." );
    is( $test_range->in_range(-47), 1, "Number (negative) matched against middle of invalid-style range." );
    is( $test_range->in_range(25),  1, "Number matched against end of invalid-style range." );
    is( $test_range->in_range(-45), 1, "Number (negative) matched against end of invalid-style range." );
    is( $test_range->in_range(22),  1, "Number matched inside first range of invalid-style range." );
    is( $test_range->in_range(-46), 1, "Number (negative) matched inside first range of invalid-style range." );
    is( $test_range->in_range(24),  1, "Number matched inside second range of invalid-style range." );
    is( $test_range->in_range(-48), 1, "Number (negative) matched inside second range of invalid-style range." );

    is( $test_range->in_range(32),  1, "Number matched against start of backwards longer-invalid-style range." );
    is( $test_range->in_range(-58), 1, "Number (negative) matched against start of backwards longer-invalid-style range." );
    is( $test_range->in_range(30),  1, "Number matched against middle of backwards longer-invalid-style range." );
    is( $test_range->in_range(-60), 1, "Number (negative) matched against middle of backwards longer-invalid-style range." );
    is( $test_range->in_range(27),  1, "Number matched against end of backwards longer-invalid-style range." );
    is( $test_range->in_range(-55), 1, "Number (negative) matched against end of backwards longer-invalid-style range." );
    is( $test_range->in_range(31),  1, "Number matched inside first range of backwards longer-invalid-style range." );
    is( $test_range->in_range(-59), 1, "Number (negative) matched inside first range of backwards longer-invalid-style range." );
    is( $test_range->in_range(28),  1, "Number matched inside second range of backwards longer-invalid-style range." );
    is( $test_range->in_range(-56), 1, "Number (negative) matched inside second range of backwards longer-invalid-style range." );
}

# Not in range
{
    isnt( $test_range->in_range(4),         1, "Number not in range." );
    isnt( $test_range->in_range(1_000_000), 1, "Number not in range." );
    isnt( $test_range->in_range(-1),        1, "Number (negative) not in range" );
    isnt( $test_range->in_range(12),        1, "Number (possible range_token misinterpretation) not in range." );           
}



##################################################################################
1;



__END__