package HTML::MasonX::Inspector::ObjectCode;

use strict;
use warnings;

our $VERSION = '0.01';

use Digest::MD5 ();

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        inspector => sub { die 'An `inspector` is required' },
        path      => sub { die 'A `path` is required' },
        # ... private fields
        _raw_obj_code   => sub {},
        _clean_obj_code => sub {},
    )
}

sub BUILD {
    my ($self, $params) = @_;

    my $interp   = $self->{inspector}->interpreter;
    my $source   = $interp->resolve_comp_path_to_source( $self->{path} );
    my $obj_code = $source->object_code( compiler => $interp->compiler );

    $self->{_raw_obj_code} = $obj_code;
}

sub raw_source { ${ $_[0]->{_raw_obj_code} } }

sub clean_source {
    my ($self) = @_;

    return $self->{_clean_obj_code}
        if defined $self->{_clean_obj_code};

    my $obj_code = $self->raw_source;

    # this is variable, so it needs to be
    # stripped out since it is variable
    $obj_code =~ s/\s*\'load_time\'\s*\=\>\s*\d+\,//;

    # This is the comp_root and may be different
    # on different machines, so we should strip
    # it out now.
    my $comp_root = $self->{inspector}->interpreter->comp_root;
    $comp_root .= '/' unless $comp_root =~ /\/$/;
    $obj_code =~ s/\#line (\d+) \"$comp_root/\#line $1 \"/g;

    return $self->{_clean_obj_code} = $obj_code;
}

sub checksum {
    my ($self) = @_;
    return Digest::MD5::md5_hex( $self->source );
}

1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::ObjectCode - ...

=head1 DESCRIPTION

=cut
