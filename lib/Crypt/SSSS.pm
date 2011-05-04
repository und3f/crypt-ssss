package Crypt::SSSS;

use strict;
use warnings;

our $VERSION = 0.1;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(ssss_distribute ssss_reconstruct);

use POSIX qw(ceil pow);
use Math::Polynom;
use Crypt::SSSS::Message;

require Carp;

sub ssss_distribute(%) {
    my (%data) = @_;

    my $message = $data{message} or Carp::croak 'Missed "message" argument';

    my $k = $data{k} or Carp::croak 'Missed "k" argument';
    my $n = $data{n} || $k;

    my $p = $data{p} or Carp::croak 'Missed "p" argument';

    my $messages = {};

    for my $x (1 .. $n) {
        $messages->{$x} = Crypt::SSSS::Message->new(p => $p);
    }

    my @args = unpack 'C*', $message;
    while (@args) {
        my @a = splice @args, 0, $k;

        for my $x (1 .. $n) {

            my $res = 0;
            for my $pow (0 .. $k - 1) {
                $res += $a[$pow] * pow($x, $pow);

            }

            # print "$x → ", $res % $p, "\n";
            $messages->{$x}->push_data($res % $p);
        }
    }

    $messages;
}

sub ssss_reconstruct($$$;$) {
    my ($p, $messages, $size) = @_;

    my @xs = keys %$messages;

    my $k = @xs;

    my %mdata;
    foreach my $x (@xs) {
        $mdata{$x} =
          Crypt::SSSS::Message->build_from_binary($p, $messages->{$x})
          ->get_data;
    }

    $size ||= @{(values %mdata)[0]};

    my $message = '';

    for (my $l = 0; $l < $size; $l++) {
        my $fx = Math::Polynom->new(0 => 0);
        for my $i (@xs) {
            my $pl = Math::Polynom->new(0 => 1);
            my $d = 1;
            for my $j (@xs) {
                if ($j != $i) {
                    $pl = $pl->multiply(Math::Polynom->new(1 => 1, 0 => -$j));
                    $d *= $i - $j;
                }
            }
            $d += $p if $d < 0;

            my ($m) = extended_gcb($d, $p);
            $m += $p if $m < 0;

            $fx = $fx->add($pl->multiply($m * $mdata{$i}->[$l]));
        }

        for (values %{$fx->{polynom}}) {
            $_ %= $p;
            $_ += $p if $_ < 0;
        }

        for (my $i = 0; $i < $k; $i++) {
            $message .= pack 'C', $fx->{polynom}->{$i};
        }
    }

    $message;
}

sub extended_gcb {
    my ($a, $b) = @_;

    return (1, 0) if $b == 0;

    my $q = int($a / $b);
    my $r = $a % $b;
    my ($s, $t) = extended_gcb($b, $r);

    return ($t, $s - $q * $t);
}

1;
__END__

=head1 NAME

Crypt::SSSS - implementation of Shamir's Secret Sharing System.

=head1 SYNOPSIS

    use Crypt::SSSS;

    # use (3, 3) scheme
    my $shares = ssss_distribute(
        message => "\x06\x1c\x08",
        k       => 3,
        n       => 3,
        p       => 257);

    # Save shares
    for my $share (1..3) {
        open my $fh, '>', "share${share}.dat";
        print $fh $shares->{$share}->binary;
        close $fh;
    }

    # Reconstruct message
    my $ishares = {};
    for my $share (1..3) {
        open my $fh, '<', "share${share}.dat";
        $ishares->{$share} = do {
            local $/; # slurp!
            <$fh>;
        };
        close $fh;
    }

    print "Original message: ", sprintf '"\x%02x\x%02x\x%02x"',
        unpack('C*', ssss_reconstruct(257, $ishares));

=head1 DESCRIPTION

Implementation of Shamir's Secret Sharing Scheme.

=head1 ATTRIBUTES

Crypt::SSSS implements the following attributes.

=head2 C<ssss_distribute>

    my $messages = ssss_distribute(
        message => $message,
        p       => $p,
        k       => $k,
        n       => $n, # By default equals to k
    );

Distribute C<$message> to C<$n> shares, so that any C<$k> shares would be
enough to reconstruct the secret. C<$p> is a prime number.

=head2 C<ssss_reconstruct>

    my $secret = ssss_reconstruct($p, $messages);

Reconstruct message from given C<$messages>. C<$p> is a prime number used to
distribute message.

=head1 AUTHOR

Sergey Zasenko, C<undef@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Sergey Zasenko.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
