package HTML::MasonX::Critic;
# ABSTRACT: Critique HTML::Mason pages

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();

use HTML::MasonX::Inspector;

use HTML::MasonX::Inspector::Query::PerlCritic;

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

    $self->{_inspector} = HTML::MasonX::Inspector->new(
        comp_root    => $self->{comp_root},
        use_warnings => 1, # FIXME - not sure how, but this is ugly
    );

    my $config = $self->{config};

    # convert the perl-critic-* stuff to fit proper Perl::Critic args
    $self->{_perl_critic_config} = {
        ($config->{perl_critic_severity} ? ('-severity'      => $config->{perl_critic_severity}) : ()),
        ($config->{perl_critic_policy}   ? ('-single-policy' => $config->{perl_critic_policy})   : ()),
        ($config->{perl_critic_profile}  ? ('-profile'       => $config->{perl_critic_profile})  : ()),
        ($config->{perl_critic_theme}    ? ('-theme'         => $config->{perl_critic_theme})    : ()),
    };

    # stuff for Mason::Critic ...
    $self->{_mason_critic_config} = {

    };
}


sub critique {
    my ($self, $file) = @_;

    my $compiler   = $self->{_inspector}->get_compiler_inspector_for_path( $file );
    my @violations = HTML::MasonX::Inspector::Query::PerlCritic->critique_compiler_component(
        $compiler,
        %{ $self->{_perl_critic_config} }
    );

    return @violations;
}


1;

__END__

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
