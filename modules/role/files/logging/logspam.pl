#!/usr/bin/env perl

# This deduplicates exceptions from exception.log and error.log and prints them
# with a leading count of their occurrence and a snippet of the stacktrace.
#
# In practice, you may want the logspam-watch wrapper.
#
# This is hacky and contains many assumptions, but has proven useful when
# watching for breakage during deploys.

use warnings;
use strict;
use 5.10.0;

use List::Util qw(min max);

my $terminal_width = `tput cols`;
chomp $terminal_width;

# Default to /srv/mw-log, use MW_LOG_DIRECTORY if available from
# environment:
my $mw_log_dir = '/srv/mw-log';
if (defined $ENV{MW_LOG_DIRECTORY}) {
  $mw_log_dir = $ENV{MW_LOG_DIRECTORY};
}

my $loglines = tail("${mw_log_dir}/exception.log")
             . tail("${mw_log_dir}/error.log");

# Treat the datestamped log line as a separator between records - we're
# interested in how often the stack trace appears
my @errors = split m{

  ^           # start of datestamped log line
    [\d-]{10} # datestamp
    .*        # remainder of line
  $           # EOL

}mx, $loglines;

# A pattern for extracting exception names and the invariant stack traces from
# errors looking like so:
# [Exception WMFTimeoutException] (/srv/mediawiki/wmf-config/set-time-limit.php:39) the execution time limit of 60 seconds was exceeded
#   #0 /srv/mediawiki/php-1.35.0-wmf.4/includes/parser/Preprocessor_Hash.php(689): {closure}(integer)
#   #1 /srv/mediawiki/php-1.35.0-wmf.4/includes/parser/Parser.php(3125): Preprocessor_Hash->preprocessToObj(string, integer)
#   ...
my $exception_pat = qr{
  ^                         # Start of error
    \[Exception [ ] (.*?)\] # Yank out the class of our exception
    (.*?)                   # Stack trace
  $                         # End of error
}mx;

# Count times each stacktrace appears:
my %unique_errors;
my $max_exception_len = 0;
foreach (@errors) {
  if ( $_ =~ $exception_pat ) {
    # Retain this for display use:
    $max_exception_len = max(length $1, $max_exception_len);

    my $unique_error_msg = "$1\t$2";
    $unique_error_msg =~ s/^ \s+ | \s+ $//gx; # Strip whitespace.
    $unique_errors{$unique_error_msg}++;
  }
}

my $display_width = $terminal_width - ($max_exception_len + 16);

foreach (keys %unique_errors) {
  my ($exception, $trace) = split "\t";

  my $count = $unique_errors{$_};
  my $display_exception = sprintf("% ${max_exception_len}s", $exception, $_);
  my $display_trace = substr($trace, 0, $display_width);

  say join "\t", ($count, $display_exception, $display_trace);
}

# I'm being incredibly lazy here and shelling out to tail:
sub tail {
  my ($file) = @_;
  return `tail -3000 $file`;
}
