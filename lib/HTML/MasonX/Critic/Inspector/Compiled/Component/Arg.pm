package HTML::MasonX::Critic::Inspector::Compiled::Component::Arg;
# ABSTRACT: Compile time view of a Mason argument

use strict;
use warnings;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object';
use slots (
    sigil         => sub { die 'A `sigil` is required' },
    symbol        => sub { die 'A `symbol` is required' },
    default_value => sub { die 'A `default_value` is required' },
    line_number   => sub { die 'A `line_number` is required' },
);

sub BUILD {
    my ($self, $params) = @_;

    if ( defined $self->{default_value} ) {
        $self->{default_value} =~ s/^\s*//; # remove leading spaces ...
        $self->{default_value} =~ s/\;$//;  # remove trailing semicolon ...
        $self->{default_value} =~ s/\s*$//; # remove trailing spaces ...
    }
}

sub sigil  { $_[0]->{sigil}  }
sub symbol { $_[0]->{symbol} }

sub name { $_[0]->{sigil} . $_[0]->{symbol} }

sub line_number   { $_[0]->{line_number}   }
sub default_value { $_[0]->{default_value} }

1;

__END__

=pod

=head1 DESCRIPTION

=cut
