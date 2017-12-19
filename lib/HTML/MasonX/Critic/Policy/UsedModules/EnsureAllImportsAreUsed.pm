package HTML::MasonX::Critic::Policy::UsedModules::EnsureAllImportsAreUsed;
# ABSTRACT: Make sure that all explictly imported subroutines are used

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Critic::Inspector::Query::PerlCode;

use HTML::MasonX::Critic::Inspector::Mason::ModuleImport;

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

    my @blocks = @{ $component->blocks->all_blocks };

    # Gather ....
    foreach my $block ( @blocks ) {

        my @includes = HTML::MasonX::Critic::Inspector::Query::PerlCode->find_includes( $block );
        foreach my $include ( @includes ) {

            next if $include->does_not_call_import;
            next if $include->number_of_imports == 0;

            foreach my $import ( $include->imports ) {
                next if $import->is_tag;
                $imported_subs{ $import->token } = [ $include, $import ];
            }
        }
    }

    if ( my @ignored = @{ $self->{ignore} } ) {
        # if we are ignoring it, just delete it
        delete $imported_subs{ $_ } foreach @ignored;
    }

    # Check ...
    foreach my $block ( @blocks ) {

        my @sub_calls = HTML::MasonX::Critic::Inspector::Query::PerlCode->find_subroutine_calls( $block, ignore_builtins => 1 );

        foreach my $sub_call ( @sub_calls ) {
            # If this is a fully qualified call, then skip it
            next if $sub_call->is_fully_qualified_call;
            # if this is a built-in, then skip it
            next if $sub_call->is_built_in;

            # if we find a call to it, we can remove
            # it from the list of imported subs ...
            delete $imported_subs{ $sub_call->literal };
        }
    }

    # anything that remains is stuff
    # that didn't get called ...
    foreach my $sub_name ( keys %imported_subs ) {
        my ($include, $import) = @{ $imported_subs{ $sub_name } };
        push @violations => $self->violation(
            DESC,
            (sprintf EXPL, $sub_name),
            HTML::MasonX::Critic::Inspector::Mason::ModuleImport->new(
                include => $include,
                import  => $import,
            )
        );
    }

    return @violations;
}


1;

__END__

=pod

=head1 DESCRIPTION

If a subroutine is no longer used, it should no longer be
imported. This policy will compile a list of all explicitly
imported subroutines and then ensure that there is at least
one call to that subroutine.

This is advised because Mason adds all imports into the same
L<HTML::Mason::Command> namespace. This is a problem because all
Mason pages share this same namespace at runtime. This can create
subtle bugs that are sensitive to the loading order of Mason pages
since Mason pages are often compiled on-demand.

=head1 OPTIONS

=over 4

=item C<ignore>

This is a list of subroutines imports we can ignore.

=back

=cut

