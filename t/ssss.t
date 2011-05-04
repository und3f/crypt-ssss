#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 13;

use_ok 'Crypt::SSSS';
can_ok 'Crypt::SSSS', qw(ssss_distribute ssss_reconstruct);

my $messages = Crypt::SSSS::ssss_distribute(
    message => "\x0b\x08\x07",
    k       => 3,
    n       => 5,
    p       => 13,
);

my $p = (values %$messages)[0]->get_p;

is_deeply $messages->{1}->get_data, [0x00], 'distributed data';
is_deeply $messages->{2}->get_data, [0x03], 'distributed data';
is_deeply $messages->{3}->get_data, [0x07], 'distributed data';
is_deeply $messages->{4}->get_data, [0x0c], 'distributed data';
is_deeply $messages->{5}->get_data, [0x05], 'distributed data';

is_deeply [
    (   unpack 'C*',
        Crypt::SSSS::ssss_reconstruct(
            $p,
            {   2 => $messages->{2}->binary,
                3 => $messages->{3}->binary,
                4 => $messages->{4}->binary
            },
            1
        )
    )
  ],
  [0x0b, 0x08, 0x07],
  'original message reconstructed';


$messages = Crypt::SSSS::ssss_distribute(
    message => "\x06\x1c\x08\x0b\x1f\x4a",
    k       => 3,
    p       => 257,
    n       => 4,
);

$p = (values %$messages)[0]->get_p;

is_deeply $messages->{1}->get_data, [42,  116], 'distributed data';
is_deeply $messages->{2}->get_data, [94,  112], 'distributed data';
is_deeply $messages->{3}->get_data, [162, 256], 'distributed data';
is_deeply $messages->{4}->get_data, [246, 34],  'distributed data';


is_deeply [
    (   unpack 'C*',
        Crypt::SSSS::ssss_reconstruct(
            $p,
            {   1 => $messages->{1}->binary,
                2 => $messages->{2}->binary,
                3 => $messages->{3}->binary
            }
        )
    )
  ],
  [0x06, 0x1c, 0x08, 0x0b, 0x1f, 0x4a], 'original messages reconstructed';
