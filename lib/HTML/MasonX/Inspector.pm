package HTML::MasonX::Inspector;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use List::Util   ();
use Scalar::Util ();

use HTML::Mason::Interp;

use HTML::MasonX::Inspector::ObjectCode;
use HTML::MasonX::Inspector::Compiler;
use HTML::MasonX::Inspector::Runtime;

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        # ... private
        _mason_args  => sub { +[] },
        _interpreter => sub {},
    )
}

sub BUILDARGS {
    my $class = shift;
    if ( scalar @_ == 1 ) {
        # attach to a running interpreter ...
        Carp::confess('You can either pass an instance of `HTML::Mason::Interp` or a list of key-value args for its constructor')
            unless Scalar::Util::blessed( $_[0] )
                && $_[0]->isa('HTML::Mason::Interp');

        return +{ _interpreter => $_[0] };
    }
    else {
        # all args are mason args
        return +{ _mason_args => [ @_[ 1 .. $#_ ] ] };
    }
}

sub BUILD {
    my ($self, $params) = @_;

    if ( not defined $self->{_interpreter} ) {
        # make the interpreter, but first
        # prepare the $params to pass to
        # Mason, and since we will alter it
        # we make a copy ...
        my %mason_args = @{ $self->{_mason_args} };

        # at least make sure they set up comp_root
        Carp::confess( 'Cannot create a new Mason Interpreter unless you supply `comp_root` parameter' )
            unless $mason_args{comp_root};

        Carp::confess( 'The `comp_root` must be a valid directory' )
            unless -e $mason_args{comp_root} && -d $mason_args{comp_root};

        # prep the comp_root before passing to Mason ...
        $mason_args{comp_root} = $mason_args{comp_root}->stringify
            if Scalar::Util::blessed( $mason_args{comp_root} )
            && $mason_args{comp_root}->isa('Path::Tiny');

        # ... build an interpreter ...

        my $interpreter = HTML::Mason::Interp->new( %mason_args )
            || die "Could not load Mason Interpreter";

        # then set up the minimum needs to mock this run ...
        $interpreter->set_global(
            $_ => HTML::MasonX::Inspector::__EVIL__->new
        ) foreach map s/^[$@%]//r, $interpreter->compiler->allow_globals; #/

        $self->{_interpreter} = $interpreter;
    }
}

## accessor ...

sub interpreter { $_[0]->{_interpreter} }

## do things ...

sub get_object_code_for_path {
    my ($self, $path) = @_;

    return HTML::MasonX::Inspector::ObjectCode->new(
        interpreter => $self->interpreter,
        path        => $path,
    );
}

sub get_compiler_for_path {
    my ($self, $path) = @_;

    return HTML::MasonX::Inspector::Compiler->new(
        interpreter => $self->interpreter,
        path        => $path,
    );
}

sub get_runtime_for_path {
    my ($self, $path) = @_;

    return HTML::MasonX::Inspector::Runtime->new(
        interpreter => $self->interpreter,
        path        => $path,
    );
}

## internal stuff ...

## ------------------------------------------- ##
## Ugly internal stuff
## ------------------------------------------- ##

package    # ignore this, internal use only
  HTML::MasonX::Inspector::__EVIL__ {
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
