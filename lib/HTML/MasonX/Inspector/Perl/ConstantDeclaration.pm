package HTML::MasonX::Inspector::Perl::ConstantDeclaration;
# ABSTRACT: Query result objects representing a Perl constant declaration

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
        # private data
        _symbol    => sub {},
        _arguments => sub {},
    )
}

sub BUILD {
    my ($self, $params) = @_;

 	Carp::confess('The `ppi` node must be an instance of `PPI::Statement::Include`, not '.ref($self->{ppi}))
		unless Scalar::Util::blessed( $self->{ppi} )
			&& $self->{ppi}->isa('PPI::Statement::Include');

    # TODO:
    # Look into using PPIx::Utilities::Statement export,
    # &get_constant_name_elements_from_declaring_statement
    # to parse out the constant values, the code below is
    # probably not as good.
    # - SL

    my @args = $self->{ppi}->arguments;

    # if we have a HASH ref constructor ...
    if ( $args[0]->isa('PPI::Structure::Constructor') ) {
        @args = $args[0]->schildren;
        # and it's first child is just an expression
        if ( $args[0]->isa('PPI::Statement::Expression') ) {
            # then we use those children instead ...
            @args = $args[0]->schildren;
        }
    }

    if ( $args[0]->isa('PPI::Token::Quote') || $args[0]->isa('PPI::Token::Word') ) {
        my $symbol = shift @args;
        $self->{_symbol} = $symbol->literal;
    }
    else {
        Carp::confess('Expected to find a symbol of type `PPI::Token::Quote` or `PPI::Token::Word`, but found '.ref($args[0]))
    }

    # drop any seperators ...
    shift @args
        while @args
           && $args[0]->isa('PPI::Token::Operator')
           && ($args[0]->content eq ',' || $args[0]->content eq '=>');

    # and just take what is left of args and strigify them ...
    $self->{_arguments} = [ map { "$_" } @args ];
}

sub ppi    { $_[0]->{ppi} }
sub source { $_[0]->{ppi}->content }

sub symbol        {    $_[0]->{_symbol}               }
sub arguments     { @{ $_[0]->{_arguments} }          }
sub filename      { $_[0]->{ppi}->logical_filename    }
sub line_number   { $_[0]->{ppi}->logical_line_number }
sub column_number { $_[0]->{ppi}->column_number       }

1;

__END__

=pod

=head1 DESCRIPTION

=cut
