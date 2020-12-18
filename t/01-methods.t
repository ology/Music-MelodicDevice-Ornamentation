#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::MelodicDevice::Ornamentation';

my $obj = new_ok 'Music::MelodicDevice::Ornamentation';# => [ verbose => 1 ];

my $expect = [['d6', 'D#5'], ['d90', 'D5']];
my $got = $obj->grace_note('qn', 'D5', 1);
is_deeply $got, $expect, 'grace_note above';
$expect = [['d6', 'D5'], ['d90', 'D5']];
$got = $obj->grace_note('qn', 'D5', 0);
is_deeply $got, $expect, 'grace_note same';
$expect = [['d6', 'C#5'], ['d90', 'D5']];
$got = $obj->grace_note('qn', 'D5', -1);
is_deeply $got, $expect, 'grace_note below';

$expect = [['d24','D#5'], ['d24','D5'], ['d24','C#5'], ['d24','D5']];
$got = $obj->turn('qn', 'D5', 1);
is_deeply $got, $expect, 'turn';

$expect = [['d24','D5'], ['d24','D#5'], ['d24','D5'], ['d24','D#5']];
$got = $obj->trill('qn', 'D5', 2, 1);
is_deeply $got, $expect, 'trill';

$obj = new_ok 'Music::MelodicDevice::Ornamentation' => [ scale_name => 'major' ];

$expect = [['d6', 'E5'], ['d90', 'D5']];
$got = $obj->grace_note('qn', 'D5', 1);
is_deeply $got, $expect, 'grace_note above';
$expect = [['d6', 'D5'], ['d90', 'D5']];
$got = $obj->grace_note('qn', 'D5', 0);
is_deeply $got, $expect, 'grace_note same';
$expect = [['d6', 'C5'], ['d90', 'D5']];
$got = $obj->grace_note('qn', 'D5', -1);
is_deeply $got, $expect, 'grace_note below';

$expect = [['d24','E5'], ['d24','D5'], ['d24','C5'], ['d24','D5']];
$got = $obj->turn('qn', 'D5', 1);
is_deeply $got, $expect, 'turn';

$expect = [['d24','D5'], ['d24','E5'], ['d24','D5'], ['d24','E5']];
$got = $obj->trill('qn', 'D5', 2, 1);
is_deeply $got, $expect, 'trill';

done_testing();
