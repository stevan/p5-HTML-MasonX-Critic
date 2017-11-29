package HTML::MasonX::Inspector::Query::PerlCritic;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();
use Perl::Critic ();

sub critique_object_code {
    my ($class, $object_code, %opts) = @_;

    Carp::confess('The object code must be an instance of `HTML::MasonX::Inspector::ObjectCode`')
        unless Scalar::Util::blessed($object_code)
            && $object_code->isa('HTML::MasonX::Inspector::ObjectCode');

    my $critic     = exists $opts{perl_critic} ? $opts{perl_critic} : Perl::Critic->new( %opts );
    my $code       = $object_code->object_code;
    my @violations = $critic->critique( $code );

    return @violations;
}

sub critique_compiler_component {
    my ($class, $compiler, %opts) = @_;

    Carp::confess('The compiler must be an instance of `HTML::MasonX::Inspector::Compiler`')
        unless Scalar::Util::blessed($compiler)
            && $compiler->isa('HTML::MasonX::Inspector::Compiler');

    my $critic   = exists $opts{perl_critic} ? $opts{perl_critic} : Perl::Critic->new( %opts );
    my $filename = $compiler->comp_path;
    my $comp     = $compiler->get_main_component;
    my $blocks   = $comp->blocks;

    my @code;

    # Compile Time ...

    push @code => "## == Compile Time ========================\n\n";
    push @code => "use strict;\n"   if $compiler->use_strict;
    push @code => "use warnings;\n" if $compiler->use_warnings;

    push @code => "## -- global args -------------------------\n";
    push @code => ('our ('.(join ', ' => map { $_ } $compiler->allow_globals).");\n");

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

    if ( my $preamble = $compiler->preamble ) {
        push @code => "## -- preamble -------------------------\n";
        push @code => $preamble;
    }

    push @code => "## -- body --------------------------------\n";
    push @code => $comp->body->raw;

    if ( $blocks->has_cleanup_blocks ) {
        push @code => "## -- cleanup blocks -----------------------\n";
        push @code => map $_->raw, @{ $blocks->cleanup_blocks };
    }

    if ( my $postamble = $compiler->postamble ) {
        push @code => "## -- postamble -------------------------\n";
        push @code => $postamble;
    }

    push @code => "\n## == End =================================\n";

    my $code       = join '' => @code;
    my @violations = $critic->critique( \$code );

    #warn $code;

    return @violations;
}


1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::Query::PerlCritic - HTML::Mason::Compiler sea cucumber guts

=head1 DESCRIPTION

=cut
