package App::Sloop::CompilerReportGenerator;

use strict;
use warnings;

our $VERSION = '0.01';

use DBI          ();
use Carp         ();
use Scalar::Util ();

use App::Sloop ();

use UNIVERSAL::Object;

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
	%HAS = (
		git_sha   => sub { die 'A `git_sha` is required' },
		comp_root => sub { die 'A `comp_root` is required' },
		# ...
		_dbh              => sub {},
		_database_file    => sub {},
		_current_file_id  => sub {},
		_current_block_id => sub {},
	)
}

sub BUILD {
	my ($self, $params) = @_;

	my $data_root = Path::Tiny::path( $App::Sloop::CONFIG{'DATA_ROOT'} )->child('compiler-report');

    $self->{_database_file} = $data_root->child( 'reports' )->child( $self->{git_sha} );
}

sub report_database_file { $_[0]->{_database_file} }

sub init_report {
	my ($self) = @_;

	$self->init_dbh;
	$self->setup_report_tables;
}

sub finish_report {
	my ($self) = @_;

	$self->{_dbh}->disconnect;
}

## ...

sub init_dbh {
	my ($self) = @_;

    Carp::confess('A database file already exists ('.$self->{_database_file}.')')
    	if -e $self->{_database_file};

    $self->{_dbh} = DBI->connect(
        ('dbi:SQLite:dbname='.$self->{_database_file}, '', ''),
        { PrintError => 0, RaiseError => 1 }
    );
}

