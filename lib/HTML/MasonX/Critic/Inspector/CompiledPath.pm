package HTML::MasonX::Critic::Inspector::CompiledPath;
# ABSTRACT: Tools for inspecting the compiler internals of HTML::Mason

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();
use Clone        ();

use HTML::MasonX::Critic::Inspector::Compiled::Component;
use HTML::MasonX::Critic::Inspector::Compiled::Component::Arg;
use HTML::MasonX::Critic::Inspector::Compiled::Component::Blocks;
use HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode;

our $VERSION = '0.01';

use parent 'UNIVERSAL::Object';
use slots (
    interpreter => sub { die 'An `interpreter` is required' },
    path        => sub { die 'A `path` is required' },
    # ...
    _compiler  => sub {},
    _abs_path  => sub {},
    _main_comp => sub {},
);

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
    $self->{_abs_path} = $source->friendly_name;
}

## accessors

sub abs_path { $_[0]->{_abs_path} }

## access stuff within the frozen compiler ...

sub comp_path            {    $_[0]->{_compiler}->{comp_path}            }
sub comp_root            {    $_[0]->{_compiler}->{comp_root}            }
sub comp_class           {    $_[0]->{_compiler}->{comp_class}           }
sub subcomp_class        {    $_[0]->{_compiler}->{subcomp_class}        }
sub in_package           {    $_[0]->{_compiler}->{in_package}           }

sub object_id            {    $_[0]->{_compiler}->object_id              }

sub use_strict           {    $_[0]->{_compiler}->{use_strict}           }
sub use_warnings         {    $_[0]->{_compiler}->{use_warnings}         }

sub preamble             {    $_[0]->{_compiler}->{preamble}             }
sub postamble            {    $_[0]->{_compiler}->{postamble}            }

sub allow_globals        {    $_[0]->{_compiler}->allow_globals          }
sub default_escape_flags { @{ $_[0]->{_compiler}->default_escape_flags } }

## collect info ...

sub root_component {
    my ($self) = @_;

    #use Data::Dumper;
    #warn Dumper $self->{_compiler};

    Carp::confess('Not a valid main component, expected in_main to be true')
        unless exists $self->{_compiler}->{main_compile}->{in_main}
            && $self->{_compiler}->{main_compile}->{in_main};

    # steal all the data from Mason ...
    $self->{_main_comp} //= _build_component(
        %{ $self->{_compiler}->{main_compile} },
        name => $self->comp_path,
        type => 'main',
    );
}

## ...

sub _build_component {
    my %compile = @_;

    # normalize some of this, Mason internal
    # naming conventions are not always consistent
    $compile{attributes}     = delete $compile{attr}   if exists $compile{attr};
    $compile{sub_components} = delete $compile{def}    if exists $compile{def};
    $compile{methods}        = delete $compile{method} if exists $compile{method};

    ## Transform some stuff ...

    # inflate the args ...
    $compile{args} = [ map _build_arg_object( $_ ), @{ $compile{args} } ] if exists $compile{args};

    # clean the flags
    if ( exists $compile{flags} ) {
        $compile{flags}->{ $_ } = _unquote_value(_clean_value( $compile{flags}->{ $_ } ))
            foreach keys %{ $compile{flags} };
    }

    # clean the attrs ...
    if ( exists $compile{attributes} ) {
        $compile{attributes}->{ $_ } = _clean_value( $compile{attributes}->{ $_ } )
            foreach keys %{ $compile{attributes} };
    }

    # inflate the methods ...
    $compile{methods} = {
        map {;
            $_,
            _build_component(
                %{ $compile{methods}->{ $_ } },
                name => $_,
                type => 'method',
            )
        } keys %{ $compile{methods} }
    } if exists $compile{methods};

    # inflate the sub_components ...
    $compile{sub_components} = {
        map {;
            $_,
            _build_component(
                %{ $compile{sub_components}->{ $_ } },
                name => $_,
                type => 'sub',
            )
        } keys %{ $compile{sub_components} }
    } if exists $compile{sub_components};

    # NOTE:
    # it is important to note that the main block
    # is basically a combination of any <%perl>
    # blocks as well as any HTML with embedded
    # templates in it.
    $compile{body}   = _build_perl_object( $compile{body} )     if exists $compile{body};
    $compile{blocks} = _build_blocks_object( $compile{blocks} ) if exists $compile{blocks};

    return HTML::MasonX::Critic::Inspector::Compiled::Component->new( %compile );
}

sub _build_arg_object {
    my ($arg) = @_;
    return HTML::MasonX::Critic::Inspector::Compiled::Component::Arg->new(
        sigil           => $arg->{type},
        symbol          => $arg->{name},
        default_value   => _clean_value( $arg->{default} ),
        type_constraint => $arg->{type_constraint},
        line_number     => $arg->{line},
    );
}

sub _build_blocks_object {
    my ($blocks) = @_;
    return HTML::MasonX::Critic::Inspector::Compiled::Component::Blocks->new(
        once    => [ map _build_perl_object ( $_ ), @{ $blocks->{once}    || [] } ],
        init    => [ map _build_perl_object ( $_ ), @{ $blocks->{init}    || [] } ],
        filter  => [ map _build_perl_object ( $_ ), @{ $blocks->{filter}  || [] } ],
        cleanup => [ map _build_perl_object ( $_ ), @{ $blocks->{cleanup} || [] } ],
        shared  => [ map _build_perl_object ( $_ ), @{ $blocks->{shared}  || [] } ],
    );
}

sub _build_perl_object {
    my ($body) = @_;
    return HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode->new( source => \$body )
}

sub _clean_value {
    my ($val) = @_;
    # return undef as we got it ...
    return $val unless defined $val;
    $val =~ s/^\s*//;  # remove leading spaces ...
    $val =~ s/\;$//;   # remove trailing semicolon ...
    $val =~ s/\s*$//;  # remove trailing spaces ...
    $val;
}

sub _unquote_value {
    my ($val) = @_;
    # return undef as we got it ...
    return $val unless defined $val;
    $val =~ s/^['"]//; # remove leading quotes ...
    $val =~ s/['"]$//; # remove trailing quotes ...
    $val;
}

1;

__END__

=pod

=head1 DESCRIPTION

=cut
