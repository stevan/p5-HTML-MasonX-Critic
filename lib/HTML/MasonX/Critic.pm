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
        comp_root    => sub { die 'A `comp_root` is required' },
        # ... private
        _inspector   => sub {},
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
}


sub critique {
    my ($self, $file, %critic_args) = @_;

    my $compiler   = $self->{_inspector}->get_compiler_inspector_for_path( $file );
    my @violations = HTML::MasonX::Inspector::Query::PerlCritic->critique_compiler_component(
        $compiler,
        %critic_args
    );

    return @violations;
}


1;

__END__

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
