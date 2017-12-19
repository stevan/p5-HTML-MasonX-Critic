package HTML::MasonX::Critic::Inspector::Query::MasonCritic;
# ABSTRACT: Run Mason critic on inspector objects

use strict;
use warnings;

our $VERSION = '0.01';

use Carp            ();
use Scalar::Util    ();
use Module::Runtime ();
use Config::Tiny    ();

sub critique_compiler_component {
    my ($class, $compiler, %opts) = @_;

    Carp::confess('The compiler must be an instance of `HTML::MasonX::Critic::Inspector::Compiler`')
        unless Scalar::Util::blessed($compiler)
            && $compiler->isa('HTML::MasonX::Critic::Inspector::Compiler');

    my @policies;

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

    my $component  = $compiler->get_main_component;
    my @violations = map $_->violates( $component ), @policies;

    return @violations;
}

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

=head1 DESCRIPTION

=cut
