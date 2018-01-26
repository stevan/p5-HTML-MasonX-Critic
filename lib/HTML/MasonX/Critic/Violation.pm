package HTML::MasonX::Critic::Violation;
# ABSTRACT: A representation of the violation in Mason

use strict;
use warnings;

use Carp                ();
use Scalar::Util        ();
use String::Format      ();
use File::Basename      ();
use Perl::Critic::Utils ();

use HTML::MasonX::Critic::Violation::SourceFile;
use HTML::MasonX::Critic::Violation::BlameFile;

our $VERSION = '0.01';

use overload '""' => 'to_string';

use parent 'UNIVERSAL::Object';
use slots (
    description   => sub { die 'A `description` must be provided'  },
    explanation   => sub { die 'An `explanation` must be provided' },
    policy        => sub { die 'An `policy` must be provided'      },
    element       => sub { die 'An `element` must be provided'     },
    # private data
    _filename      => sub {},
    _source        => sub {},
    _line_number   => sub {},
    _column_number => sub {},
    _highlight     => sub {},
);

sub BUILD {
    my ($self, $params) = @_;

    Carp::confess('The `element` must be an object which responds to the following methods: filename, source, line_number, column_number')
        unless Scalar::Util::blessed( $self->{element} )
            && $self->{element}->can('filename')
            && $self->{element}->can('source')
            && $self->{element}->can('line_number')
            && $self->{element}->can('column_number');

    # NOTE:
    # grab this information now, otherwise it is
    # possible that these values in the element
    # might get garbage collected because PPI
    # is so freakin' insane about that stuff.
    # - SL
    $self->{_filename}      = $self->{element}->filename;
    $self->{_source}        = $self->{element}->source;
    $self->{_line_number}   = $self->{element}->line_number;
    $self->{_column_number} = $self->{element}->column_number;

    if ( $self->{element}->can('highlight') ) {
        $self->{_highlight} = $self->{element}->highlight;
    }
}

## accessors

sub description   { $_[0]->{description}    }
sub explanation   { $_[0]->{explanation}    }
sub policy        { $_[0]->{policy}         }
sub filename      { $_[0]->{_filename}      }
sub source        { $_[0]->{_source}        }
sub line_number   { $_[0]->{_line_number}   }
sub column_number { $_[0]->{_column_number} }
sub highlight     { $_[0]->{_highlight}     }

## the associated source file ...

sub source_file { HTML::MasonX::Critic::Violation::SourceFile->new( violation => $_[0] ) }

sub blame_file {
    my ($self, %opts) = @_;

    Carp::confess('A `git_work_tree` is required to create a BlameFile object')
        unless exists $opts{git_work_tree};

    Carp::confess('The `git_work_tree` must be a valid directory')
        unless -d $opts{git_work_tree};

    HTML::MasonX::Critic::Violation::BlameFile->new(
        violation     => $_[0],
        git_work_tree => $opts{git_work_tree},
    );
}

## Fulfill the expected interface ...

sub severity { 1 } # we don't mess around

*logical_filename    = \&filename;
*logical_line_number = \&line_number;

# NOTE:
# this whole &to_string and &{get,set}_format
# thing is stolen from Perl::Critic.
# - SL

my $format = Perl::Critic::Utils::verbosity_to_format;

sub set_format { $format = Perl::Critic::Utils::verbosity_to_format( $_[0] ) }
sub get_format { $format }

sub to_string {
    my $self = shift;

    return String::Format::stringf(
        $format => (
            'f' => sub { $self->logical_filename },
            'g' => sub { $self->filename },
            'F' => sub { File::Basename::basename( $self->logical_filename ) },
            'G' => sub { File::Basename::basename( $self->filename ) },
            'l' => sub { $self->logical_line_number },
            'L' => sub { $self->line_number },
            'c' => sub { $self->column_number },
            'C' => sub { Scalar::Util::blessed( $self->{element} ) },
            'm' => $self->description,
            'e' => $self->explanation,
            's' => $self->severity,
            'P' => $self->policy,
            'p' => ($self->policy =~ s/^.*\:\:Critic\:\:Policy\:\://r), # /
            'd' => sub { $self->explanation },
            'r' => sub { $self->source },
        )
    );
}

1;

__END__

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
