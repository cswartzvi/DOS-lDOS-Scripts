#! /usr/bin/perl -w

use strict;
use warnings;

my $dos_name= 'dos';
my $ldos_name= 'intKS';
my $ext= 'dat';

####################################################################################
# Input
####################################################################################
#Energy Values
my $Estart = -60.0;
my $Estop = 30.0;
my $dE = 0.01;

#Allginment values
my $cutoff = 0.001;                 #- Threshold for aligning DOS and lDOS
my $cutoff_search = -8.0;           #- Value At which we start to search or this Threshold
my $cutoff_check  = 0.8;            #- Error check to make sure that we start searching for
                                    #   the Threshold in a (+/-) region that is ALREADY 
                                    #   below the threshold
####################################################################################
####################################################################################

if ($#ARGV != 1){
   print " ERROR: DOS and lDOS directories need to be command line arguments\n";
   print "    1) Density of States \n";
   print "    2) Local Density of States \n\n";
   exit 5;
}

my $dos_dir = $ARGV[0];
my $ldos_dir = $ARGV[1];

printf "----------------------------------\n";
printf "\n Average DOS/LDOS (with Shift) \n";
printf("\n  Starting Energy          : %6.3f", $Estart);
printf("\n  Ending Energy            : %6.3f", $Estop);
printf("\n  Energy interval          : %6.3f", $dE);
printf("\n  DOS Threshold            : %6.3f", $cutoff);
printf("\n  DOS Threshold start      : %6.3f", $cutoff_search);
printf("\n  DOS Threshold +/- check  : %6.3f\n", $cutoff_check);
printf "----------------------------------\n\n";

my $num_dos = 0;
my $num_ldos = 0;

my @dos_total = undef;
my @ldos_total = undef;
my $int_num = undef;

#Compute the number of intervals in E range
$int_num = ($Estop - $Estart)/$dE;

#intialize $dos_total
foreach my $i (0 .. $int_num){
   $dos_total[$i] = 0.0;
}

