#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use 5.010;
use open IN => ":utf8";
use open OUT => ":utf8";
use open IO => ":utf8";

unless(defined($ARGV[0])) {
	say "Please input a file.";
	exit(1);
}

# Lex
my $tokens = &lexicalAnalyze($ARGV[0]);

# Process
my $address;
my @stack;
my $commandClone = $tokens;
my $tempClonedCommand;
my $beforeSubRoutineCall;
for(;;) {

	# Push to stack
	if ($tokens =~ s/^(SS)//) {
		$tokens =~ s/^([S|T]*)N//;

		my $num = $1;
		$num =~ s/S/0/g; $num =~ s/T/1/g;
		my $dec = unpack("C*", pack("B*", $num));
		unshift(@stack, $dec);

	# Copy top of stack
	} elsif ($tokens =~ s/^SNS//) {
		unshift(@stack, $stack[0]);

	# Swap top of stack between the second of stack
	} elsif ($tokens =~ s/^SNT//) {
		my $fst = shift(@stack);
		my $snd = shift(@stack);
		unshift(@stack, $snd);
		unshift(@stack, $fst);

	# Drop top of stack
	} elsif ($tokens =~ s/^SNN//) {
		shift(@stack);

	# Add
	} elsif ($tokens =~ s/^TSSS//) {
		my $fst = shift(@stack);
		my $snd = shift(@stack);
		unshift(@stack, ($fst + $snd));

	# Sub
	} elsif ($tokens =~ s/^TSST//) {
		my $fst = shift(@stack);
		my $snd = shift(@stack);
		unshift(@stack, ($fst - $snd));

	# Mult
	} elsif ($tokens =~ s/^TSSN//) {
		my $fst = shift(@stack);
		my $snd = shift(@stack);
		unshift(@stack, ($fst * $snd));

	# Div
	} elsif ($tokens =~ s/^TSTS//) {
		my $fst = shift(@stack);
		my $snd = shift(@stack);
		unshift(@stack, ($fst / $snd));

	# Mod
	} elsif ($tokens =~ s/^TSTT//) {
		my $fst = shift(@stack);
		my $snd = shift(@stack);
		unshift(@stack, ($fst % $snd));

	# Store value to address
	} elsif ($tokens =~ s/^TTS//) {
		$address = shift(@stack);

	# Unstore value from address to stack
	} elsif ($tokens =~ s/^TTT//) {
		if(defined($address)) {
			unshift(@stack, $address);
		} else {
			say "Address is not stored.";
			exit(1);
		}

	# Output character of top of the stack
	} elsif ($tokens =~ s/TNSS//) {
		print (pack "C*", shift(@stack));

	# Output number of top of the stack
	} elsif ($tokens =~ s/TNST//) {
		print (shift(@stack));

	# Set label
	} elsif ($tokens =~ s/(NSS)//) {
		$tokens =~ s/^([S|T]*)N//;

	# Call sub routine
	} elsif ($tokens =~ s/^(NST)//) {
		$tokens =~ s/^([S|T]*)N//;
		my $subRoutineLabel = $1;
		$tempClonedCommand = $commandClone;
		$tempClonedCommand =~ s/^[S|T|N]*NSS${subRoutineLabel}N//;
		$beforeSubRoutineCall = $tokens;
		$tokens = $tempClonedCommand;

	# Unconfitional Jump
	} elsif ($tokens =~ s/^(NSN)//) {
		$tokens =~ s/^([S|T]*)N//;
		my $unconJumpLabel = $1;
		$tempClonedCommand = $commandClone;
		$tempClonedCommand =~ s/^[S|T|N]*NSS${unconJumpLabel}N//;
		$tokens = $tempClonedCommand;
	
	# JZ
	} elsif ($tokens =~ s/^(NTS)//) {
		$tokens =~ s/^([S|T]*)N//;
		my $jzLabel = $1;
		if ($stack[0] == 0) {
			$tempClonedCommand = $commandClone;
			$tempClonedCommand =~ s/^[S|T|N]*NSS${jzLabel}N//;
			$tokens = $tempClonedCommand;
		}

	# JM
	} elsif ($tokens =~ s/^(NTT)//) {
		$tokens =~ s/^([S|T]*)N//;
		my $jmLabel = $1;
		if ($stack[0] < 0) {
			$tempClonedCommand = $commandClone;
			$tempClonedCommand =~ s/^[S|T|N]*NSS${jmLabel}N//;
			$tokens = $tempClonedCommand;
		}

	# End of Sub Routine
	} elsif ($tokens =~ s/^NTN//) {
		$tokens = $beforeSubRoutineCall;

	# End of Programm
	} elsif ($tokens =~ s/^NNN//) {
		last;

	# Error
	} else {
		say "Syntax error";
		exit(1);
	}

	# End? (Command Strings are null)
	if ($tokens eq '') {
		last;
	}

}

sub lexicalAnalyze {
	my($inputFilename) = @_;
	open(FH, $inputFilename);

	my @tokenList;
	foreach(<FH>) {
		s/\x0D?\x0A$//g; # chomp
		for(;;) {
			if(s/^はぁ、豊崎愛生さん…//) {
				push(@tokenList, "S");
			} elsif (s/^僕は…//) {
				push(@tokenList, "T");
			} elsif (s/^もう…！//) {
				push(@tokenList, "N");
			} elsif (s/^.//) {
				# Nothing to do.
			} else {
				last;
			}
		}
	}

	return join('', @tokenList);
}
