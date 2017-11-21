package HTML::MasonX::Inspector::Runtime;

use strict;
use warnings;

our $VERSION = '0.01';

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        interpreter => sub { die 'An `interpreter` is required' },
        path        => sub { die 'A `path` is required' },
        # ... private fields
        _component => sub {},
    )
}

sub BUILD {
    my ($self, $params) = @_;

    my $path = $self->{path};

    # prep this before passing to Mason ...
    $path = $path->stringify
        if Scalar::Util::blessed( $path )
        && $path->isa('Path::Tiny');

    # and for whatever reason, load()
    # wants something that looks like
    # an absolute path, so we add a /
    # if needed ...
    $path = '/' . $path unless $path =~ /^\//;

    my $interp    = $self->{interpreter};
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
