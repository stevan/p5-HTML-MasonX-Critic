#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Critic::Inspector');
}

my $MASON_FILE_NAME = '010-compiler.html';
my $COMP_ROOT       = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE_NAME )->spew(q[
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

subtest '... simple inspector test' => sub {

    my $i = HTML::MasonX::Critic::Inspector->new( comp_root => $COMP_ROOT );
    isa_ok($i, 'HTML::MasonX::Critic::Inspector');

    my $state = $i->get_compiler_inspector_for_path( $MASON_FILE_NAME );
    isa_ok($state, 'HTML::MasonX::Critic::Inspector::Compiler');

    my $comp = $state->get_main_component;
    isa_ok($comp, 'HTML::MasonX::Critic::Inspector::Compiler::Component');

    is($comp->name, $MASON_FILE_NAME, '... got the expected name');

    subtest '... testing the args' => sub {

        my @args = @{ $comp->args };
        is(3, scalar @args, '... we have three args');

        my ($foo, $bar, $baz) = @args;

        subtest '... check the $foo argument' => sub {
            isa_ok($foo, 'HTML::MasonX::Critic::Inspector::Compiler::Component::Arg');
            is($foo->sigil, '$', '... got the expected sigil');
            is($foo->symbol, 'foo', '... got the expected symbol');
            is($foo->name, '$foo', '... got the expected name');
            is($foo->line_number, 3, '... got the expected line_number');
            is($foo->default_value, '10', '... got the expected default value');
        };

        subtest '... check the $bar argument' => sub {
            isa_ok($bar, 'HTML::MasonX::Critic::Inspector::Compiler::Component::Arg');
            is($bar->sigil, '$', '... got the expected sigil');
            is($bar->symbol, 'bar', '... got the expected symbol');
            is($bar->name, '$bar', '... got the expected name');
            is($bar->line_number, 4, '... got the expected line_number');
            is($bar->default_value, 'undef', '... got the expected default value');
        };

        subtest '... check the $baz argument' => sub {
            isa_ok($baz, 'HTML::MasonX::Critic::Inspector::Compiler::Component::Arg');
            is($baz->sigil, '$', '... got the expected sigil');
            is($baz->symbol, 'baz', '... got the expected symbol');
            is($baz->name, '$baz', '... got the expected name');
            is($baz->line_number, 5, '... got the expected line_number');
            is($baz->default_value, '\'GORCH\'', '... got the expected default value');
        };
    };

    subtest '... testing the flags' => sub {
        my %flags = %{ $comp->flags };
        is(1, scalar keys %flags, '... we have one flag');

        is((keys   %flags)[0], 'inherit', '... there is only one flag key available');
        is((values %flags)[0], '/some_handler', '... got the expected value');
    };

    subtest '... testing the attrs' => sub {

        my %attrs = %{ $comp->attributes };
        is(2, scalar keys %attrs, '... we have two attrs');

        my ($color, $fonts) = @attrs{qw[ color fonts ]};

        is($color, '\'blue\'', '... got the expected value for color attribute');
        is($fonts, '[qw(arial geneva helvetica)]', '... got the expected value for fonts attribute');
    };

    subtest '... testing the methods' => sub {

        my %methods = %{ $comp->methods };
        is(1, scalar keys %methods, '... we have one method');

        my $method = $methods{'.label'};
        isa_ok($method, 'HTML::MasonX::Critic::Inspector::Compiler::Component');

        is($method->name, '.label', '... got the expected name');

        isa_ok($method->body, 'HTML::MasonX::Critic::Inspector::Compiler::Component::PerlCode');
        isa_ok($method->blocks, 'HTML::MasonX::Critic::Inspector::Compiler::Component::Blocks');

        my ($label, $value) = @{ $method->args };

        subtest '... check the $label argument' => sub {
            isa_ok($label, 'HTML::MasonX::Critic::Inspector::Compiler::Component::Arg');
            is($label->sigil, '$', '... got the expected sigil');
            is($label->symbol, 'label', '... got the expected symbol');
            is($label->name, '$label', '... got the expected name');
            is($label->line_number, 19, '... got the expected line_number');
            is($label->default_value, undef, '... got the expected default value');
        };

        subtest '... check the $value argument' => sub {
            isa_ok($value, 'HTML::MasonX::Critic::Inspector::Compiler::Component::Arg');
            is($value->sigil, '$', '... got the expected sigil');
            is($value->symbol, 'value', '... got the expected symbol');
            is($value->name, '$value', '... got the expected name');
            is($value->line_number, 20, '... got the expected line_number');
            is($value->default_value, undef, '... got the expected default value');
        };

    };

    subtest '... testing the sub_components' => sub {

        my %sub_components = %{ $comp->sub_components };
        is(1, scalar keys %sub_components, '... we have one def');

        my $sub_comp = $sub_components{'.banner'};
        isa_ok($sub_comp, 'HTML::MasonX::Critic::Inspector::Compiler::Component');

        is($sub_comp->name, '.banner', '... got the expected name');

        isa_ok($sub_comp->body, 'HTML::MasonX::Critic::Inspector::Compiler::Component::PerlCode');
        isa_ok($sub_comp->blocks, 'HTML::MasonX::Critic::Inspector::Compiler::Component::Blocks');

        my ($title) = @{ $sub_comp->args };

        subtest '... check the $title argument' => sub {
            isa_ok($title, 'HTML::MasonX::Critic::Inspector::Compiler::Component::Arg');
            is($title->sigil, '$', '... got the expected sigil');
            is($title->symbol, 'title', '... got the expected symbol');
            is($title->name, '$title', '... got the expected name');
            is($title->line_number, 27, '... got the expected line_number');
            is($title->default_value, undef, '... got the expected default value');
        };

    };

    subtest '... testing the blocks' => sub {

        my $blocks = $comp->blocks;
        isa_ok($blocks, 'HTML::MasonX::Critic::Inspector::Compiler::Component::Blocks');

        ok($blocks->has_once_blocks, '... we have once blocks');
        ok($blocks->has_init_blocks, '... we have init blocks');

        ok(!$blocks->has_filter_blocks, '... we do not have filter blocks');
        ok(!$blocks->has_shared_blocks, '... we do not have shared blocks');
        ok(!$blocks->has_cleanup_blocks, '... we do not have cleanup blocks');

        my ($once) = @{ $blocks->once_blocks };
        isa_ok($once, 'HTML::MasonX::Critic::Inspector::Compiler::Component::PerlCode');

        my ($init) = @{ $blocks->init_blocks };
        isa_ok($init, 'HTML::MasonX::Critic::Inspector::Compiler::Component::PerlCode');

    };

};

done_testing;

