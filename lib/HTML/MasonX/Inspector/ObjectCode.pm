package HTML::MasonX::Inspector::ObjectCode;

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
        _obj_code  => sub {},
        _sanitized => sub {},
    )
}

sub BUILD {
    my ($self, $params) = @_;

    my $path = $self->{path};

    # prep this before passing to Mason ...
    $path = $path->stringify
        if Scalar::Util::blessed( $path )
        && $path->isa('Path::Tiny');

    my $interp   = $self->{interpreter};
    my $source   = $interp->resolve_comp_path_to_source( $path );
    my $obj_code = $source->object_code( compiler => $interp->compiler );

    $self->{_obj_code} = $obj_code;
}

# accessor

sub object_code { $_[0]->{_obj_code} }

# ... source

sub source { ${ $_[0]->object_code } }

sub sanitized_source {
    my ($self) = @_;

    return $self->{_sanitized}
        if defined $self->{_sanitized};

    my $obj_code = $self->source;

    # this is variable, so it needs to be
    # stripped out since it is variable
    $obj_code =~ s/\s*\'load_time\'\s*\=\>\s*\d+\,//;

    # This is the comp_root and may be different
    # on different machines, so we should strip
    # it out now.
    my $comp_root = $self->{inspector}->interpreter->comp_root;
    $comp_root .= '/' unless $comp_root =~ /\/$/;
    $obj_code =~ s/\#line (\d+) \"$comp_root/\#line $1 \"/g;

    return $self->{_sanitized} = $obj_code;
}

1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::ObjectCode - ...

=head1 DESCRIPTION

=cut
