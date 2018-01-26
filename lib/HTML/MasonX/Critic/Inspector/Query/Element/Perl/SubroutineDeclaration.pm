package HTML::MasonX::Critic::Inspector::Query::Element::Perl::SubroutineDeclaration;
# ABSTRACT: Query result objects representing Perl subroutine declaration

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object';
use roles 'HTML::MasonX::Critic::Inspector::Query::Element';
use slots (
    ppi => sub { die 'A `ppi` node is required' },
);

sub BUILD {
    my ($self, $params) = @_;

 	Carp::confess('The `ppi` node must be an instance of `PPI::Statement::Sub`, not '.ref($self->{ppi}))
		unless Scalar::Util::blessed( $self->{ppi} )
			&& $self->{ppi}->isa('PPI::Statement::Sub');
}

sub ppi { $_[0]->{ppi} }

# Element API
sub source        { $_[0]->{ppi}->content             }
sub filename      { $_[0]->{ppi}->logical_filename    }
sub line_number   { $_[0]->{ppi}->logical_line_number }
sub column_number { $_[0]->{ppi}->column_number       }

# ...

sub symbol { $_[0]->{ppi}->name }

1;

__END__

=pod

=head1 DESCRIPTION

=cut
