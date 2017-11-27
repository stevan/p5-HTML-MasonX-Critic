package HTML::MasonX::Inspector::Perl::MethodCall::Invocant;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        ppi => sub { die 'A `ppi` node is required' },
    )
}

sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('The `ppi` node must be an instance of `PPI::Token::Word` or `PPI::Token::Symbol`, not '.ref($self->{ppi}))
        unless Scalar::Util::blessed( $self->{ppi} )
            && ($self->{ppi}->isa('PPI::Token::Symbol') || $self->{ppi}->isa('PPI::Token::Word'));
}

sub ppi { $_[0]->{ppi} }

sub name          { $_[0]->{ppi}->content                 }
sub is_virtual    { $_[0]->{ppi}->isa('PPI::Token::Word') }
sub line_number   { $_[0]->{ppi}->logical_line_number     }
sub column_number { $_[0]->{ppi}->column_number           }

1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::Util::Perl - HTML::Mason::Compiler sea cucumber guts

=head1 DESCRIPTION

=cut
