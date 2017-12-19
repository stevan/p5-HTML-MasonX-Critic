#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Critic');
}

my $MASON_FILE_NAME = '071-violation-source-file.html';
my $COMP_ROOT       = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE_NAME )->spew(q[
<%init>
foo();
bar();
baz();
</%init>
]);

subtest '... simple violation test' => sub {

    my $i = HTML::MasonX::Critic::Inspector->new( comp_root => $COMP_ROOT );
    isa_ok($i, 'HTML::MasonX::Critic::Inspector');

    my $state = $i->get_compiler_inspector_for_path( $MASON_FILE_NAME );
    isa_ok($state, 'HTML::MasonX::Critic::Inspector::Compiler');

    my $comp = $state->get_main_component;
    isa_ok($comp, 'HTML::MasonX::Critic::Inspector::Compiler::Component');

    my $blocks = $comp->blocks;
    isa_ok($blocks, 'HTML::MasonX::Critic::Inspector::Compiler::Component::Blocks');

    my ($init) = @{ $blocks->init_blocks };
    isa_ok($init, 'HTML::MasonX::Critic::Inspector::Compiler::Component::PerlCode');

    my @subcalls = HTML::MasonX::Critic::Inspector::Query::PerlCode->find_subroutine_calls( $init, ignore_builtins => 1 );
    is(scalar(@subcalls), 3, '... got the three calls');

    isa_ok($_, 'HTML::MasonX::Critic::Inspector::Perl::SubroutineCall')
        foreach @subcalls;

    my ($foo, $bar, $baz) = @subcalls;

    my $v = HTML::MasonX::Critic::Violation->new(
        description   => 'Description',
        explanation   => 'Explanation',
        policy        => 'Policy',
        element       => $bar
    );
    isa_ok($v, 'HTML::MasonX::Critic::Violation');

    is($v->description,   'Description',    '... got expected value for description');
    is($v->explanation,   'Explanation',    '... got expected value for explanation');
    is($v->policy,        'Policy',         '... got expected value for policy');
    is($v->source,        'bar',            '... got expected value for source');
    is($v->line_number,   4,                '... got expected value for line_number');
    is($v->column_number, 1,                '... got expected value for column_number');
    is($v->highlight,     'bar',            '... got expected value for highlight');
    is(
        Path::Tiny::path($v->filename)->basename,
        $MASON_FILE_NAME,
        '... got expected value for filename'
    );

    my $f = $v->source_file;
    isa_ok($f, 'HTML::MasonX::Critic::Violation::SourceFile');

    subtest '... just get the violation lines' => sub {

        my ($line) = $f->get_violation_lines;
        isa_ok($line, 'HTML::MasonX::Critic::Violation::SourceFile::Line');

        is($line->line,     "bar();\n", '... got the line');
        is($line->line_num, 4,        '... got the line-num');
        ok($line->in_violation, '... this line is in the violation');
        ok($line->is_in_between(3, 6), '... this line is between line 3 and line 6');
    };

    subtest '... just get the violation lines - 1' => sub {

        my ($line1, $line2) = $f->get_violation_lines( before => 1 );
        isa_ok($line1, 'HTML::MasonX::Critic::Violation::SourceFile::Line');
        isa_ok($line2, 'HTML::MasonX::Critic::Violation::SourceFile::Line');

        is($line1->line,     "foo();\n", '... got the line');
        is($line1->line_num, 3,        '... got the line-num');
        ok(!$line1->in_violation, '... this line is in the violation');
        ok($line1->is_in_between(3, 6), '... this line is between line 3 and line 6');

        is($line2->line,     "bar();\n", '... got the line');
        is($line2->line_num, 4,        '... got the line-num');
        ok($line2->in_violation, '... this line is in the violation');
        ok($line2->is_in_between(3, 6), '... this line is between line 3 and line 6');
    };

    subtest '... just get the violation lines + 1' => sub {

        my ($line1, $line2) = $f->get_violation_lines( after => 1 );
        isa_ok($line1, 'HTML::MasonX::Critic::Violation::SourceFile::Line');
        isa_ok($line2, 'HTML::MasonX::Critic::Violation::SourceFile::Line');

        is($line1->line,     "bar();\n", '... got the line');
        is($line1->line_num, 4,        '... got the line-num');
        ok($line1->in_violation, '... this line is in the violation');
        ok($line1->is_in_between(3, 6), '... this line is between line 3 and line 6');

        is($line2->line,     "baz();\n", '... got the line');
        is($line2->line_num, 5,        '... got the line-num');
        ok(!$line2->in_violation, '... this line is in the violation');
        ok($line2->is_in_between(3, 6), '... this line is between line 3 and line 6');
    };

    subtest '... just get the violation lines -/+ 1' => sub {

        my ($line1, $line2, $line3) = $f->get_violation_lines( before => 1, after => 1 );
        isa_ok($line1, 'HTML::MasonX::Critic::Violation::SourceFile::Line');
        isa_ok($line2, 'HTML::MasonX::Critic::Violation::SourceFile::Line');
        isa_ok($line3, 'HTML::MasonX::Critic::Violation::SourceFile::Line');

        is($line1->line,     "foo();\n", '... got the line');
        is($line1->line_num, 3,        '... got the line-num');
        ok(!$line1->in_violation, '... this line is in the violation');
        ok($line1->is_in_between(3, 6), '... this line is between line 3 and line 6');

        is($line2->line,     "bar();\n", '... got the line');
        is($line2->line_num, 4,        '... got the line-num');
        ok($line2->in_violation, '... this line is in the violation');
        ok($line2->is_in_between(3, 6), '... this line is between line 3 and line 6');

        is($line3->line,     "baz();\n", '... got the line');
        is($line3->line_num, 5,        '... got the line-num');
        ok(!$line3->in_violation, '... this line is in the violation');
        ok($line3->is_in_between(3, 6), '... this line is between line 3 and line 6');
    };


    subtest '... just get the violation lines all' => sub {

        my ($blank, $open, $line1, $line2, $line3, $close) = $f->get_violation_lines( all => 1 );
        isa_ok($blank, 'HTML::MasonX::Critic::Violation::SourceFile::Line');
        isa_ok($open,  'HTML::MasonX::Critic::Violation::SourceFile::Line');
        isa_ok($line1, 'HTML::MasonX::Critic::Violation::SourceFile::Line');
        isa_ok($line2, 'HTML::MasonX::Critic::Violation::SourceFile::Line');
        isa_ok($line3, 'HTML::MasonX::Critic::Violation::SourceFile::Line');
        isa_ok($close, 'HTML::MasonX::Critic::Violation::SourceFile::Line');

        is($blank->line,     "\n", '... got the line');
        is($blank->line_num, 1,        '... got the line-num');
        ok(!$blank->in_violation, '... this line is in the violation');
        ok(!$blank->is_in_between(3, 6), '... this line is not between line 3 and line 6');

        is($open->line,     "<%init>\n", '... got the line');
        is($open->line_num, 2,        '... got the line-num');
        ok(!$open->in_violation, '... this line is in the violation');
        ok(!$open->is_in_between(3, 6), '... this line is not between line 3 and line 6');

        is($line1->line,     "foo();\n", '... got the line');
        is($line1->line_num, 3,        '... got the line-num');
        ok(!$line1->in_violation, '... this line is in the violation');
        ok($line1->is_in_between(3, 6), '... this line is between line 3 and line 6');

        is($line2->line,     "bar();\n", '... got the line');
        is($line2->line_num, 4,        '... got the line-num');
        ok($line2->in_violation, '... this line is in the violation');
        ok($line2->is_in_between(3, 6), '... this line is between line 3 and line 6');

        is($line3->line,     "baz();\n", '... got the line');
        is($line3->line_num, 5,        '... got the line-num');
        ok(!$line3->in_violation, '... this line is in the violation');
        ok($line3->is_in_between(3, 6), '... this line is between line 3 and line 6');

        is($close->line,     "</%init>\n", '... got the line');
        is($close->line_num, 6,        '... got the line-num');
        ok(!$close->in_violation, '... this line is in the violation');
        ok(!$close->is_in_between(3, 6), '... this line is not between line 3 and line 6');
    };
};

done_testing;
