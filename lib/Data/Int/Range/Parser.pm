package Data::Int::Range::Parser;

use 5.008;
use strict;
use warnings;
use warnings::register;
use Carp;
use List::Util qw/min max/;
require Exporter;

our @ISA       = qw/Exporter/;
our @EXPORT_OK = qw/clean_range/;

=head1 TODO

1. Handle spaces in groups (like '1, 2' such that split ',', "1, 2" does not give '1' and ' 2' but '1' and '2')

2. Be sure to handle numbers correct. \d+ doesn't match 1_000_000 which is a valid number to perl.

3. Add option for ignoring quoted fields and/or non-numbers

=head1 NAME

Data::Int::Range::Parser - Parse Perl number ranges.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Handle integer ranges.

    use Data::Int::Range::Parser;

    my $range = Data::Int::Range::Parser->new( 
        range     => ['1..3', 5, 6, '8-10', '15..11'],
    );

    say $range->as_string;
    # 1..3, 5, 6, 8..10, 11..15

    say $range->as_ints;
    # 1, 2, 3, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15

    $range->set_explicit_reverse(1);
    say $range->as_ints;
    # 1, 2, 3, 5, 6, 8, 9, 10, 15, 14, 13, 12, 11



    $range->set_no_reverse(1);

    say $range->as_string;
    # 1..3, 5, 6, 8..10, 15..11

    $range->set_explicit_reverse(1);
    say $range->as_string;
    # 1..3, 5, 6, 8,..10, 15, 14, 13, 12, 11

=head1 DESCRIPTION

Number range library. Turn strings into ranges, modify ranges, turn ranges into regexes, validate ranges, etc.

=head1 METHODS

=head2 new

Create new Data::Int::Range::Parser object.

=cut

sub new {
    my ($class, $args) = (shift, shift);
    my $self  = {};

    $self->{ranges}           = exists $args->{ranges}           ?$args->{ranges}         :[];

    # Probably need to quotemeta these values from user input
    $self->{group_token}      = exists $args->{group_token}      ?$args->{group_token}    :[','];   # These can be regexes
    $self->{range_token}      = exists $args->{range_token}      ?$args->{range_token}    :['..'];  # or strings

    # Options
    $self->{no_reverse}       = exists $args->{no_reverse}       ?$args->{no_reverse}     :0; # Don't turn 3..1 to 1..3
    $self->{no_overlap}       = exists $args->{no_overlap}       ?$args->{no_overlap}     :0; # Turn 1..5,4..6 into 1..6
    $self->{preserve_order}   = exists $args->{preserve_order}   ?$args->{preserve_order} :1; # Turns 3..1 to 3,2,1 to preserve order
    $self->{strict}           = exists $args->{strict}           ?$args->{strict}         :0; # Skip invalid perl ranges like 3..1 or 1..3..10 or 1..


    bless $self, $class;
    return $self;
}


=head2 in_range

Check if a number or range of numbers falls within the range object. Returns 1 if yes, 0 if no. If it is a partial match (like 1..3 against 2..4) 
it will return an array of the values that are in range (2,3)

=cut

sub in_range {
    my ($self, $against) = (shift, shift);

    my $rx_group_delim = _build_regex_delim( $self->{group_token} );
    my $rx_range_delim = _build_regex_delim( $self->{range_token} );

    my $stored_ranges = $self->{strict}
                            ?$self->{ranges}
                            :clean_range( 
                                $self->{ranges}, 
                                $self->{group_token}, 
                                $self->{range_token}, 
                                $self->{strict},
                            );

    return _in_range($stored_ranges, $against, $self->{group_token}, $self->{range_token});
}


# end
1;


=head1 EXPORT

=head1 SUBROUTINES

=head2 clean_range

Transform technically bad ranges into proper perl ranges.
    
    my @ranges = (1, 2, 3, '5..7..10');
    say clean_range(\@ranges,',','..');
    # [1, 2, 3, 4, '5..7', '8..10']

=cut

sub clean_range {
    # TODO: To perl, (\d+).(\d+) counts as $1 (rounded down to remove decimal point)
    # TODO wantarray/scalar
    my ($ranges, $group_tokens, $range_tokens, $strict) = @_;

    my $rx_group_delim = _build_regex_delim( $group_tokens );
    my $rx_range_delim = _build_regex_delim( $range_tokens );

    my @new_groups = map { 
        join($range_tokens->[0], _min_max( split($rx_range_delim, $_) )); 
    } map { split($rx_group_delim, ($_)) } @{$ranges};

    # DELETE OVER LAPPING RANGES HERE
    #@new_groups = _consolidate_range( \@new_groups );
    return \@new_groups;
}


# PRIVATE SUBROUTINES

sub _in_range {
    my ($ranges, $against, $group_tokens, $range_tokens) = @_;

    my $rx_group_delim = _build_regex_delim( $group_tokens );
    my $rx_range_delim = _build_regex_delim( $range_tokens );

    return 1 if( _exact_match(@_) || _range_match(@_) );
}

# Does not match against ranges (i.e. 1 does not match 1..5,6 but matches 1,2..6)
sub _exact_match {
    my ($ranges, $against, $group_tokens, $range_tokens) = @_;

    my $rx_group_delim = _build_regex_delim( $group_tokens );
    my $rx_range_delim = _build_regex_delim( $range_tokens );
    
    return 1 if 
        grep { $against == $_ }
           grep { split($rx_range_delim,$_, 2) == 1 } 
                map { split($rx_group_delim, $_) } 
                    @{$ranges};
}

# Does not match against single values (i.e. 1 does not match 1,2..6 byt matches 1..5,6)
sub _range_match {
    my ($ranges, $against, $group_tokens, $range_tokens) = @_;

    my $rx_group_delim = _build_regex_delim( $group_tokens );
    my $rx_range_delim = _build_regex_delim( $range_tokens );

    return 1 if( 
        grep { 
            my ($start, $end) = _min_max( split($rx_range_delim, $_) );
            (sort {$a <=> $b} $start, $end, $against)[1] == $against; 
        } grep { split($rx_range_delim, $_,2) >= 2 } 
            map { split($rx_group_delim, $_) } 
                @{$ranges}
    );
}

sub _consolidate_range {
    my ($ranges, $group_tokens, $range_tokens, $strict) = @_;

    my $rx_group_delim = _build_regex_delim( $group_tokens );
    my $rx_range_delim = _build_regex_delim( $range_tokens );

    #grep { split(/$rx_range_delim/, $_) <= 1 } @{$new_groups};

    #return @new_groups;
}

sub _min_max {
    my ($min,$max) = (min(@_),max(@_));
    return (defined $max && $min != $max)?($min,$max):$min;
}

sub _build_regex_delim {
    # Not sure if this is the best way to handle multiple regex's being passed. For now it seems ok.
    return ('(?:' . join('|', map { ref $_ eq 'Regexp'?$_:quotemeta($_) } @{$_[0]}) . ')');
}

=head1 AUTHOR

Nick Logan, C<< <ugexe at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-perl-number-range at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Perl-Number-Range>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Int::Range::Parser


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Perl-Number-Range>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Perl-Number-Range>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Perl-Number-Range>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Perl-Number-Range/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Nick Logan.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

# End of Data::Int::Range::Parser


__END__
