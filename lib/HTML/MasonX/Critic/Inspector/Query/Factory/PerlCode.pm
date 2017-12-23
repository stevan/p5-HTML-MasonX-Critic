package HTML::MasonX::Critic::Inspector::Query::Factory::PerlCode;
# ABSTRACT: Query HTML::MasonX::Component::PerlCode objects with PPI

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();

use Perl::Critic::Utils ();

use HTML::MasonX::Critic::Inspector::Query::Element::Perl::UsedModule;
use HTML::MasonX::Critic::Inspector::Query::Element::Perl::UsedModule::Conditional;

use HTML::MasonX::Critic::Inspector::Query::Element::Perl::ConstantDeclaration;
use HTML::MasonX::Critic::Inspector::Query::Element::Perl::SubroutineDeclaration;

use HTML::MasonX::Critic::Inspector::Query::Element::Perl::MethodCall;
use HTML::MasonX::Critic::Inspector::Query::Element::Perl::SubroutineCall;

sub find_includes {
    my ($class, $perl_code, %opts) = @_;

    Carp::confess('The perl code passed must be an instance of `HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode`')
        unless Scalar::Util::blessed( $perl_code )
            && $perl_code->isa('HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode');

    return $perl_code->find_with_ppi(
        node_type => 'PPI::Statement::Include',
        filter    => sub { $_[0]->module ne 'constant' },
        transform => sub {
            $_[0]->module eq 'if'
                ? HTML::MasonX::Critic::Inspector::Query::Element::Perl::UsedModule::Conditional->new( ppi => $_[0] )
                : HTML::MasonX::Critic::Inspector::Query::Element::Perl::UsedModule->new( ppi => $_[0] )
        }
    );
}

sub find_subroutine_declarations {
    my ($class, $perl_code, %opts) = @_;

    Carp::confess('The perl code passed must be an instance of `HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode`')
        unless Scalar::Util::blessed( $perl_code )
            && $perl_code->isa('HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode');

    return $perl_code->find_with_ppi(
        node_type => 'PPI::Statement::Sub',
        transform => sub {
            HTML::MasonX::Critic::Inspector::Query::Element::Perl::SubroutineDeclaration->new( ppi => $_[0] )
        }
    );
}

sub find_constant_declarations {
    my ($class, $perl_code, %opts) = @_;

    Carp::confess('The perl code passed must be an instance of `HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode`')
        unless Scalar::Util::blessed( $perl_code )
            && $perl_code->isa('HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode');

    return $perl_code->find_with_ppi(
        node_type => 'PPI::Statement::Include',
        filter    => sub { $_[0]->module eq 'constant' },
        transform => sub {
            HTML::MasonX::Critic::Inspector::Query::Element::Perl::ConstantDeclaration->new( ppi => $_[0] )
        }
    );
}

sub find_method_calls {
    my ($class, $perl_code, %opts) = @_;

    Carp::confess('The perl code passed must be an instance of `HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode`')
        unless Scalar::Util::blessed( $perl_code )
            && $perl_code->isa('HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode');

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
            HTML::MasonX::Critic::Inspector::Query::Element::Perl::MethodCall->new( ppi => $_[0] )
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

sub find_subroutine_calls {
    my ($class, $perl_code, %opts) = @_;

    Carp::confess('The perl code passed must be an instance of `HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode`')
        unless Scalar::Util::blessed( $perl_code )
            && $perl_code->isa('HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode');

    my $ignore_builtins = $opts{ignore_builtins};

    my @sub_calls = $perl_code->find_with_ppi(
        node_type => 'PPI::Token::Word',
        filter    => sub {
            my $is_function_call = Perl::Critic::Utils::is_function_call( $_[0] );

            # if it is not a function call, then
            # we can just return false here  ...
            return 0 unless $is_function_call;

            # if it is a function call, and we are
            # not ignoring the built-in functions,
            # then we can stop filtering and return
            # true here since we know that $is_function_call
            # is true.
            return 1 if not $ignore_builtins;

            # if it is a function call and we are not
            # planning to filter out the built-ins, then
            # we need to filter on this variable
            return not(Perl::Critic::Utils::is_perl_builtin( $_[0] ));
        },
        transform => sub {
            HTML::MasonX::Critic::Inspector::Query::Element::Perl::SubroutineCall->new( ppi => $_[0] )
        }
    );

    return @sub_calls;
}


1;

__END__

=pod

=head1 DESCRIPTION

=cut
