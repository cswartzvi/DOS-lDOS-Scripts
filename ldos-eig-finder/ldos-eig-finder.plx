#! /usr/bin/perl -w

use strict;
use warnings;

if ($#ARGV != 1) {
   print " ERROR: Arguments must be 1)ldos file name 2)Eig file name\n\n";
   exit 2;
}

my $ldos_file = $ARGV[0]; 
my $eig_file = $ARGV[1];

open LDOSFILE, "<", $ldos_file or die " ERROR: Cannot open $ldos_file!!\n";
open EIGFILE, "<", $eig_file or die " ERROR: Cannot open $eig_file!!\n";

my @ldos_lines = <LDOSFILE>;
my @eig_lines = <EIGFILE>;

close  LDOSFILE;
close  EIGFILE;


#Loop through the ldos file, find highest pike
#----------------------------------------------------------
my $high_val = 0.0;
my $high_energy = 0.0;

foreach my $i (0 .. $#ldos_lines) {
  
   my @temp = split /\s+\n?/, $ldos_lines[$i];
   #print "$temp[1] $temp[2] \n";

   if ($temp[2] > $high_val) {
      $high_val = $temp[2];
      $high_energy= $temp[1];
   }

}

#Debug: Highest value
#print "\n\n Highest value $high_val, at $high_energy\n\n";
#----------------------------------------------------------

#Loop through to find all the major pikes
#----------------------------------------------------------
my @peaks = ();

foreach my $i (0 .. $#ldos_lines) {
   my @temp = split /\s+\n?/, $ldos_lines[$i]; 
   if ( $temp[2] > ((1/4)*$high_val) ) {
      push @peaks, $temp[1]; 
   }
}

#Debug: Peak Energies
#print"\n\n Total Peaks:\n";
#print"\n@peaks\n\n";
#----------------------------------------------------------

#Loop through the eig file find eig valueswithing the tolerance
#----------------------------------------------------------
my @eigen = ();
my $eigen_num = undef;
my $current_diff = undef;

foreach my $nl (0 .. $#peaks) { 
   $current_diff = 100;
   foreach my $ne (0 .. $#eig_lines) {
      if ($eig_lines[$ne] ne  "\n"){
         my @temp = split /\s+/, $eig_lines[$ne];
         #print "$temp[0]\n";

         my $diff = abs($peaks[$nl] - $temp[0]);
         if ($diff < $current_diff) {
            $current_diff = $diff;
            $eigen_num =  $ne + 1;
         }
      }
   }
   #Debug: Print Eigen Number
   #print "\n\n Eigen $nl : $eigen_num";

   #check to make sure that this eigenvalue isn't already found
   my $new = 1;
   foreach my $i (0 .. $#eigen){
      if ($eigen_num == $eigen[$i]){
         $new = 0;
      }
   } 
   if ($new) { push @eigen, $eigen_num};
}
print "@eigen\n";
#----------------------------------------------------------
