use strict;
use warnings;
use IPC::Open3;
use File::Spec;
use File::Basename;
use Symbol 'gensym';
use Test::More tests => 2;

my $toolname =  File::Spec->catfile(dirname($0), File::Spec->updir,
				    'contrib', 'sssstool');

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
my @hashes = qw(001-ID7BQ6JQhA==
                002-ayecbHBIhA==
                003-GgKfYYWAhA==
                004-LhAKQvHohA==
                005-Jo/dQLWQhA==);

is_deeply([runtool(qw(-d -k 3 -n 5 -p 257), map { ('-m', $_) } @message)],
          [@hashes],
	  'encrypt');
is_deeply([runtool('-r', '-p', 257, '-l', length(join('',@message)),
		   map { ('-m', $_) } @hashes)],
	  [join('',@message)],
	  'decrypt');
