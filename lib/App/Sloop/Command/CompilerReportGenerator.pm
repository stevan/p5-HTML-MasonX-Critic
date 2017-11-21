package App::Sloop::Command::CompilerReportGenerator;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Git::Wrapper;

use HTML::MasonX::Inspector;

use App::Sloop::MasonFileFinder;
use App::Sloop::CompilerReportGenerator;

use App::Sloop -command;

sub command_names { 'generate-compiler-report' }

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'dir=s',   'the directory in which to look in', { required => 1 } ],
        [ 'dry-run', 'just print out the info', { default => 0 } ],
        [],
        [ 'comp-root=s', 'HTML::Mason comp_root', { default => $App::Sloop::CONFIG{'COMP_ROOT'} } ],
        [],
        $class->SUPER::opt_spec,
    )
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $dir       = $opt->dir;
    my $comp_root = $opt->comp_root;
    my $verbose   = $opt->verbose;
    my ($sha)     = Git::Wrapper->new( $dir )->RUN('rev-parse', 'HEAD');

    my $reporter    = App::Sloop::CompilerReportGenerator->new( git_sha => $sha, comp_root => $comp_root );
    my $inspector   = HTML::MasonX::Inspector->new( comp_root => $comp_root );
    my $file_finder = App::Sloop::MasonFileFinder->new( root_dir => $dir );

    if ( -e $reporter->report_database_file ) {
        # XXX:
        # backup the old one perhaps?
        # - SL
        $reporter->report_database_file->remove;
    }

    $reporter->init_report unless $opt->dry_run;

    my $indent_depth = 0;
    my $indenter     = sub { ($_[0] // '  ') x $indent_depth };

    if ( $verbose ) {
        warn $indenter->(), 'git_sha   : ', $sha, "\n";
        warn $indenter->(), 'comp_root : ', $comp_root, "\n";
    }

    my $files = $file_finder->find_all_mason_files;

    while ( my $file = $files->next ) {
        $indent_depth++;

        my $path = $file->relative( $comp_root );

        my $checksum       = $inspector->get_object_code_checksum_for_path( $path );
        my $compiler_state = $inspector->get_compiler_for_path( $path );

        if ( $verbose ) {
            warn $indenter->('=='), "\n";
            warn $indenter->(), 'path     : ',     $path, "\n";
            warn $indenter->(), 'checksum : ', $checksum, "\n";
        }

        $reporter->insert_new_file(
            $path,
            $checksum
        ) unless $opt->dry_run;

        if ( my @args = $compiler_state->get_args ) {
            $reporter->insert_args( @args ) unless $opt->dry_run;

            warn $indenter->('--'), "\n";
            warn $indenter->(), 'args:', "\n";
            $indent_depth++;
            warn $indenter->('--'), "\n";
            foreach my $arg ( @args ) {
                warn $indenter->(), $arg->{name}, ' : ', $arg->{default}, "\n";
            }
            $indent_depth--;
        }

        if ( my @flags = $compiler_state->get_flags ) {
            $reporter->insert_flags( @flags ) unless $opt->dry_run;

            warn $indenter->('--'), "\n";
            warn $indenter->(), 'flags:', "\n";
            $indent_depth++;
            warn $indenter->('--'), "\n";
            foreach my $flag ( @flags ) {
                warn $indenter->(), $flag->{name}, "\n";
                warn $indenter->(), $flag->{value}, "\n";
            }
            $indent_depth--;
        }

        if ( my @attrs = $compiler_state->get_attr ) {
            $reporter->insert_attr( @attrs ) unless $opt->dry_run;

            warn $indenter->('--'), "\n";
            warn $indenter->(), 'attr:', "\n";
            $indent_depth++;
            warn $indenter->('--'), "\n";
            foreach my $attr ( @attrs ) {
                warn $indenter->(), $attr->{name}, "\n";
                warn $indenter->(), $attr->{value}, "\n";
            }
            $indent_depth--;
        }

        if ( my @defs = $compiler_state->get_definitions ) {
            $reporter->insert_defs( @defs ) unless $opt->dry_run;

            warn $indenter->('--'), "\n";
            warn $indenter->(), 'defs:', "\n";
            $indent_depth++;
            warn $indenter->('--'), "\n";
            foreach my $def ( @defs ) {
                warn $indenter->(), $def->{name}, "\n";
            }
            $indent_depth--;
        }

        if ( my @methods = $compiler_state->get_methods ) {
            $reporter->insert_methods( @methods ) unless $opt->dry_run;

            warn $indenter->('--'), "\n";
            warn $indenter->(), 'methods:', "\n";
            $indent_depth++;
            warn $indenter->('--'), "\n";
            foreach my $method ( @methods ) {
                warn $indenter->(), $method->{name}, "\n";
            }
            $indent_depth--;
        }

        if ( my @violations = $compiler_state->get_violations ) {
            $reporter->insert_violations( @violations ) unless $opt->dry_run;

            warn $indenter->('--'), "\n";
            warn $indenter->(), 'violations:', "\n";
            $indent_depth++;
            warn $indenter->('--'), "\n";
            foreach my $violation ( @violations ) {
                warn $indenter->(), 'line_number   : ', $violation->line_number, "\n";
                warn $indenter->(), 'column_number : ', $violation->column_number, "\n";
                warn $indenter->(), 'severity      : ', $violation->severity, "\n";
                warn $indenter->(), 'policy        : ', $violation->policy, "\n";
                warn $indenter->(), 'source        : ', $violation->source, "\n";
                warn $indenter->(), 'description   : ', $violation->description, "\n";
                warn $indenter->('--'), "\n";
            }
            $indent_depth--;
        }

        my %blocks = $compiler_state->get_blocks;

        foreach my $block_type ( keys %blocks ) {
            $indent_depth++;

            my $blocks = $blocks{ $block_type };

            warn $indenter->('--'), "\n";
            warn $indenter->(), 'type : ', $block_type, "\n";

            foreach my $block ( @$blocks ) {
                $indent_depth++;

                $reporter->insert_new_block( $block_type, $block ) unless $opt->dry_run;

                my @includes    = $block->includes;
                my @constants   = $block->constants;
                my @subroutines = $block->subroutines;

                if ( $verbose ) {
                    warn $indenter->('--'), "\n";
                    warn $indenter->(), 'checksum              : ', $block->checksum, "\n";
                    warn $indenter->(), 'size                  : ', $block->size, "\n";
                    warn $indenter->(), 'lines                 : ', $block->lines, "\n";
                    warn $indenter->(), 'starting_line_number  : ', $block->starting_line_number, "\n";
                    warn $indenter->(), 'does_mason_postproc   : ', $block->does_mason_postproc, "\n";
                    warn $indenter->(), 'might_abort_request   : ', $block->might_abort_request, "\n";
                    warn $indenter->(), 'might_redirect_user   : ', $block->might_redirect_user, "\n";
                    warn $indenter->(), 'complexity_score      : ', $block->complexity_score, "\n";
                    warn $indenter->(), 'number_of_includes    : ', scalar @includes, "\n";
                    warn $indenter->(), 'number_of_constants   : ', scalar @constants, "\n";
                    warn $indenter->(), 'number_of_subroutines : ', scalar @subroutines, "\n";
                }

                foreach my $include ( @includes ) {
                    $indent_depth++;

                    $reporter->insert_new_include( $include ) unless $opt->dry_run;

                    if ($verbose) {
                        warn $indenter->('--'), "\n";
                        warn $indenter->(), 'line_number          : ', $include->line_number, "\n";
                        warn $indenter->(), 'column_number        : ', $include->column_number, "\n";
                        warn $indenter->(), 'usage                : ', $include->type, "\n";
                        warn $indenter->(), 'name                 : ', $include->module, "\n";
                        warn $indenter->(), 'imports              : ', (join ', ' => map $_->token, $include->imports), "\n";
                        warn $indenter->(), 'is_conditional       : ', $include->is_conditional, "\n";
                        warn $indenter->(), 'does_not_call_import : ', $include->does_not_call_import, "\n";
                    }

                    $indent_depth--;
                }

                foreach my $constant ( @constants ) {
                    $indent_depth++;

                    $reporter->insert_new_constant( $constant ) unless $opt->dry_run;

                    if ($verbose) {
                        warn $indenter->('--'), "\n";
                        warn $indenter->(), 'line_number   : ', $constant->line_number, "\n";
                        warn $indenter->(), 'column_number : ', $constant->column_number, "\n";
                        warn $indenter->(), 'symbol        : ', $constant->symbol, "\n";
                        warn $indenter->(), 'arguments     : ', (join ', ' => $constant->arguments), "\n";
                    }

                    $indent_depth--;
                }

                foreach my $subroutine ( @subroutines ) {
                    $indent_depth++;

                    $reporter->insert_new_subroutine( $subroutine ) unless $opt->dry_run;

                    if ($verbose) {
                        warn $indenter->('--'), "\n";
                        warn $indenter->(), 'line_number   : ', $subroutine->line_number, "\n";
                        warn $indenter->(), 'column_number : ', $subroutine->column_number, "\n";
                        warn $indenter->(), 'symbol        : ', $subroutine->symbol, "\n";
                    }

                    $indent_depth--;
                }

                $indent_depth--;
            }

            $indent_depth--;
        }

        $indent_depth--;
    }

    $reporter->finish_report unless $opt->dry_run;
}

1;

__END__

# ABSTRACT: Non-representational

=pod

=head1 DESCRIPTION

FEED ME!

=cut
