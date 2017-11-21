package App::Sloop::Command::FindAllMasonFiles;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use App::Sloop::MasonFileFinder;

use App::Sloop -command;

sub command_names { 'find-all-mason-files' }

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'dir=s', 'the directory in which to look in', { required => 1 } ],
        [],
        $class->SUPER::opt_spec,
    )
}


sub execute {
    my ($self, $opt, $args) = @_;

    my $dir    = $opt->dir;
    my $finder = App::Sloop::MasonFileFinder->new( root_dir => $dir );
    my $files  = $finder->find_all_mason_files;

    warn sprintf "Looking for mason files in %s\n" => $dir if $opt->verbose;

    my $count = 0;
    while ( my $file = $files->next ) {
        $count++;
        print $file->relative( $dir ), "\n";
    }

    warn sprintf "Found %d files in %s\n" => $count, $dir if $opt->verbose;
}

1;

__END__

# ABSTRACT: Non-representational

=pod

=head1 DESCRIPTION

FEED ME!

=cut
