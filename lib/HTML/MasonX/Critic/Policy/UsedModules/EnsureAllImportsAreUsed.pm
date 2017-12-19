package HTML::MasonX::Critic::Policy::UsedModules::EnsureAllImportsAreUsed;
# ABSTRACT: Make sure that all explictly imported subroutines are used

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Inspector::Query::PerlCode;

use HTML::MasonX::Critic::Policy;
our @ISA; BEGIN { @ISA = ('HTML::MasonX::Critic::Policy') }
our %HAS; BEGIN {
    %HAS = (
        %HTML::MasonX::Critic::Policy::HAS,
        ignore => sub { +[] }
    )
}

use constant DESC => q[Make sure that all explictly imported subroutines are used];
use constant EXPL => q[The subroutine '%s' is explictly imported, but is never called.];

sub violates {
    my ($self, $component) = @_;

    my @violations;

    my %imported_subs;

    if ( my @ignored = @{ $self->{ignore} } ) {
        $imported_subs{ $_ } = 'ignored' foreach @ignored;
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
                $imported_subs{ $import->token } = $include;
            }
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

            # if we find a call to it, we can remove
            # it from the list of imported subs ...
            delete $imported_subs{ $sub_call->literal }
                if exists $imported_subs{ $sub_call->literal };
        }
    }

    foreach my $sub_name ( keys %imported_subs ) {
        push @violations => $self->violation(
            DESC,
            (sprintf EXPL, $sub_name),
            $imported_subs{ $sub_name }
        );
    }

    return @violations;
}


1;

__END__

=pod

=head1 DESCRIPTION

=cut
