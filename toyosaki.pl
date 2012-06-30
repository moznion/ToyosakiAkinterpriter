#!/usr/bin/perl

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

# Stack commands.
my @commands;
foreach(<FH>) {
	s/\x0D?\x0A$//g; # chomp
	for(;;) {
		if(s/^はぁ、豊崎愛生さん…//) {
			push(@commands, "S");
		} elsif (s/^僕は…//) {
			push(@commands, "T");
		} elsif (s/^もう…！//) {
			push(@commands, "N");
		} elsif (s/^.//) {
		} else {
			last;
		}
	}
}

my $command = join('', @commands);

# Process
my $address;
my @stack;
my $commandClone = $command;
my $tempClonedCommand;
my $beforeSubRoutineCall;
for(;;) {

	# Push to stack
	if ($command =~ s/^(SS)//) {
		$command =~ s/^([S|T]*)N//;

		my $num = $1;
		$num =~ s/S/0/g; $num =~ s/T/1/g;
		my $dec = unpack("C*", pack("B*", $num));
		unshift(@stack, $dec);

	# Copy top of stack
	} elsif ($command =~ s/^SNS//) {
		unshift(@stack, $stack[0]);

	# Swap top of stack between the second of stack
	} elsif ($command =~ s/^SNT//) {
		my $fst = shift(@stack);
		my $snd = shift(@stack);
		unshift(@stack, $snd);
		unshift(@stack, $fst);

	# Drop top of stack
	} elsif ($command =~ s/^SNN//) {
		shift(@stack);

	# Add
	} elsif ($command =~ s/^TSSS//) {
		my $fst = shift(@stack);
		my $snd = shift(@stack);
		unshift(@stack, ($fst + $snd));

	# Sub
	} elsif ($command =~ s/^TSST//) {
		my $fst = shift(@stack);
		my $snd = shift(@stack);
		unshift(@stack, ($fst - $snd));

	# Mult
	} elsif ($command =~ s/^TSSN//) {
		my $fst = shift(@stack);
		my $snd = shift(@stack);
		unshift(@stack, ($fst * $snd));

	# Div
	} elsif ($command =~ s/^TSTS//) {
		my $fst = shift(@stack);
		my $snd = shift(@stack);
		unshift(@stack, ($fst / $snd));

	# Mod
	} elsif ($command =~ s/^TSTT//) {
		my $fst = shift(@stack);
		my $snd = shift(@stack);
		unshift(@stack, ($fst % $snd));

	# Store value to address
	} elsif ($command =~ s/^TTS//) {
		$address = shift(@stack);

	# Unstore value from address to stack
	} elsif ($command =~ s/^TTT//) {
		if(defined($address)) {
			unshift(@stack, $address);
		} else {
			say "Address is not stored.";
			exit(1);
		}

	# Output character of top of the stack
	} elsif ($command =~ s/TNSS//) {
		print (pack "C*", shift(@stack));

	# Output number of top of the stack
	} elsif ($command =~ s/TNST//) {
		print (shift(@stack));

	# Set label
	} elsif ($command =~ s/(NSS)//) {
		$command =~ s/^([S|T]*)N//;

	# Call sub routine
	} elsif ($command =~ s/^(NST)//) {
		$command =~ s/^([S|T]*)N//;
		my $subRoutineLabel = $1;
		$tempClonedCommand = $commandClone;
		$tempClonedCommand =~ s/^[S|T|N]*NSS${subRoutineLabel}N//;
		$beforeSubRoutineCall = $command;
		$command = $tempClonedCommand;

	# Unconfitional Jump
	} elsif ($command =~ s/^(NSN)//) {
		$command =~ s/^([S|T]*)N//;
		my $unconJumpLabel = $1;
		$tempClonedCommand = $commandClone;
		$tempClonedCommand =~ s/^[S|T|N]*NSS${unconJumpLabel}N//;
		$command = $tempClonedCommand;
	
	# JZ
	} elsif ($command =~ s/^(NTS)//) {
		$command =~ s/^([S|T]*)N//;
		my $jzLabel = $1;
		if ($stack[0] == 0) {
			$tempClonedCommand = $commandClone;
			$tempClonedCommand =~ s/^[S|T|N]*NSS${jzLabel}N//;
			$command = $tempClonedCommand;
		}

	# JM
	} elsif ($command =~ s/^(NTT)//) {
		$command =~ s/^([S|T]*)N//;
		my $jmLabel = $1;
		if ($stack[0] < 0) {
			$tempClonedCommand = $commandClone;
			$tempClonedCommand =~ s/^[S|T|N]*NSS${jmLabel}N//;
			$command = $tempClonedCommand;
		}

	# End of Sub Routine
	} elsif ($command =~ s/^NTN//) {
		$command = $beforeSubRoutineCall;

	# End of Programm
	} elsif ($command =~ s/^NNN//) {
		last;

	# Error
	} else {
		say "Syntax error";
		exit(1);
	}

	# End? (Command Strings are null)
	if ($command eq '') {
		last;
	}

}
