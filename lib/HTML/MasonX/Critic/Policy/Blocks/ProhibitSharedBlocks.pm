package HTML::MasonX::Critic::Policy::Blocks::ProhibitSharedBlocks;
# ABSTRACT: Mason <%shared> blocks expands variable scopes which is bad

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Inspector::Mason::Block;

use HTML::MasonX::Critic::Policy;
our @ISA; BEGIN { @ISA = ('HTML::MasonX::Critic::Policy') }
our %HAS; BEGIN { %HAS = %HTML::MasonX::Critic::Policy::HAS }

use constant DESC => q[Mason's <%shared> blocks will expand the scope of a variable, which is bad.];
use constant EXPL => q[Mason's <%shared> blocks allow you to share variables across multiple scopes (body, sub-components, etc.) which is generally a bad thing. Keep scopes tight.];

sub violates {
    my ($self, $component) = @_;

    my @violations;
    if ( my $blocks = $component->blocks ) {
        if ( $blocks->has_shared_blocks ) {
            foreach my $block ( @{ $blocks->shared_blocks } ) {
                push @violations => $self->violation(
                    DESC,
                    EXPL,
                    HTML::MasonX::Inspector::Mason::Block->new(
                        type => 'shared',
                        code => $block,
                    )
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

Mason C<< <%shared> >> blocks are a means of sharing variables
between components, therefore expanding the variables scope,
which is really problematic when trying to get a handle upon a
Mason codebase.

=cut
