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
my @stack;
my $address;
my $clonedTokens = $tokens;
my $tempClonedTokens;
my @tokensBeforeCalledSubRoutine;

# Dispatch
for(;;) {

	# Push to stack
	if ($tokens =~ s/^(SS)//) {
		$tokens =~ s/^([S|T]*)N//;
		unshift(@stack, &token2bin($1));
	}

	# Copy top of stack
	elsif ($tokens =~ s/^SNS//) {
		unshift(@stack, $stack[0]);
	}

	# Swap top of the stack for the second of stack
	elsif ($tokens =~ s/^SNT//) {
		my $first = shift(@stack);
		my $second = shift(@stack);
		unshift(@stack, $second);
		unshift(@stack, $first);
	}

	# Drop top of stack
	elsif ($tokens =~ s/^SNN//) {
		shift(@stack);
	}

	# Add
	elsif ($tokens =~ s/^TSSS//) {
		my $first = shift(@stack);
		my $second = shift(@stack);
		unshift(@stack, ($first + $second));
	}

	# Sub
	elsif ($tokens =~ s/^TSST//) {
		my $first = shift(@stack);
		my $second = shift(@stack);
		unshift(@stack, ($first - $second));
	}

	# Mult
	elsif ($tokens =~ s/^TSSN//) {
		my $first = shift(@stack);
		my $second = shift(@stack);
		unshift(@stack, ($first * $second));
	}

	# Div
	elsif ($tokens =~ s/^TSTS//) {
		my $first = shift(@stack);
		my $second = shift(@stack);
		unshift(@stack, ($first / $second));
	}

	# Mod
	elsif ($tokens =~ s/^TSTT//) {
		my $first = shift(@stack);
		my $second = shift(@stack);
		unshift(@stack, ($first % $second));
	}

	# Store value to address
	elsif ($tokens =~ s/^TTS//) {
		$address = shift(@stack);
	}

	# Push content of address to stack
	elsif ($tokens =~ s/^TTT//) {
		if(defined($address)) {
			unshift(@stack, $address);
		} else {
			say "Address is not stored.";
			exit(1);
		}
	}

	# Output character of top of the stack
	elsif ($tokens =~ s/TNSS//) {
		print (pack "C*", shift(@stack));
	}

	# Output number of top of the stack
	elsif ($tokens =~ s/TNST//) {
		print (shift(@stack));
	}

	# Set label
	elsif ($tokens =~ s/(NSS)//) {
		$tokens =~ s/^([S|T]*)N//;
	}

	# Unconfitional Jump
	elsif ($tokens =~ s/^NSN//) {
		$tokens =~ s/^([S|T]*)N//;
		my $unconJumpLabel = $1;

		$tempClonedTokens = $clonedTokens;
		if ($tempClonedTokens =~ s/^[S|T|N]*NSS${unconJumpLabel}N//) {
			$tokens = $tempClonedTokens;
		} else {
			say "Error: Label (".&replaceToken2Word($unconJumpLabel).") is not defined.";
			exit(1);
		}
	}
	
	# Jump if top of the stack equals zero.
	elsif ($tokens =~ s/^NTS//) {
		$tokens =~ s/^([S|T]*)N//;
		my $jzLabel = $1;

		if ($stack[0] == 0) {
			$tempClonedTokens = $clonedTokens;
			if($tempClonedTokens =~ s/^[S|T|N]*NSS${jzLabel}N//) {
				$tokens = $tempClonedTokens;
			} else {
				say "Error: Label (".&replaceToken2Word($jzLabel).") is not defined.";
				exit(1);
			}
		}
	}

	# Jump if top of the stack smaller than zero.
	elsif ($tokens =~ s/^(NTT)//) {
		$tokens =~ s/^([S|T]*)N//;
		my $jmLabel = $1;

		if ($stack[0] < 0) {
			$tempClonedTokens = $clonedTokens;
			if($tempClonedTokens =~ s/^[S|T|N]*NSS${jmLabel}N//) {
				$tokens = $tempClonedTokens;
			} else {
				say "Error: Label (".&replaceToken2Word($jmLabel).") is not defined.";
				exit(1);
			}
		}
	}

	# Call sub routine
	elsif ($tokens =~ s/^(NST)//) {
		$tokens =~ s/^([S|T]*)N//;
		my $subRoutineLabel = $1;

		$tempClonedTokens = $clonedTokens;
		if($tempClonedTokens =~ s/^[S|T|N]*NSS${subRoutineLabel}N//) {
			unshift(@tokensBeforeCalledSubRoutine, $tokens);
			$tokens = $tempClonedTokens;
		} else {
				say "Error: Label (".&replaceToken2Word($subRoutineLabel).") is not defined.";
				exit(1);
		}
	}

	# End of Sub Routine
	elsif ($tokens =~ s/^NTN//) {
		$tokens = shift(@tokensBeforeCalledSubRoutine);
	}

	# End of Programm
	elsif ($tokens =~ s/^NNN//) {
		last;
	}

	# Error
	else {
		say "Syntax error";
		exit(1);
	}

	# End (Command Strings are null)
	if ($tokens eq '') {
		last;
	}

}

###########################################################################################

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

sub token2bin {
		my($num) = @_;
		$num =~ s/S/0/g;
		$num =~ s/T/1/g;
		return unpack("C*", pack("B*", $num));
}

sub replaceToken2Word {
	my($label) = @_;

	$label =~ s/S/はぁ、豊崎愛生さん…/g;
	$label =~ s/T/僕は…/g;
	$label =~ s/N/もう…！/g;

	return $label;
}
