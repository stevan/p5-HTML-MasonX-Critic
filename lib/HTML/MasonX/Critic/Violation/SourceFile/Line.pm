package HTML::MasonX::Critic::Violation::SourceFile::Line;
# ABSTRACT: A line in a source file associated with a violation

use strict;
use warnings;

our $VERSION = '0.01';

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        line         => sub { die 'A `line` is required' },
        line_num     => sub { die 'A `line_num` is required' },
        in_violation => sub { 0 },
        # private data
    )
}

sub metadata { sprintf '%04d', $_[0]->line_num }

sub line     { $_[0]->{line}     }
sub line_num { $_[0]->{line_num} }

sub is_in_between {
    my ($self, $start, $end) = @_;

    return $self->{line_num} >= $start
        && $self->{line_num} <  $end;
}

sub in_violation {
    my $self = shift;
    if ( @_ ) {
        $self->{in_violation} = shift;
    }
    return $self->{in_violation};
}

1;

__END__

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

