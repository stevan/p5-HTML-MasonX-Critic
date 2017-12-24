package HTML::MasonX::Critic;
# ABSTRACT: Critique HTML::Mason pages

use strict;
use warnings;

our $VERSION = '0.01';

use Carp            ();
use Scalar::Util    ();
use Module::Runtime ();
use Config::Tiny    ();
use Perl::Critic    ();

use HTML::MasonX::Critic::Policy;
use HTML::MasonX::Critic::Violation;
use HTML::MasonX::Critic::Inspector;

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        comp_root => sub { die 'A `comp_root` is required' },
        config    => sub { +{} },
        # ... private
        _inspector           => sub {},
        _mason_critic_config => sub { +{} },
        _perl_critic_config  => sub { +{} },
    )
}

sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('The `comp_root` must be a valid directory')
        unless -d $self->{comp_root};

    # build some subobjects ...

    $self->{_inspector} = HTML::MasonX::Critic::Inspector->new(
        comp_root    => $self->{comp_root},
        use_warnings => 1, # FIXME - not sure how, but this is ugly
    );

    my $config = $self->{config};

    # convert the perl-critic-* stuff to fit proper Perl::Critic args
    $self->{_perl_critic_config} = {
        ($config->{perl_critic_policy}   ? ('-single-policy' => $config->{perl_critic_policy})   : ()),
        ($config->{perl_critic_profile}  ? ('-profile'       => $config->{perl_critic_profile})  : ()),
    };

    # stuff for Mason::Critic ...
    $self->{_mason_critic_config} = {
        ($config->{mason_critic_policy}  ? ('policy'  => $config->{mason_critic_policy})  : ()),
        ($config->{mason_critic_profile} ? ('profile' => $config->{mason_critic_profile}) : ()),
    };
}

sub critique {
    my ($self, $file) = @_;

    my $compiled_path = $self->{_inspector}->compile_path( $file );

    my @violations;

    if ( keys %{ $self->{_perl_critic_config} } ) {
        push @violations => $self->critique_perl( $compiled_path );
    }

    if ( keys %{ $self->{_mason_critic_config} } ) {
        push @violations => $self->critique_mason( $compiled_path );
    }

    return @violations;
}

sub critique_perl {
    my ($self, $compiled_path) = @_;

    Carp::confess('The compiled_path must be an instance of `HTML::MasonX::Critic::Inspector::CompiledPath`')
        unless Scalar::Util::blessed($compiled_path)
            && $compiled_path->isa('HTML::MasonX::Critic::Inspector::CompiledPath');

    my $critic   = Perl::Critic->new( -severity => 1, %{ $self->{_perl_critic_config} } );
    my $filename = $compiled_path->abs_path;
    my $comp     = $compiled_path->root_component;
    my $blocks   = $comp->blocks;

    my @code;

    # Compile Time ...

    push @code => "## == Compile Time ========================\n\n";
    push @code => "use strict;\n"   if $compiled_path->use_strict;
    push @code => "use warnings;\n" if $compiled_path->use_warnings;

    push @code => "## -- global args -------------------------\n";
    push @code => ('our ('.(join ', ' => map { $_ } $compiled_path->allow_globals).");\n");

    if ( $blocks->has_once_blocks ) {
        push @code => "## -- once blocks -------------------------\n";
        push @code => map $_->raw, @{ $blocks->once_blocks };
    }

    # Runtime ...

    push @code => "\n## == Run  Time ============================\n\n";

    if ( my $args = $comp->args ) {
        push @code => "## -- args --------------------------------\n";
        foreach my $arg ( @$args ) {
            push @code => '#line '.$arg->line_number." \"$filename\"\n";
            push @code => 'my '.$arg->name.";\n";
        }
    }

    if ( $blocks->has_init_blocks ) {
        push @code => "## -- init blocks -------------------------\n";
        push @code => map $_->raw, @{ $blocks->init_blocks };
    }

    if ( my $preamble = $compiled_path->preamble ) {
        push @code => "## -- preamble -------------------------\n";
        push @code => $preamble;
    }

    push @code => "## -- body --------------------------------\n";
    push @code => $comp->body->raw;

    if ( $blocks->has_cleanup_blocks ) {
        push @code => "## -- cleanup blocks -----------------------\n";
        push @code => map $_->raw, @{ $blocks->cleanup_blocks };
    }

    if ( my $postamble = $compiled_path->postamble ) {
        push @code => "## -- postamble -------------------------\n";
        push @code => $postamble;
    }

    push @code => "\n## == End =================================\n";

    my $code       = join '' => @code;
    my @violations = $critic->critique( \$code );

    #warn $code;

    return @violations;
}

sub critique_mason {
    my ($self, $compiled_path) = @_;

    Carp::confess('The compiled_path must be an instance of `HTML::MasonX::Critic::Inspector::CompiledPath`')
        unless Scalar::Util::blessed($compiled_path)
            && $compiled_path->isa('HTML::MasonX::Critic::Inspector::CompiledPath');

    my @policies;

    my %opts = %{ $self->{_mason_critic_config} };

    if ( $opts{policy} ) {
        push @policies => _load_policy( $opts{policy} );
    }
    elsif ( $opts{profile} ) {
        Carp::confess('The `profile` must be a valid path, not ('.$opts{profile}.')')
            unless -f $opts{profile};

        my $profile = Config::Tiny->read( $opts{profile} );

        push @policies => map _load_policy( $_, $profile->{ $_ } ), keys %$profile;
    }
    else {
        Carp::confess('You have niether a `policy` nor  a `profile`, nothing to critique');
    }

    my $component  = $compiled_path->root_component;
    my @violations = map $_->violates( $component ), @policies;

    return @violations;
}

## ...

sub _load_policy {
    my ($name, $args) = @_;

    $name = index( $name, 'HTML::MasonX::Critic::Policy::' ) == 0
        ? $name
        : 'HTML::MasonX::Critic::Policy::'.$name;

    foreach my $arg ( keys %$args ) {
        if ( $args->{ $arg } =~ /\,/ ) {
            $args->{ $arg } = [ split /\,/ => $args->{ $arg } ];
        }
    }

    Module::Runtime::use_package_optimistically( $name )->new( %$args );
}


1;

__END__

=pod

=head1 SYNOPSIS

    say('Under ¯\_(ツ)_/¯ Construction');

=head1 DESCRIPTION

The three key components in this system are:

=head2 Inspector

First in the inspector, it is the means by which we introspect
Mason compilation run and query the results. These queries
then return objects that can be used to identify issues.

=head2 Policy

Policies are a way of describing a code pattern that you wish
to identify and inspect. These modules will query and inspect
a compilation run to determine if the code matches the pattern
described in the policy.

=head2 Violation

Violations are the matches found by a policy. They contain
information about code pattern that was matched including
the file it is from and the exact location within that file.

=cut
