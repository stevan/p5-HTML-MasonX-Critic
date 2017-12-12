package HTML::MasonX::Inspector::Query::MasonCritic;
# ABSTRACT: Run Mason critic on inspector objects

use strict;
use warnings;

our $VERSION = '0.01';

use Carp            ();
use Scalar::Util    ();
use Module::Runtime ();

sub critique_compiler_component {
    my ($class, $compiler, %opts) = @_;

    Carp::confess('The compiler must be an instance of `HTML::MasonX::Inspector::Compiler`')
        unless Scalar::Util::blessed($compiler)
            && $compiler->isa('HTML::MasonX::Inspector::Compiler');

    $opts{policy} = 'HTML::MasonX::Critic::Policy::'.$opts{policy}
        unless index( $opts{policy}, 'HTML::MasonX::Critic::Policy::' ) == 0;

    my $policy     = Module::Runtime::use_package_optimistically( $opts{policy} )->new;
    my $component  = $compiler->get_main_component;
    my @violations = $policy->violates( $component );

    return @violations;
}

1;

__END__

=pod

=head1 DESCRIPTION

=cut
