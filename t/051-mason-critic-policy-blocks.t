#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Critic');
    use_ok('HTML::MasonX::Critic::Inspector::Query::Factory::MasonCritic');
}

my $MASON_FILE_NAME = '051-mason-critic-policy-blocks.html';
my $COMP_ROOT       = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE_NAME )->spew(q[
<%shared>
my ($foo, $bar);
</%shared>
<%filter>
tr/a-z/A-Z/
</%filter>
]);

subtest '... testing Blocks::ProhibitSharedBlocks policy' => sub {

    my $POLICY = 'HTML::MasonX::Critic::Policy::Blocks::ProhibitSharedBlocks';

    my $i = HTML::MasonX::Critic::Inspector->new( comp_root => $COMP_ROOT );
    isa_ok($i, 'HTML::MasonX::Critic::Inspector');

    my $state = $i->compile_path( $MASON_FILE_NAME );
    isa_ok($state, 'HTML::MasonX::Critic::Inspector::CompiledPath');

    my @violations = HTML::MasonX::Critic::Inspector::Query::Factory::MasonCritic->critique(
        $state,
        policy => $POLICY
    );

    is(scalar(@violations), 1, '... got two violations back');
    my ($shared) = @violations;

    subtest '... testing the violation' => sub {

        is(
            $shared->source,
            (join "\n" => '<%shared>', 'my ($foo, $bar);', '</%shared>'),
            '... got the expected source'
        );
        is($shared->line_number, 2, '... got the expected line number');
        is($shared->column_number, 1, '... got the expected column number');
        is($shared->filename, $state->abs_path, '... got the expected filename');
        is($shared->policy, $POLICY, '... got the expected policy');
    };
};

subtest '... testing Blocks::ProhibitSharedBlocks policy' => sub {

    my $POLICY = 'HTML::MasonX::Critic::Policy::Blocks::ProhibitFilterBlocks';

    my $i = HTML::MasonX::Critic::Inspector->new( comp_root => $COMP_ROOT );
    isa_ok($i, 'HTML::MasonX::Critic::Inspector');

    my $state = $i->compile_path( $MASON_FILE_NAME );
    isa_ok($state, 'HTML::MasonX::Critic::Inspector::CompiledPath');

    my @violations = HTML::MasonX::Critic::Inspector::Query::Factory::MasonCritic->critique(
        $state,
        policy => $POLICY
    );

    is(scalar(@violations), 1, '... got two violations back');
    my ($filter) = @violations;

    subtest '... testing the violation' => sub {

        is(
            $filter->source,
            (join "\n" => '<%filter>', 'tr/a-z/A-Z/', '</%filter>'),
            '... got the expected source'
        );
        is($filter->line_number, 5, '... got the expected line number');
        is($filter->column_number, 1, '... got the expected column number');
        is($filter->filename, $state->abs_path, '... got the expected filename');
        is($filter->policy, $POLICY, '... got the expected policy');
    };
};

done_testing;

