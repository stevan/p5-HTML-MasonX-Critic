#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Inspector');
}

my $MASON_FILE = '001-basic.html';
my $COMP_ROOT  = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE )->spew(q[
<%args>
$greeting => undef
</%args>
<%init>
$greeting ||= 'World';
</%init>
<h1>Hello <% $greeting %></h1>
]);

subtest '... simple sloop test' => sub {

    my $sloop = HTML::MasonX::Inspector->new(
        comp_root     => $COMP_ROOT,
        allow_globals => [ '$x' ],
        static_source => 1
    );
    isa_ok($sloop, 'HTML::MasonX::Inspector');

    subtest '... testing the runtime' => sub {

        my $runtime = $sloop->get_runtime_for_path( $MASON_FILE );
        isa_ok($runtime, 'HTML::MasonX::Inspector::Runtime');

        my $comp = $runtime->component;
        isa_ok($comp, 'HTML::Mason::Component');
    };

};

done_testing;

