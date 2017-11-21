package HTML::MasonX::Inspector::Compiler::Flag;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();

use UNIVERSAL::Object;

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        key   => sub { die 'A `key` is required' },
        value => sub { die 'A `value` is required' },
    )
}

sub BUILD {
    my ($self, $params) = @_;

    $self->{value} =~ s/^\s*//;  # remove leading spaces ...
    $self->{value} =~ s/\;$//;   # remove trailing semicolon ...
    $self->{value} =~ s/\s*$//;  # remove trailing spaces ...
    $self->{value} =~ s/^['"]//; # remove leading quotes ...
    $self->{value} =~ s/['"]$//; # remove trailing quotes ...
}

sub key   { $_[0]->{key}   }
sub value { $_[0]->{value} }

1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::Compiler::Flag - HTML::Mason::Compiler sea cucumber guts

=head1 DESCRIPTION

=cut
