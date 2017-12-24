package HTML::MasonX::Critic;
# ABSTRACT: Critique HTML::Mason pages

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();

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

    my $compiler = $self->{_inspector}->compile_path( $file );

    my @violations;

    if ( keys %{ $self->{_perl_critic_config} } ) {
        push @violations => HTML::MasonX::Critic::Inspector::Query::Factory::PerlCritic->critique(
            $compiler,
            %{ $self->{_perl_critic_config} }
        );
    }

    if ( keys %{ $self->{_mason_critic_config} } ) {
        push @violations => HTML::MasonX::Critic::Inspector::Query::Factory::MasonCritic->critique(
            $compiler,
            %{ $self->{_mason_critic_config} }
        );
    }

    return @violations;
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
