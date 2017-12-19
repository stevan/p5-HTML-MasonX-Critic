package HTML::MasonX::Critic::Inspector::Compiler::Component::PerlCode;
# ABSTRACT: Compile time view of a peice of Perl code in a Mason component

use strict;
use warnings;

our $VERSION = '0.01';

use Digest::MD5 ();
use PPI         ();

use UNIVERSAL::Object;

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        source    => sub { die 'Some `source` is required' },
        # ... internal fields
        _ppi      => sub {},
        _checksum => sub {},
        _lines    => sub {},
    )
}

sub BUILD {
    my ($self, $params) = @_;

    $self->{_ppi} = PPI::Document->new( $self->{source}, readonly => 1 );
}

## Info ...

sub ppi  { $_[0]->{_ppi}        }
sub raw  { ${ $_[0]->{source} } }
sub size { length $_[0]->raw    }

sub lines  {
    my ($self) = @_;
    $self->{_lines} //= scalar split /\n/ => ${ $self->{source} };
}

sub checksum {
    my ($self) = @_;
    $self->{_checksum} //= Digest::MD5::md5_hex( $self->raw );
}

sub discover_filename {
    my ($self) = @_;

    my $code = ${ $_[0]->{source} };

    my ($filename) = ($code =~ /^#line \d* \"(.*)\"/);

    Carp::confess('Unable to find filename in:['.$code.']')
        if $code && not $filename;

    return $filename;
}

sub starting_line_number {
    my ($self) = @_;

    my $code = ${ $_[0]->{source} };

    my ($line_number) = ($code =~ /^#line (\d*)/);

    Carp::confess('Unable to find line number in:['.$code.']')
        if $code && not $line_number;

    return $code ? $line_number : 0;
}

sub find_with_ppi {
    my ($self, %opts) = @_;

    my ($node_type, $filter, $transform) = @opts{qw[ node_type filter transform ]};

    my @results = @{ $self->{_ppi}->find( $node_type ) || [] };
    return unless @results;

    @results = grep { $filter->($_)    } @results if $filter;
    @results = map  { $transform->($_) } @results if $transform;
    return @results;
}


1;

__END__

=pod

=head1 DESCRIPTION

=cut
