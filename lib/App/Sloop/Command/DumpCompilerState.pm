package App::Sloop::Command::DumpCompilerState;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use List::Util ();

use HTML::MasonX::Inspector;

use App::Sloop -command;

sub command_names { 'dump-compiler-state' }

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'path=s',       'Path to the file to dump about', { required => 1 } ],
        [],
        [ 'comp-root=s', 'HTML::Mason comp_root', { default => $App::Sloop::CONFIG{'COMP_ROOT'} } ],
        [],
        $class->SUPER::opt_spec,
    )
}

sub execute {
    my ($self, $opt, $args) = @_;


    my $path      = $opt->path;
    my $comp_root = $opt->comp_root;

    my $inspector      = HTML::MasonX::Inspector->new( comp_root => $comp_root );
    my $compiler_state = $inspector->get_compiler_for_path( $path );

    binmode(STDOUT, ":utf8");

    my %totals;
    my %tables;

    $tables{__header__} = $self->draw_table(
        [ 'Path Type', 'Path' ],
        [ 'compilation root', $comp_root ],
        [ 'mason file path', $path ],
        {
            set_column_style => sub {
                $_[0]->set_column_style('Path' => ( wrap => 0 ));
                $_[0]->set_column_style('Path Type' => (
                    lpad    => 2,
                    align   => 'right',
                    bgcolor => '999999',
                ))
            }
        }
    );

    if ( my @args = $compiler_state->get_args ) {
        $tables{args} = $self->draw_table(
            [ '#L', 'Name', 'Default Value', 'Has Constraint' ],
            (map [
                $_->{line_number},
                $_->{name},
                $_->{default},
                $_->{has_constraint},
            ], @args),
            {
            set_column_style => sub {
                $_[0]->set_column_style('Has Constraint' => ( type => 'bool' ));
            }
        }
        );
    }

    if ( my @flags = $compiler_state->get_flags ) {
        $tables{flags} = $self->draw_table(
            [ 'Name', 'Value' ],
            map [ $_->{name}, $_->{value} ], @flags
        );
    }

    if ( my @attr = $compiler_state->get_attr ) {
        $tables{attr} = $self->draw_table(
            [ 'Name', 'Value' ],
            map [ $_->{name}, $_->{value} ], @attr
        );
    }

    if ( my @definitions = $compiler_state->get_definitions ) {
        $tables{defs} = $self->draw_table(
            [ '#L', 'Name', 'Args', 'LoC', 'Complexity' ],
            map [
                $_->{body}->starting_line_number,
                $_->{name},
                (join ', ' => @{$_->{args}}),
                $_->{body}->lines,
                $_->{body}->complexity_score,
            ], @definitions
        );
    }

    if ( my @methods = $compiler_state->get_methods ) {
        $tables{methods} = $self->draw_table(
            [ '#L', 'Name', 'Args', 'LoC', 'Complexity' ],
            map [
                $_->{body}->starting_line_number,
                $_->{name},
                (join ', ' => @{$_->{args}}),
                $_->{body}->lines,
                $_->{body}->complexity_score,
            ], @methods
        )
    }

    if ( my @violations = $compiler_state->get_violations ) {
        $totals{violations} += scalar @violations;
        $tables{violations} = $self->draw_table(
            [ 'L#', 'C#', 'Severity', 'Policy', 'Description', 'Source' ],
            (map [
                $_->line_number,
                $_->column_number,
                $_->severity,
                $_->policy,
                $_->description,
                $_->source,
            ], sort {
                $a->line_number <=> $b->line_number
            } @violations),
            # opts ...
            {
                show_row_separator => 1,
                set_column_style   => sub {
                    $_[0]->set_column_style('Policy' => ( wrap => 0 ));
                }
            }
        );
    }

    if ( my %blocks = $compiler_state->get_blocks ) {

        $tables{blocks} = {};

        foreach my $name ( keys %blocks ) {

            my @blocks = @{ $blocks{$name} };

            my %block_tables;

            $block_tables{main} = $self->draw_table(
                [
                    'Starting Line #',
                    'Lines',
                    'Complexity Score',
                    'Does Postproc',
                    'Might Abort Request',
                    'Might Redirect User'
                ],
                (map [
                    $_->starting_line_number,
                    $_->lines,
                    $_->complexity_score,
                    $_->does_mason_postproc,
                    $_->might_abort_request,
                    $_->might_redirect_user,
                ], @blocks),
                {
                    set_column_style => sub {
                        $_[0]->set_column_style( 'Does Postproc'       => ( type => 'bool' ));
                        $_[0]->set_column_style( 'Might Abort Request' => ( type => 'bool' ));
                        $_[0]->set_column_style( 'Might Redirect User' => ( type => 'bool' ));
                    }
                }
            );

            if ( my @includes = map $_->includes, @blocks ) {
                $block_tables{includes} = $self->draw_table(
                    [
                        'L#',
                        'C#',
                        'Type',
                        'Module',
                        'Is Conditional',
                        'Does not call import'
                    ],
                    (map [
                        $_->line_number,
                        $_->column_number,
                        $_->type,
                        $_->module,
                        $_->is_conditional,
                        $_->does_not_call_import,
                    ], @includes),
                    {
                        set_column_style => sub {
                            $_[0]->set_column_style( 'Type' => ( align => 'middle' ));
                            $_[0]->set_column_style( 'Module' => ( wrap => 0 ));
                            $_[0]->set_column_style( 'Is Conditional' => ( type => 'bool' ));
                            $_[0]->set_column_style( 'Does not call import' => ( type => 'bool' ));
                        }
                    }
                );

                if ( grep $_->number_of_imports, @includes ) {
                    $block_tables{imports} = $self->draw_table(
                        [ 'Module', 'Imports' ],
                        (map {
                            [ $_->module, join ', ' => map { $_->token } $_->imports ]
                        } grep $_->number_of_imports, @includes),
                        {
                            show_row_separator => 1,
                            set_column_style   => sub {
                                $_[0]->set_column_style('Module'  => ( wrap => 0 ));
                                $_[0]->set_column_style('Imports' => ( width => 50 ));
                            }
                        }
                    );
                }
            }

            if ( my @constants = map $_->constants, @blocks ) {
                $block_tables{constants} =  $self->draw_table(
                    [ 'L#', 'C#', 'Symbol', 'Arguments' ],
                    (map [
                        $_->line_number,
                        $_->column_number,
                        $_->symbol,
                        (join ', ' => $_->arguments),
                    ], @constants),
                    {
                        set_column_style => sub {
                            $_[0]->set_column_style('Symbol' => ( wrap => 0 ));
                        }
                    }
                );
            }

            if ( my @subroutines = map $_->subroutines, @blocks ) {
                $block_tables{subroutines} = $self->draw_table(
                    [ 'L#', 'C#', 'Symbol' ],
                    (map [
                        $_->line_number,
                        $_->column_number,
                        $_->symbol,
                    ], @subroutines),
                    {
                        set_column_style => sub {
                            $_[0]->set_column_style('Symbol' => ( wrap => 0 ));
                        }
                    }
                );
            }

            $tables{blocks}->{ $name } = \%block_tables;

            # calculate totals for the block name ...
            foreach ( @blocks ) {
                $totals{size}        += $_->size;
                $totals{lines}       += $_->lines;
                $totals{complexity}  += $_->complexity_score;
                $totals{includes}    += $_->number_of_includes;
                $totals{constants}   += $_->number_of_constants;
                $totals{subroutines} += $_->number_of_subroutines;
            }
        }
    }

    my @order = qw[
        flags
        attr
        args
        defs
        methods
        violations
    ];

    print $tables{__header__};

    foreach my $name ( grep exists $tables{ $_ }, @order ) {
        print $self->draw_table(
            [ ucfirst $name    ],
            [ $tables{ $name } ],
            {
                no_border        => 1,
                set_column_style => sub {
                    $_[0]->set_column_style( ucfirst $name, ( wrap => 0 ));
                }
            }
        );
    }

    foreach my $name ( sort { $a cmp $b } keys %{$tables{blocks}} ) {
        print $self->draw_table(
            [ "Block <%$name>" ],
            (map [ $_ ], grep defined, @{ $tables{blocks}->{ $name } }{qw[ main includes imports subroutines constants ]} ),
            {
                container        => 1,
                set_column_style => sub {
                    $_[0]->set_column_style("Block <%$name>", ( wrap => 0 ));
                }
            }
        );
    }

    print $self->draw_table(
        [ 'Totals', 'Values' ],
        [ 'Complexity Score',  $totals{complexity}  || '-' ],
        [ 'Critic Violations', $totals{violations}  || '-' ],
        [ 'Perl Includes',     $totals{includes}    || '-' ],
        [ 'Constants',         $totals{constants}   || '-' ],
        [ 'Subroutines',       $totals{subroutines} || '-' ],
        [ 'Lines of Code',     $totals{lines}       || '-' ],
        {
            no_border        => 1,
            set_column_style => sub {
                $_[0]->set_column_style( 'Totals', (
                    align => 'right',
                    lpad  => 2,
                ));
                $_[0]->set_column_style( 'Values', ( rpad => 2 ));
            }
        }
    );

    print "\n";

    if ( $opt->debug ) {
        print $inspector->get_object_code_for_path( $path )
    }

}

1;

__END__

# ABSTRACT: Non-representational

=pod

=head1 DESCRIPTION

FEED ME!

=cut
