package App::Sloop::Command::DumpObjectCode;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use HTML::MasonX::Inspector;

use App::Sloop -command;

sub command_names { 'dump-object-code' }

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'comp-root=s', 'HTML::Mason comp_root', { default => $App::Sloop::CONFIG{'COMP_ROOT'} } ],
        [],
        $class->SUPER::opt_spec,
    )
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($path) = @$args;

    my $i = HTML::MasonX::Inspector->new( comp_root => $opt->comp_root );

    print $i->get_object_code_for_path( $path )->source, "\n";
}

1;

__END__

# ABSTRACT: Non-representational

=pod

=head1 DESCRIPTION

FEED ME!

=cut
