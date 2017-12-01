package HTML::MasonX::Inspector::Compiler::Component::Blocks;
# ABSTRACT: Compile time view of a set of Mason component blocks

use strict;
use warnings;

our $VERSION = '0.01';

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        once    => sub { +[] }, # ArrayRef[ HTML::MasonX::Inspector::Compiler::Component::PerlCode ]
        init    => sub { +[] }, # ArrayRef[ HTML::MasonX::Inspector::Compiler::Component::PerlCode ]
        filter  => sub { +[] }, # ArrayRef[ HTML::MasonX::Inspector::Compiler::Component::PerlCode ]
        cleanup => sub { +[] }, # ArrayRef[ HTML::MasonX::Inspector::Compiler::Component::PerlCode ]
        shared  => sub { +[] }, # ArrayRef[ HTML::MasonX::Inspector::Compiler::Component::PerlCode ]
    )
}

sub has_once_blocks    { !! scalar @{ $_[0]->{once}    } }
sub has_init_blocks    { !! scalar @{ $_[0]->{init}    } }
sub has_filter_blocks  { !! scalar @{ $_[0]->{filter}  } }
sub has_cleanup_blocks { !! scalar @{ $_[0]->{cleanup} } }
sub has_shared_blocks  { !! scalar @{ $_[0]->{shared}  } }

sub once_blocks    { $_[0]->{once}    }
sub init_blocks    { $_[0]->{init}    }
sub filter_blocks  { $_[0]->{filter}  }
sub cleanup_blocks { $_[0]->{cleanup} }
sub shared_blocks  { $_[0]->{shared}  }

1;

__END__

=pod

=head1 DESCRIPTION

=cut
