#! /usr/bin/perl -w

use strict;
use warnings;

my $name = 'intKS';
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
if ($#ARGV != 0 ) }


printf "----------------------------------\n";
printf "\n Average lDOS (with Shift) \n";
printf("\n  Shift Value (From DOS)   : %5.2f", $shift);
printf("\n  Starting Energy          : %5.2f", $Estart);
printf("\n  Ending Energy            : %5.2f", $Estop);
printf("\n  Energy interval          : %5.2f", $dE);
printf("\n  DOS Threshold            : %5.2f", $cutoff);
printf("\n  DOS Threshold start      : %5.2f", $cutoff_search);
printf("\n  DOS Threshold +/- check  : %5.2f\n", $cutoff_check);
printf "----------------------------------\n\n";

my $num_loops = 0;

my @val_total = undef;
my $int_num = undef;

#Compute the number of intervals in E range
$int_num = ($Estop - $Estart)/$dE;

#intialize $val_total
foreach my $i (0 .. $int_num){
   $val_total[$i] = 0.0;
}

my $dir = '.';
foreach my $fp (glob("$dir/$name.$ext*")) {
   
   #Open File
   printf "%s", $fp;
   open my $fh, "<", $fp or die "\n ERROR: can't read open $fp\n";
   my @lines = <$fh>;
   close $fh or die "\n ERROR: can't read close $fp\n";


   #Reset shift value ( 0 == NOT set!!)
   my $shift = undef;

   #Read in each file Create temp arrays
   my ( @val_tmp, $En_start_tmp, $En_stop_tmp, @temp ) = undef; 
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
   #Here me build the $val_total array
   #Starting from $Estart (in @En) let $val_total ==0 until we reach the first $En_tmp value
   #then fill in all those $val_tmp values into $val_total until th array is depleted
   #after which fill the remaining @En numbers in $val_total until $Estart with zero
   #
   #$val_total{$i} ==
   # $i == |$Estart .... $En_start_tmp ... (end of $val_tmp) ... $Estop| 
   #
   my $En = 0.0;
   foreach my $i (0 .. $int_num) {
      
      $En = $i*$dE + $Estart;

      if ($En >= ($En_start_tmp - $shift)){
         if (@val_tmp) {
 
            #Update the $val_total
            my $add = shift @val_tmp or die "ERROR at $i";
            $val_total[$i] += $add;
         }
         elsif (not @val_tmp) {
            $val_total[$i] += 0.0;
         }
      }
      else{
         $val_total[$i] += 0.0;
         }

   }
   #--------------------------------------------------------------------------------

   $num_loops += 1;
}


printf "%s\n", $num_loops;
open FNAME, ">$name-avg.$ext";
select FNAME;
my $En = 0.0;
foreach my $i (0 .. $int_num) {

   $En = $i*$dE + $Estart;
      
   $val_total[$i] = $val_total[$i]/$num_loops;
   printf("%e %e \n", $En, $val_total[$i]);

}
close FNAME;
select STDOUT;
