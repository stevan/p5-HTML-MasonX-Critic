package HTML::MasonX::Inspector::Compiler::Component::PerlCode;

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

sub starting_line_number {
    my ($self) = @_;

    my $code = ${ $_[0]->{source} };

    my ($line_number) = ($code =~ /^#line (\d*)/);

    Carp::confess('Unable to find line number in:['.$code.']')
        if $code && not $line_number;

    return $code ? $line_number : 0;
}

sub find_with_ppi {
    my ($self, $ppi_class, $cb) = @_;

    my $results = $self->{_ppi}->find( $ppi_class );
    # we found nothing ...
    return unless $results;
    # we found stuff, but want to filter it ...
    return grep { $cb->($_) } @$results if $cb;
    # we found stuff and just want it ...
    return @$results;
}


1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::Util::Perl - HTML::Mason::Compiler sea cucumber guts

=head1 DESCRIPTION

=cut
