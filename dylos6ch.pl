#!/usr/bin/perl
#Takes in a dylos log file with and without a .csv extension and creates a proper .csv if not created already
#as well as -2ch.csv and -6ch.csv, which are low-passed versions of the original dylos file using an 
#exponential weighted average filter. The -2ch.csv file is "columns" 1-3 and 4-6 added together.
#Written by Nolan Hergert for BodyTrack, Summer 2011

use strict;
use warnings;

my $windowSize = 15;			#Size of averaging window (seconds)
my $alpha = 2/($windowSize+1);	#Calculate time constant (RC) 
					#http://taylortree.com/exponential-moving-average-ema/
my $delta;						#Time difference between readings 
								#in case we jump a reading

my $line;				#Current line
my @values; 			#Array of values
my $timeOld;			#Old Timestamp
my @averages;			#Average array
my $count;				#Helper var
my $republish = 0;

my $name = `basename $ARGV[0] .csv`;
chomp($name);
open (INFIL, "<$ARGV[0]") || die ("Can't open $ARGV[0] for reading");
if (!(-e "$name.csv")) {
	open (OUTFIL, ">$name.csv") || die ("Can't open $name.csv for writing");
	$republish = 1;
}
open (OUTFIL6CH, ">$name-6ch.csv") || die ("Can't open $name-6ch.csv for writing");
open (OUTFIL2CH, ">$name-2ch.csv") || die ("Can't open $name-2ch.csv for writing");

$line = readline(INFIL);
chomp($line); 	#remove \n
$line =~ tr/"//d; 		#Getting rid of all " in line
$line =~ tr/\t/,/d;		#Replace tab with comma
@values = split(',',$line);
$timeOld = $values[0];
for ($count = 0; $count < 6; $count++) {
	$averages[$count] = $values[$count+1];		#Prevent initial ramp-up
}
write_to_files();

while (<INFIL>) { 	#Iterates line by line through infil
	$line = $_; 	#Get current line
	chomp($line); 	#remove \n
	
	$line =~ tr/"//d; 				#Getting rid of all " in line
	$line =~ tr/\t/,/d;				#Replace tab with comma
	@values = split(',',$line);	
	$delta = $values[0] - $timeOld;	#If delta > 1, apply delta to alpha coefficient	
	$timeOld = $values[0];
	#Apply exponential moving average to keep it speedy
	#If we miss some samples, trust the previous data that much less
	#Also, the Dylos clock is slightly off, resulting in 61 readings in 60 seconds
	if ($delta > 0) {
		for ($count = 0; $count < 6; $count++) {
			$averages[$count] = $alpha*$values[$count+1] + ((1-$alpha) ** $delta)*$averages[$count];
		}
		write_to_files();
	}
}

sub write_to_files
{
	if ($republish == 1) {
		print OUTFIL join(',',@values);
		print OUTFIL "\n";
	}
	
	#Print out 6-ch data
	print OUTFIL6CH $values[0] . ",";
	print OUTFIL6CH int($averages[0]) . ",";
	print OUTFIL6CH int($averages[1]) . ",";
	print OUTFIL6CH int($averages[2]) . ",";
	print OUTFIL6CH int($averages[3]) . ",";
	print OUTFIL6CH int($averages[4]) . ",";
	print OUTFIL6CH int($averages[5]);	
	print OUTFIL6CH "\n";
	
	print OUTFIL2CH $values[0] . ",";
	print OUTFIL2CH int($averages[0] + $averages[1] + $averages[2]) . ",";
	print OUTFIL2CH int($averages[3] + $averages[4] + $averages[5]);
	print OUTFIL2CH "\n";

}

close(INFIL);
close(OUTFIL6CH);
close(OUTFIL2CH);
