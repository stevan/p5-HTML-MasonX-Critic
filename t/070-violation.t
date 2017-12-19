#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('HTML::MasonX::Critic::Violation');
}

package My::Simple::Element {
    sub highlight     { $_[0]->{highlight}     }
    sub source        { $_[0]->{source}        }
    sub filename      { $_[0]->{filename}      }
    sub line_number   { $_[0]->{line_number}   }
    sub column_number { $_[0]->{column_number} }
}

subtest '... simple violation test' => sub {

    my $v = HTML::MasonX::Critic::Violation->new(
        description   => 'Description',
        explanation   => 'Explanation',
        policy        => 'Policy',
        element       => bless {
            highlight     => 'source',
            source        => 'the(source)',
            filename      => 'filename.html',
            line_number   => 10,
            column_number => 1,
        } => 'My::Simple::Element',
    );
    isa_ok($v, 'HTML::MasonX::Critic::Violation');

    is($v->description,   'Description',    '... got expected value for description');
    is($v->explanation,   'Explanation',    '... got expected value for explanation');
    is($v->policy,        'Policy',         '... got expected value for policy');
    is($v->filename,      'filename.html',  '... got expected value for filename');
    is($v->source,        'the(source)',    '... got expected value for source');
    is($v->line_number,   10,               '... got expected value for line_number');
    is($v->column_number, 1,                '... got expected value for column_number');
    is($v->highlight,     'source',         '... got expected value for highlight');

};

done_testing;
