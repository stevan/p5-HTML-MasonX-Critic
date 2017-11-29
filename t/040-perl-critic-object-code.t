#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Inspector');
    use_ok('HTML::MasonX::Inspector::Query::PerlCritic');
}

my $MASON_FILE = '040-perl-critic-object-code.t';
my $COMP_ROOT  = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE )->spew(q[
<%args>
$greeting => undef
</%args>
<%once>
use Scalar::Util ();
</%once>
<%init>
my $test;
$greeting ||= 'World';
</%init>
<h1>Hello <% $greeting %></h1>
<%cleanup>
$greeting = undef;
</%cleanup>
]);

subtest '... simple perl-cricit query test' => sub {

    my $i = HTML::MasonX::Inspector->new(
        comp_root     => $COMP_ROOT,
        allow_globals => [ '$x' ]
    );
    isa_ok($i, 'HTML::MasonX::Inspector');

    subtest '... testing the object code' => sub {

        my $obj_code = $i->get_object_code_inspector_for_path( $MASON_FILE );
        isa_ok($obj_code, 'HTML::MasonX::Inspector::ObjectCode');

        my @violations = HTML::MasonX::Inspector::Query::PerlCritic->critique_object_code(
            $obj_code,
            ( '-single-policy' => 'Variables::ProhibitUnusedVariables' )
        );
        is(scalar @violations, 1, '... got one violation');

        my ($v) = @violations;
        is($v->policy, 'Perl::Critic::Policy::Variables::ProhibitUnusedVariables', '... got the expected policy name');
        is($v->logical_line_number, 9, '... got the expected line number');
        is($v->column_number, 1, '... got the expected column number');
        is($v->source, 'my $test;', '... got the expected source');
    };


    subtest '... testing the object code' => sub {

        my $compiler = $i->get_compiler_inspector_for_path( $MASON_FILE );
        isa_ok($compiler, 'HTML::MasonX::Inspector::Compiler');

        my @violations = HTML::MasonX::Inspector::Query::PerlCritic->critique_compiler_component(
            $compiler,
            ( '-single-policy' => 'Variables::ProhibitUnusedVariables' )
        );
        is(scalar @violations, 1, '... got one violation');

        my ($v) = @violations;
        is($v->policy, 'Perl::Critic::Policy::Variables::ProhibitUnusedVariables', '... got the expected policy name');
        is($v->logical_line_number, 9, '... got the expected line number');
        is($v->column_number, 1, '... got the expected column number');
        is($v->source, 'my $test;', '... got the expected source');
    };

};

done_testing;

