#! /usr/bin/perl -w


use warnings;

my $num_loops = 0;

my $dir = '.';
foreach my $fp (glob("$dir/dos.dat*")) {
  printf "%s\n", $fp;
  open my $fh, "<", $fp or die "can't read open '$fp': $OS_ERROR";
  @lines = <$fh>;
  close $fh or die "can't read close '$fp': $OS_ERROR";

   #Read in and initialize each value
   foreach $i (0 .. $#lines){
      @temp = split /\s+\n?/, $lines[$i];
      if ($num_loops == 0) {
         #-------------------------------
         #Set Histogram values
         #-------------------------------
         $En[$i]   = $temp[1];
         $dos_total[$i] = 0.0;
      }
      $dos[$i] = $temp[2];
   }

   foreach $i (0 .. $#En) {
      $dos_total[$i] += $dos[$i];

   }

   $num_loops += 1;
}

printf "%s\n", $num_loops;
open FNAME, ">dos-avg.dat";
select FNAME;
foreach $i (0 .. $#En) {

   $dos_total[$i] = $dos_total[$i]/$num_loops;
   printf("%e %e \n", $En[$i], $dos_total[$i]);

}
close FNAME;
select STDOUT;
