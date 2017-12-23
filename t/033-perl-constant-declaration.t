#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Critic');
    use_ok('HTML::MasonX::Critic::Inspector::Query::Factory::PerlCode');
}

my $MASON_FILE_NAME = '033-perl-constant-declaration.html';
my $COMP_ROOT       = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE_NAME )->spew(q[
<%once>
use constant FOO => 10;
# ...
use constant BAR => { baz => 20 };
</%once>
]);

subtest '... simple compiler test using perl blocks and queries' => sub {

    my $i = HTML::MasonX::Critic::Inspector->new( comp_root => $COMP_ROOT );
    isa_ok($i, 'HTML::MasonX::Critic::Inspector');

    my $state = $i->get_compiler_inspector_for_path( $MASON_FILE_NAME );
    isa_ok($state, 'HTML::MasonX::Critic::Inspector::Compiler');

    my $comp = $state->get_main_component;
    isa_ok($comp, 'HTML::MasonX::Critic::Inspector::Compiler::Component');

    is($comp->name, $MASON_FILE_NAME, '... got the expected name');

    my $blocks = $comp->blocks;
    isa_ok($blocks, 'HTML::MasonX::Critic::Inspector::Compiler::Component::Blocks');

    ok($blocks->has_once_blocks, '... we have once blocks');
    ok(!$blocks->has_init_blocks, '... we do not have init blocks');
    ok(!$blocks->has_filter_blocks, '... we do not have filter blocks');
    ok(!$blocks->has_shared_blocks, '... we do not have shared blocks');
    ok(!$blocks->has_cleanup_blocks, '... we do not have cleanup blocks');

    subtest '... testing the once block' => sub {

        my ($once) = @{ $blocks->once_blocks };
        isa_ok($once, 'HTML::MasonX::Critic::Inspector::Compiler::Component::PerlCode');

        my ($FOO, $BAR) = HTML::MasonX::Critic::Inspector::Query::Factory::PerlCode->find_constant_declarations( $once );

        isa_ok($FOO, 'HTML::MasonX::Critic::Inspector::Query::Element::Perl::ConstantDeclaration');
        is($FOO->symbol, 'FOO', '... got the expected subroutine name');
        is($FOO->line_number, 3, '... got the expected line number');
        is($FOO->column_number, 1, '... got the expected column number');
        is_deeply(
            [ $FOO->arguments ],
            [ '10' ],
            '... got the expected arguments'
        );

        isa_ok($BAR, 'HTML::MasonX::Critic::Inspector::Query::Element::Perl::ConstantDeclaration');
        is($BAR->symbol, 'BAR', '... got the expected subroutine name');
        is($BAR->line_number, 5, '... got the expected line number');
        is($BAR->column_number, 1, '... got the expected column number');
        is_deeply(
            [ $BAR->arguments ],
            [ '{ baz => 20 }' ],
            '... got the expected arguments'
        );
    };

};

done_testing;

