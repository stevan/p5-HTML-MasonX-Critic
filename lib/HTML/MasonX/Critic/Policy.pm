package HTML::MasonX::Critic::Policy;
# ABSTRACT: Base class for Mason policies

use strict;
use warnings;

our $VERSION = '0.01';

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN { %HAS = () }

sub violates; # ( $component )

1;

__END__

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
