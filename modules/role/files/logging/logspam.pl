#!/usr/bin/env perl

=pod

=head1 NAME

logspam - summarize exceptions from production logs

=head1 USAGE

    logspam [ --window MINUTES ] [ --minimum-hits N ] [ filter-pattern ... ]

=head2 EXAMPLES

    # Just get a list of exceptions since the last log rotation:
    logspam

    # Get a list of exceptions matching a Perl regular expression:
    logspam 'Use of.*'

    # Get a list of exceptions for the last hour:
    logspam --window 60

    # Get a list of exceptions for the half hour, hiding any exceptions
    # that only occurred once.
    logspam --window 60 --minimum-hits 2

    # Monitor logspam output every 30 seconds, sorted:
    watch -n 30 sh -c "./bin/logspam | sort -nr"

    # A shell wrapper with interactive sorting and filtering:
    logspam-watch

=head1 DESCRIPTION

This deduplicates exceptions from exception.log and error.log, then
prints them with a leading count of their occurrence and a snippet of the error
message / stack trace.  In the interests of concision, it shortens exception
names by removing any trailing "Exception" and condenses file paths.

In practice, you may want the logspam-watch wrapper.

This is hacky and contains many assumptions, but has proven useful when
watching for breakage during deploys.

=cut

use warnings;
use strict;
use 5.10.0;
use utf8;

use open ':std', ':encoding(UTF-8)';

use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);
use List::Util qw(min max);
use Time::Piece;
use Time::Seconds;
use Getopt::Long;
use Pod::Usage;

# YYYY-MM-DD HH:MM:SS.MMMMMM [requestid] host wiki version ......
my $header_pat = qr{^([\d-]{10} [\d:]{8})[.]\d{6} \[\S+\] (\S+)};

# Silence rare but irritating UTF-8 warnings.  You may wish to disable this for
# development purposes:
local $SIG{__WARN__} = sub {
  my $message = shift;
  warn($message) unless $message =~ m/^utf.*/i;
};

my $window = 1440; # minutes. Default is 24 hour window.
my $minimum_hits = 0;
my $debug = 0;
my $cat_mode = 0;

GetOptions(
  'cat'            => \$cat_mode,
  'debug'          => \$debug,
  'window=i'       => \$window,
  'minimum-hits=i' => \$minimum_hits,
  help             => sub { pod2usage(0) },
) or pod2usage();

my $orig_window = $window;

# Convert minutes to seconds
$window *= 60;

# This is an undocumented mode used internally by this script.
if ($cat_mode) {
  my $cutoff = localtime() - $window;
  for my $file (@ARGV) {
      cat_window($file, $cutoff);
  }
  exit(0);
}

# By default, match all errors:
my $filter_pattern = qr/.*/;

# Handle user-defined filter patterns:
if (defined $ARGV[0]) {
  my $user_pattern = $ARGV[0];
  eval {
    $filter_pattern = qr/$user_pattern/;
  };
  if ($@) {
    # We got a fatal error, probably meaning that the user-supplied pattern
    # couldn't be compiled for one reason or another.  Fall back to using it as
    # a literal string.
    $filter_pattern = qr/\Q$user_pattern\E/;
  }
}

chomp(my $terminal_width = `tput cols`);

# Default to /srv/mw-log, use MW_LOG_DIRECTORY if available from
# environment:
my $mw_log_dir = '/srv/mw-log';
$mw_log_dir = $ENV{MW_LOG_DIRECTORY}
  if defined $ENV{MW_LOG_DIRECTORY};

my $cat_files_cmd = "$0 --cat --window $orig_window ${mw_log_dir}/exception.log ${mw_log_dir}/error.log";

open (my $logstream, "$cat_files_cmd |")
  or die("$0: Failed to run '$cat_files_cmd'\n$!\n");

my %consolidate_patterns = (
  qr/Allowed memory size of/                               => '[mem]',
  qr/the(?: maximum)? execution time(?: limit)? of \d+ seconds was exceeded/i => '[time]',
  qr/Memcached::setMulti\(\): failed to set key/           => '[memcache]',
  qr/Cannot access the database:/                          => '[db]',
  qr/max_statement_time exceeded/                          => '[db]',
);

# A pattern for extracting exception names and the invariant error messages /
# stack traces from errors looking like so:

my $exception_pat = qr{

  ^                      # Start of exception line

    \[                   # Yank out the class of our exception / error
      (Exception|Error)
      [ ]
      (.*?)
    \]

    (.*?)                # Error message

  $                      # EOL

}msx;

# Count times each error message appears.
# Values are Time::Piece objects.
my (%error_count, %error_timestamps, %first_dates, %last_dates);

my $now = localtime();
my $start_time;
if ($window) {
  $start_time = $now - $window;
}
my $timestamp;
my $host;

