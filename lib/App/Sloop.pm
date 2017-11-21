package App::Sloop;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

$|++; # autoflush them, autoflush them all

use Path::Tiny ();

# load our CONFIG first, ...

our %CONFIG;
BEGIN {
	$CONFIG{'COMP_ROOT'} = $ENV{'SLOOP_COMP_ROOT'} // Path::Tiny->cwd;
	$CONFIG{'DATA_ROOT'} = $ENV{'SLOOP_DATA_ROOT'} // Path::Tiny::path( __FILE__ )->parent->parent->parent->child('data');

    $CONFIG{'DEBUG'}   = $ENV{'SLOOP_DEBUG'}   // 0;
    $CONFIG{'VERBOSE'} = $ENV{'SLOOP_VERBOSE'} // 0;
}

use App::Cmd::Setup -app => {
    plugins => [
        'Prompt'
    ]
};

1;

__END__

# ABSTRACT: Mason Demolition

=pod

=head1 DESCRIPTION

This module is a set of tools to help you rid yourself of
a large L<HTML::Mason> code base.

=cut
