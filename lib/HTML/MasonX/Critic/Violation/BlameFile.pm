package HTML::MasonX::Critic::Violation::BlameFile;
# ABSTRACT: The git blamed source file associated with a violation

use strict;
use warnings;

use Git::Wrapper;

use HTML::MasonX::Critic::Violation::BlameFile::Line;

our $VERSION = '0.01';

use parent 'HTML::MasonX::Critic::Violation::SourceFile';
use slots (
    # private data
    _git => sub {},
);

sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('A `git_work_tree` is required to create a BlameFile object')
        unless exists $params->{git_work_tree};

    Carp::confess('The `git_work_tree` must be a valid directory')
        unless -d $params->{git_work_tree};

    $self->{_git} = Git::Wrapper->new( $params->{git_work_tree} );
}

sub get_lines_at {
    my ($self, $start, $end) = @_;

    my $line_count = scalar $self->{_path}->lines;
    $end = $line_count if $end > $line_count;

    my @lines = $self->{_git}->blame(
        $self->{_path}->relative( $self->{_git}->dir ),
        {
            L => (join ',' => $start, $end )
        }
    );

    @lines = map $self->_convert_blame_lines( $_ ), @lines;

    return @lines;
}

sub get_all_lines {
    my ($self) = @_;

    my @lines = $self->{_git}->blame(
        $self->{_path}->relative( $self->{_git}->dir )
    );

    @lines = map $self->_convert_blame_lines( $_ ), @lines;

    return @lines;
}

## ...

sub _convert_blame_lines {
    my ($self, $blame_line) = @_;


    my ($sha, $info, $line) = ($blame_line =~ /([0-9a-f]+)\s[A-Za-z0-9_\.\/]*\s*\((\w*[^\)]*)\)\s(.*)$/);

    # first we ...
    # we match the line number
    my ($line_num) = ($info =~ /\s+(\d+)$/);
    # then strip off the line number
    $info =~ s/\s+\d+$//;
    # next we ...
    # extract the date by anchoring
    # from the rear of the string
    my ($date) = ($info =~ /([0-9-:+\s]*)$/);

    # find out how much padding is
    # in front of the date, we need
    # to make it to the author name
    my ($padding) = ($date =~ /^(\s*)/);
    # then we ...
    # make sure to trim the leading
    # spaces that come along
    $date =~ s/^\s*//;

    # then we ...
    # use that same regexp to remove
    # the date so we are left with
    # only the author's name
    $info =~ s/([0-9-:+\s]*)$//;

    utf8::decode($info);

    my $author = $info.$padding;

    return HTML::MasonX::Critic::Violation::BlameFile::Line->new(
        line     => "$line\n", # put the \n back on ...
        line_num => $line_num,
        sha      => $sha,
        author   => $author,
        date     => $date,
    );
}

1;

__END__

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