while (my $line = <$logstream>) {
  if ($line =~ /$header_pat/) {
    # Set timestamp then skip ahead to look for Exception:
    $timestamp = Time::Piece->strptime($1, "%Y-%m-%d %T");
    $host = $2;

    # If we haven't got a start time, use with the first thing in the log:
    $start_time //= $timestamp;
    next;
  }

  # Skip anything that doesn't match user-supplied filter:
  next unless $line =~ $filter_pattern;

  next unless $line =~ $exception_pat;

  # We don't care about messages from mwmaint* hosts.
  next if $host =~ /mwmaint/;

  if ($window > 0) {
    my $age = $now - $timestamp;
    next if $age > $window;
  }

  my $exception_class = $2;
  my $stack_trace = shorten($3);

  # Condense some common errors:
  for my $pattern (keys %consolidate_patterns) {
    if ($stack_trace =~ $pattern) {
      $exception_class = $consolidate_patterns{$pattern};
      $stack_trace = $pattern;
    }
  }

  # Drop the namespace of the exception class and chop off the typical
  # trailing "Exception":
  $exception_class =~ s{[a-z] [a-z]+ \\}{}xgi;
  $exception_class =~ s{Exception$}{};

  my $error_key = "$exception_class\t$stack_trace";
  $error_count{$error_key}++;

  # Assure that we have an empty arrayref if we haven't already stashed a
  # value, then add error's timestamp to list for histograms:
  $error_timestamps{$error_key} //= [ ];
  push @{ $error_timestamps{$error_key} }, $timestamp->epoch;

  # If a first-seen date isn't defined, set it:
  $first_dates{$error_key} //= $timestamp;
  $last_dates{$error_key} = $timestamp;
}
close($logstream);

# Collect max bin height and histogram rendering closures:
my $max_bin_height = 0;
my %histograms;
foreach (keys %error_timestamps) {
  my ($renderer, $max_bin_for_error) = histogram(
    $start_time->epoch,
    $now->epoch,
    @{ $error_timestamps{$_} }
  );
  $histograms{$_} = $renderer;
  $max_bin_height = max($max_bin_height, $max_bin_for_error);
}

# Set a hard limit of 20 characters for exceptions, for pathological cases:
my $max_exception_len = 20;
my $trace_width = $terminal_width - (38 + $max_exception_len);
my $hidden = 0;

# Display loop:
foreach (keys %error_count) {

  if ($error_count{$_} < $minimum_hits) {
    $hidden++;
    next;
  }

  my ($exception, $trace) = split "\t";

  # Our line template, essentially.  Separate fields with tabs for easy use
  # of sort(1) / cut(1) / awk(1) and friends:
  say join "\t", (
    $error_count{$_},
    $histograms{$_}->($max_bin_height),
    display_time($first_dates{$_}, $last_dates{$_}),
    pad_exception($exception),
    substr($trace, 0, $trace_width),
  );

}

if ($hidden) {
  say join "\t", (
    $hidden,
    '',
    "0000",
    "9999",
    pad_exception("<HIDDEN>"),
    "$hidden errors occuring less than $minimum_hits times each"
  );
}

=head1 SUBROUTINES

=over

=item pad_exception($exception)

Returns a version of $exception which has been trimmed/padded to
$max_exception_len characters.

=cut

sub pad_exception {
  my ($exception) = @_;

  # https://perldoc.perl.org/functions/sprintf.html
  # Pad/trim display name, then fill in some dots for easier reading:
  my $display_exception = sprintf("%-${max_exception_len}s", $exception);
  $display_exception = substr($display_exception, 0, $max_exception_len);
  $display_exception =~ tr/ /./;

  return $display_exception;
}

=item shorten($stack_trace)

Condense and format traces matching some common patterns.

=cut

sub shorten {
  my ($stack_trace) = @_;

  my $mw_root = '/srv/mediawiki/';

  # Strip trailing / leading whitespace:
  $stack_trace =~ s/^ \s+ | \s+ $//gx;

  if ( $stack_trace =~ m{^ \( $mw_root php-.*wmf([.].*?)/ (.*?) \) (.*) $}x ) {
    my ($version, $path, $trace) = ($1, $2, $3);
    $path = condense_path($path);
    $stack_trace = "$version $path $trace";
  }

  return $stack_trace;
}

=item condense_path($path)

Condense a typical file path by reducing to the first letter of each leading
particle and removing '.php' extensions, so that:

    includes/foo/bar/baz.php

Becomes:

    i/f/b/baz

=cut

sub condense_path {
  my ($path) = @_;

  # Condense directories to their first letter:
  $path =~ s!([a-z]) [a-z.]+ /!$1/!xgi;

  # Zap the first instance of .php - it's a given and it saves 4 chars:
  $path =~ s/[.]php//;

  return $path;
}

=item display_time(Time::Piece object, ...)

