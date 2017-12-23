package HTML::MasonX::Critic::Policy::SubroutineCalls::EnsureAllAreFullyQualified;
# ABSTRACT: All subroutine calls should be fully qualified

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Critic::Policy;
our @ISA; BEGIN { @ISA = ('HTML::MasonX::Critic::Policy') }
our %HAS; BEGIN { %HAS = %HTML::MasonX::Critic::Policy::HAS }

use constant DESC => q[All subroutine calls should be fully qualified.];
use constant EXPL => q[The subroutine `%s` is not fully qualified.];

sub violates {
    my ($self, $component) = @_;

    my @violations;

    my @blocks = @{ $component->blocks->all_blocks };

    foreach my $block ( @blocks ) {

        my @sub_calls = HTML::MasonX::Critic::Inspector::Query::Factory::PerlCode->find_subroutine_calls( $block, ignore_builtins => 1 );

        foreach my $sub_call ( @sub_calls ) {

            # If this is a fully qualified call, then skip it
            next if $sub_call->is_fully_qualified_call;

            # if this is a built-in, then skip it
            next if $sub_call->is_built_in;

            push @violations => $self->violation(
                DESC,
                (sprintf EXPL, $sub_call->literal),
                $sub_call
            );
        }
    }

    return @violations;
}

1;

__END__

=pod

=head1 DESCRIPTION

 Mason has poor namespace management, so better for all subroutine
 calls to be fully qualified to avoid uneccesary namespace
 pollution.

=cut
