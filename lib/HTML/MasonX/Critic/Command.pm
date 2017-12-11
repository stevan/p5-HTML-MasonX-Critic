package HTML::MasonX::Critic::Command;
# ABSTRACT: The guts of masoncritic command line tool

use strict;
use warnings;

our $VERSION = '0.01';

use Carp                ();
use Scalar::Util        ();
use Getopt::Long        ();
use JSON::MaybeXS       ();
use Term::ReadKey       ();
use Path::Tiny          ();
use Getopt::Long        ();
use IO::Prompt::Tiny    ();
use Term::ANSIColor     ':constants';

use HTML::MasonX::Critic;
use HTML::MasonX::Critic::Util::MasonFileFinder;

use UNIVERSAL::Object;
our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        dir                  => sub {},

        debug                => sub { $ENV{MASONCRITIC_DEBUG}            },
        verbose              => sub { $ENV{MASONCRITIC_VERBOSE}          },
        show_source          => sub { $ENV{MASONCRITIC_SHOW_SOURCE} // 0 },
        use_color            => sub { $ENV{MASONCRITIC_USE_COLOR}   // 1 },
        as_json              => sub { $ENV{MASONCRITIC_AS_JSON}     // 0 },

        perl_critic_policy   => sub {},
        perl_critic_theme    => sub { $ENV{MASONCRITIC_PERL_CRITIC_THEME}         },
        perl_critic_profile  => sub { $ENV{MASONCRITIC_PERL_CRITIC_PROFILE}       },
        perl_critic_severity => sub { $ENV{MASONCRITIC_PERL_CRITIC_SEVERITY} || 1 },

        ## private data
        _mason_critic => sub {},
        _file_finder  => sub {},
        _critic_args  => sub {},
    )
}

sub BUILD {
    my ($self) = @_;

    Getopt::Long::GetOptions(
        'debug|d'                => \$self->{debug},
        'verbose|v'              => \$self->{verbose},
        'show-source'            => \$self->{show_source},
        'color'                  => \$self->{use_color},
        'json'                   => \$self->{as_json},

        'dir=s'                  => \$self->{dir},

        'perl-critic-profile=s'  => \$self->{perl_critic_profile},
        'perl-critic-theme=s'    => \$self->{perl_critic_theme},
        'perl-critic-policy=s'   => \$self->{perl_critic_policy},
        'perl-critic-severity=s' => \$self->{perl_critic_severity},
    );

    # do this first ...
    $ENV{ANSI_COLORS_DISABLED} = ! $self->{use_color};

    ## Check the args

    $self->usage('You must specify a --dir')
        unless defined $self->{dir};

    $self->usage('The --dir must be a valid directory.')
        unless -e $self->{dir} && -d $self->{dir};

    $self->usage('You cannot set a Perl::Critic policy *and* a theme/profile')
        if defined $self->{perl_critic_policy}
            && (
                defined $self->{perl_critic_profile}
                    ||
                defined $self->{perl_critic_theme}
            );

    if ( $self->{perl_critic_profile} ) {
        $self->usage('Unable to find the Perl::Critic profile at ('.$self->{perl_critic_profile}.')')
            unless -f $self->{perl_critic_profile};
    }

    ## Build some sub-objects

    $self->{dir} = Path::Tiny::path( $self->{dir} )
        unless Scalar::Util::blessed( $self->{dir} )
            && $self->{dir}->isa('Path::Tiny');

    $self->{_mason_critic} = HTML::MasonX::Critic->new( comp_root => $self->{dir} );
    $self->{_file_finder}  = HTML::MasonX::Critic::Util::MasonFileFinder->new( root_dir => $self->{dir} );
    $self->{_critic_args}  = {
        ($self->{perl_critic_severity} ? ('-severity'      => $self->{perl_critic_severity}) : ()),
        ($self->{perl_critic_policy}   ? ('-single-policy' => $self->{perl_critic_policy})   : ()),
        ($self->{perl_critic_profile}  ? ('-profile'       => $self->{perl_critic_profile})  : ()),
        ($self->{perl_critic_theme}    ? ('-theme'         => $self->{perl_critic_theme})    : ()),
    };
}

## ...

sub usage {
    my ($self, $error) = @_;
    print $error, "\n" if $error;
    print <<'USAGE';
masoncritic [-dv] [long options...]
    --dir                  the root directory to look within
    --perl-critic-profile  set the Perl::Critic profile to use, defaults to $ENV{MASONCRITIC_PROFILE}
    --perl-critic-theme    set the Perl::Critic theme to use, defaults to $ENV{MASONCRITIC_THEME}
    --perl_critic_severity set the Perl::Critic severity, defaults to $ENV{MASONCRITIC_SEVERITY} or 1
    --perl-critic-policy   set the Perl::Critic policy to use
    --color                turn on/off color in the output
    --json                 output the violations as JSON
    --show-source          include the Mason source code in the output when in verbose mode
    -d --debug             turn on debugging
    -v --verbose           turn on verbosity
USAGE
    exit(0);
}

sub run {
    my ($self) = @_;

    my $root_dir    = $self->{dir};
    my $critic      = $self->{_mason_critic};
    my %critic_args = %{ $self->{_critic_args} };
    my $all_files   = $self->{_file_finder}->find_all_mason_files( relative => 1 );

    while ( my $file = $all_files->next ) {

        if ( my @violations = $critic->critique( $file, %critic_args ) ) {

            print BOLD, "Found (".(scalar @violations).") violations in $file\n", RESET
                unless $self->{as_json};

            foreach my $violation ( @violations ) {
                $self->_display_violation( $file, $violation );
                next unless $self->{verbose};
                next if     $self->{as_json};
                if ( my $x = IO::Prompt::Tiny::prompt( FAINT('> next violation?', RESET), 'y') ) {
                    last if $x eq 'n';
                }
            }
        }
        else {
            print ITALIC, GREEN, "No violations in $file\n", RESET
                unless $self->{as_json};
        }
    }

    exit;
}

## ...

sub TERM_WIDTH () {
    return eval {
        local $SIG{__WARN__} = sub {''};
        ( Term::ReadKey::GetTerminalSize() )[0];
    } || 80
}

use constant HR_ERROR => ( '== ERROR ' . ( '=' x ( TERM_WIDTH - 9 ) ) );
use constant HR_DARK  => ( '=' x TERM_WIDTH );
use constant HR_LIGHT => ( '-' x TERM_WIDTH );

sub _display_violation {
    my ($self, $file, $violation) = @_;

    if ( $self->{as_json} ) {
        print JSON::MaybeXS->new->encode({
            filename      => $violation->logical_filename,
            line_number   => $violation->logical_line_number,
            column_number => $violation->column_number,
            policy        => $violation->policy,
            severity      => $violation->severity,
            source        => $violation->source,
            description   => $violation->description,
            explanation   => $violation->explanation,
        }), "\n";
    }
    else {
        if ( $self->{verbose} ) {
            print HR_DARK, "\n";
            print BOLD, RED, (sprintf "Violation: %s\n" => $violation->description), RESET;
            print HR_DARK, "\n";
            print sprintf "%s\n" => $violation->explanation;
            print HR_LIGHT, "\n";
            #if ( $DEBUG ) {
            #    print sprintf "%s\n" => $violation->diagnostics;
            #    print HR_LIGHT, "\n";
            #}
            print sprintf "  policy   : %s\n"           => $violation->policy;
            print sprintf "  severity : %d\n"           => $violation->severity;
            print sprintf "  location : %s @ <%d:%d>\n" => (
                $file,
                $violation->logical_line_number,
                $violation->column_number
            );
            print HR_LIGHT, "\n";
            print ITALIC, (sprintf "%s\n" => $violation->source), RESET;
            print HR_LIGHT, "\n";
            if ( $self->{show_source} ) {
                my @lines;

                my $starting_line       = $violation->logical_line_number - 5;
                   $starting_line       = 1 if $starting_line < 0;
                my $lines_to_capture    = 10;
                my $line_number_counter = $starting_line;

                my $fh = Path::Tiny::path( $violation->logical_filename )->openr;
                # skip to the start line ....
                $fh->getline                while --$starting_line;
                push @lines => $fh->getline while not($fh->eof) && --$lines_to_capture;
                $fh->close;

                # drop the first line if it is a blank
                if ( $lines[0] =~ /^\s*$/ ) {
                    $line_number_counter++;
                    shift @lines;
                }

                foreach my $line ( @lines ) {

                    if ( $line_number_counter eq $violation->logical_line_number ) {
                        print BOLD, (sprintf '%03d:> %s' => $line_number_counter, (join '' => RED, $line)), RESET;
                    }
                    else {
                        print FAINT, (sprintf '%03d:  %s' => $line_number_counter, (join '' => RESET, $line)), RESET;
                    }

                    $line_number_counter++;
                }

                print HR_LIGHT, "\n";
            }
        }
        else {
            print RED, $violation, RESET;
        }
    }
}

1;

__END__

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
