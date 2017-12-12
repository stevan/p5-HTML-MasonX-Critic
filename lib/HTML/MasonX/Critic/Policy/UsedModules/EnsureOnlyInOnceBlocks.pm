package HTML::MasonX::Critic::Policy::UsedModules::EnsureOnlyInOnceBlocks;
# ABSTRACT: Only allow modules to be loaded within <%once> blocks

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Critic::Violation;
use HTML::MasonX::Inspector::Query::PerlCode;

use HTML::MasonX::Critic::Policy;
our @ISA; BEGIN { @ISA = ('HTML::MasonX::Critic::Policy') }
our %HAS; BEGIN { %HAS = %HTML::MasonX::Critic::Policy::HAS }

use constant DESC => q[Only allow modules to be loaded within <%once> blocks.];
use constant EXPL => q[Module '%s' should only be used within <%%once> blocks, all other blocks may be executed multiple times.];

sub violates {
    my ($self, $component) = @_;

    my @violations;

    push @violations, $self->_check_blocks_for_includes( $component->body )
        if $component->has_body;

    my $blocks = $component->blocks;

    push @violations => $self->_check_blocks_for_includes( @{ $blocks->init_blocks } )
        if $blocks->has_init_blocks;

    push @violations => $self->_check_blocks_for_includes( @{ $blocks->filter_blocks } )
        if $blocks->has_filter_blocks;

    push @violations => $self->_check_blocks_for_includes( @{ $blocks->cleanup_blocks } )
        if $blocks->has_cleanup_blocks;

    push @violations => $self->_check_blocks_for_includes( @{ $blocks->shared_blocks } )
        if $blocks->has_shared_blocks;

    return @violations;
}

# ...

sub _check_blocks_for_includes {
    my ($self, @blocks) = @_;

    my @violations;
    foreach my $block ( @blocks ) {

        my @includes = HTML::MasonX::Inspector::Query::PerlCode->find_includes( $block );

        foreach my $include ( @includes ) {
            push @violations => $self->violation(
                DESC,
                (sprintf EXPL, $include->module),
                $include,
            );
        }
    }
    return @violations;
}


1;

__END__

=pod

=head1 DESCRIPTION

=cut
