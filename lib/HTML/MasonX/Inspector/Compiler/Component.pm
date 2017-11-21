package HTML::MasonX::Inspector::Compiler::Component;

use strict;
use warnings;

our $VERSION = '0.01';

use HTML::MasonX::Inspector::Compiler::Arg;
use HTML::MasonX::Inspector::Compiler::Flag;
use HTML::MasonX::Inspector::Compiler::Attr;
use HTML::MasonX::Inspector::Compiler::Method;
use HTML::MasonX::Inspector::Compiler::Def;

use HTML::MasonX::Inspector::Util::Perl;

use UNIVERSAL::Object;

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        args   => sub {},
        attr   => sub {},
        flags  => sub {},
        method => sub {},
        def    => sub {},
        body   => sub {},
        blocks => sub {},
    )
}

sub BUILD {
    my ($self, $params) = @_;

    $self->{args} = [
        map
            HTML::MasonX::Inspector::Compiler::Arg->new(
                sigil           => $_->{type},
                symbol          => $_->{name},
                default_value   => $_->{default},
                type_constraint => $_->{type_constraint},
                line_number     => $_->{line},
            ), @{ $self->{args} }
    ];

    $self->{flags} = [
        map
            HTML::MasonX::Inspector::Compiler::Flag->new(
                key   => $_,
                value => $self->{flags}->{ $_ },
            ), sort keys %{ $self->{flags} }
    ];

    $self->{attr} = [
        map
            HTML::MasonX::Inspector::Compiler::Attr->new(
                key   => $_,
                value => $self->{attr}->{ $_ },
            ), sort keys %{ $self->{attr} }
    ];

    $self->{method} = [
        map
            HTML::MasonX::Inspector::Compiler::Method->new(
                name => $_,
                args => [
                    map
                        HTML::MasonX::Inspector::Compiler::Arg->new(
                            sigil           => $_->{type},
                            symbol          => $_->{name},
                            default_value   => $_->{default},
                            type_constraint => $_->{type_constraint},
                            line_number     => $_->{line},
                        ), @{ $self->{method}->{$_}->{args} }
                ],
                body => HTML::MasonX::Inspector::Util::Perl->new(
                    source => \( $self->{method}->{$_}->{body} )
                ),
            ), keys %{ $self->{method} }
    ];

    $self->{def} = [
        map
            HTML::MasonX::Inspector::Compiler::Def->new(
                name => $_,
                args => [
                    map
                        HTML::MasonX::Inspector::Compiler::Arg->new(
                            sigil           => $_->{type},
                            symbol          => $_->{name},
                            default_value   => $_->{default},
                            type_constraint => $_->{type_constraint},
                            line_number     => $_->{line},
                        ), @{ $self->{def}->{$_}->{args} }
                ],
                body => HTML::MasonX::Inspector::Util::Perl->new(
                    source => \( $self->{def}->{$_}->{body} )
                ),
            ), keys %{ $self->{def} }
    ];

    # NOTE:
    # it is important to note that the main block
    # is basically a combination of any <%perl>
    # blocks as well as any HTML with embedded
    # templates in it.
    $self->{body} = HTML::MasonX::Inspector::Util::Perl->new(
        source => \(my $b = $self->{body})
    );

    $self->{blocks} = {
        once    => [ map HTML::MasonX::Inspector::Util::Perl->new(source => \$_), @{ $self->{blocks}->{once}    || [] } ],
        init    => [ map HTML::MasonX::Inspector::Util::Perl->new(source => \$_), @{ $self->{blocks}->{init}    || [] } ],
        filter  => [ map HTML::MasonX::Inspector::Util::Perl->new(source => \$_), @{ $self->{blocks}->{filter}  || [] } ],
        cleanup => [ map HTML::MasonX::Inspector::Util::Perl->new(source => \$_), @{ $self->{blocks}->{cleanup} || [] } ],
        shared  => [ map HTML::MasonX::Inspector::Util::Perl->new(source => \$_), @{ $self->{blocks}->{shared}  || [] } ],
    };
}

sub args    { @{ $_[0]->{args}   } }
sub attrs   { @{ $_[0]->{attr}   } }
sub flags   { @{ $_[0]->{flags}  } }
sub methods { @{ $_[0]->{method} } }
sub defs    { @{ $_[0]->{def}    } }

sub body   { $_[0]->{body}   }
sub blocks { $_[0]->{blocks} }

1;

__END__

=pod

=head1 NAME

HTML::MasonX::Inspector::Compiler::Attr - HTML::Mason::Compiler sea cucumber guts

=head1 DESCRIPTION

=cut