sub setup_report_tables {
	my ($self) = @_;

	$self->{_dbh}->do(q[
		CREATE TABLE `file` (
		    `file_id`   INTEGER,
			`path`      TEXT NOT NULL,
			`checksum`  TEXT NOT NULL,

			PRIMARY KEY(`file_id` ASC)
		)
	]);

	$self->{_dbh}->do(q[
		CREATE TABLE `arg` (
		    `arg_id`         INTEGER,
		    `name`           TEXT NOT NULL,
		    `default`        TEXT NOT NULL,
		    `has_constraint` BOOLEAN NOT NULL,
			`line_number`    INTEGER NOT NULL,
			`file_id`        INTEGER NOT NULL, -- refs file.file_id

			PRIMARY KEY(`arg_id` ASC),
			FOREIGN KEY(`file_id`) REFERENCES file(`file_id`)
		)
	]);

	$self->{_dbh}->do(q[
		CREATE TABLE `flag` (
		    `flag_id` INTEGER,
		    `name`    TEXT NOT NULL,
		    `value`   TEXT NOT NULL,
			`file_id` INTEGER NOT NULL, -- refs file.file_id

			PRIMARY KEY(`flag_id` ASC),
			FOREIGN KEY(`file_id`) REFERENCES file(`file_id`)
		)
	]);

	$self->{_dbh}->do(q[
		CREATE TABLE `attr` (
		    `attr_id` INTEGER,
		    `name`    TEXT NOT NULL,
		    `value`   TEXT NOT NULL,
			`file_id` INTEGER NOT NULL, -- refs file.file_id

			PRIMARY KEY(`attr_id` ASC),
			FOREIGN KEY(`file_id`) REFERENCES file(`file_id`)
		)
	]);

	$self->{_dbh}->do(q[
		CREATE TABLE `def` (
		    `def_id`          INTEGER,
		    `name`            TEXT NOT NULL,
		    `arg_count` 	  INTEGER NOT NULL,
		    `body_size` 	  INTEGER NOT NULL,
		    `body_line_count` INTEGER NOT NULL,
			`file_id`         INTEGER NOT NULL, -- refs file.file_id

			PRIMARY KEY(`def_id` ASC),
			FOREIGN KEY(`file_id`) REFERENCES file(`file_id`)
		)
	]);

	$self->{_dbh}->do(q[
		CREATE TABLE `method` (
		    `method_id` 	  INTEGER,
		    `name`      	  TEXT NOT NULL,
		    `arg_count` 	  INTEGER NOT NULL,
		    `body_size` 	  INTEGER NOT NULL,
		    `body_line_count` INTEGER NOT NULL,
			`file_id`         INTEGER NOT NULL, -- refs file.file_id

			PRIMARY KEY(`method_id` ASC),
			FOREIGN KEY(`file_id`) REFERENCES file(`file_id`)
		)
	]);

	# TODO:
	# - method/def-args should be its own table
	# - method/def-body should be added to the block
	#   table and associated ID stored in method

	$self->{_dbh}->do(q[
		CREATE TABLE `violation` (
		    `violation_id`  INTEGER,
			`line_number`   INTEGER NOT NULL,
			`column_number` INTEGER NOT NULL,
			`severity`      INTEGER NOT NULL,
		    `policy`        TEXT NOT NULL,
			`source`        TEXT NOT NULL,
			`description`   TEXT NOT NULL,
			`file_id`       INTEGER NOT NULL, -- refs file.file_id

			PRIMARY KEY(`violation_id` ASC),
			FOREIGN KEY(`file_id`) REFERENCES file(`file_id`)
		)
	]);

	$self->{_dbh}->do(q[
		CREATE TABLE `block` (
		    `block_id`              INTEGER,
			`type`                  TEXT NOT NULL,
			`checksum`              TEXT NOT NULL,
			`size`                  INTEGER NOT NULL,
			`lines`                 INTEGER NOT NULL,
			`starting_line_number`  INTEGER NOT NULL,
			`does_mason_postproc`   BOOLEAN NOT NULL,
			`might_abort_request`   BOOLEAN NOT NULL,
			`might_redirect_user`   BOOLEAN NOT NULL,
			`complexity_score`      INTEGER NOT NULL,
			`number_of_includes`    INTEGER NOT NULL,
			`number_of_constants`   INTEGER NOT NULL,
			`number_of_subroutines` INTEGER NOT NULL,
			`file_id`               INTEGER NOT NULL, -- refs file.file_id

			PRIMARY KEY(`block_id` ASC),
			FOREIGN KEY(`file_id`) REFERENCES file(`file_id`)
		)
	]);

	$self->{_dbh}->do(q[
		CREATE TABLE `include` (
		    `include_id`           INTEGER,
			`line_number`          INTEGER NOT NULL,
			`column_number`        INTEGER NOT NULL,
			`type`                 TEXT NOT NULL,
		    `module`               TEXT NOT NULL,
		    `number_of_imports`    INTEGER NOT NULL,
		    `is_conditional`       BOOLEAN NOT NULL,
		    `does_not_call_import` BOOLEAN NOT NULL,
			`block_id`             INTEGER NOT NULL, -- refs block.block_id

			PRIMARY KEY(`include_id` ASC),
			FOREIGN KEY(`block_id`) REFERENCES block(`block_id`)
		)
	]);

	$self->{_dbh}->do(q[
		CREATE TABLE `import` (
		    `import_id`  INTEGER,
			`token`      TEXT NOT NULL,
			`is_tag`     BOOLEAN NOT NULL,
			`include_id` INTEGER NOT NULL, -- refs include.include_id

			PRIMARY KEY(`import_id` ASC),
			FOREIGN KEY(`include_id`) REFERENCES include(`include_id`)
		)
	]);

	$self->{_dbh}->do(q[
		CREATE TABLE `constant` (
		    `constant_id` INTEGER,
		    `line_number`   INTEGER NOT NULL,
			`column_number` INTEGER NOT NULL,
			`symbol`        TEXT NOT NULL,
			`arguments`     TEXT NOT NULL,
			`block_id`      INTEGER NOT NULL, -- refs block.block_id

			PRIMARY KEY(`constant_id` ASC),
			FOREIGN KEY(`block_id`) REFERENCES block(`block_id`)
		)
	]);

	$self->{_dbh}->do(q[
		CREATE TABLE `subroutine` (
		    `subroutine_id` INTEGER,
		    `line_number`   INTEGER NOT NULL,
			`column_number` INTEGER NOT NULL,
			`symbol`        TEXT NOT NULL,
			`block_id`      INTEGER NOT NULL, -- refs block.block_id

			PRIMARY KEY(`subroutine_id` ASC),
			FOREIGN KEY(`block_id`) REFERENCES block(`block_id`)
		)
	]);
}

## Inserts ...

