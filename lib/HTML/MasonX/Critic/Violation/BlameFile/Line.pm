package HTML::MasonX::Critic::Violation::BlameFile::Line;
# ABSTRACT: A line in a source file associated with a violation

use strict;
use warnings;

our $VERSION = '0.01';

use parent 'HTML::MasonX::Critic::Violation::SourceFile::Line';
use slots (
    sha    => sub {},
    author => sub {},
    date   => sub {},
);

sub metadata {
    my ($self) = @_;
    sprintf '%s (%s %s) %04d' => (
        $self->sha,
        $self->author,
        $self->date,
        $self->line_num
    )
}

sub sha    { $_[0]->{sha}    }
sub author { $_[0]->{author} }
sub date   { $_[0]->{date}   }

1;

__END__

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

