package App::Sloop::Command;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Text::ANSITable ();

use App::Cmd::Setup -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'verbose|v', 'display additional information', { default => $App::HTML::MasonX::Sloop::CONFIG{'VERBOSE'}                     } ],
        [ 'debug|d',   'display debugging information',  { default => $App::HTML::MasonX::Sloop::CONFIG{'DEBUG'}, implies => 'verbose' } ],
    );
}

sub draw_table {
    my ($self, $cols, @rows) = @_;

    my $opts = {};
    $opts = pop @rows if ref $rows[-1] eq 'HASH';

    my %opts = ();
    if ( $opts->{no_border} ) {
        $opts{border_style} = 'Default::singlei_boxchar';
    }
    elsif ( $opts->{container} ) {
        $opts{border_style} = 'Default::singleo_utf8';
    }
    else {
        $opts{border_style} = 'Default::single_ascii';
    }

    my $t = Text::ANSITable->new(
        use_utf8           => 1,
        use_box_chars      => 1,
        show_row_separator => (exists $opts->{show_row_separator} ? 1 : 0),
        %opts
    );

    $t->columns($cols);
    $opts->{set_column_style}->( $t )
        if exists $opts->{set_column_style};

    foreach my $row (@rows) {
        $t->add_row( $row );
    }

    my $output = $t->draw;

    return $output;
}

1;

__END__

# ABSTRACT: Base command class

=pod

=head1 DESCRIPTION

=cut
