package HTML::MasonX::Inspector::Compiler::Method;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();

use HTML::MasonX::Inspector::Compiler::Arg;
use HTML::MasonX::Inspector::PerlSource;

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

    Carp::confess('The `body` must be an instance of `HTML::MasonX::Inspector::PerlSource`, not ('.$self->{body}.')')
        unless Scalar::Util::blessed( $self->{body} )
            && $self->{body}->isa('HTML::MasonX::Inspector::PerlSource');

    Carp::confess('All `args` must be an instance of `HTML::MasonX::Inspector::Compiler::Arg`, not ('.$_.')')
        unless scalar grep {
            Scalar::Util::blessed( $_ )
                &&
            $_->isa('HTML::MasonX::Inspector::Compiler::Arg')
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

HTML::MasonX::Inspector::Compiler::Method - HTML::Mason::Compiler sea cucumber guts

=head1 DESCRIPTION

=cut
