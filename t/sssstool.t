use strict;
use warnings;
use IPC::Open3;
use File::Spec;
use File::Basename;
use Symbol 'gensym';
use Test::More tests => 2;

my $toolname =  File::Spec->catfile(dirname($0), File::Spec->updir,
				    'bin', 'sssstool');

sub runtool {
    open(my $nullin, '<', File::Spec->devnull);
    my ($fhout,$fherr) = (gensym,gensym);

    my $pid = open3($nullin, $fhout, $fherr,
		    'perl', $toolname, @_);
    my @out;
    while (<$fhout>) {
	chomp;
	push @out, $_;
    }
    my $err = do { local $/; <$fherr> };
    waitpid($pid, 0);
    my $status = $? >> 8;
    if ($? || $err) {
	die "error: \"$err\", status $?"
    }
    return @out;
}

my @message = ('the ', 'very', ' secret', '!');

my @hashes = qw(
		 001-ADsfZPfA5So=
		 002-ACWPYqTDZWw=
		 003-AAPc73AJBa4=
		 004-ABYHq0GhzfA=
		 005-ABwP5iGBuDA=
	      );

my @rhashes = qw(
		 002-ACWPYqTDZWw=
		 003-AAPc73AJBa4=
		 004-ABYHq0GhzfA=
	      );

is_deeply([runtool(qw(-d -k 3 -n 5 -p 257), map { ('-m', $_) } @message)],
	  [@hashes],
	  'encrypt');

is_deeply([runtool(qw(-r -p 257), map { ('-m', $_) } @rhashes)],
	  [join('',@message)],
	  'decrypt');

done_testing;
