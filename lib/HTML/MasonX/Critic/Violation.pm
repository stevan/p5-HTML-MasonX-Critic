package HTML::MasonX::Critic::Violation;
# ABSTRACT: A representation of the violation in Mason

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        description   => sub { die 'A `description` must be provided'  },
        explanation   => sub { die 'An `explanation` must be provided' },
        policy        => sub { die 'An `policy` must be provided'      },
        element       => sub { die 'An `element` must be provided'     },
    )
}

sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('The `element` must be an object which responds to the following methods: filename, source, line_number, column_number')
        unless Scalar::Util::blessed( $self->{element} )
            && $self->{element}->can('filename')
            && $self->{element}->can('source')
            && $self->{element}->can('line_number')
            && $self->{element}->can('column_number');
}

## accessors

sub description   { $_[0]->{description} }
sub explanation   { $_[0]->{explanation} }
sub policy        { $_[0]->{policy}      }

# deletgators ...

sub filename      { $_[0]->{element}->filename      }
sub source        { $_[0]->{element}->source        }
sub line_number   { $_[0]->{element}->line_number   }
sub column_number { $_[0]->{element}->column_number }

## Fulfill the expected interface ...

sub severity { 1 }

*logical_filename    = \&filename;
*logical_line_number = \&line_number;

1;

__END__

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
