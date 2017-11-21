package HTML::MasonX::Inspector::Runtime;

use strict;
use warnings;

our $VERSION = '0.01';

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        inspector => sub { die 'An `inspector` is required' },
        path      => sub { die 'A `path` is required' },
        # ... private fields
        _component => sub {},
    )
}

sub BUILD {
    my ($self, $params) = @_;

    my $path      = $self->{path} =~ /^\// ? $self->{path} : '/'.$self->{path};
    my $interp    = $self->{inspector}->interpreter;
    my $component = $interp->load( $path );

    #use Data::Dumper;
    #warn Dumper $interp;

    $self->{_component} = $component;
}

sub component { $_[0]->{_component} }

1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::Runtime - ...

=head1 DESCRIPTION

=cut
