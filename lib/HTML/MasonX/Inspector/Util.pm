package HTML::MasonX::Inspector::Util;

use strict;
use warnings;

use Perl::Tidy  ();
use Digest::MD5 ();

our $VERSION = '0.01';

## ...

our @EXPORT_OK = qw[
	calculate_checksum
	calculate_path_for_checksum
	tidy_code
];

## ...

sub import { (shift)->import_into( scalar caller, @_ ) }

sub import_into {
    my (undef, $into, @export) = @_;
    no strict 'refs';
    *{$into.'::'.$_} = \&{$_} foreach @export;
}

## ....

sub calculate_path_for_checksum {
	my ($checksum) = @_;

	my @parts         = ($checksum =~ /^(.{1})(.{2})(.{2})/);
	my $hash_dir      = join '/' => @parts;
    my $checksum_file = join '/' => $hash_dir, $checksum;

    return $checksum_file;
}

sub calculate_checksum {
	my ($data) = @_;
	return Digest::MD5::md5_hex( $data );
}

sub tidy_code {
    my ($code) = @_;

    my $dest = '';

    # NOTE:
    # this is needed to normalize it across
    # machines (Mac & Linux versions do
    # slightly diff things for some reason)
    # - SL
    my @argv = ( "-l=80" );

    my $error_flag = Perl::Tidy::perltidy(
        source      => \$code,
        destination => \$dest,
        argv        => ( join ' ' => @argv ),
    );

    die "Could not tidy code because or an error"
      if $error_flag;

    return $dest;
}

1;

__END__

=pod

=cut
