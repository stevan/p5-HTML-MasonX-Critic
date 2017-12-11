package HTML::MasonX::Inspector::Perl::UsedModule;
# ABSTRACT: Query result objects representing used Perl modules

use strict;
use warnings;

our $VERSION = '0.01';

use Carp         ();
use Scalar::Util ();

use HTML::MasonX::Inspector::Perl::UsedModule::ImportedToken;

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        ppi => sub { die 'A `ppi` node is required' },
        # ... cache some data ...
        _imports => sub {},
    )
}

sub BUILD {
    my ($self, $params) = @_;

    #use Data::Dumper;
    #warn __PACKAGE__, Dumper $self;

 	Carp::confess('The `ppi` node must be an instance of `PPI::Statement::Include`, not '.ref($self->{ppi}))
		unless Scalar::Util::blessed( $self->{ppi} )
			&& $self->{ppi}->isa('PPI::Statement::Include');

}

sub ppi    { $_[0]->{ppi} }
sub source { $_[0]->{ppi}->content }

sub line_number   { $_[0]->{ppi}->logical_line_number }
sub column_number { $_[0]->{ppi}->column_number       }

sub type { $_[0]->{ppi}->type }

sub is_runtime    { $_[0]->{ppi}->type eq 'require' }
sub is_conditional { 0 }

sub is_pragma       { !! $_[0]->{ppi}->pragma  }
sub is_perl_version { !! $_[0]->{ppi}->version }

sub module         { $_[0]->{ppi}->module         }
sub module_version { $_[0]->{ppi}->module_version }

sub arguments { $_[0]->{ppi}->arguments }

## No import

sub does_call_import {
    my ($self) = @_;
    return ! $self->does_not_call_import;
}

sub does_not_call_import {
	my ($self) = @_;

    # check some cases that
    # can't possibly be true
    return 1 if $self->is_perl_version; # there is no `import` to call with perl versions
    return 1 if $self->is_runtime;      # `require` will not call `import`

	# we should have no imports
	return 0 unless $self->number_of_imports == 0;
	# and we should have args ...
	my @args = $self->arguments;
	return 0 unless @args;
	# well, just one arg really ...
	return 0 unless scalar @args == 1;
	# and it should be a list,
	# with no children in it
	return 1
		if $args[0]->isa('PPI::Structure::List')
		&& scalar $args[0]->schildren == 0;
	# give up if nothing else matched ...
	return 0;
}

## Imports

sub number_of_imports { return scalar $_[0]->imports }

sub imports {
	my ($self) = @_;

	my @args = $self->arguments;

	$self->{_imports} = [
		map HTML::MasonX::Inspector::Perl::UsedModule::ImportedToken->new(
			token => $_
		), $self->_flatten_import_list_from_PPI( @args )
	] unless $self->{_imports};

	return @{ $self->{_imports} }
}

## ...

sub _flatten_import_list_from_PPI {
	my ($self, @args) = @_;

	my @imports;
	foreach my $arg ( @args ) {

		# skip commas
		next if $arg->isa('PPI::Token::Operator')
			 && ($arg->content eq ',' || $arg->content eq '=>');

		# case of qw[] import list ...
		if ( $arg->isa('PPI::Token::QuoteLike::Words') ) {
			push @imports => $arg->literal;
		}
		# case of quoted string ...
		elsif ( $arg->isa('PPI::Token::Quote') ) {
			push @imports => $arg->string;
		}
		# case of bareword ...
		elsif ( $arg->isa('PPI::Token::Word') ) {
			push @imports => $arg->literal;
		}
		# case of a list expression ...
		elsif ( $arg->isa('PPI::Structure::List') ) {
			# and we can just recurse here ...
			my @children = $arg->schildren;
			push @imports => $self->_flatten_import_list_from_PPI( @children );
		}
		# case of expression (non-list)
		elsif ( $arg->isa('PPI::Statement::Expression') ) {
			# and we can just recurse here ...
			my @children = $arg->schildren;
			push @imports => $self->_flatten_import_list_from_PPI( @children );
		}
		# in case we encounter something odd ...
		else {
			use Data::Dumper;
			die "ARG: " . Dumper [ $arg, $self->{ppi} ];
		}
	}

	return @imports;
}


1;

__END__

=pod

=head1 DESCRIPTION

=cut
