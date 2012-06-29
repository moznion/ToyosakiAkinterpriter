#

use strict;
use warnings;
use utf8;
use Encode;
use 5.010;
use open IN => ":utf8";
use open OUT => ":utf8";
use open IO => ":utf8";

unless(defined($ARGV[0])) {
	say "Please input a file.";
	exit(1);
}

my $inputFilename = $ARGV[0];
open(FH, $inputFilename);

my @commands;
foreach(<FH>) {
	s/\x0D?\x0A$//g; # chomp
	for(;;) {
		if(s/^(豊崎愛生さん…)//) {
			unshift(@commands, "S");
		} elsif (s/^(僕は…)//) {
			unshift(@commands, "T");
		} elsif (s/^(もう…！)//) {
			unshift(@commands, "N");
		} elsif (s/^.//) {
		} else {
			last;
		}
	}
}
