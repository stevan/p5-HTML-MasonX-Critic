#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Inspector');
}

my $MASON_FILE = '010-compiler-state.html';
my $COMP_ROOT  = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE )->spew(q[
<%args>
$foo => 10;
$bar => undef;
$baz => 'GORCH';
</%args>

<%flags>
inherit=>'/some_handler'
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

<& .banner, title => 'Hello World' &>

<& SELF:.label, label => 'FOO', value => $foo &>
<& SELF:.label, label => 'BAR', value => $bar &>
<& SELF:.label, label => 'BAZ', value => $baz &>
]);

subtest '... simple sloop test' => sub {

    my $sloop = HTML::MasonX::Inspector->new( comp_root => $COMP_ROOT );
    isa_ok($sloop, 'HTML::MasonX::Inspector');

    my $state = $sloop->get_compiler_state_for_path( $MASON_FILE );
    isa_ok($state, 'HTML::MasonX::Inspector::CompilerState');

    subtest '... testing the args' => sub {

        my @args = $state->get_args;
        is(3, scalar @args, '... we have three args');

        my ($foo, $bar, $baz) = @args;

        subtest '... check the $foo argument' => sub {
            isa_ok($foo, 'HTML::MasonX::Inspector::CompilerState::Arg');
            is($foo->sigil, '$', '... got the expected sigil');
            is($foo->symbol, 'foo', '... got the expected symbol');
            is($foo->name, '$foo', '... got the expected name');
            is($foo->line_number, 3, '... got the expected line_number');
            is($foo->default_value, '10', '... got the expected default value');
        };

        subtest '... check the $bar argument' => sub {
            isa_ok($bar, 'HTML::MasonX::Inspector::CompilerState::Arg');
            is($bar->sigil, '$', '... got the expected sigil');
            is($bar->symbol, 'bar', '... got the expected symbol');
            is($bar->name, '$bar', '... got the expected name');
            is($bar->line_number, 4, '... got the expected line_number');
            is($bar->default_value, 'undef', '... got the expected default value');
        };

        subtest '... check the $baz argument' => sub {
            isa_ok($baz, 'HTML::MasonX::Inspector::CompilerState::Arg');
            is($baz->sigil, '$', '... got the expected sigil');
            is($baz->symbol, 'baz', '... got the expected symbol');
            is($baz->name, '$baz', '... got the expected name');
            is($baz->line_number, 5, '... got the expected line_number');
            is($baz->default_value, '\'GORCH\'', '... got the expected default value');
        };
    };

    subtest '... testing the flags' => sub {

        my @flags = $state->get_flags;
        is(1, scalar @flags, '... we have one flag');
        isa_ok($flags[0], 'HTML::MasonX::Inspector::CompilerState::Flag');

        is($flags[0]->key, 'inherit', '... there is only one flag key available');
        is($flags[0]->value, '/some_handler', '... got the expected value');

    };

    subtest '... testing the attrs' => sub {

        my @attrs = $state->get_attrs;
        is(2, scalar @attrs, '... we have two attrs');

        my ($color, $fonts) = @attrs;

        subtest '... check the color attribute' => sub {
            isa_ok($color, 'HTML::MasonX::Inspector::CompilerState::Attr');
            is($color->key, 'color', '... got the expected key');
            is($color->value, 'blue', '... got the expected value');
        };

        subtest '... check the fonts attribute' => sub {
            isa_ok($fonts, 'HTML::MasonX::Inspector::CompilerState::Attr');
            is($fonts->key, 'fonts', '... got the expected key');
            is($fonts->value, '[qw(arial geneva helvetica)]', '... got the expected value');
            is_deeply(
                $fonts->evaluated_value,
                [qw(arial geneva helvetica)],
                '... got the expected evaluated value'
            );
        };

    };

    subtest '... testing the methods' => sub {

        my @methods = $state->get_methods;
        is(1, scalar @methods, '... we have one method');

        my ($method) = @methods;

        is($method->name, '.label', '... got the expected name');

        my ($label, $value) = $method->get_args;

        subtest '... check the $label argument' => sub {
            isa_ok($label, 'HTML::MasonX::Inspector::CompilerState::Arg');
            is($label->sigil, '$', '... got the expected sigil');
            is($label->symbol, 'label', '... got the expected symbol');
            is($label->name, '$label', '... got the expected name');
            is($label->line_number, 19, '... got the expected line_number');
            is($label->default_value, undef, '... got the expected default value');
        };

        subtest '... check the $value argument' => sub {
            isa_ok($value, 'HTML::MasonX::Inspector::CompilerState::Arg');
            is($value->sigil, '$', '... got the expected sigil');
            is($value->symbol, 'value', '... got the expected symbol');
            is($value->name, '$value', '... got the expected name');
            is($value->line_number, 20, '... got the expected line_number');
            is($value->default_value, undef, '... got the expected default value');
        };

    };

    subtest '... testing the defs' => sub {

        my @defs = $state->get_defs;
        is(1, scalar @defs, '... we have one def');

        my ($def) = @defs;

        is($def->name, '.banner', '... got the expected name');

        my ($title) = $def->get_args;

        subtest '... check the $title argument' => sub {
            isa_ok($title, 'HTML::MasonX::Inspector::CompilerState::Arg');
            is($title->sigil, '$', '... got the expected sigil');
            is($title->symbol, 'title', '... got the expected symbol');
            is($title->name, '$title', '... got the expected name');
            is($title->line_number, 27, '... got the expected line_number');
            is($title->default_value, undef, '... got the expected default value');
        };

    };

};

done_testing;

