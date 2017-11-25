package HTML::MasonX::Inspector::Query::PerlCode;

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Inspector::Perl::UsedModule;
use HTML::MasonX::Inspector::Perl::UsedModule::Conditional;

use HTML::MasonX::Inspector::Perl::ConstantDeclaration;
use HTML::MasonX::Inspector::Perl::SubroutineDeclaration;

sub find_includes {
    my ($class, $perl_code) = @_;

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
    my ($class, $perl_code) = @_;

    return $perl_code->find_with_ppi(
        node_type => 'PPI::Statement::Sub',
        transform => sub {
            HTML::MasonX::Inspector::Util::Perl::SubroutineDeclaration->new( ppi => $_[0] )
        }
    );
}

sub find_constant_declarations {
    my ($class, $perl_code) = @_;

    return $perl_code->find_with_ppi(
        node_type => 'PPI::Statement::Include',
        filter    => sub { $_[0]->module eq 'constant' },
        transform => sub {
            HTML::MasonX::Inspector::Util::Perl::ConstantDeclaration->new( ppi => $_[0] )
        }
    );
}

1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::Query::PerlCode - HTML::Mason::Compiler sea cucumber guts

=head1 DESCRIPTION

=cut
