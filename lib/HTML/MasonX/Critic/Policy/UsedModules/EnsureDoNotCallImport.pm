package HTML::MasonX::Critic::Policy::UsedModules::EnsureDoNotCallImport;
# ABSTRACT: Mason policy to ensure all modules pass an empty list

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Inspector::Query::PerlCode;

use HTML::MasonX::Critic::Policy;
our @ISA; BEGIN { @ISA = ('HTML::MasonX::Critic::Policy') }
our %HAS; BEGIN { %HAS = %HTML::MasonX::Critic::Policy::HAS }

use constant DESC => q[Used modules should not call the import function.];
use constant EXPL => q[When using module '%s', you should pass an explicit empty list to prevent the module's &import method from being called.];

sub violates {
    my ($self, $component) = @_;

    my @violations;

    return @violations unless $component->blocks->has_once_blocks;

    my @once_blocks = @{ $component->blocks->once_blocks };

    foreach my $once ( @once_blocks ) {

        my @includes = HTML::MasonX::Inspector::Query::PerlCode->find_includes( $once );

        foreach my $include ( @includes ) {
            if ( $include->does_call_import ) {
                push @violations => $self->violation(
                    DESC,
                    (sprintf EXPL, $include->module),
                    $include
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

All used modules within a Mason page should pass an explicit empty
list to prevent the module's C<import> method from being called.

   use Scalar::Util ();
   use DateTime     ();

This is advised because Mason adds all imports into the same
L<HTML::Mason::Command> namespace. This is a problem because all
Mason pages share this same namespace at runtime. This can create
subtle bugs that are sensitive to the loading order of Mason pages
since Mason pages are often compiled on-demand.

Because of all this it is better to not import anything at all and
just use fully qualified subroutine calls.

=cut
