package App::Sloop::Command::DumpObjectCode;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use HTML::MasonX::Sloop;
use HTML::MasonX::Inspector::Util qw[ tidy_code ];

use App::Sloop -command;

sub command_names { 'dump-object-code' }

sub opt_spec {
    my ($class) = @_;
    return (
    	[ 'checksum', 'just show the checksum of the code', { default => 0 } ],
        [],
        [ 'comp-root=s', 'HTML::Mason comp_root', { default => $App::HTML::MasonX::CONFIG{'COMP_ROOT'} } ],
        [],
        $class->SUPER::opt_spec,
    )
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($path) = @$args;

    my $i = HTML::MasonX::Sloop->new( comp_root => $opt->comp_root );

    if ( $opt->checksum ) {
    	print $i->get_object_code_checksum_for_path( $path ), "\n";
    }
    else {
        warn  $i->get_object_code_checksum_for_path( $path ), "\n" if $opt->verbose;
    	print tidy_code( $i->get_object_code_for_path( $path ) ), "\n";
    }
}

1;

__END__

# ABSTRACT: Non-representational

=pod

=head1 DESCRIPTION

FEED ME!

=cut
