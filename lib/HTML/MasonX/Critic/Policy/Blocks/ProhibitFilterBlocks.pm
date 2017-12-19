package HTML::MasonX::Critic::Policy::Blocks::ProhibitFilterBlocks;
# ABSTRACT: Mason <%filter> blocks are insane, don't use them

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Inspector::Mason::Block;

use HTML::MasonX::Critic::Policy;
our @ISA; BEGIN { @ISA = ('HTML::MasonX::Critic::Policy') }
our %HAS; BEGIN { %HAS = %HTML::MasonX::Critic::Policy::HAS }

use constant DESC => q[Mason <%filter> blocks are insane, don't use them.];
use constant EXPL => q[Mason <%filter> blocks are just nuts, they let you run a regexp over the entire generated content.];

sub violates {
    my ($self, $component) = @_;

    my @violations;
    if ( my $blocks = $component->blocks ) {
        if ( $blocks->has_filter_blocks ) {
            foreach my $block ( @{ $blocks->filter_blocks } ) {
                push @violations => $self->violation(
                    DESC,
                    EXPL,
                    HTML::MasonX::Inspector::Mason::Block->new(
                        type => 'filter',
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

Mason C<< <%filter> >> blocks are basically just a regular
expression run over the entire output, this is horrible
action-at-a-distance and really problematic when trying to
get a handle upon a Mason codebase.

=cut
