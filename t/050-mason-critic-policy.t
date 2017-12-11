#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Inspector');
    use_ok('HTML::MasonX::Inspector::Query::MasonCritic');
}

my $POLICY = 'HTML::MasonX::Critic::Policy::ProhibitIncludesFromImportingTags';

my $MASON_FILE_NAME = '050-mason-critic-policy.html';
my $COMP_ROOT       = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE_NAME )->spew(q[
<%once>
use Scalar::Util 'blessed', qw[ :Test foo bar ];
use List::Util   qw[ :All ];
use File::Spec   ();
</%once>
]);

subtest '... testing stuff' => sub {

    my $i = HTML::MasonX::Inspector->new( comp_root => $COMP_ROOT );
    isa_ok($i, 'HTML::MasonX::Inspector');

    my $state = $i->get_compiler_inspector_for_path( $MASON_FILE_NAME );
    isa_ok($state, 'HTML::MasonX::Inspector::Compiler');

    my @violations = HTML::MasonX::Inspector::Query::MasonCritic->critique_compiler_component(
        $state,
        policy => $POLICY
    );

    is(scalar(@violations), 2, '... got two violations back');
    my ($scalar_util, $list_util) = @violations;

    subtest '... testing the Scalar::Util violation' => sub {
        is($scalar_util->source, q[use Scalar::Util 'blessed', qw[ :Test foo bar ];], '... got the expected source');
        is($scalar_util->line_number, 3, '... got the expected line number');
        is($scalar_util->column_number, 1, '... got the expected column number');
        is($scalar_util->filename, $state->abs_path, '... got the expected filename');
        is($scalar_util->policy, $POLICY, '... got the expected policy');
    };

    subtest '... testing the List::Util violation' => sub {
        is($list_util->source, q[use List::Util   qw[ :All ];], '... got the expected source');
        is($list_util->line_number, 4, '... got the expected line number');
        is($list_util->column_number, 1, '... got the expected column number');
        is($list_util->filename, $state->abs_path, '... got the expected filename');
        is($list_util->policy, $POLICY, '... got the expected policy');
    };

};

done_testing;

