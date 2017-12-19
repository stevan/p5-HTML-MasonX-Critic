package HTML::MasonX::Critic::Violation::SourceFile;
# ABSTRACT: The source file associated with a violation

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Critic::Violation::SourceFile::Line;

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        violation     => sub { die 'A `violation` is required' },
        # private data
        _path         => sub {},
        _source_lines => sub {},
    )
}


sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('The violation must reference a valid filename, not ('.$self->{violation}->logical_filename.')')
        unless -f $self->{violation}->logical_filename;

    $self->{_path}         = Path::Tiny::path( $self->{violation}->logical_filename );
    $self->{_source_lines} = [ split /\n/ => $self->{violation}->source ];
}

sub get_violation_lines {
    my ($self, %opts) = @_;

    my $start = $self->{violation}->logical_line_number;
    my $end   = $start + scalar @{ $self->{_source_lines} };

    my $violation_start = $start;
    my $violation_end   = $end;

    my @lines;
    if ( $opts{before} || $opts{after} ) {
        if ( my $lines_before = $opts{before} ) {
            $start -= $lines_before;
            $start = 1 if $start <= 0;
        }

        if ( my $lines_after = $opts{after} ) {
            $end += $lines_after;
        }

        @lines = $self->get_lines_at( $start, $end );
    }
    elsif ( $opts{all} ) {
        @lines = $self->get_all_lines;
    }
    else {
        @lines = $self->get_lines_at( $start, $end );
    }

    foreach my $line ( @lines ) {
        $line->in_violation(1)
            if $line->is_in_between( $violation_start, $violation_end );
    }

    return @lines;
}

sub get_lines_at {
    my ($self, $start, $end) = @_;

    my @lines;

    my $starting_line       = $start;
       $starting_line       = 1 if $starting_line <= 0;
    my $lines_to_capture    = $end - $start;
    my $line_number_counter = $starting_line;

    my $fh = $self->{_path}->openr;

    # skip to the start line ....
    $fh->getline  while --$starting_line;

    while ( not($fh->eof) && $lines_to_capture ) {
        push @lines => HTML::MasonX::Critic::Violation::SourceFile::Line->new(
            line_num => $line_number_counter,
            line     => $fh->getline
        );
        $lines_to_capture--;
        $line_number_counter++;
    }

    $fh->close;

    return @lines;
}

sub get_all_lines {
    my ($self) = @_;

    my @lines;

    my $line_number_counter = 1;

    my $fh = $self->{_path}->openr;
    while ( not($fh->eof) ) {
        push @lines => HTML::MasonX::Critic::Violation::SourceFile::Line->new(
            line_num => $line_number_counter,
            line     => $fh->getline
        );
        $line_number_counter++;
    }

    $fh->close;

    return @lines;
}

1;

__END__

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

