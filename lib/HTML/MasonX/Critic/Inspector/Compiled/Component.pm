package HTML::MasonX::Critic::Inspector::Compiled::Component;
# ABSTRACT: Compile time view of a Mason component

use strict;
use warnings;

use Carp ();

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object';
use slots (
    name           => sub { die 'A `name` is required' },
    type           => sub { die 'A `type` is required' },
    args           => sub { +[] }, # ArrayRef[ HTML::MasonX::Critic::Inspector::Compiled::Component::Arg ]
    attributes     => sub { +{} }, # HashRef
    flags          => sub { +{} }, # HashRef
    methods        => sub { +{} }, # HashRef[ HTML::MasonX::Critic::Inspector::Compiled::Component ]
    sub_components => sub { +{} }, # HashRef[ HTML::MasonX::Critic::Inspector::Compiled::Component ]
    body           => sub {     }, # HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode
    blocks         => sub { +{} }, # HTML::MasonX::Critic::Inspector::Compiled::Component::Blocks
);

sub BUILD {
    my ($self, $params) = @_;

    # normalise this ...
    $self->{type} = lc $self->{type};
    # now check it ...
    Carp::confess('The `type` must be one of the following (sub, main, method) not ('.$self->{type}.')')
        unless $self->{type} =~ /(sub|main|method)/;
}

sub name { $_[0]->{name} }
sub type { $_[0]->{type} }

sub args           { $_[0]->{args}           }
sub attributes     { $_[0]->{attributes}     }
sub flags          { $_[0]->{flags}          }
sub methods        { $_[0]->{methods}        }
sub sub_components { $_[0]->{sub_components} }
sub blocks         { $_[0]->{blocks}         }

sub body     {         $_[0]->{body} }
sub has_body { defined $_[0]->{body} }

1;

__END__

=pod

=head1 DESCRIPTION

=cut
