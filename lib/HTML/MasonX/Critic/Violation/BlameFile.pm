package HTML::MasonX::Critic::Violation::BlameFile;
# ABSTRACT: The git blamed source file associated with a violation

use strict;
use warnings;

our $VERSION = '0.01';

use Git::Wrapper;

use HTML::MasonX::Critic::Violation::BlameFile::Line;

use HTML::MasonX::Critic::Violation::SourceFile;
our @ISA; BEGIN { @ISA = ('HTML::MasonX::Critic::Violation::SourceFile') }
our %HAS; BEGIN {
    %HAS = (
        %HTML::MasonX::Critic::Violation::SourceFile::HAS,
        # private data
        _git          => sub {},
    )
}


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

    my ($sha, $metadata, $line_num, $line) = ($blame_line =~ /^([a-f0-9]+) \((.*) (\d+)\) (.*)$/);
    my ($author, $date) = ($metadata =~ /^(.*) (\d\d\d\d\-\d\d\-\d\d .*)$/);

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