foreach my $fp (glob("$dos_dir/$dos_name.$ext*")) {
   
   #Reset shift value ( 0 == NOT set!!)
   my $shift = undef;

   my ( @val_tmp, $En_start_tmp, $En_stop_tmp, @temp ) = undef; 

   #Open File DOS File
   printf " DOS File: %s", $fp;
   open my $dos_fh, "<", $fp or die "\n ERROR: can't read open $fp\n";

   ##Open File lDOS File
   my ($num) = $fp =~ /([^.]+)$/;
   my $ldos_file = "$ldos_dir/$ldos_name.$num";
   printf ", lDOS File: %s", $ldos_file;
   my $fileopened = open my $ldos_fh, "<", $ldos_file;

   #####################################################################################3
   # DOS
   #####################################################################################3
   
   my @lines = <$dos_fh>;
   close $dos_fh or die "\n ERROR: can't read close $dos_fh\n";


   #Read in each file Create temp arrays
   foreach my $i (0 .. $#lines){
      @temp = split /\s+\n?/, $lines[$i];

      #temp varaibles
      if ($i == 0){  
         $En_start_tmp = $temp[1];
         $val_tmp[0] = $temp[2];
      }
      elsif ($i == $#lines){
         $En_stop_tmp = $temp[1];
      }
      else {
         push @val_tmp, $temp[2];
      }


      #check to see if we are above the cutoff_search value. This is where we will actively 
      #search for a value greater then or equal to the cutoff => $shift
      if ( abs($cutoff_search - $temp[1]) < $cutoff_check && $temp[2] > $cutoff ){
         print "\n  ERROR: Active cutoff search initialized to early. Adjust cutoff_search value.\n";
         exit 5;
      }
      if ($temp[1] > $cutoff_search && $temp[2] >= $cutoff && not defined $shift ){ 
         $shift = $temp[1]; 
         print ", shift: $shift \n";
      }
   }


   #Error Check 
   my $check_dE = ($En_stop_tmp - $En_start_tmp)/($#lines );
   if ( $check_dE != $dE){
      print "\n ERROR: Script Interval not Aligned with those in $fp, Check dE!!\n";
      print "          Script Interval: $dE,     $fp Interval: $check_dE \n\n";
      exit 5;
   }

   #--------------------------------------------------------------------------------
   #Here we build the $dos_total array
   #Starting from $Estart (in @En) let $dos_total ==0 until we reach the first $En_tmp value
   #then fill in all those $dos_tmp values into $dos_total until th array is depleted
   #after which fill the remaining @En numbers in $dos_total until $Estart with zero
   #
   #$dos_total{$i} ==
   # $i == |$Estart .... $En_start_tmp ... (end of $dos_tmp) ... $Estop| 
   #
   my $En = 0.0;
   foreach my $i (0 .. $int_num) {
      
      $En = $i*$dE + $Estart;

      if ($En >= ($En_start_tmp - $shift)){
         if (@val_tmp) {
 
            #Update the $dos_total
            my $add = shift @val_tmp or die "ERROR at $i";
            $dos_total[$i] += $add;
         }
         elsif (not @val_tmp) {
            $dos_total[$i] += 0.0;
         }
      }
      else{
         $dos_total[$i] += 0.0;
         }

   }
   #Update ldos number
   $num_dos += 1;
   #####################################################################################3
   


   #####################################################################################3
   # LDOS
   #####################################################################################3

   # Check to see if there is a ldos file
   if (not $fileopened){
      print "\n WARNING: $ldos_file does not exist. Skipping File.\n";
      next;
   }

   @lines = <$ldos_fh>;
   close $ldos_fh or die "\n ERROR: can't read close $ldos_fh\n";

   #Read in each file Create temp arrays
   foreach my $i (0 .. $#lines){
      @temp = split /\s+\n?/, $lines[$i];

      #temp varaibles
      if ($i == 0){  
         $En_start_tmp = $temp[1];
         $val_tmp[0] = $temp[2];
      }
      elsif ($i == $#lines){
         $En_stop_tmp = $temp[1];
      }
      else {
         push @val_tmp, $temp[2];
      }
   }


   #Error Check 
   my $check_dE = ($En_stop_tmp - $En_start_tmp)/($#lines );
   if ( $check_dE != $dE){
      print "\n ERROR: Script Interval not Aligned with those in $ldos_fh Check dE!!\n";
      print "          Script Interval: $dE,     $fp Interval: $check_dE \n\n";
      exit 5;
   }

   #--------------------------------------------------------------------------------
   #Here we build the $ldos_total array
   #Starting from $Estart (in @En) let $ldos_total ==0 until we reach the first $En_tmp value
   #then fill in all those $dos_tmp values into $ldos_total until th array is depleted
   #after which fill the remaining @En numbers in $ldos_total until $Estart with zero
   #
   #$dos_total{$i} ==
   # $i == |$Estart .... $En_start_tmp ... (end of $val_tmp) ... $Estop| 
   #
   my $En = 0.0;
   foreach my $i (0 .. $int_num) {
      
      $En = $i*$dE + $Estart;

      if ($En >= ($En_start_tmp - $shift)){
         if (@val_tmp) {
 
            #Update the $ldos_total
            my $add = shift @val_tmp or die "ERROR at $i";
            $ldos_total[$i] += $add;
         }
         elsif (not @val_tmp) {
            $ldos_total[$i] += 0.0;
         }
      }
      else{
         $ldos_total[$i] += 0.0;
         }

   }
   #--------------------------------------------------------------------------------

   #Update ldos number
   $num_ldos += 1;
   #####################################################################################3
}


printf "\n\n\n Number of DOS Files  : %d\n", $num_dos;
printf " Number of lDOS Files : %d\n\n", $num_ldos;

#DOS Print
open FNAME, ">$dos_name-avg.$ext";
select FNAME;
my $En = 0.0;
foreach my $i (0 .. $int_num) {

   $En = $i*$dE + $Estart;
      
   $dos_total[$i] = $dos_total[$i]/$num_dos;
   printf("%e %e \n", $En, $dos_total[$i]);

}
close FNAME;

#lDOS Print
open FNAME, ">$ldos_name-avg.$ext";
select FNAME;
my $En = 0.0;
foreach my $i (0 .. $int_num) {

   $En = $i*$dE + $Estart;
      
   $ldos_total[$i] = $ldos_total[$i]/$num_ldos;
   printf("%e %e \n", $En, $ldos_total[$i]);

}
close FNAME;

select STDOUT;
