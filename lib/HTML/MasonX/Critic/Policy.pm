package HTML::MasonX::Critic::Policy;
# ABSTRACT: Base class for Mason policies

use strict;
use warnings;

use HTML::MasonX::Critic::Violation;

our $VERSION = '0.01';

sub violates; # ( $component )

sub violation {
    my ($self, $description, $explanation, $element) = @_;

    HTML::MasonX::Critic::Violation->new(
        policy      => Scalar::Util::blessed($self),
        description => $description,
        explanation => $explanation,
        element     => $element,
    );
}

1;

__END__

=pod

=head1 DESCRIPTION

=cut
