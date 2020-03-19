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
    die "$?" if $?;
    die $err if $err;
    return @out;
}

sub runtest {
    my @result = runtool(qw(-d -k 3 -n 5 -P test-),
			 map { ('-m', $_) } @_);
    return runtool('-r', '-l', length(join('',@_)), map { ('-m', $_) } @result);
}

my @message = ('the ', 'very', ' secret', '!');
my @hashes = qw(001-UE+0LTtSwhA=
                002-MkkXkLo/QhA=
                003-Rs8TuP9lwhA=
                004-CgDA4gpCghA=
                005-g6AHRcxZQhA=);

is_deeply([runtool(qw(-d -k 3 -n 5 -P test-), map { ('-m', $_) } @message)],
          [@hashes],
	  'encrypt');
is_deeply([runtool('-r', '-l', length(join('',@message)),
		   map { ('-m', $_) } @hashes)],
	  [join('',@message)],
	  'decrypt');
