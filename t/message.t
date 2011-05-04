#!/usr/bin/env perl

use common::sense;

use Test::More tests => 10;

use_ok 'TSS::Message';
my $m = new_ok 'TSS::Message', [p => 257];

$m->push_data(0xf6);
$m->push_data(0x00);
$m->push_data(0x101);

is $m->get_p, 257;
is_deeply $m->get_data, [0xf6, 0x00, 0x101];
is_deeply [unpack 'C*', $m->binary], [0x7b, 0x00, 0x20, 0x20];
is_deeply TSS::Message->build_from_binary($m->get_p, $m->binary)->get_data,
  [0xf6, 0x00, 0x101];

$m = new_ok 'TSS::Message', [p => 13];
$m->push_data(0x00);
$m->push_data(0x01);
$m->push_data(0x0a);
$m->push_data(0x01);
is_deeply $m->get_data, [0x00, 0x01, 0x0a, 0x01];
is_deeply [unpack 'C*', $m->binary], [0x01, 0xa1];
is_deeply TSS::Message->build_from_binary($m->get_p, $m->binary)->get_data,
  [0x00, 0x01, 0x0a, 0x01];
