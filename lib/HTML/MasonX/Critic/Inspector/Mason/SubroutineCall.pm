package HTML::MasonX::Critic::Inspector::Mason::SubroutineCall;
# ABSTRACT: An object representing a subroutine call

use strict;
use warnings;

our $VERSION = '0.01';

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        sub_call => sub { die 'An `sub_call` is required' },
    )
}

sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('The `sub_call` node must be an instance of `HTML::MasonX::Critic::Inspector::Perl::SubroutineCall`, not '.ref($self->{sub_call}))
        unless Scalar::Util::blessed( $self->{sub_call} )
            && $self->{sub_call}->isa('HTML::MasonX::Critic::Inspector::Perl::SubroutineCall');
}

sub highlight     { $_[0]->{sub_call}->source        }
sub source        { $_[0]->{sub_call}->source        }
sub filename      { $_[0]->{sub_call}->filename      }
sub line_number   { $_[0]->{sub_call}->line_number   }
sub column_number { $_[0]->{sub_call}->column_number }

1;

__END__

=pod

=head1 DESCRIPTION

=cut
