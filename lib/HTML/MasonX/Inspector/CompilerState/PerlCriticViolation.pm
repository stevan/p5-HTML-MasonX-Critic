package HTML::MasonX::Inspector::CompilerState::PerlCriticViolation;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();

use UNIVERSAL::Object;

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        violation => sub { die 'A `violation` node is required' },
    )
}

sub BUILD {
    my ($self, $params) = @_;

   Carp::confess('The `violation` must be an instance of `Perl::Critic::Violation`')
		unless Scalar::Util::blessed( $self->{violation} )
			&& $self->{violation}->isa('Perl::Critic::Violation');

}

sub line_number   { $_[0]->{violation}->logical_line_number }
sub column_number { $_[0]->{violation}->column_number       }
sub severity      { $_[0]->{violation}->severity            }
sub source        { $_[0]->{violation}->source              }
sub description   { $_[0]->{violation}->description         }

sub policy {
    # get the short name ...
    $_[0]->{violation}->policy =~ s/^Perl\:\:Critic\:\:Policy\:\://r
}

1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::CompilerState::CodeBlock - HTML::Mason::Compiler sea cucumber guts

=head1 DESCRIPTION

=cut
