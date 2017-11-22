package HTML::MasonX::Inspector::Compiler::Component;

use strict;
use warnings;

our $VERSION = '0.01';

use Scalar::Util ();

use UNIVERSAL::Object;

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        args           => sub { +[] }, # ArrayRef[ HTML::MasonX::Inspector::Compiler::Component::Arg ]
        attributes     => sub { +{} }, # HashRef
        flags          => sub { +{} }, # HashRef
        methods        => sub { +{} }, # HashRef[ HTML::MasonX::Inspector::Compiler::Method ]
        sub_components => sub { +{} }, # HashRef[ HTML::MasonX::Inspector::Compiler::SubComponent ]
        body           => sub {     }, # HTML::MasonX::Inspector::Util::Perl
        blocks         => sub { +{} }, # HashRef[ HTML::MasonX::Inspector::Util::Perl ]
    )
}

sub args           { $_[0]->{args}           }
sub attributes     { $_[0]->{attributes}     }
sub flags          { $_[0]->{flags}          }
sub methods        { $_[0]->{methods}        }
sub sub_components { $_[0]->{sub_components} }

sub body   { $_[0]->{body}   }
sub blocks { $_[0]->{blocks} }

## ...

1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::Compiler::Attr - HTML::Mason::Compiler sea cucumber guts

=head1 DESCRIPTION

=cut
