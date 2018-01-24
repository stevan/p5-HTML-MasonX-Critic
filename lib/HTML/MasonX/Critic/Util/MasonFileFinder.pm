package HTML::MasonX::Critic::Util::MasonFileFinder;
# ABSTRACT: Utility module to locate Mason files

use strict;
use warnings;

our $VERSION = '0.01';

use Path::Tiny         ();
use Directory::Scanner ();

use UNIVERSAL::Object;

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        root_dir => sub { die 'A `root_dir` is required' },
    )
}

## ...

our @MASON_FILES                          = qw( autohandlers dhandlers handler );
our @MASON_EXTENSIONS                     = qw( m mc mi mas mason comp );
our @MASON_MIGHT_EXECUTE_THESE_EXTENSIONS = qw( html xml json txt csv );
our @FILES_MASON_WILL_SKIP                = qw( png jpg jpeg gif ts js css ico );

our $MASON_FILES                          = join '|' => @MASON_FILES;
our $MASON_EXTENSIONS                     = join '|' => @MASON_EXTENSIONS;
our $MASON_MIGHT_EXECUTE_THESE_EXTENSIONS = join '|' => @MASON_MIGHT_EXECUTE_THESE_EXTENSIONS;
our $FILES_MASON_WILL_SKIP                = join '|' => @FILES_MASON_WILL_SKIP;

## ...

sub find_all_mason_files {
    my ($self) = @_;

    my $dir = $self->{root_dir};

    my $stream = Directory::Scanner->for( $dir )
        ->ignore(sub {
            my $base = $_->basename;
            my $rel  = $_->relative( $dir )->stringify;

            $base =~ /^\./ # ignore hidden things ...
                ||
            $base eq 'package.json' # ignore things we can ignore ...
                ||
            (
                $_->is_dir # ignore some dirs ...
                &&
                (
                    # vendor code
                    $base eq 'vendor'
                        ||
                    # static things
                    $base eq 'static'
                )
            )
        })
        ->recurse
        ->match(sub {
            my $base = $_->basename;

            $_->is_file
                &&
            $base !~ /\.($FILES_MASON_WILL_SKIP)$/
                &&
            (
                $base =~ /^($MASON_FILES)$/
                    ||
                $base =~ /\.($MASON_EXTENSIONS)$/
                    ||
                $base =~ /\.($MASON_MIGHT_EXECUTE_THESE_EXTENSIONS)$/
            )
        })
    ;

    return $stream;
}


1;

__END__

=pod

=head1 DESCRIPTION

=cut

