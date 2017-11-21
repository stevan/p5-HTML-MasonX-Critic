package HTML::MasonX::Inspector::Compiler;

use strict;
use warnings;

our $VERSION = '0.01';

use Clone ();

use HTML::MasonX::Inspector::Compiler::Component;

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        interpreter => sub { die 'An `interpreter` is required' },
        path        => sub { die 'A `path` is required' },
        # ...
        _compiler => sub {},
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
    my $compiler = $interp->compiler;
    my $source   = $interp->resolve_comp_path_to_source( $path );

    ## -----------------------------------
    ## WARNING!!!
    ## -----------------------------------
    ## This horror is what happens inside
    ## the compiler, it is gross, but it
    ## has to be done here. It makes me sad.
    ## -----------------------------------
    local $compiler->{current_compile} = {};
    local $compiler->{main_compile}    = $compiler->{current_compile};
    local $compiler->{paused_compiles} = [];
    local $compiler->{comp_path}       = $source->comp_path;

    $compiler->lexer->lex(
        comp_source => $source->comp_source,
        name        => $source->friendly_name,
        compiler    => $compiler
    );

    ## -----------------------------------
    ## *sigh*
    ## -----------------------------------
    ## Now we need to freeze the state of
    ## the compiler because the `local`
    ## stuff above goes out of scope once
    ## we return from this BUILD. I weep.
    ## -----------------------------------
    $self->{_compiler} = Clone::clone( $compiler );

    #use Data::Dumper;
    #die Dumper $self->{_compiler};
}

## access stuff ...

sub comp_root            {    $_[0]->{_compiler}->{comp_root}            }
sub object_id            {    $_[0]->{_compiler}->object_id              }
sub allow_globals        {    $_[0]->{_compiler}->allow_globals          }
sub default_escape_flags { @{ $_[0]->{_compiler}->default_escape_flags } }

## collect info ...

sub get_main_component {
    my ($self) = @_;
    my $comp = $self->{_compiler}->{main_compile};
    return HTML::MasonX::Inspector::Compiler::Component->new( %$comp );
}

1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::Compiler - HTML::Mason::Compiler sea cucumber

=head1 DESCRIPTION



=cut
