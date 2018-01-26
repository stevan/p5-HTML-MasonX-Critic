package HTML::MasonX::Critic::Inspector::Query::Element::Perl::UsedModule::ImportedToken;
# ABSTRACT: Query result objects representing the import token for used Perl modules

use strict;
use warnings;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object';
use roles 'HTML::MasonX::Critic::Inspector::Query::Element';
use slots (
    include => sub { die 'An `include` is required' },
    token   => sub { die 'A `token` is required'    },
);

sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('The `include` node must be an instance of `HTML::MasonX::Critic::Inspector::Query::Element::Perl::UsedModule`, not '.ref($self->{include}))
        unless Scalar::Util::blessed( $self->{include} )
            && $self->{include}->isa('HTML::MasonX::Critic::Inspector::Query::Element::Perl::UsedModule');
}

sub token   { $_[0]->{token}                }
sub is_tag  { $_[0]->token =~ /^\:/ ? 1 : 0 }
sub is_name { $_[0]->is_tag ? 0 : 1         }

# Element API
sub highlight     { $_[0]->token                    }
sub source        { $_[0]->{include}->source        }
sub filename      { $_[0]->{include}->filename      }
sub line_number   { $_[0]->{include}->line_number   }
sub column_number { $_[0]->{include}->column_number }

1;

__END__

=pod

=head1 DESCRIPTION

=cut