Condense datestamps in the format C<2020-01-01 00:00:00> for display.  Adds some
glyphs to flag especially recent events.

=cut

sub display_time {
  # Set this once, keep it around as a state var:
  state $now = localtime;

  return join "\t", map {
    # Indicate recency with glyph:
    my $t = $_;
    my $age = $now - $t;
    my $glyph = ' ';
    $glyph = '◦' if $age < 600; # 10 min
    $glyph = '○' if $age < 300; # 5 min
    $glyph = '◍' if $age < 150; # 2.5 min
    $glyph = '●' if $age < 60;  # 1 min

    # $glyph is concat'd here instead of included in the format string because
    # this strftime() doesn't play well with utf8:
    $t->strftime("%H%M ") . $glyph;
  } @_;
}

=item histogram($start, $end, @timestamps)

Takes start and end of range in epoch time and an array of timestamps.

Returns a callback to render a 7-character histogram scaled to max value, and
the value of the largest bin for the given error.

=cut

sub histogram {
  my $start = shift;
  my $end = shift;
  my (@timestamps) = @_;

  my @bars = qw( ▁ ▂ ▃ ▄ ▅ ▆ ▇ );
  my $bin_count = 7;
  my $range = $end - $start;
  my $bin_width = $range / $bin_count;

  # Divide time range into bins:
  my %bins;
  for (0..($bin_count - 1)) {
    my $bin_start = $start + ($_ * $bin_width);
    $bins{$bin_start} = 0;
  }

  # Count events falling into each bin:
  foreach my $event (@timestamps) {
    foreach my $bin (keys %bins) {
      if (($event > $bin) && ($event < ($bin + $bin_width))) {
        $bins{$bin}++;
        next;
      }
    }
  }

  my $biggest_bin = max(values %bins);

  # A closure which will render %bins into a histogram, scaled to the
  # provided max bin height - this way we can use the same scale for all
  # errors when we display them:
  my $renderer = sub {
    my ($max_bin_height) = @_;

    my $output;

    # Display a bar for each bin:
    foreach my $bin (sort keys %bins) {
      my $bar_level = 0;
      if ($max_bin_height == 1) {
        if ($bins{$bin}) {
          $bar_level = 1;
        }
      } else {
        $bar_level = int(
          (log($bins{$bin} + 1) / log($max_bin_height)) * (scalar @bars)
        );
      }
      my $bar = '_';
      if ($bar_level) {
        $bar = $bars[$bar_level - 1];
      }
      $output .= $bar;
    }

    return $output;
  };

  return ($renderer, $biggest_bin);
}

=item grok_nearest_timestamp($fh)

Reads lines from $fh until a line is read which has a parseable
timestamp.  Returns two values:
1) a Time::Piece representing the timestamp
2) the file position of the line

If EOF is reached, returns undef and the position of the end of file
(i.e, the file length).

=cut

sub grok_nearest_timestamp {
  my ($fh) = @_;

  my $pos = tell($fh);

  while (my $line = <$fh>) {
    if ($line =~ /$header_pat/) {
      return Time::Piece->strptime($1, "%Y-%m-%d %T"), $pos;
    }
    $pos = tell($fh);
  }

  return undef, $pos;
}

=item cat_window($filename, $cutoff)

Print the tail end of $filename to stdout, starting with log entries
with a timestamp near $cutoff.  All entries on or after $cutoff will
be printed.  There may also be a few earlier entries printed.

=cut

sub cat_window {
  my ($filename, $cutoff) = @_;

  my $fh;
  open($fh, $filename) || die("$0: Failed to open $filename: $!\n");

  my $low = 0;
  my $high = -s $filename;

  my $pos=0;
  my $probes=0;

  while ($low < $high) {
    $pos = int ( ($high + $low) / 2 );

    $probes++;
    my $width = $high - $low;
    print("$probes: [$low, $high] Width $width, Mid: $pos, ") if $debug;
    seek($fh, $pos, SEEK_SET) || die("$0: failed to seek to position $pos: $!\n");

    my ($ts, $actual_pos) = grok_nearest_timestamp($fh);
    print("(actual $actual_pos) $ts") if $debug;

    if ($actual_pos >= $high) {
      print(" No more progress. Using low position\n") if $debug;
      $pos = $low;
      last;
    }

    $pos=$actual_pos;

    if ($ts >= $cutoff) {
      print(" <<<<\n") if $debug;
      # We're within the data we want. Back up to make sure we
      # didn't miss anything.
      $high = $pos;
    } else {
      print(" >>>>\n") if $debug;
      # We're in too-old data.  No need to go further back.
      $low = $pos;
    }
  }

  if ($debug) {
    print("Would start reading the file at position $pos\n");
  } else {
    seek($fh, $pos, SEEK_SET) || die("$0: failed to seek to position $pos: $!\n");

    while (<$fh>) {
      print;
    }
  }
  close($fh);
}

=back
