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

=pod

## Various Mason "Things" we want to catch

### TODO:
# Generalise this stuff below with a mason_method_calls grouping
# that would basically collect calls to the mason allowed_globals
# ($m, etc.)
# This would allow us to track certain kinds of usages of mason
# features.

sub does_mason_postproc {
    my ($self) = @_;

    unless ( $self->{_does_postproc} ) {
        my $words = $self->{_ppi}->find('PPI::Token::Word');

        if ( $words ) {
            $self->{_does_postproc} = (scalar grep {
                $_->method_call && $_->literal eq 'postproc'
            } @$words) ? 1 : 0;
        }
        else {
            $self->{_does_postproc} = 0;
        }
    }

    return $self->{_does_postproc};
}

sub might_abort_request {
    my ($self) = @_;

    unless ( $self->{_might_abort_request} ) {
        my $words = $self->{_ppi}->find('PPI::Token::Word');

        if ( $words ) {
            $self->{_might_abort_request} = (scalar grep {
                $_->method_call && $_->literal eq 'abort'
            } @$words) ? 1 : 0;
        }
        else {
            $self->{_might_abort_request} = 0;
        }
    }

    return $self->{_might_abort_request};
}

sub might_redirect_user {
    my ($self) = @_;

    unless ( $self->{_might_redirect_user} ) {
        my $words = $self->{_ppi}->find('PPI::Token::Word');

        if ( $words ) {
            $self->{_might_redirect_user} = (scalar grep {
                $_->method_call && $_->literal eq 'redirect'
            } @$words) ? 1 : 0;
        }
        else {
            $self->{_might_redirect_user} = 0;
        }
    }

    return $self->{_might_redirect_user};
}


## TODO:
# Detect `SELF:`, `PARENT:` and `REQUEST:`
# calls as well, they are slightly different
# and also catch the `attr:` calls too.
sub might_call_components {
    my ($self) = @_;

    unless ( $self->{_might_call_components} ) {
        my $words = $self->{_ppi}->find('PPI::Token::Word');

        if ( $words ) {
            $self->{_might_call_components} = (scalar grep {
                $_->method_call && $_->literal eq 'comp'
            } @$words) ? 1 : 0;
        }
        else {
            $self->{_might_call_components} = 0;
        }
    }

    return $self->{_might_call_components};
}

## SubroutineDeclarations

sub number_of_subroutines {
    my ($self) = @_;
    return scalar $self->subroutines;
}

sub subroutines {
    my ($self) = @_;

    unless ( $self->{_subroutines} ) {
        my $subs = $self->{_ppi}->find('PPI::Statement::Sub');

        $self->{_subroutines} = [
            map {
                HTML::MasonX::Inspector::Util::Perl::SubroutineDeclaration->new( ppi => $_ )
            } @{ $subs || [] }
        ];
    }

    return @{ $self->{_subroutines} };
}

## ConstantDeclarations

sub number_of_constants {
    my ($self) = @_;
    return scalar $self->constants;
}

sub constants {
    my ($self) = @_;

    unless ( $self->{_constants} ) {
        my $incs = $self->{_ppi}->find('PPI::Statement::Include');

        $self->{_constants} = [
            map {
                HTML::MasonX::Inspector::Util::Perl::ConstantDeclaration->new( ppi => $_ )
            } grep {
                # for this we only want the constants
                $_->module eq 'constant'
            } @{ $incs || [] }
        ];
    }

    return @{ $self->{_constants} };
}

## Includes

sub number_of_includes {
    my ($self) = @_;
    return scalar $self->includes;
}

sub includes {
    my ($self) = @_;

    unless ( $self->{_includes} ) {
        my $incs = $self->{_ppi}->find('PPI::Statement::Include');

        #use Data::Dumper;
        $self->{_includes} = [
            map {
                #warn "IN MAP: ", Dumper $_;
                $_->module eq 'if'
                    ? HTML::MasonX::Inspector::Util::Perl::UsedModule::Conditional->new( ppi => $_ )
                    : HTML::MasonX::Inspector::Util::Perl::UsedModule->new( ppi => $_ )
            } grep {
                # Skip constants, they are another thing entirely ...
                $_->module ne 'constant'
            } @{ $incs || [] }
        ];
    }

    return @{ $self->{_includes} };
}
1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::Util::Perl - HTML::Mason::Compiler sea cucumber guts

=head1 DESCRIPTION

=cut
