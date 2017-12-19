#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Critic::Inspector');
}

my $MASON_FILE = '020-runtime.html';
my $COMP_ROOT  = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE )->spew(q[
<%args>
$foo => 10;
$bar => undef;
$baz => 'GORCH';
</%args>

<%flags>
inherit => '/some_handler'
</%flags>

<%attr>
color => 'blue'
fonts => [qw(arial geneva helvetica)]
</%attr>

<%method .label>
    <%args>
        $label
        $value
    </%args>
    <div><% $label %> : <% $value %></div>
</%method>

<%def .banner>
    <%args>
        $title
    </%args>
    <h1><% $title %></h1>
</%def>

<%once>
use Scalar::Util 'blessed';
use List::Util   qw[ max uniq ];
use File::Spec   ();
</%once>

<%init>
$bar //= $foo * $foo;
</%init>

<h1><& attr:color &></h1>

<& .banner, title => 'Hello World' &>

<& SELF:.label, label => 'FOO', value => $foo &>
<& SELF:.label, label => 'BAR', value => $bar &>
<& SELF:.label, label => 'BAZ', value => $baz &>
]);

subtest '... simple runtime test' => sub {

    my $i = HTML::MasonX::Critic::Inspector->new(
        comp_root     => $COMP_ROOT,
        allow_globals => [ '$x' ],
        static_source => 1
    );
    isa_ok($i, 'HTML::MasonX::Critic::Inspector');

    subtest '... testing the runtime' => sub {

        my $runtime = $i->get_runtime_inspector_for_path( $MASON_FILE );
        isa_ok($runtime, 'HTML::MasonX::Critic::Inspector::Runtime');

        my $comp = $runtime->component;
        isa_ok($comp, 'HTML::Mason::Component');

        #use Data::Dumper;
        #warn Dumper $comp;
    };

};

done_testing;

