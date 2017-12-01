package HTML::MasonX::Inspector::Perl::MethodCall;
# ABSTRACT: Query result objects representing a Perl method call

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();

use HTML::MasonX::Inspector::Perl::MethodCall::Invocant;

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        ppi       => sub { die 'A `ppi` node is required' },
        # private data
        _invocant => sub {},
    )
}

sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('The `ppi` node must be an instance of `PPI::Token::Word`, not '.ref($self->{ppi}))
        unless Scalar::Util::blessed( $self->{ppi} )
            && $self->{ppi}->isa('PPI::Token::Word');
}

sub ppi { $_[0]->{ppi} }

sub name          { $_[0]->{ppi}->literal             }
sub line_number   { $_[0]->{ppi}->logical_line_number }
sub column_number { $_[0]->{ppi}->column_number       }

sub find_invocant {
    my ($self) = @_;

    unless ( $self->{_invocant} ) {
        my $operator = $self->{ppi}->previous_sibling;
        my $invocant = $operator->previous_sibling;

        # look for argument list, and if we find
        # it, look at the previous, previous instead
        if ( $invocant->isa('PPI::Structure::List') ) {
            $invocant = $invocant->previous_sibling;
        }

        $self->{_invocant} = HTML::MasonX::Inspector::Perl::MethodCall::Invocant->new( ppi => $invocant );
    }

    return $self->{_invocant};
}

1;

__END__

=pod

=head1 DESCRIPTION

=cut
