package HTML::MasonX::Critic::Inspector::Mason::UsedModule;
# ABSTRACT: An object representing a module use

use strict;
use warnings;

our $VERSION = '0.01';

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        used_module => sub { die 'An `used_module` is required' },
    )
}

sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('The `used_module` node must be an instance of `HTML::MasonX::Critic::Inspector::Perl::UsedModule`, not '.ref($self->{used_module}))
        unless Scalar::Util::blessed( $self->{used_module} )
            && $self->{used_module}->isa('HTML::MasonX::Critic::Inspector::Perl::UsedModule');
}

sub highlight     { $_[0]->{used_module}->module        }
sub source        { $_[0]->{used_module}->source        }
sub filename      { $_[0]->{used_module}->filename      }
sub line_number   { $_[0]->{used_module}->line_number   }
sub column_number { $_[0]->{used_module}->column_number }

1;

__END__

=pod

=head1 DESCRIPTION

=cut
