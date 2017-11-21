#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Sloop');
    use_ok('HTML::MasonX::Sloop::Util', qw[ calculate_checksum ]);
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

    my $sloop = HTML::MasonX::Sloop::Inspector->new(
        comp_root     => $COMP_ROOT,
        allow_globals => [ '$x' ]
    );
    isa_ok($sloop, 'HTML::MasonX::Sloop::Inspector');

    is($sloop->comp_root, $COMP_ROOT->stringify, '... the comp root is as we expected');
    is_deeply(
        [ $sloop->allow_globals ],
        [ '$x' ],
        '... got the expected globals in Mason'
    );

    subtest '... testing the object code' => sub {

        my $obj_code;
        is(
            exception { $obj_code = $sloop->get_object_code_for_path( $MASON_FILE ) },
            undef, '... got object code without exception'
        );

        my $obj_code_checksum;
        is(
            exception { $obj_code_checksum = $sloop->get_object_code_checksum_for_path( $MASON_FILE ) },
            undef, '... got object code checksum without exception'
        );

        ok($obj_code, '... we got something back from the object code');
        ok($obj_code_checksum, '... we got something back from the object code checksum');

        is(calculate_checksum( $obj_code ), $obj_code_checksum, '... checksum is cool');

        like( $obj_code, $_, '... the object code matches ' . $_ ) foreach (
            qr/package HTML\:\:Mason\:\:Commands/,
            qr/use vars qw\(\s*\$m\s*\$x\s*\)\;/,
            qr/\$greeting\s*\|\|\=\s*\'World\'\;/,
            qr/\$m\-\>print\(\s*\'\<h1\>Hello \'\s*\)\;/,
            qr/\$m\-\>print\(\s*\$greeting\s*\)\;/,
        );

        #warn $obj_code;
    };

};

done_testing;

