package HTML::MasonX::Critic::Policy::UsedModules::ProhibitImportingTags;
# ABSTRACT: Mason policy to not allow tags to be imported

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Critic::Inspector::Query::Factory::PerlCode;

use HTML::MasonX::Critic::Policy;
our @ISA; BEGIN { @ISA = ('HTML::MasonX::Critic::Policy') }
our %HAS; BEGIN { %HAS = %HTML::MasonX::Critic::Policy::HAS }

use constant DESC => q[Importing tags (sets of exported functions) is bad.];
use constant EXPL => q[Importing tag '%s' into Mason is ill-advised because Mason includes all imports in the same HTML::Mason::Command namespace.];

sub violates {
    my ($self, $component) = @_;

    my @violations;

    return @violations unless $component->blocks->has_once_blocks;

    my @once_blocks = @{ $component->blocks->once_blocks };

    foreach my $once ( @once_blocks ) {

        my @includes = HTML::MasonX::Critic::Inspector::Query::Factory::PerlCode->find_includes( $once );

        foreach my $include ( @includes ) {
            # skip if it doesn't call import
            next if $include->does_not_call_import;

            # skip if we have no imports ...
            next if $include->number_of_imports == 0;

            my @imports = $include->imports;

            foreach my $import ( @imports ) {
                if (  $import->is_tag ) {
                    push @violations => $self->violation(
                        DESC,
                        (sprintf EXPL, $import->token),
                        $import,
                    );
                }
            }
        }
    }

    return @violations;
}


1;

__END__

=pod

=head1 DESCRIPTION

Importing tags (sets of subroutine exports) into Mason is ill-advised
because Mason adds all imports into the same L<HTML::Mason::Command>
namespace. This is a problem because all Mason pages share this same
namespace and so can easily trample on each other's imports. This
can create bugs that are sensitive to the loading order of Mason pages
since Mason pages are often compiled on-demand.

Because of all this it is better to be explict about exactly what you
wish to import, or to not import anything at all and use fully qualified
subroutine calls.

=cut
