#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Inspector');
    use_ok('HTML::MasonX::Inspector::Query::PerlCode');
}

my $MASON_FILE_NAME = '011-compiler-perl.html';
my $COMP_ROOT       = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE_NAME )->spew(q[
<%once>
use Scalar::Util 'blessed';
use List::Util   qw[ max uniq ];
use File::Spec   ();
use feature      qw[ say ];
use DateTime     0.20;
use v5.20;
require Test::More;
</%once>
]);

subtest '... simple compiler test using perl blocks and queries' => sub {

    my $i = HTML::MasonX::Inspector->new( comp_root => $COMP_ROOT );
    isa_ok($i, 'HTML::MasonX::Inspector');

    my $state = $i->get_compiler_inspector_for_path( $MASON_FILE_NAME );
    isa_ok($state, 'HTML::MasonX::Inspector::Compiler');

    my $comp = $state->get_main_component;
    isa_ok($comp, 'HTML::MasonX::Inspector::Compiler::Component');

    is($comp->name, $MASON_FILE_NAME, '... got the expected name');

    my $blocks = $comp->blocks;
    isa_ok($blocks, 'HTML::MasonX::Inspector::Compiler::Component::Blocks');

    ok($blocks->has_once_blocks, '... we have once blocks');
    ok(!$blocks->has_init_blocks, '... we do not have init blocks');
    ok(!$blocks->has_filter_blocks, '... we do not have filter blocks');
    ok(!$blocks->has_shared_blocks, '... we do not have shared blocks');
    ok(!$blocks->has_cleanup_blocks, '... we do not have cleanup blocks');

    subtest '... testing the once block' => sub {

        my ($once) = @{ $blocks->once_blocks };
        isa_ok($once, 'HTML::MasonX::Inspector::Compiler::Component::PerlCode');

        my (
            $scalar_util,
            $list_util,
            $file_spec,
            $feature,
            $datetime,
            $perl_version,
            $required_test_more,
        ) = HTML::MasonX::Inspector::Query::PerlCode->find_includes( $once );

        subtest '... testing include `use Scalar::Util "blessed";`' => sub {

            isa_ok($scalar_util, 'HTML::MasonX::Inspector::Perl::UsedModule');

            is($scalar_util->module, 'Scalar::Util', '... got the expected module name');
            is($scalar_util->module_version, undef, '... got the expected module version');

            ok(!$scalar_util->is_runtime, '... expected response from is_runtime');
            ok(!$scalar_util->is_conditional, '... expected response from is_conditional');
            ok(!$scalar_util->is_pragma, '... expected response from is_pragma');
            ok(!$scalar_util->is_perl_version, '... expected response from is_perl_version');

            ok(!$scalar_util->does_not_call_import, '... this calls import');

        };

        subtest '... testing include `use List::Util qw[ max uniq ]`' => sub {

            isa_ok($list_util, 'HTML::MasonX::Inspector::Perl::UsedModule');

            is($list_util->module, 'List::Util', '... got the expected module name');
            is($list_util->module_version, undef, '... got the expected module version');

            ok(!$list_util->is_runtime, '... expected response from is_runtime');
            ok(!$list_util->is_conditional, '... expected response from is_conditional');
            ok(!$list_util->is_pragma, '... expected response from is_pragma');
            ok(!$list_util->is_perl_version, '... expected response from is_perl_version');

            ok(!$list_util->does_not_call_import, '... this calls import');
        };

        subtest '... testing include `use File::Spec ();`' => sub {

            isa_ok($file_spec, 'HTML::MasonX::Inspector::Perl::UsedModule');

            is($file_spec->module, 'File::Spec', '... got the expected module name');
            is($file_spec->module_version, undef, '... got the expected module version');

            ok(!$file_spec->is_runtime, '... expected response from is_runtime');
            ok(!$file_spec->is_conditional, '... expected response from is_conditional');
            ok(!$file_spec->is_pragma, '... expected response from is_pragma');
            ok(!$file_spec->is_perl_version, '... expected response from is_perl_version');

            ok($file_spec->does_not_call_import, '... this does not call import');
        };

        subtest '... testing include `use feature qw[ say ];`' => sub {

            isa_ok($feature, 'HTML::MasonX::Inspector::Perl::UsedModule');

            is($feature->module, 'feature', '... got the expected module name');
            is($feature->module_version, undef, '... got the expected module version');

            ok($feature->is_pragma, '... expected response from is_pragma');
            ok(!$feature->is_runtime, '... expected response from is_runtime');
            ok(!$feature->is_conditional, '... expected response from is_conditional');
            ok(!$feature->is_perl_version, '... expected response from is_perl_version');

        };

        subtest '... testing include `use DateTime 0.20;`' => sub {

            isa_ok($datetime, 'HTML::MasonX::Inspector::Perl::UsedModule');

            is($datetime->module, 'DateTime', '... got the expected module name');
            is($datetime->module_version, '0.20', '... got the expected module version');

            ok(!$datetime->is_runtime, '... expected response from is_runtime');
            ok(!$datetime->is_conditional, '... expected response from is_conditional');
            ok(!$datetime->is_pragma, '... expected response from is_pragma');
            ok(!$datetime->is_perl_version, '... expected response from is_perl_version');

            ok(!$datetime->does_not_call_import, '... this calls import');

        };

        subtest '... testing include `use v5.20;`' => sub {

            isa_ok($perl_version, 'HTML::MasonX::Inspector::Perl::UsedModule');

            is($perl_version->module, '', '... got the expected module name');
            is($perl_version->module_version, undef, '... got the expected module version');

            ok($perl_version->is_perl_version, '... expected response from is_perl_version');

            ok(!$perl_version->is_runtime, '... expected response from is_runtime');
            ok(!$perl_version->is_conditional, '... expected response from is_conditional');
            ok(!$perl_version->is_pragma, '... expected response from is_pragma');
        };

        subtest '... testing include `require Test::More;`' => sub {

            isa_ok($required_test_more, 'HTML::MasonX::Inspector::Perl::UsedModule');

            is($required_test_more->module, 'Test::More', '... got the expected module name');
            is($required_test_more->module_version, undef, '... got the expected module version');

            ok($required_test_more->is_runtime, '... expected response from is_runtime');

            ok(!$required_test_more->is_conditional, '... expected response from is_conditional');
            ok(!$required_test_more->is_pragma, '... expected response from is_pragma');
            ok(!$required_test_more->is_perl_version, '... expected response from is_perl_version');
            ok(!$required_test_more->does_not_call_import, '... this calls import');

        };

    };

};

done_testing;

