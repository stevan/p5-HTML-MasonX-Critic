#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Critic');
    use_ok('HTML::MasonX::Critic::Inspector::Query::PerlCode');
}

my $MASON_FILE_NAME = '032-perl-subroutine-declaration.html';
my $COMP_ROOT       = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE_NAME )->spew(q[
<%once>
sub foo { $_[0] x 'FOO' }
sub bar {
    my ($baz) = @_;
    return foo( $baz + 10 );
}
</%once>
]);

subtest '... simple compiler test using perl blocks and queries' => sub {

    my $i = HTML::MasonX::Critic::Inspector->new( comp_root => $COMP_ROOT );
    isa_ok($i, 'HTML::MasonX::Critic::Inspector');

    my $state = $i->compile_path( $MASON_FILE_NAME );
    isa_ok($state, 'HTML::MasonX::Critic::Inspector::CompiledPath');

    my $comp = $state->root_component;
    isa_ok($comp, 'HTML::MasonX::Critic::Inspector::Compiled::Component');

    is($comp->name, $MASON_FILE_NAME, '... got the expected name');

    my $blocks = $comp->blocks;
    isa_ok($blocks, 'HTML::MasonX::Critic::Inspector::Compiled::Component::Blocks');

    ok($blocks->has_once_blocks, '... we have once blocks');
    ok(!$blocks->has_init_blocks, '... we do not have init blocks');
    ok(!$blocks->has_filter_blocks, '... we do not have filter blocks');
    ok(!$blocks->has_shared_blocks, '... we do not have shared blocks');
    ok(!$blocks->has_cleanup_blocks, '... we do not have cleanup blocks');

    subtest '... testing the once block' => sub {

        my ($once) = @{ $blocks->once_blocks };
        isa_ok($once, 'HTML::MasonX::Critic::Inspector::Compiled::Component::PerlCode');

        my ($foo, $bar) = HTML::MasonX::Critic::Inspector::Query::PerlCode->find_subroutine_declarations( $once );

        isa_ok($foo, 'HTML::MasonX::Critic::Inspector::Query::Element::Perl::SubroutineDeclaration');
        is($foo->symbol, 'foo', '... got the expected subroutine name');
        is($foo->line_number, 3, '... got the expected line number');
        is($foo->column_number, 1, '... got the expected column number');

        isa_ok($bar, 'HTML::MasonX::Critic::Inspector::Query::Element::Perl::SubroutineDeclaration');
        is($bar->symbol, 'bar', '... got the expected subroutine name');
        is($bar->line_number, 4, '... got the expected line number');
        is($bar->column_number, 1, '... got the expected column number');
    };

};

done_testing;

