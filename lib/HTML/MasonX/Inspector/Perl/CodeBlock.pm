package HTML::MasonX::Inspector::Perl::CodeBlock;

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Inspector::Perl::ModuleInclude;
use HTML::MasonX::Inspector::Perl::ModuleInclude::Conditional;
use HTML::MasonX::Inspector::Perl::Constant;
use HTML::MasonX::Inspector::Perl::Subroutine;

use Digest::MD5                 ();
use PPI                         ();
use Perl::Critic::Utils::McCabe ();

use UNIVERSAL::Object;

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        code                 => sub { die 'Some `code` is required' },
        # ... internal fields
        _ppi                 => sub {},
        # CACHED DATA
        # ... bools
        _does_postproc       => sub {},
        _might_abort_request => sub {},
        _might_redirect_user => sub {},
        # ... scalar
        _checksum            => sub {},
        _complexity          => sub {},
        # ... collections
        _lines               => sub {},
        _includes            => sub {},
        _constants           => sub {},
        _subroutines         => sub {},
    )
}

sub BUILD {
    my ($self, $params) = @_;

    $self->{_ppi} = PPI::Document->new( $self->{code}, readonly => 1 );
}

## Info ...

sub raw  { ${ $_[0]->{code} } }
sub size { length $_[0]->raw  }

sub starting_line_number {
    my ($self) = @_;

    my $code = ${ $_[0]->{code} };

    my ($line_number) = ($code =~ /^#line (\d*)/);

    Carp::confess('Unable to find line number in:['.$code.']')
        if $code && not $line_number;

    return $code ? $line_number : 0;
}

sub lines  {
    my ($self) = @_;

    $self->{_lines} //= scalar split /\n/ => ${ $self->{code} };
}

sub checksum {
    my ($self) = @_;

    $self->{_checksum} //= Digest::MD5::md5_hex( $self->raw );
}

sub complexity_score {
    my ($self) = @_;

    $self->{_complexity} //= Perl::Critic::Utils::McCabe::calculate_mccabe_of_main( $self->{_ppi} );
}

## Various Mason "Things" we want to catch

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

## Subroutines

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
                HTML::MasonX::Inspector::Perl::Subroutine->new( ppi => $_ )
            } @{ $subs || [] }
        ];
    }

    return @{ $self->{_subroutines} };
}

## Constants

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
                HTML::MasonX::Inspector::Perl::Constant->new( ppi => $_ )
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
                    ? HTML::MasonX::Inspector::Perl::ModuleInclude::Conditional->new( ppi => $_ )
                    : HTML::MasonX::Inspector::Perl::ModuleInclude->new( ppi => $_ )
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

HTML::MasonX::Inspector::Perl::CodeBlock - HTML::Mason::Compiler sea cucumber guts

=head1 DESCRIPTION

=cut
