package HTML::MasonX::Inspector::Query::PerlCode;
# ABSTRACT: Query HTML::MasonX::Component::PerlCode objects with PPI

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();

use HTML::MasonX::Inspector::Perl::UsedModule;
use HTML::MasonX::Inspector::Perl::UsedModule::Conditional;

use HTML::MasonX::Inspector::Perl::ConstantDeclaration;
use HTML::MasonX::Inspector::Perl::SubroutineDeclaration;

use HTML::MasonX::Inspector::Perl::MethodCall;

sub find_includes {
    my ($class, $perl_code, %opts) = @_;

    Carp::confess('The perl code passed must be an instance of `HTML::MasonX::Inspector::Compiler::Component::PerlCode`')
        unless Scalar::Util::blessed( $perl_code )
            && $perl_code->isa('HTML::MasonX::Inspector::Compiler::Component::PerlCode');

    return $perl_code->find_with_ppi(
        node_type => 'PPI::Statement::Include',
        filter    => sub { $_[0]->module ne 'constant' },
        transform => sub {
            $_[0]->module eq 'if'
                ? HTML::MasonX::Inspector::Perl::UsedModule::Conditional->new( ppi => $_[0] )
                : HTML::MasonX::Inspector::Perl::UsedModule->new( ppi => $_[0] )
        }
    );
}

sub find_subroutine_declarations {
    my ($class, $perl_code, %opts) = @_;

    Carp::confess('The perl code passed must be an instance of `HTML::MasonX::Inspector::Compiler::Component::PerlCode`')
        unless Scalar::Util::blessed( $perl_code )
            && $perl_code->isa('HTML::MasonX::Inspector::Compiler::Component::PerlCode');

    return $perl_code->find_with_ppi(
        node_type => 'PPI::Statement::Sub',
        transform => sub {
            HTML::MasonX::Inspector::Perl::SubroutineDeclaration->new( ppi => $_[0] )
        }
    );
}

sub find_constant_declarations {
    my ($class, $perl_code, %opts) = @_;

    Carp::confess('The perl code passed must be an instance of `HTML::MasonX::Inspector::Compiler::Component::PerlCode`')
        unless Scalar::Util::blessed( $perl_code )
            && $perl_code->isa('HTML::MasonX::Inspector::Compiler::Component::PerlCode');

    return $perl_code->find_with_ppi(
        node_type => 'PPI::Statement::Include',
        filter    => sub { $_[0]->module eq 'constant' },
        transform => sub {
            HTML::MasonX::Inspector::Perl::ConstantDeclaration->new( ppi => $_[0] )
        }
    );
}

sub find_method_calls {
    my ($class, $perl_code, %opts) = @_;

    Carp::confess('The perl code passed must be an instance of `HTML::MasonX::Inspector::Compiler::Component::PerlCode`')
        unless Scalar::Util::blessed( $perl_code )
            && $perl_code->isa('HTML::MasonX::Inspector::Compiler::Component::PerlCode');

    my ($invocant_name, $method_name);
    $invocant_name = $opts{invocant_name} if exists $opts{invocant_name};
    $method_name   = $opts{method_name}   if exists $opts{method_name};

    my @method_calls = $perl_code->find_with_ppi(
        node_type => 'PPI::Token::Word',
        filter    => (defined $method_name
            ? sub { $_[0]->method_call && $_[0]->literal eq $method_name }
            : sub { $_[0]->method_call }
        ),
        transform => sub {
            HTML::MasonX::Inspector::Perl::MethodCall->new( ppi => $_[0] )
        }
    );

    if ( $invocant_name ) {
        my @filtered;
        foreach my $method_call ( @method_calls ) {
            if ( my $inv = $method_call->find_invocant ) {
                push @filtered => $method_call
                    if $inv->name eq $invocant_name;
            }
        }
        @method_calls = @filtered;
    }

    return @method_calls;
}

1;

__END__

=pod

=head1 DESCRIPTION

=cut
