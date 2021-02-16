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

    # A shell wrapper with interactive sorting and filtering: 
    logspam-watch

    # Monitor logspam output every 30 seconds, sorted:
    watch -n 30 sh -c "./bin/logspam | sort -nr"

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
# Avoid messages like: utf8 "\xD7" does not map to Unicode at ./modules/role/files/logging/logspam.pl line 124, <$logstream> line 129347.
no warnings 'utf8';
use open qw(:std :utf8);

use List::Util qw(min max);
use Time::Piece;
use Time::Seconds;
use Getopt::Long;
use Pod::Usage;

my $window = 0; # minutes.  0 means no window defined
my $minimum_hits = 0;

GetOptions(
  "window=i" => \$window,
  "minimum-hits=i" => \$minimum_hits,
) or pod2usage();

# Convert minutes to seconds
$window *= 60;

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
    $filter_pattern = qr/\Q$user_pattern\E/
  }
}

my $terminal_width = `tput cols`;
chomp $terminal_width;

# Default to /srv/mw-log, use MW_LOG_DIRECTORY if available from
# environment:
my $mw_log_dir = '/srv/mw-log';
$mw_log_dir = $ENV{MW_LOG_DIRECTORY}
  if defined $ENV{MW_LOG_DIRECTORY};

my $cat_files_cmd = "cat ${mw_log_dir}/exception.log ${mw_log_dir}/error.log";

open (my $logstream, "$cat_files_cmd |")
  or die("$0: Failed to run '$cat_files_cmd'\n$!\n");

my %consolidate_patterns = (
  qr/Allowed memory size of/                               => '[mem]',
  qr/the execution time limit of \d+ seconds was exceeded/ => '[time]',
  qr/Memcached::setMulti\(\): failed to set key/           => '[memcache]',
);

my $timestamp_pat = qr{^([\d-]{10} [\d:]{8})};

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
my (%error_count, %first_dates, %last_dates);

my $now = localtime();
my $timestamp;

while (<$logstream>) {
  if (/$timestamp_pat/) {
    $timestamp = Time::Piece->strptime($1, "%Y-%m-%d %T");
    next;
  }

  if (/$exception_pat/) {
   if ($window > 0) {
     my $age = $now - $timestamp;
     next if $age > $window;
   }

   my $exception_class = $2;
   my $stack_trace = shorten($3);
   my $matched_line = $&; # (the whole match)

   # Make sure any user-supplied filter matches:
   next unless $matched_line =~ $filter_pattern;

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

   # If a first-seen date isn't defined, set it:
   $first_dates{$error_key} //= $timestamp;
   $last_dates{$error_key} = $timestamp;
  }
}
close($logstream);

# Set a hard limit of 20 characters for exceptions, for pathological cases:
my $max_exception_len = 20;
my $trace_width = $terminal_width - (30 + $max_exception_len);

my $hidden = 0;

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
    display_time($first_dates{$_}, $last_dates{$_}),
    pad_exception($exception),
    substr($trace, 0, $trace_width),
  );
}

if ($hidden) {
  say join "\t", (
    $hidden,
    "0000", "9999",
    pad_exception("<HIDDEN>"),
    "$hidden errors occuring less than $minimum_hits times each");
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
  my $parsoid_root = '/srv/deployment/parsoid/deploy-cache/revs/';

  # Strip trailing / leading whitespace:
  $stack_trace =~ s/^ \s+ | \s+ $//gx;

  if ( $stack_trace =~ m{^ \( $mw_root php-.*wmf([.].*?)/ (.*?) \) (.*) $}x ) {
    my ($version, $path, $trace) = ($1, $2, $3);
    $path = condense_path($path);
    $stack_trace = "$version $path $trace";
  }

  if ( $stack_trace =~ m{^ \( $parsoid_root ([a-z0-9]{6}) .*? / (.*?) \) (.*) $}x) {
    my ($rev, $path, $trace) = ($1, $2, $3);
    $path = condense_path($path);
    $stack_trace = "parsoid:$rev $path $trace";
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
  state $now = localtime;
  return join "\t", map {
    # Indicate recency with a one or two character glyph:
    my $t = $_;
    my $age = $now - $t;
    my $glyph = ' ';
    $glyph = '.' if $age < 420;
    $glyph = '?' if $age < 240;
    $glyph = '!' if $age < 60;
    $t->strftime("%H%M $glyph");
  } @_;
}

=back