sub insert_new_file {
	my ($self, $path, $checksum) = @_;

	Carp::confess('You must specify a path')
		unless defined $path;

	Carp::confess('The path must be an instance of Path::Tiny')
		unless Scalar::Util::blessed($path) && $path->isa('Path::Tiny');

	Carp::confess('You must specify a checksum')
		unless defined $checksum;

	my $SQL = q[
		INSERT INTO `file` (
			`path` ,
			`checksum`
		) VALUES(?, ?)
	];

	$self->{_dbh}->do(
		$SQL, {},
		$path->stringify,
		$checksum
	);

	$self->{_current_file_id}  = $self->{_dbh}->last_insert_id( undef, undef, undef, undef, {} );
	$self->{_current_block_id} = undef;
}

sub insert_args {
	my ($self, @args) = @_;

	Carp::confess('Cannot insert args without current file')
		unless $self->{_current_file_id};

	my $SQL = q[
		INSERT INTO `arg` (
			`name` ,
			`default`,
			`has_constraint`,
			`line_number`,
			`file_id`
		) VALUES(?, ?, ?, ?, ?)
	];

	foreach my $arg ( @args ) {
		$self->{_dbh}->do(
			$SQL, {},
			$arg->{name},
			$arg->{default},
			$arg->{has_constraint},
			$arg->{line_number},
			$self->{_current_file_id},
		);
	}
}

sub insert_flags {
	my ($self, @flags) = @_;

	Carp::confess('Cannot insert flags without current file')
		unless $self->{_current_file_id};

	my $SQL = q[
		INSERT INTO `flag` (
			`name`,
			`value`,
			`file_id`
		) VALUES(?, ?, ?)
	];

	foreach my $flag ( @flags ) {
		$self->{_dbh}->do(
			$SQL, {},
			$flag->{name},
			$flag->{value},
			$self->{_current_file_id},
		);
	}
}

sub insert_attr {
	my ($self, @attrs) = @_;

	Carp::confess('Cannot insert attr without current file')
		unless $self->{_current_file_id};

	my $SQL = q[
		INSERT INTO `attr` (
			`name`,
			`value`,
			`file_id`
		) VALUES(?, ?, ?)
	];

	foreach my $attr ( @attrs ) {
		$self->{_dbh}->do(
			$SQL, {},
			$attr->{name},
			$attr->{value},
			$self->{_current_file_id},
		);
	}
}

sub insert_defs {
	my ($self, @defs) = @_;

	Carp::confess('Cannot insert defs without current file')
		unless $self->{_current_file_id};

	my $SQL = q[
		INSERT INTO `def` (
			`name`,
			`arg_count`,
			`body_size`,
			`body_line_count`,
			`file_id`
		) VALUES(?, ?, ?, ?, ?)
	];

	foreach my $def ( @defs ) {
		$self->{_dbh}->do(
			$SQL, {},
			$def->{name},
			(scalar @{ $def->{args} }),
			$def->{body}->size,
			$def->{body}->lines,
			$self->{_current_file_id},
		);
	}

	# TODO: def args
	# TODO: def body
}

sub insert_methods {
	my ($self, @methods) = @_;

	Carp::confess('Cannot insert methods without current file')
		unless $self->{_current_file_id};

	my $SQL = q[
		INSERT INTO `method` (
			`name` ,
			`arg_count`,
			`body_size`,
			`body_line_count`,
			`file_id`
		) VALUES(?, ?, ?, ?, ?)
	];

	foreach my $method ( @methods ) {
		$self->{_dbh}->do(
			$SQL, {},
			$method->{name},
			(scalar @{ $method->{args} }),
			$method->{body}->size,
			$method->{body}->lines,
			$self->{_current_file_id},
		);
	}

	# TODO: method args
	# TODO: method body
}

sub insert_violations {
	my ($self, @violations) = @_;

	Carp::confess('Cannot insert new violation without current file')
		unless $self->{_current_file_id};

	my $SQL = q[
		INSERT INTO `violation` (
			`line_number`,
			`column_number`,
			`severity`,
			`policy`,
			`source`,
			`description`,
			`file_id`
		) VALUES(?, ?, ?, ?, ?, ?, ?)
	];

	foreach my $violation ( @violations ) {
		$self->{_dbh}->do(
			$SQL, {},
			$violation->line_number,
			$violation->column_number,
			$violation->severity,
			$violation->policy,
			$violation->source,
			$violation->description,
			$self->{_current_file_id},
		);
	}
}

