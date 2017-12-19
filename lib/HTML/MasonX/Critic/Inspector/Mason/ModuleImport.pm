package HTML::MasonX::Critic::Inspector::Mason::ModuleImport;
# ABSTRACT: An object representing a specific import from a used module

use strict;
use warnings;

our $VERSION = '0.01';

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        include => sub { die 'An `include` is required' },
        import  => sub { die 'An `import` is required' },
    )
}

sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('The `include` node must be an instance of `HTML::MasonX::Critic::Inspector::Perl::UsedModule`, not '.ref($self->{include}))
        unless Scalar::Util::blessed( $self->{include} )
            && $self->{include}->isa('HTML::MasonX::Critic::Inspector::Perl::UsedModule');

    Carp::confess('The `import` node must be an instance of `HTML::MasonX::Critic::Inspector::Perl::UsedModule::ImportedToken`, not '.ref($self->{import}))
        unless Scalar::Util::blessed( $self->{import} )
            && $self->{import}->isa('HTML::MasonX::Critic::Inspector::Perl::UsedModule::ImportedToken');
}

sub highlight { $_[0]->{import}->token }

sub source        { $_[0]->{include}->source        }
sub filename      { $_[0]->{include}->filename      }
sub line_number   { $_[0]->{include}->line_number   }
sub column_number { $_[0]->{include}->column_number }

1;

__END__

=pod

=head1 DESCRIPTION

=cut
