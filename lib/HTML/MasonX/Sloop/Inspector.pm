package HTML::MasonX::Sloop::Inspector;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use List::Util   ();
use Scalar::Util ();

use HTML::Mason::Interp;

use HTML::MasonX::Sloop::Inspector::ObjectCode;
use HTML::MasonX::Sloop::Inspector::CompilerState;

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        # ... private
        _interpreter => sub {},
    )
}

sub BUILDARGS {
    my $class = shift;
    my $args  = $class->next::method( @_ );

    Carp::confess( 'Cannot create a new Mason Interpreter unless you supply `comp_root` parameter' )
        unless $args->{comp_root};

    Carp::confess( 'The `comp_root` must be a valid directory' )
        unless -e $args->{comp_root} && -d $args->{comp_root};

    return $args;
}

sub BUILD {
    my ($self, $params) = @_;

    # make the interpreter, but first
    # prepare the $params to pass to
    # Mason, and since we will alter it
    # we make a copy ...
    my %mason_args = %$params;

    # prep the comp_root before passing to Mason ...
    $mason_args{comp_root} = $mason_args{comp_root}->stringify
        if Scalar::Util::blessed( $mason_args{comp_root} )
        && $mason_args{comp_root}->isa('Path::Tiny');

    # ... build an interpreter ...

    my $interpreter = HTML::Mason::Interp->new( %mason_args )
        || die "Could not load Mason Interpreter";

    # then set up the minimum needs to mock this run ...
    $interpreter->set_global(
        $_ => HTML::MasonX::Sloop::Inspector::__EVIL__->new
    ) foreach map s/^[$@%]//r, $interpreter->compiler->allow_globals; #/

    $self->{interpreter} = $interpreter;
}

## accessor ...

sub interpreter { $_[0]->{interpreter} }

## do things ...

sub get_object_code_for_path {
    my ($self, $path) = @_;

    return HTML::MasonX::Sloop::Inspector::ObjectCode->new(
        inspector => $self,
        path      => $path,
    );
}

sub get_compiler_state_for_path {
    my ($self, $path) = @_;

    return HTML::MasonX::Sloop::Inspector::CompilerState->new(
        inspector => $self,
        path      => $path,
    );
}

## internal stuff ...

sub _load_component_for_path {
    my ($self, $path) = @_;
    my $interp   = $self->interpreter;
    my $source   = $self->_resolve_path( $path );
    my $obj_code = $source->object_code( compiler => $interp->compiler );
    my $comp     = $interp->eval_object_code( object_code => $obj_code );
    return $comp;
}

## ------------------------------------------- ##
## Ugly internal stuff
## ------------------------------------------- ##

package    # ignore this, internal use only
  HTML::MasonX::Sloop::Inspector::__EVIL__ {
    sub AUTOLOAD { return bless {}, __PACKAGE__ }
    sub DESTROY { () }
}

## ------------------------------------------- ##

1;

__END__

=pod

=head1 NAME

HTML::MasonX::Sloop - HTML::Mason Demolition Tools

=cut