sub insert_new_block {
	my ($self, $type, $block) = @_;

	Carp::confess('You must specify a type')
		unless defined $type;

	Carp::confess('You must specify a block')
		unless defined $block;

	Carp::confess('The block must be an instance of HTML::MasonX::Inspector::PerlSource')
		unless Scalar::Util::blessed($block)
			&& $block->isa('HTML::MasonX::Inspector::PerlSource');

	Carp::confess('Cannot insert new block without current file')
		unless $self->{_current_file_id};

	my $SQL = q[
		INSERT INTO `block` (
			`type`,
			`checksum`,
			`size`,
			`lines`,
			`starting_line_number`,
			`does_mason_postproc`,
			`might_abort_request`,
			`might_redirect_user`,
			`complexity_score`,
			`number_of_includes`,
			`number_of_constants`,
			`number_of_subroutines`,
			`file_id`
		) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	];

	$self->{_dbh}->do(
		$SQL, {},
		$type,
		$block->checksum,
		$block->size,
		$block->lines,
		$block->starting_line_number,
		$block->does_mason_postproc,
		$block->might_abort_request,
		$block->might_redirect_user,
		$block->complexity_score,
		$block->number_of_includes,
		$block->number_of_constants,
		$block->number_of_subroutines,
		$self->{_current_file_id},
	);

	$self->{_current_block_id} = $self->{_dbh}->last_insert_id( undef, undef, undef, undef, {} );
}

sub insert_new_include {
	my ($self, $include) = @_;

	Carp::confess('You must specify an include')
		unless defined $include;

	Carp::confess('Cannot insert new include without current block')
		unless $self->{_current_block_id};

	my $include_SQL = q[
		INSERT INTO `include` (
			`line_number`,
			`column_number`,
			`type`,
			`module`,
			`number_of_imports`,
			`is_conditional`,
			`does_not_call_import`,
			`block_id`
		) VALUES(?, ?, ?, ?, ?, ?, ?, ?)
	];

	$self->{_dbh}->do(
		$include_SQL, {},
		$include->line_number,
		$include->column_number,
		$include->type,
		$include->module,
		$include->number_of_imports,
		$include->is_conditional,
		$include->does_not_call_import,
		$self->{_current_block_id},
	);

	my $include_id = $self->{_dbh}->last_insert_id( undef, undef, undef, undef, {} );
	my $import_SQL = q[
		INSERT INTO `import` (
			`token`,
			`is_tag`,
			`include_id`
		) VALUES(?, ?, ?)
	];

	foreach my $import ( $include->imports ) {
		$self->{_dbh}->do(
			$import_SQL, {},
			$import->token,
			$import->is_tag,
			$include_id
		);
	}
}

sub insert_new_constant {
	my ($self, $constant) = @_;

	Carp::confess('You must specify an constant')
		unless defined $constant;

	Carp::confess('Cannot insert new constant without current block')
		unless $self->{_current_block_id};

	my $constant_SQL = q[
		INSERT INTO `constant` (
			`line_number`,
			`column_number`,
			`symbol`,
			`arguments`,
			`block_id`
		) VALUES(?, ?, ?, ?, ?)
	];

	$self->{_dbh}->do(
		$constant_SQL, {},
		$constant->line_number,
		$constant->column_number,
		$constant->symbol,
		(join ', ' => $constant->arguments),
		$self->{_current_block_id},
	);
}

sub insert_new_subroutine {
	my ($self, $subroutine) = @_;

	Carp::confess('You must specify an subroutine')
		unless defined $subroutine;

	Carp::confess('Cannot insert new subroutine without current block')
		unless $self->{_current_block_id};

	my $subroutine_SQL = q[
		INSERT INTO `subroutine` (
			`line_number`,
			`column_number`,
			`symbol`,
			`block_id`
		) VALUES(?, ?, ?, ?)
	];

	$self->{_dbh}->do(
		$subroutine_SQL, {},
		$subroutine->line_number,
		$subroutine->column_number,
		$subroutine->symbol,
		$self->{_current_block_id},
	);
}

1;

__END__

=pod

=cut
