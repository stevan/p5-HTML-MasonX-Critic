package HTML::MasonX::Critic::Policy::ProhibitIncludesFromImportingTags;
# ABSTRACT: Mason policy to not allow tags to be imported

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Critic::Violation;
use HTML::MasonX::Inspector::Query::PerlCode;

use HTML::MasonX::Critic::Policy;
our @ISA; BEGIN { @ISA = ('HTML::MasonX::Critic::Policy') }
our %HAS; BEGIN { %HAS = %HTML::MasonX::Critic::Policy::HAS }

use constant DESC => q[Importing tags (sets of exported functions) into Mason is bad.];
use constant EXPL => q[Importing tag '%s' into Mason is ill-advised because Mason includes all imports in the same HTML::Mason::Command namespace.];

sub violates {
    my ($self, $component) = @_;

    my @violations;

    return @violations unless $component->blocks->has_once_blocks;

    my @once_blocks = @{ $component->blocks->once_blocks };

    foreach my $once ( @once_blocks ) {

        my @includes = HTML::MasonX::Inspector::Query::PerlCode->find_includes( $once );

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
                        $include,
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

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
