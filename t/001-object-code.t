#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Inspector');
}

my $MASON_FILE = '001-basic.html';
my $COMP_ROOT  = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE )->spew(q[
<%args>
$greeting => undef
</%args>
<%init>
$greeting ||= 'World';
</%init>
<h1>Hello <% $greeting %></h1>
]);

subtest '... simple sloop test' => sub {

    my $sloop = HTML::MasonX::Inspector->new(
        comp_root     => $COMP_ROOT,
        allow_globals => [ '$x' ]
    );
    isa_ok($sloop, 'HTML::MasonX::Inspector');

    subtest '... testing the object code' => sub {

        my $obj_code;
        is(
            exception { $obj_code = $sloop->get_object_code_for_path( $MASON_FILE ) },
            undef, '... got object code without exception'
        );

        isa_ok($obj_code, 'HTML::MasonX::Inspector::ObjectCode');

        my $src = $obj_code->clean_source;
        like( $src, $_, '... the object code matches ' . $_ ) foreach (
            qr/package HTML\:\:Mason\:\:Commands/,
            qr/use vars qw\(\s*\$m\s*\$x\s*\)\;/,
            qr/\$greeting\s*\|\|\=\s*\'World\'\;/,
            qr/\$m\-\>print\(\s*\'\<h1\>Hello \'\s*\)\;/,
            qr/\$m\-\>print\(\s*\$greeting\s*\)\;/,
        );
    };

};

done_testing;

