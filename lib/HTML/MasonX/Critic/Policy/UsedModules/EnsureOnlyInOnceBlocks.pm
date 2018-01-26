package HTML::MasonX::Critic::Policy::UsedModules::EnsureOnlyInOnceBlocks;
# ABSTRACT: Only allow modules to be loaded within <%once> blocks

use strict;
use warnings;

use HTML::MasonX::Critic::Inspector::Query::PerlCode;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object';
use roles 'HTML::MasonX::Critic::Policy';

use constant DESC => q[Only allow modules to be loaded within <%once> blocks.];
use constant EXPL => q[Using the module '%s' in the '%s' block is bad, modules should only be used within <%%once> blocks.];

sub violates {
    my ($self, $component) = @_;

    my @violations;

    push @violations, $self->_check_blocks_for_includes( body => $component->body )
        if $component->has_body;

    my $blocks = $component->blocks;

    push @violations => $self->_check_blocks_for_includes( init => @{ $blocks->init_blocks } )
        if $blocks->has_init_blocks;

    push @violations => $self->_check_blocks_for_includes( filter => @{ $blocks->filter_blocks } )
        if $blocks->has_filter_blocks;

    push @violations => $self->_check_blocks_for_includes( cleanup => @{ $blocks->cleanup_blocks } )
        if $blocks->has_cleanup_blocks;

    push @violations => $self->_check_blocks_for_includes( shared => @{ $blocks->shared_blocks } )
        if $blocks->has_shared_blocks;

    return @violations;
}

# ...

sub _check_blocks_for_includes {
    my ($self, $block_type, @blocks) = @_;

    my @violations;
    foreach my $block ( @blocks ) {

        my @includes = HTML::MasonX::Critic::Inspector::Query::PerlCode->find_includes( $block );

        foreach my $include ( @includes ) {
            push @violations => $self->violation(
                DESC,
                (sprintf EXPL, $include->module, $block_type),
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

Modules should only be used within C<< <%once> >> blocks because
these are the only ones that will run only once at compile-time.

All other blocks are possibly re-executed at runtime, which is
often not a problem because C<perl> will not try to load again,
but this is not good for code organization and is generally not
the right way to do things in Mason so should be discouraged.

=cut
