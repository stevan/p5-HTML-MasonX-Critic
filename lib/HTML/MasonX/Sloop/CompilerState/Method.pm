package HTML::MasonX::Sloop::CompilerState::Method;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();

use HTML::MasonX::Sloop::CompilerState::Arg;
use HTML::MasonX::Sloop::CompilerState::CodeBlock;

use UNIVERSAL::Object;

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        name => sub { 'A `name` is required' },
        args => sub { 'A `args` is required' },
        body => sub { 'A `body` is required' },
    )
}

sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('The `body` must be an instance of `HTML::MasonX::Sloop::CompilerState::CodeBlock`, not ('.$self->{body}.')')
        unless Scalar::Util::blessed( $self->{body} )
            && $self->{body}->isa('HTML::MasonX::Sloop::CompilerState::CodeBlock');

    Carp::confess('All `args` must be an instance of `HTML::MasonX::Sloop::CompilerState::Arg`, not ('.$_.')')
        unless scalar grep {
            Scalar::Util::blessed( $_ )
                &&
            $_->isa('HTML::MasonX::Sloop::CompilerState::Arg')
        } @{ $self->{args} };
}

sub name { $_[0]->{name} }
sub args { $_[0]->{args} }
sub body { $_[0]->{body} }

sub get_args { @{ $_[0]->{args} } }

1;

__END__

=pod

=head1 NAME

HTML::MasonX::Sloop::CompilerState::Method - HTML::Mason::Compiler sea cucumber guts

=head1 DESCRIPTION

=cut
