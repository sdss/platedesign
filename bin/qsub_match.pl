#!/usr/bin/perl
#
# qsub_match.pl
#
# Submits PBS job that perform spectro-photo matching.
#
# Usage:
#   qsub_match.pl [--test] [--verbose] [--platerun=platerun]
#                 [--clobber]
#
# Options:
#   --platerun    - run on this platerun
#   --test        - Create PBS files but do not submit them
#   --verbose     - Print lots of extra stuff.
#   --clobber     - Pass the /clobber keyword to the idl routines
#
# M. Blanton, NYU
# (Based on create_match_jobs.pl B. A. Weaver, NYU)
#
use warnings;
use strict;
use Getopt::Long;
use File::Find;
use IO::File;
#
# Defaults
#
my $test = 0;
my $verbose = 0;
my $platerun = 0;
my $clobber = 0;
GetOptions( 'test' => \$test, 'verbose' => \$verbose, 
    'platerun=s' => \$platerun, 'clobber' => \$clobber );
die "You must specify a plate run!" if (!$platerun);
#
# Directory to write job files
#
my $jobdir = "$ENV{HOME}/jobs";
my ($jobname, $matchcommand);
mkdir $jobdir unless -d $jobdir;
mkdir "$jobdir/done" unless -d "$jobdir/done";
chdir $jobdir;
$jobname = "match-$platerun";
$matchcommand = qq{platerun_match, '$platerun'};
$matchcommand .= ", /clobber" if $clobber;
my $filename = "$jobdir/$jobname.csh";
my $job = IO::File->new(">$filename");
print $job <<EOT;
#!/bin/tcsh
# Turn off mail
#PBS -m n
# Merge standard error with standard output
#PBS -j oe
# Project/repo for accounting
#PBS -A boss
# Job name
#PBS -N $jobname
# Job queue
#PBS -q data_io
# Set a good umask for output files
#PBS -W umask=0022
# Job requirements
# END OF PBS DIRECTIVES
#
# Startup message
#
echo -n "Starting up at "
/bin/date
#
# Setup what we need
#
setup photoop trunk
setup platedesign trunk
setup platelist trunk
#
# Run IDL
#
idl -e "$matchcommand"
set status1 = \${status}
if (\${status1} != 0) then
    echo "This job has died!"
    exit \${status1}
endif
#
# Finish up
#
/bin/mv --verbose $jobdir/$jobname.csh $jobdir/done
echo -n "Finishing up at "
/bin/date
exit 0

EOT

$job->close();
my $id = $test ? 0 : qsub($filename);
print "$id\n" if $verbose and not $test;

sub qsub
{
    my $job = shift;
    my $jobid = `qsub $job`;
    chomp $jobid;
    return $jobid;
}

