package HTML::MasonX::Critic::Policy::UsedModules::ProhibitSubCallsWithoutExplicitImport;
# ABSTRACT: Make sure that all called subroutines are explicitly imported

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Inspector::Query::PerlCode;

use HTML::MasonX::Critic::Policy;
our @ISA; BEGIN { @ISA = ('HTML::MasonX::Critic::Policy') }
our %HAS; BEGIN {
    %HAS = (
        %HTML::MasonX::Critic::Policy::HAS,
        allow => sub { +[] }
    )
}

use constant DESC => q[Make sure that all called subroutines are explicitly imported];
use constant EXPL => q[The subroutine '%s' is not explicitly imported, but is being called.];

sub violates {
    my ($self, $component) = @_;

    my @violations;

    my %available_subs;

    if ( my @allowed = @{ $self->{allow} } ) {
        $available_subs{ $_ } = 'allowed' foreach @allowed;
    }

    my @blocks = @{ $component->blocks->all_blocks };

    # Gather ....
    foreach my $block ( @blocks ) {

        my @includes = HTML::MasonX::Inspector::Query::PerlCode->find_includes( $block );
        foreach my $include ( @includes ) {

            next if $include->does_not_call_import;
            next if $include->number_of_imports == 0;

            foreach my $import ( $include->imports ) {
                next if $import->is_tag;
                $available_subs{ $import->token } = $include->module;
            }
        }

        my @constants = HTML::MasonX::Inspector::Query::PerlCode->find_constant_declarations( $block );
        foreach my $constant ( @constants ) {
            $available_subs{ $constant->symbol } = 'constant';
        }

        my @subroutines = HTML::MasonX::Inspector::Query::PerlCode->find_subroutine_declarations( $block );
        foreach my $subroutine ( @subroutines ) {
            $available_subs{ $subroutine->symbol } = 'sub';
        }
    }

    # Check ...
    foreach my $block ( @blocks ) {

        my @sub_calls = HTML::MasonX::Inspector::Query::PerlCode->find_subroutine_calls( $block, ignore_builtins => 1 );

        foreach my $sub_call ( @sub_calls ) {
            # If this is a fully qualified call, then skip it
            next if $sub_call->is_fully_qualified_call;
            # if this is a built-in, then skip it
            next if $sub_call->is_built_in;

            unless ( $available_subs{ $sub_call->literal } ) {
                push @violations => $self->violation(
                    DESC,
                    (sprintf EXPL, $sub_call->literal),
                    $sub_call
                );
            }
        }
    }

    return @violations;
}


1;

__END__

=pod

=head1 DESCRIPTION

=cut
