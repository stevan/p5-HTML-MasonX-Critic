package HTML::MasonX::Critic::Inspector::Query::Element::Mason::Block;
# ABSTRACT: An object representing a Mason block

use strict;
use warnings;

our $VERSION = '0.01';

use UNIVERSAL::Object;
use HTML::MasonX::Critic::Inspector::Query::Element;
our @ISA;  BEGIN { @ISA = ('UNIVERSAL::Object') }
our @DOES; BEGIN { @DOES = ('HTML::MasonX::Critic::Inspector::Query::Element') }
our %HAS;  BEGIN {
    %HAS = (
        type => sub { die 'A `type` is required' },
        code => sub { die 'A `code` is required' },
    )
}

sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('The `code` node must be an instance of `HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode`, not '.ref($self->{code}))
        unless Scalar::Util::blessed( $self->{code} )
            && $self->{code}->isa('HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode');
}

# Element API

sub source {
    my ($self) = @_;

    my @raw = split /\n/ => $self->{code}->raw;
    # shift off the two things that Mason adds ...
    shift @raw if $raw[0] =~ /^#line \d+/; # the line directive
    shift @raw if $raw[0] =~ /^\s*$/;      # and a newline

    return join "\n" => (
        '<%'.$self->{type}.'>',
        @raw,
        '</%'.$self->{type}.'>',
    );
}

sub filename      { $_[0]->{code}->discover_filename    }
sub line_number   { $_[0]->{code}->starting_line_number }
sub column_number { 1 }

1;

__END__

=pod

=head1 DESCRIPTION

=cut
