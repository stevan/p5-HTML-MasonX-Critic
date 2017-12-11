package HTML::MasonX::Critic::Violation;
# ABSTRACT: A representation of the violation in Mason

use strict;
use warnings;

our $VERSION = '0.01';

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        description   => sub { die 'A `description` must be provided'  },
        explanation   => sub { die 'An `explanation` must be provided' },
        policy        => sub { die 'An `policy` must be provided'      },
        filename      => sub { die 'A `filename` must be provided'     },
        source        => sub { die 'A `source` must be provided'       },
        line_number   => sub { 0 },
        column_number => sub { 0 },
    )
}

## accessors

sub description   { $_[0]->{description}   }
sub explanation   { $_[0]->{explanation}   }
sub policy        { $_[0]->{policy}        }
sub filename      { $_[0]->{filename}      }
sub source        { $_[0]->{source}        }
sub line_number   { $_[0]->{line_number}   }
sub column_number { $_[0]->{column_number} }

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
